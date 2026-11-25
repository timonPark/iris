import json
import threading
import time
import uuid
from collections.abc import Callable, Iterator
from dataclasses import dataclass
from datetime import UTC, datetime
from typing import Any

import httpx
import pytest
from sqlalchemy import func, select
from sqlalchemy.engine import Engine
from sqlalchemy.orm import sessionmaker

import app.runs as runs_module
from app.chat import EMPTY_ANSWER_PLACEHOLDER
from app.config import get_settings
from app.hermes import create_hermes_client
from app.models import Account, AccountStatus, Answer, AnswerStatus, ChatSession, Question
from tests.conftest import LiveServer
from tests.factories import AccountFactory, ChatFactory
from tests.fakes import CRASH, FAIL, HANG, FakeHermes
from tests.sse import Event, iter_events, names, read_events

pytestmark = pytest.mark.integration

URL: str = "/api/v1/sessions/questions"
ERROR_SERVER: dict[str, Any] = {"error": {"code": "SERVER_ERROR", "message": "서버 오류가 발생했습니다."}}


@dataclass
class Reply:
    status_code: int
    events: list[Event]  # SSE 응답이면 이벤트, 아니면 빈 목록
    body: dict[str, Any]  # 일반 JSON 응답이면 본문, 아니면 빈 사전


def token_of(live: LiveServer, account: Account, password: str = "correct-password") -> str:
    response: httpx.Response = httpx.post(
        f"{live.base_url}/api/v1/auth/login", json={"loginId": account.login_id, "password": password}
    )
    assert response.status_code == 200
    return response.json()["accessToken"]


