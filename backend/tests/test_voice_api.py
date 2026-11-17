import threading
import time
import uuid
from pathlib import Path
from typing import Any

import httpx
import pytest
from sqlalchemy import func, select
from sqlalchemy.engine import Engine
from sqlalchemy.orm import sessionmaker

import app.voice_api as voice_api
from app.errors import (
    ApiError,
    audio_too_long,
    speech_not_recognized,
    validation_failed,
    voice_processing_failed,
)
from app.models import Account, AccountStatus, AnswerStatus, ChatSession, Question
from tests.conftest import LiveServer
from tests.factories import AccountFactory, ChatFactory
from tests.fakes import HANG, FakeHermes, FakeVoice
from tests.sse import Event, names, read_events

pytestmark = pytest.mark.integration

URL: str = "/api/v1/voice/questions"
RECORDING: bytes = b"fake-recording-bytes"


def token_of(live: LiveServer, account: Account) -> str:
    response: httpx.Response = httpx.post(
        f"{live.base_url}/api/v1/auth/login",
        json={"loginId": account.login_id, "password": "correct-password"},
    )
    assert response.status_code == 200
    return response.json()["accessToken"]


def speak(
    live: LiveServer,
    token: str | None,
    *,
    audio: bytes | None = RECORDING,
    session_id: str | uuid.UUID | None = None,
) -> tuple[httpx.Response, list[Event]]:
    """녹음을 올리고 응답을 끝까지 읽는다(SSE면 이벤트도 돌려준다)."""
    headers: dict[str, str] = {} if token is None else {"Authorization": f"Bearer {token}"}
    files: dict[str, Any] = {} if audio is None else {"audio": ("rec.m4a", audio, "audio/mp4")}
    data: dict[str, str] = {} if session_id is None else {"sessionId": str(session_id)}
    with httpx.Client(base_url=live.base_url, timeout=20) as client:
        with client.stream("POST", URL, files=files, data=data, headers=headers) as response:
            if response.headers["content-type"].startswith("text/event-stream"):
                return response, read_events(response)
            response.read()
            return response, []


def error_code(response: httpx.Response) -> str:
    return str(response.json()["error"]["code"])


def stored_questions(engine: Engine) -> int:
    with sessionmaker(engine)() as db:
        return int(db.scalar(select(func.count()).select_from(Question)) or 0)


@pytest.fixture
def voice_live(live_server: LiveServer) -> LiveServer:
    live_server.app.state.voice = FakeVoice()
    live_server.app.state.hermes = FakeHermes(["안녕", "하세요"])
    return live_server


def test_a_recording_becomes_the_corrected_question_then_the_answer_streams(
    voice_live: LiveServer, account_factory: AccountFactory, migrated_engine: Engine
) -> None:
    owner: Account = account_factory.create()
    response, events = speak(voice_live, token_of(voice_live, owner))
    assert response.status_code == 200
    assert response.headers["content-type"].startswith("text/event-stream")
    assert names(events) == ["session", "question", "delta", "delta", "done"]
    assert events[1][1] == {"text": "오늘 서울 날씨가 어때요"}
    assert voice_live.app.state.hermes.calls == [[{"role": "user", "content": "오늘 서울 날씨가 어때요"}]]
    with sessionmaker(migrated_engine)() as db:
        question: Question = db.scalars(
            select(Question).join(ChatSession).where(ChatSession.account_id == owner.id)
        ).one()
        assert question.text == "오늘 서울 날씨가 어때요"
        assert question.answer.status is AnswerStatus.COMPLETED
        assert question.answer.text == "안녕하세요"
    fake: FakeVoice = voice_live.app.state.voice
    assert fake.contents == [RECORDING]


def test_a_followup_recording_has_no_session_event_and_sends_the_history(
    voice_live: LiveServer, account_factory: AccountFactory, chat_factory: ChatFactory
) -> None:
    owner: Account = account_factory.create()
    first = chat_factory.exchange(owner, "내 이름은 철수야", "반가워요")
    response, events = speak(voice_live, token_of(voice_live, owner), session_id=first.session_id)
    assert names(events) == ["question", "delta", "delta", "done"]
    assert voice_live.app.state.hermes.calls[0][:2] == [
        {"role": "user", "content": "내 이름은 철수야"},
        {"role": "assistant", "content": "반가워요"},
    ]


def test_no_database_connection_is_held_while_a_recording_is_processed(
    voice_live: LiveServer, account_factory: AccountFactory, chat_factory: ChatFactory
) -> None:
    owner: Account = account_factory.create()
    pool = voice_live.app.state.engine.pool
    fake: FakeVoice = FakeVoice(probe=pool.checkedout)
    voice_live.app.state.voice = fake
    token: str = token_of(voice_live, owner)
    speak(voice_live, token)  # 첫 질문(세션 없음)
    first = chat_factory.exchange(owner, "질문", "답변")
    speak(voice_live, token, session_id=first.session_id)  # 이어서 묻기
    assert fake.probed == [0, 0]  # 녹음을 처리하는 동안 연결을 붙잡으면 몇 명만 동시에 말해도 서버 전체가 멈춘다


def test_the_uploaded_recording_is_deleted_after_a_successful_question(voice_live: LiveServer, account_factory: AccountFactory) -> None:
    owner: Account = account_factory.create()
    speak(voice_live, token_of(voice_live, owner))
    fake: FakeVoice = voice_live.app.state.voice
    assert len(fake.calls) == 1
    assert not fake.calls[0].exists() and not fake.calls[0].parent.exists()


FAILURES: list[tuple[str, ApiError | Exception, int, str]] = [
    ("too long", audio_too_long(), 422, "AUDIO_TOO_LONG"),
    ("not recognized", speech_not_recognized(), 422, "SPEECH_NOT_RECOGNIZED"),
    ("invalid file", validation_failed("녹음 파일을 확인해 주세요."), 422, "VALIDATION_FAILED"),
    ("a stage failed", voice_processing_failed(), 500, "VOICE_PROCESSING_FAILED"),
    ("unexpected crash", RuntimeError("boom"), 500, "VOICE_PROCESSING_FAILED"),
]


@pytest.mark.parametrize(("label", "error", "status", "code"), FAILURES, ids=[f[0] for f in FAILURES])
def test_when_a_stage_fails_hermes_is_not_called_nothing_is_saved_and_the_file_is_deleted(
    voice_live: LiveServer,
    account_factory: AccountFactory,
    migrated_engine: Engine,
    label: str,
    error: Exception,
    status: int,
    code: str,
) -> None:
    owner: Account = account_factory.create()
    fake: FakeVoice = FakeVoice(error=error)
    voice_live.app.state.voice = fake
    before: int = stored_questions(migrated_engine)
    response, events = speak(voice_live, token_of(voice_live, owner))
    assert (response.status_code, error_code(response)) == (status, code)
    assert events == []
    assert voice_live.app.state.hermes.calls == []
    assert stored_questions(migrated_engine) == before
    assert not fake.calls[0].parent.exists()


def test_the_pipeline_error_message_is_not_leaked_for_unexpected_crashes(
    voice_live: LiveServer, account_factory: AccountFactory
) -> None:
    owner: Account = account_factory.create()
    voice_live.app.state.voice = FakeVoice(error=RuntimeError("/Users/secret/path failed"))
    response, _ = speak(voice_live, token_of(voice_live, owner))
    assert "secret" not in response.text


def test_missing_or_empty_recordings_are_validation_errors_without_running_the_pipeline(
    voice_live: LiveServer, account_factory: AccountFactory
) -> None:
    owner: Account = account_factory.create()
    token: str = token_of(voice_live, owner)
    for audio in (None, b""):
        response, _ = speak(voice_live, token, audio=audio)
        assert (response.status_code, error_code(response)) == (422, "VALIDATION_FAILED")
    assert voice_live.app.state.voice.calls == []


def test_an_oversized_upload_is_refused_as_too_long_without_running_the_pipeline(
    voice_live: LiveServer, account_factory: AccountFactory, monkeypatch: pytest.MonkeyPatch
) -> None:
    owner: Account = account_factory.create()
    monkeypatch.setattr(voice_api, "MAX_UPLOAD_BYTES", 1000)
    response, _ = speak(voice_live, token_of(voice_live, owner), audio=b"x" * 1001)
    assert (response.status_code, error_code(response)) == (422, "AUDIO_TOO_LONG")
    assert voice_live.app.state.voice.calls == []
    ok, _ = speak(voice_live, token_of(voice_live, owner), audio=b"x" * 1000)
    assert ok.status_code == 200