def auth(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def ask(live: LiveServer, token: str, text: str, session_id: uuid.UUID | str | None = None) -> Reply:
    body: dict[str, Any] = {"text": text}
    if session_id is not None:
        body["sessionId"] = str(session_id)
    with httpx.Client(base_url=live.base_url, timeout=20) as client:
        with client.stream("POST", URL, json=body, headers=auth(token)) as response:
            if response.headers["content-type"].startswith("text/event-stream"):
                return Reply(response.status_code, read_events(response), {})
            response.read()
            return Reply(response.status_code, [], response.json())


def wait_until(check: Callable[[], bool], timeout: float = 10.0) -> None:
    deadline: float = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if check():
            return
        time.sleep(0.05)
    raise AssertionError("기다린 조건이 시간 안에 이루어지지 않았다")


def stored(engine: Engine, account: Account) -> list[tuple[str, str, AnswerStatus]]:
    """이 계정에 저장된 (질문, 답변, 답변 상태). 오래된 것부터."""
    with sessionmaker(engine)() as db:
        rows = db.execute(
            select(Question.text, Answer.text, Answer.status)
            .join(Answer, Answer.question_id == Question.id)
            .join(ChatSession, ChatSession.id == Question.session_id)
            .where(ChatSession.account_id == account.id)
            .order_by(Question.created_at)
        ).all()
        return [(row[0], row[1], row[2]) for row in rows]


def session_count(engine: Engine, account: Account) -> int:
    with sessionmaker(engine)() as db:
        return db.scalar(
            select(func.count()).select_from(ChatSession).where(ChatSession.account_id == account.id)
        ) or 0


@pytest.fixture(autouse=True)
def no_run_is_left_behind(live_server: LiveServer) -> Iterator[None]:
    """테스트가 끝났을 때 진행 중인 작업이 남아 있으면 다음 테스트를 오염시키므로 실패로 본다."""
    yield
    wait_until(lambda: live_server.app.state.runs.active_count() == 0, timeout=5)


# --- 정상 흐름 -------------------------------------------------------------------------


def test_first_question_streams_session_deltas_and_done_and_stores_the_pair(
    live_server: LiveServer, account_factory: AccountFactory, migrated_engine: Engine
) -> None:
    owner: Account = account_factory.create()
    live_server.app.state.hermes = FakeHermes(["안녕", "하세요"])
    reply: Reply = ask(live_server, token_of(live_server, owner), "오늘 날씨 어때?")
    assert reply.status_code == 200
    assert names(reply.events) == ["session", "delta", "delta", "done"]
    assert [data["text"] for name, data in reply.events if name == "delta"] == ["안녕", "하세요"]
    session_id: str = reply.events[0][1]["id"]
    assert stored(migrated_engine, owner) == [("오늘 날씨 어때?", "안녕하세요", AnswerStatus.COMPLETED)]
    with sessionmaker(migrated_engine)() as db:
        chat: ChatSession = db.get(ChatSession, uuid.UUID(session_id))
        assert (chat.account_id, chat.title) == (owner.id, "오늘 날씨 어때?")
        answer: Answer = db.scalars(select(Answer)).all()[-1]
        assert str(answer.id) == reply.events[-1][1]["answerId"]
    assert live_server.app.state.hermes.calls == [[{"role": "user", "content": "오늘 날씨 어때?"}]]
    sent: list[dict[str, str]] = live_server.app.state.hermes.raw_calls[0]
    assert sent[0]["role"] == "system" and "옵시디언" in sent[0]["content"]  # 자료 요청 지시문이 맨 앞에 붙는다
    with sessionmaker(migrated_engine)() as db:  # 지시문은 저장하지 않는다
        assert all("옵시디언" not in text for text in db.scalars(select(Question.text)).all())
        assert all("옵시디언" not in text for text in db.scalars(select(Answer.text)).all())


def test_response_is_a_server_sent_event_stream_without_caching(
    live_server: LiveServer, account_factory: AccountFactory
) -> None:
    owner: Account = account_factory.create()
    live_server.app.state.hermes = FakeHermes(["a"])
    with httpx.Client(base_url=live_server.base_url, timeout=20) as client:
        with client.stream(
            "POST", URL, json={"text": "질문"}, headers=auth(token_of(live_server, owner))
        ) as response:
            assert response.headers["content-type"].startswith("text/event-stream")
            assert "no-cache" in response.headers["cache-control"]
            assert response.headers.get("x-accel-buffering") == "no"
            response.read()


def test_followup_question_sends_the_whole_history_and_creates_no_new_session(
    live_server: LiveServer,
    account_factory: AccountFactory,
    chat_factory: ChatFactory,
    migrated_engine: Engine,
) -> None:
    owner: Account = account_factory.create()
    first = chat_factory.exchange(owner, "내 이름은 철수야", "반가워요 철수님")
    chat_factory.exchange(owner, "취미는 등산", "멋지네요", session_id=first.session_id)
    fake: FakeHermes = FakeHermes(["철수님이죠"])
    live_server.app.state.hermes = fake
    reply: Reply = ask(live_server, token_of(live_server, owner), "내 이름이 뭐지?", first.session_id)
    assert names(reply.events) == ["delta", "done"]  # 이미 있는 세션이라 session 이벤트가 없다
    assert fake.calls == [
        [
            {"role": "user", "content": "내 이름은 철수야"},
            {"role": "assistant", "content": "반가워요 철수님"},
            {"role": "user", "content": "취미는 등산"},
            {"role": "assistant", "content": "멋지네요"},
            {"role": "user", "content": "내 이름이 뭐지?"},
        ]
    ]
    assert session_count(migrated_engine, owner) == 1
    assert [q for q, _, _ in stored(migrated_engine, owner)][-1] == "내 이름이 뭐지?"


def test_context_includes_stopped_answers_and_marks_empty_ones(
    live_server: LiveServer, account_factory: AccountFactory, chat_factory: ChatFactory
) -> None:
    owner: Account = account_factory.create()
    first = chat_factory.exchange(owner, "긴 질문", "받은 부분", status=AnswerStatus.STOPPED)
    chat_factory.exchange(owner, "바로 멈춘 질문", "", session_id=first.session_id, status=AnswerStatus.STOPPED)
    fake: FakeHermes = FakeHermes(["ok"])
    live_server.app.state.hermes = fake
    ask(live_server, token_of(live_server, owner), "계속", first.session_id)
    assert [m["content"] for m in fake.calls[0]] == [
        "긴 질문", "받은 부분", "바로 멈춘 질문", EMPTY_ANSWER_PLACEHOLDER, "계속",
    ]


def test_only_the_questions_session_is_sent_not_other_sessions_or_users(
    live_server: LiveServer, account_factory: AccountFactory, chat_factory: ChatFactory
) -> None:
    owner: Account = account_factory.create()
    stranger: Account = account_factory.create()
    mine = chat_factory.exchange(owner, "내 세션 질문", "내 세션 답")
    chat_factory.exchange(owner, "내 다른 세션 질문", "내 다른 세션 답")
    chat_factory.exchange(stranger, "남의 비밀 질문", "남의 비밀 답")
    fake: FakeHermes = FakeHermes(["ok"])
    live_server.app.state.hermes = fake
    ask(live_server, token_of(live_server, owner), "이어서", mine.session_id)
    sent: str = str(fake.calls)
    assert "내 세션 질문" in sent
    assert "내 다른 세션" not in sent
    assert "남의 비밀" not in sent


def test_an_old_session_still_accepts_questions(
    live_server: LiveServer, account_factory: AccountFactory, chat_factory: ChatFactory,
    migrated_engine: Engine,
) -> None:
    owner: Account = account_factory.create()
    old = chat_factory.exchange(owner, "작년 질문", "작년 답", at=datetime(2025, 1, 1, tzinfo=UTC))
    live_server.app.state.hermes = FakeHermes(["새 답"])
    reply: Reply = ask(live_server, token_of(live_server, owner), "오랜만이야", old.session_id)
    assert names(reply.events) == ["delta", "done"]
    assert len(stored(migrated_engine, owner)) == 2


# --- 시작하기 전에 거부되는 경우(일반 JSON 오류, Hermes도 호출하지 않음, 아무것도 저장하지 않음) ---


@pytest.mark.parametrize(
    ("text", "code"),
    [("가" * 65_537, "QUESTION_TOO_LONG"), ("", "VALIDATION_FAILED"), ("   ", "VALIDATION_FAILED"),
     ("a\x00b", "VALIDATION_FAILED")],
)
def test_bad_questions_are_refused_before_anything_starts(
    live_server: LiveServer, account_factory: AccountFactory, migrated_engine: Engine,
    text: str, code: str,
) -> None:
    owner: Account = account_factory.create()
    fake: FakeHermes = FakeHermes()
    live_server.app.state.hermes = fake
    reply: Reply = ask(live_server, token_of(live_server, owner), text)
    assert (reply.status_code, reply.body["error"]["code"]) == (422, code)
    assert fake.calls == []
    assert session_count(migrated_engine, owner) == 0


def test_a_question_at_the_length_limit_is_accepted(
    live_server: LiveServer, account_factory: AccountFactory
) -> None:
    owner: Account = account_factory.create()
    live_server.app.state.hermes = FakeHermes(["ok"])
    reply: Reply = ask(live_server, token_of(live_server, owner), "가" * 65_536)
    assert names(reply.events)[-1] == "done"


def test_missing_foreign_deleted_and_malformed_sessions_are_session_not_found(
    live_server: LiveServer, account_factory: AccountFactory, chat_factory: ChatFactory
) -> None:
    owner: Account = account_factory.create()
    stranger: Account = account_factory.create()
    theirs = chat_factory.exchange(stranger, "남의 질문")
    gone = chat_factory.exchange(owner, "지울 질문")
    chat_factory.soft_delete(owner, gone.session_id)
    fake: FakeHermes = FakeHermes()
    live_server.app.state.hermes = fake
    token: str = token_of(live_server, owner)
    for session_id in (uuid.uuid4(), theirs.session_id, gone.session_id, "not-a-uuid"):
        reply: Reply = ask(live_server, token, "들어가면 안 됨", session_id)
        assert reply.status_code == 404
        assert reply.body["error"]["code"] == "SESSION_NOT_FOUND"
    assert fake.calls == []


def test_every_request_checks_the_account(
    live_server: LiveServer, account_factory: AccountFactory, migrated_engine: Engine
) -> None:
    fake: FakeHermes = FakeHermes()
    live_server.app.state.hermes = fake
    assert ask(live_server, "garbage", "질문").body["error"]["code"] == "UNAUTHORIZED"
    temporary: Account = account_factory.create(password_change_required=True)
    reply: Reply = ask(live_server, token_of(live_server, temporary), "질문")
    assert (reply.status_code, reply.body["error"]["code"]) == (403, "PASSWORD_CHANGE_REQUIRED")
    blocked: Account = account_factory.create()
    blocked_token: str = token_of(live_server, blocked)
    account_factory.update(blocked.login_id, status=AccountStatus.BLOCKED)
    reply = ask(live_server, blocked_token, "질문")
    assert (reply.status_code, reply.body["error"]["code"]) == (403, "ACCOUNT_BLOCKED")
    assert fake.calls == []
    assert session_count(migrated_engine, blocked) == 0


# --- Hermes 오류 -----------------------------------------------------------------------


def test_hermes_down_gives_a_server_error_and_stores_nothing(
    live_server: LiveServer, account_factory: AccountFactory, migrated_engine: Engine
) -> None:
    owner: Account = account_factory.create()
    token: str = token_of(live_server, owner)
    live_server.app.state.hermes = FakeHermes(fail_on_open=True)
    reply: Reply = ask(live_server, token, "질문")
    assert (reply.status_code, reply.body) == (500, ERROR_SERVER)
    assert reply.events == []  # SSE가 아니라 일반 오류 응답
    assert session_count(migrated_engine, owner) == 0
    # 실패한 작업이 남아 세션을 막지 않는다: Hermes가 돌아오면 바로 된다.
    live_server.app.state.hermes = FakeHermes(["ok"])
    assert names(ask(live_server, token, "다시").events)[-1] == "done"


def test_hermes_error_after_some_text_keeps_the_received_part_as_stopped(
    live_server: LiveServer, account_factory: AccountFactory, migrated_engine: Engine
) -> None:
    owner: Account = account_factory.create()
    live_server.app.state.hermes = FakeHermes(["받은 ", "부분", FAIL])
    reply: Reply = ask(live_server, token_of(live_server, owner), "질문")
    assert names(reply.events) == ["session", "delta", "delta", "error"]
    assert reply.events[-1][1] == ERROR_SERVER["error"]
    assert stored(migrated_engine, owner) == [("질문", "받은 부분", AnswerStatus.STOPPED)]


def test_hermes_error_before_any_text_stores_nothing(
    live_server: LiveServer, account_factory: AccountFactory, migrated_engine: Engine
) -> None:
    owner: Account = account_factory.create()
    live_server.app.state.hermes = FakeHermes([FAIL])
    reply: Reply = ask(live_server, token_of(live_server, owner), "질문")
    assert names(reply.events) == ["session", "error"]
    assert session_count(migrated_engine, owner) == 0


def test_an_answer_with_no_text_is_an_error_and_stores_nothing(
    live_server: LiveServer, account_factory: AccountFactory, migrated_engine: Engine
) -> None:
    owner: Account = account_factory.create()
    live_server.app.state.hermes = FakeHermes([])
    reply: Reply = ask(live_server, token_of(live_server, owner), "질문")
    assert names(reply.events) == ["session", "error"]
    assert session_count(migrated_engine, owner) == 0


def test_an_unexpected_error_mid_stream_also_keeps_the_received_part(
    live_server: LiveServer, account_factory: AccountFactory, migrated_engine: Engine
) -> None:
    """Hermes 오류가 아닌 예외(전송 계층 등)여도 이미 받은 부분을 잃으면 안 된다."""
    owner: Account = account_factory.create()
    live_server.app.state.hermes = FakeHermes(["받은 부분", CRASH])
    reply: Reply = ask(live_server, token_of(live_server, owner), "질문")
    assert names(reply.events) == ["session", "delta", "error"]
    assert stored(migrated_engine, owner) == [("질문", "받은 부분", AnswerStatus.STOPPED)]


def test_the_question_keeps_the_time_it_was_asked_not_the_time_the_answer_finished(
    live_server: LiveServer, account_factory: AccountFactory, migrated_engine: Engine
) -> None:
    owner: Account = account_factory.create()
    live_server.app.state.hermes = FakeHermes(["하나 ", "둘 ", "셋"], delay=0.3)
    ask(live_server, token_of(live_server, owner), "질문")
    with sessionmaker(migrated_engine)() as db:
        question_at, answer_at, session_created, session_updated = db.execute(
            select(Question.created_at, Answer.created_at, ChatSession.created_at, ChatSession.updated_at)
            .join(Answer, Answer.question_id == Question.id)
            .join(ChatSession, ChatSession.id == Question.session_id)
            .where(ChatSession.account_id == owner.id)
        ).one()
    assert (answer_at - question_at).total_seconds() >= 0.8  # 답변이 끝나기까지 걸린 시간
    assert session_created == question_at  # 세션은 첫 질문을 한 때 생겼다
    assert session_updated == answer_at  # 최근 활동은 답변이 끝난 때


# --- 중지 ------------------------------------------------------------------------------


def stop_url(session_id: str) -> str:
    return f"/api/v1/sessions/{session_id}/stop"


def test_stop_saves_the_received_part_as_stopped_and_cuts_the_hermes_connection(
    live_server: LiveServer, account_factory: AccountFactory, migrated_engine: Engine
) -> None:
    owner: Account = account_factory.create()
    token: str = token_of(live_server, owner)
    fake: FakeHermes = FakeHermes(["하나", "둘", HANG])
    live_server.app.state.hermes = fake
    with httpx.Client(base_url=live_server.base_url, timeout=20) as client:
        with client.stream("POST", URL, json={"text": "질문"}, headers=auth(token)) as response:
            stream: Iterator[Event] = iter_events(response)
            events: list[Event] = [next(stream), next(stream), next(stream)]
            assert names(events) == ["session", "delta", "delta"]
            stop: httpx.Response = client.post(stop_url(events[0][1]["id"]), headers=auth(token))
            assert stop.status_code == 204
            events += list(stream)
    assert names(events) == ["session", "delta", "delta", "stopped"]
    assert stored(migrated_engine, owner) == [("질문", "하나둘", AnswerStatus.STOPPED)]
    assert fake.cancelled is True  # Hermes 연결을 끊었다
    # 중지된 세션에는 바로 다시 질문할 수 있다.
    live_server.app.state.hermes = FakeHermes(["ok"])
    again: Reply = ask(live_server, token, "계속", events[0][1]["id"])
    assert names(again.events)[-1] == "done"


def test_stopping_while_hermes_is_still_connecting_ends_as_stopped_not_as_an_error(
    live_server: LiveServer, account_factory: AccountFactory, chat_factory: ChatFactory,
    migrated_engine: Engine,
) -> None:
    owner: Account = account_factory.create()
    existing = chat_factory.exchange(owner, "먼저 한 질문", "먼저 한 답")
    token: str = token_of(live_server, owner)
    live_server.app.state.hermes = FakeHermes(hang_on_open=True)
    replies: list[Reply] = []
    thread: threading.Thread = threading.Thread(
        target=lambda: replies.append(ask(live_server, token, "연결 중에 멈출 질문", existing.session_id))
    )
    thread.start()
    wait_until(lambda: live_server.app.state.runs.active_count() == 1)
    with httpx.Client(base_url=live_server.base_url, timeout=20) as client:
        stop: httpx.Response = client.post(stop_url(str(existing.session_id)), headers=auth(token))
    thread.join(timeout=15)
    assert stop.status_code == 204
    assert (replies[0].status_code, names(replies[0].events)) == (200, ["stopped"])
    assert stored(migrated_engine, owner)[-1] == ("연결 중에 멈출 질문", "", AnswerStatus.STOPPED)


def test_stopping_before_any_text_saves_an_empty_stopped_answer(
    live_server: LiveServer, account_factory: AccountFactory, migrated_engine: Engine
) -> None:
    owner: Account = account_factory.create()
    token: str = token_of(live_server, owner)
    live_server.app.state.hermes = FakeHermes([HANG])
    with httpx.Client(base_url=live_server.base_url, timeout=20) as client:
        with client.stream("POST", URL, json={"text": "질문"}, headers=auth(token)) as response:
            stream: Iterator[Event] = iter_events(response)
            session_id: str = next(stream)[1]["id"]
            assert client.post(stop_url(session_id), headers=auth(token)).status_code == 204
            events: list[Event] = list(stream)
    assert names(events) == ["stopped"]
    assert stored(migrated_engine, owner) == [("질문", "", AnswerStatus.STOPPED)]


def test_stop_without_a_running_answer_or_for_someone_elses_run(
    live_server: LiveServer, account_factory: AccountFactory, chat_factory: ChatFactory
) -> None:
    owner: Account = account_factory.create()
    stranger: Account = account_factory.create()
    mine = chat_factory.exchange(owner, "끝난 질문")
    owner_token: str = token_of(live_server, owner)
    with httpx.Client(base_url=live_server.base_url, timeout=20) as client:
        idle: httpx.Response = client.post(stop_url(str(mine.session_id)), headers=auth(owner_token))
        assert (idle.status_code, idle.json()["error"]["code"]) == (409, "NOT_STREAMING")
        for session_id in (str(uuid.uuid4()), "not-a-uuid"):
            unknown: httpx.Response = client.post(stop_url(session_id), headers=auth(owner_token))
            assert (unknown.status_code, unknown.json()["error"]["code"]) == (404, "SESSION_NOT_FOUND")
        foreign: httpx.Response = client.post(
            stop_url(str(mine.session_id)), headers=auth(token_of(live_server, stranger))
        )
        assert (foreign.status_code, foreign.json()["error"]["code"]) == (404, "SESSION_NOT_FOUND")
        assert client.post(stop_url(str(mine.session_id))).status_code == 401


def test_a_stranger_cannot_stop_someone_elses_running_answer(
    live_server: LiveServer, account_factory: AccountFactory, migrated_engine: Engine
) -> None:
    owner: Account = account_factory.create()
    stranger: Account = account_factory.create()
    owner_token: str = token_of(live_server, owner)
    live_server.app.state.hermes = FakeHermes(["진행", HANG])
    with httpx.Client(base_url=live_server.base_url, timeout=20) as client:
        with client.stream("POST", URL, json={"text": "질문"}, headers=auth(owner_token)) as response:
            stream: Iterator[Event] = iter_events(response)
            session_id: str = next(stream)[1]["id"]
            next(stream)
            attempt: httpx.Response = client.post(
                stop_url(session_id), headers=auth(token_of(live_server, stranger))
            )
            assert (attempt.status_code, attempt.json()["error"]["code"]) == (404, "SESSION_NOT_FOUND")
            assert live_server.app.state.runs.active_count() == 1  # 남이 멈추지 못했다
            assert client.post(stop_url(session_id), headers=auth(owner_token)).status_code == 204
            list(stream)


# --- 한 세션에 하나만 ------------------------------------------------------------------


def test_a_second_question_in_a_running_session_is_session_busy(
    live_server: LiveServer, account_factory: AccountFactory, chat_factory: ChatFactory
) -> None:
    owner: Account = account_factory.create()
    token: str = token_of(live_server, owner)
    existing = chat_factory.exchange(owner, "먼저 한 질문")
    other = chat_factory.exchange(owner, "다른 세션 질문")
    fake: FakeHermes = FakeHermes(["진행", HANG])
    live_server.app.state.hermes = fake
    with httpx.Client(base_url=live_server.base_url, timeout=20) as client:
        with client.stream(
            "POST", URL, json={"text": "오래 걸리는 질문", "sessionId": str(existing.session_id)},
            headers=auth(token),
        ) as response:
            stream: Iterator[Event] = iter_events(response)
            next(stream)  # 진행 중
            busy: Reply = ask(live_server, token, "끼어드는 질문", existing.session_id)
            assert (busy.status_code, busy.body["error"]["code"]) == (409, "SESSION_BUSY")
            assert len(fake.calls) == 1  # 끼어든 질문은 Hermes에 가지 않았다
            # 다른 세션은 동시에 질문할 수 있다.
            live_server.app.state.hermes = FakeHermes(["ok"])
            assert names(ask(live_server, token, "다른 세션에서", other.session_id).events)[-1] == "done"
            live_server.app.state.hermes = fake
            assert client.post(stop_url(str(existing.session_id)), headers=auth(token)).status_code == 204
            list(stream)


def test_two_simultaneous_questions_in_one_session_run_only_one(
    live_server: LiveServer, account_factory: AccountFactory, chat_factory: ChatFactory,
    migrated_engine: Engine,
) -> None:
    """두 요청이 동시에 '진행 중인 답변 없음' 검사를 통과해도, 등록 단계에서 하나만 시작되어야 한다."""
    owner: Account = account_factory.create()
    existing = chat_factory.exchange(owner, "먼저 한 질문")
    token: str = token_of(live_server, owner)
    fake: FakeHermes = FakeHermes(["하나 ", "둘"], delay=0.4)
    live_server.app.state.hermes = fake
    barrier: threading.Barrier = threading.Barrier(2)
    replies: list[Reply] = []

    def attempt(text: str) -> None:
        barrier.wait()
        replies.append(ask(live_server, token, text, existing.session_id))

    threads: list[threading.Thread] = [
        threading.Thread(target=attempt, args=(f"동시 질문 {n}",)) for n in range(2)
    ]
    for thread in threads:
        thread.start()
    for thread in threads:
        thread.join(timeout=30)
    statuses: list[tuple[int, str]] = sorted(
        (reply.status_code, reply.body["error"]["code"] if reply.body else "stream") for reply in replies
    )
    assert statuses == [(200, "stream"), (409, "SESSION_BUSY")]
    assert len(fake.calls) == 1  # Hermes에는 하나만 갔다
    assert len(stored(migrated_engine, owner)) == 2  # 먼저 한 질문 + 이긴 질문 하나


def test_asking_into_someone_elses_running_session_is_session_not_found_not_busy(
    live_server: LiveServer, account_factory: AccountFactory
) -> None:
    """남의 세션이 진행 중이라는 사실(BUSY)이 새면 안 된다. 내 세션이 아니므로 없는 세션과 같다."""
    owner: Account = account_factory.create()
    stranger: Account = account_factory.create()
    owner_token: str = token_of(live_server, owner)
    live_server.app.state.hermes = FakeHermes(["진행", HANG])
    with httpx.Client(base_url=live_server.base_url, timeout=20) as client:
        with client.stream("POST", URL, json={"text": "질문"}, headers=auth(owner_token)) as response:
            stream: Iterator[Event] = iter_events(response)
            session_id: str = next(stream)[1]["id"]
            next(stream)
            reply: Reply = ask(live_server, token_of(live_server, stranger), "끼어들기", session_id)
            assert (reply.status_code, reply.body["error"]["code"]) == (404, "SESSION_NOT_FOUND")
            assert live_server.app.state.runs.active_count() == 1  # 남의 요청이 등록부를 건드리지 않았다
            assert client.post(stop_url(session_id), headers=auth(owner_token)).status_code == 204
            list(stream)


# --- 연결이 끊겨도 끝까지 ---------------------------------------------------------------


def test_a_client_that_disconnects_does_not_stop_the_answer_from_being_saved(
    live_server: LiveServer, account_factory: AccountFactory, migrated_engine: Engine
) -> None:
    owner: Account = account_factory.create()
    token: str = token_of(live_server, owner)
    fake: FakeHermes = FakeHermes(["하나 ", "둘 ", "셋 ", "넷"], delay=0.3)
    live_server.app.state.hermes = fake
    with httpx.Client(base_url=live_server.base_url, timeout=20) as client:
        with client.stream("POST", URL, json={"text": "질문"}, headers=auth(token)) as response:
            stream: Iterator[Event] = iter_events(response)
            session_id: str = next(stream)[1]["id"]
            next(stream)  # 첫 조각만 받고 연결을 끊는다(앱이 백그라운드로 간 경우)
    # 끊긴 동안에도 세션은 진행 중이다.
    busy: Reply = ask(live_server, token, "끼어들기", session_id)
    assert (busy.status_code, busy.body["error"]["code"]) == (409, "SESSION_BUSY")
    wait_until(lambda: len(stored(migrated_engine, owner)) == 1)
    assert stored(migrated_engine, owner) == [("질문", "하나 둘 셋 넷", AnswerStatus.COMPLETED)]
    assert fake.cancelled is False and fake.finished is True


# --- keepalive ---------------------------------------------------------------------------


def test_idle_streams_get_keepalive_comments(
    live_server: LiveServer, account_factory: AccountFactory, monkeypatch: pytest.MonkeyPatch
) -> None:
    monkeypatch.setattr(runs_module, "KEEPALIVE_SECONDS", 0.1)
    owner: Account = account_factory.create()
    token: str = token_of(live_server, owner)
    live_server.app.state.hermes = FakeHermes([HANG])
    session_id: str = ""
    keepalives: int = 0
    with httpx.Client(base_url=live_server.base_url, timeout=20) as client:
        with client.stream("POST", URL, json={"text": "질문"}, headers=auth(token)) as response:
            lines: Iterator[str] = response.iter_lines()
            for line in lines:
                if line.startswith("data:") and not session_id:
                    session_id = json.loads(line.removeprefix("data:").strip())["id"]
                if line.startswith(": keepalive"):
                    keepalives += 1
                    if keepalives >= 2:
                        break
            assert client.post(stop_url(session_id), headers=auth(token)).status_code == 204
            list(lines)
    assert keepalives >= 2


# --- 실제 Hermes -------------------------------------------------------------------------


@pytest.mark.hermes
def test_real_hermes_answers_a_question_that_refers_to_the_earlier_conversation(
    live_server: LiveServer, account_factory: AccountFactory, migrated_engine: Engine
) -> None:
    """완료 조건: 같은 세션에서 앞 대화를 참조한 질문에 맞게 답한다(실제 모델을 호출하므로 비용이 든다)."""
    settings = get_settings()
    if settings.hermes_api_key is None:
        pytest.skip("backend/.env에 HERMES_API_KEY가 없다")
    live_server.app.state.hermes = create_hermes_client(settings)
    owner: Account = account_factory.create()
    token: str = token_of(live_server, owner)
    first: Reply = ask(live_server, token, "기억해 줘: 내 비밀 단어는 파란고래야. 기억했다고만 짧게 답해.")
    assert names(first.events)[-1] == "done"
    session_id: str = first.events[0][1]["id"]
    second: Reply = ask(live_server, token, "내가 말한 비밀 단어가 뭐지? 그 단어만 답해.", session_id)
    assert names(second.events)[-1] == "done"
    answer: str = "".join(data["text"] for name, data in second.events if name == "delta")
    assert "파란고래" in answer
    assert len(stored(migrated_engine, owner)) == 2