def test_tokens_are_checked_before_anything_is_processed(
    voice_live: LiveServer, account_factory: AccountFactory, migrated_engine: Engine
) -> None:
    healthy: Account = account_factory.create()
    anonymous, _ = speak(voice_live, None)
    assert (anonymous.status_code, error_code(anonymous)) == (401, "UNAUTHORIZED")
    token: str = token_of(voice_live, healthy)  # 로그인한 뒤에 차단되는 경우
    with sessionmaker(migrated_engine).begin() as db:
        db.get(Account, healthy.id).status = AccountStatus.BLOCKED
    response, _ = speak(voice_live, token)
    assert (response.status_code, error_code(response)) == (403, "ACCOUNT_BLOCKED")
    pending: Account = account_factory.create(password_change_required=True)
    response, _ = speak(voice_live, token_of(voice_live, pending))
    assert (response.status_code, error_code(response)) == (403, "PASSWORD_CHANGE_REQUIRED")
    assert voice_live.app.state.voice.calls == []


def test_unknown_foreign_and_malformed_sessions_are_not_found_before_processing(
    voice_live: LiveServer, account_factory: AccountFactory, chat_factory: ChatFactory
) -> None:
    owner: Account = account_factory.create()
    other: Account = account_factory.create()
    theirs = chat_factory.exchange(other, "남의 질문", "남의 답변")
    token: str = token_of(voice_live, owner)
    for session_id in (uuid.uuid4(), theirs.session_id, "not-a-uuid"):
        response, _ = speak(voice_live, token, session_id=session_id)
        assert (response.status_code, error_code(response)) == (404, "SESSION_NOT_FOUND")
    assert voice_live.app.state.voice.calls == []


def test_a_session_that_is_still_answering_is_busy_before_processing(
    voice_live: LiveServer, account_factory: AccountFactory, chat_factory: ChatFactory
) -> None:
    owner: Account = account_factory.create()
    first = chat_factory.exchange(owner, "질문", "답변")
    token: str = token_of(voice_live, owner)
    voice_live.app.state.hermes = FakeHermes(["부분", HANG])  # 첫 음성 질문의 답변이 끝나지 않는다
    holder: list[httpx.Response] = []
    thread: threading.Thread = threading.Thread(
        target=lambda: holder.append(speak(voice_live, token, session_id=first.session_id)[0])
    )
    thread.start()
    try:
        deadline: float = time.monotonic() + 10
        while voice_live.app.state.runs.get(first.session_id) is None and time.monotonic() < deadline:
            time.sleep(0.05)
        calls_before: int = len(voice_live.app.state.voice.calls)
        response, _ = speak(voice_live, token, session_id=first.session_id)
        assert (response.status_code, error_code(response)) == (409, "SESSION_BUSY")
        assert len(voice_live.app.state.voice.calls) == calls_before  # 무거운 처리 전에 거절했다
    finally:
        stop: httpx.Response = httpx.post(
            f"{voice_live.base_url}/api/v1/sessions/{first.session_id}/stop",
            headers={"Authorization": f"Bearer {token}"},
        )
        thread.join(timeout=15)
    assert stop.status_code == 204 and holder[0].status_code == 200


def test_when_hermes_cannot_be_reached_the_question_is_not_saved_and_the_file_is_deleted(
    voice_live: LiveServer, account_factory: AccountFactory, migrated_engine: Engine
) -> None:
    owner: Account = account_factory.create()
    voice_live.app.state.hermes = FakeHermes(fail_on_open=True)
    before: int = stored_questions(migrated_engine)
    response, _ = speak(voice_live, token_of(voice_live, owner))
    assert (response.status_code, error_code(response)) == (500, "SERVER_ERROR")
    assert stored_questions(migrated_engine) == before
    assert not voice_live.app.state.voice.calls[0].parent.exists()


def test_the_voice_path_is_in_the_api_document() -> None:
    assert Path(__file__).resolve().parents[2].joinpath("docs/api/openapi.yaml").read_text().count(URL) == 1
