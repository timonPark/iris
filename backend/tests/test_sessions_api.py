import base64
import json
import uuid
from datetime import UTC, datetime, timedelta
from typing import Any

import pytest
from fastapi.testclient import TestClient
from httpx import Response
from sqlalchemy import select
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session, sessionmaker

from app.models import Account, AccountStatus, AnswerStatus, ChatSession, Question
from tests.factories import AccountFactory, ChatFactory

pytestmark = pytest.mark.integration

BASE: datetime = datetime(2026, 11, 17, 9, 0, 0, tzinfo=UTC)
SESSIONS_URL: str = "/api/v1/sessions"


def at(minutes: int) -> datetime:
    return BASE + timedelta(minutes=minutes)


def token_of(client: TestClient, account: Account, password: str = "correct-password") -> str:
    response: Response = client.post(
        "/api/v1/auth/login", json={"loginId": account.login_id, "password": password}
    )
    assert response.status_code == 200
    return response.json()["accessToken"]


def auth(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def code_of(response: Response) -> str:
    return response.json()["error"]["code"]


def session_ids(response: Response) -> list[str]:
    return [item["id"] for item in response.json()["items"]]


# --- 인증 ------------------------------------------------------------------------------


def test_every_session_api_needs_a_valid_token(app_client: TestClient) -> None:
    some_id: str = str(uuid.uuid4())
    calls: list[Response] = [
        app_client.get(SESSIONS_URL),
        app_client.get(f"{SESSIONS_URL}/{some_id}/questions"),
        app_client.delete(f"{SESSIONS_URL}/{some_id}"),
    ]
    for response in calls:
        assert (response.status_code, code_of(response)) == (401, "UNAUTHORIZED")


def test_blocked_or_temporary_password_accounts_are_refused(
    app_client: TestClient, account_factory: AccountFactory
) -> None:
    temporary: Account = account_factory.create(password_change_required=True)
    temporary_token: str = token_of(app_client, temporary)
    blocked: Account = account_factory.create()
    blocked_token: str = token_of(app_client, blocked)
    account_factory.update(blocked.login_id, status=AccountStatus.BLOCKED)
    response: Response = app_client.get(SESSIONS_URL, headers=auth(temporary_token))
    assert (response.status_code, code_of(response)) == (403, "PASSWORD_CHANGE_REQUIRED")
    response = app_client.get(SESSIONS_URL, headers=auth(blocked_token))
    assert (response.status_code, code_of(response)) == (403, "ACCOUNT_BLOCKED")


# --- 목록 ------------------------------------------------------------------------------


def test_list_has_the_documented_shape_and_newest_activity_first(
    app_client: TestClient, account_factory: AccountFactory, chat_factory: ChatFactory
) -> None:
    owner: Account = account_factory.create()
    older: Question = chat_factory.exchange(owner, "오래된 세션", at=at(0))
    newer: Question = chat_factory.exchange(owner, "새 세션입니다", at=at(10))
    response: Response = app_client.get(SESSIONS_URL, headers=auth(token_of(app_client, owner)))
    assert response.status_code == 200
    body: dict[str, Any] = response.json()
    assert set(body) == {"items"}  # 다음 페이지가 없으면 nextCursor가 없다
    assert [item["id"] for item in body["items"]] == [str(newer.session_id), str(older.session_id)]
    assert set(body["items"][0]) == {"id", "title", "updatedAt"}
    assert body["items"][0]["title"] == "새 세션입니다"
    assert body["items"][0]["updatedAt"].startswith("2026-11-17T09:10:00")


def test_empty_list_for_an_account_without_sessions(
    app_client: TestClient, account_factory: AccountFactory
) -> None:
    owner: Account = account_factory.create()
    response: Response = app_client.get(SESSIONS_URL, headers=auth(token_of(app_client, owner)))
    assert (response.status_code, response.json()) == (200, {"items": []})


def test_list_pages_follow_next_cursor_and_cover_every_session_once(
    app_client: TestClient, account_factory: AccountFactory, chat_factory: ChatFactory
) -> None:
    owner: Account = account_factory.create()
    created: list[str] = [
        str(chat_factory.exchange(owner, f"세션 {n}", at=at(n)).session_id) for n in range(5)
    ]
    headers: dict[str, str] = auth(token_of(app_client, owner))
    seen: list[str] = []
    params: dict[str, Any] = {"limit": 2}
    pages: int = 0
    while True:
        response: Response = app_client.get(SESSIONS_URL, params=params, headers=headers)
        assert response.status_code == 200
        seen.extend(session_ids(response))
        pages += 1
        next_cursor: str | None = response.json().get("nextCursor")
        if next_cursor is None:
            break
        params = {"limit": 2, "cursor": next_cursor}
    assert pages == 3
    assert seen == list(reversed(created))


def test_default_page_size_is_20(
    app_client: TestClient, account_factory: AccountFactory, chat_factory: ChatFactory
) -> None:
    owner: Account = account_factory.create()
    for n in range(21):
        chat_factory.exchange(owner, f"세션 {n}", at=at(n))
    response: Response = app_client.get(SESSIONS_URL, headers=auth(token_of(app_client, owner)))
    assert len(response.json()["items"]) == 20
    assert "nextCursor" in response.json()


@pytest.mark.parametrize("limit", ["0", "101", "-1", "abc"])
def test_limit_outside_1_to_100_is_a_validation_error(
    app_client: TestClient, account_factory: AccountFactory, limit: str
) -> None:
    owner: Account = account_factory.create()
    response: Response = app_client.get(
        SESSIONS_URL, params={"limit": limit}, headers=auth(token_of(app_client, owner))
    )
    assert (response.status_code, code_of(response)) == (422, "VALIDATION_FAILED")


def test_bad_cursor_is_a_validation_error_on_both_lists(
    app_client: TestClient, account_factory: AccountFactory, chat_factory: ChatFactory
) -> None:
    owner: Account = account_factory.create()
    mine: Question = chat_factory.exchange(owner, "질문", at=at(0))
    headers: dict[str, str] = auth(token_of(app_client, owner))
    for url in (SESSIONS_URL, f"{SESSIONS_URL}/{mine.session_id}/questions"):
        response: Response = app_client.get(url, params={"cursor": "garbage"}, headers=headers)
        assert (response.status_code, code_of(response)) == (422, "VALIDATION_FAILED")


def test_a_cursor_from_one_list_cannot_be_used_on_another(
    app_client: TestClient, account_factory: AccountFactory, chat_factory: ChatFactory
) -> None:
    owner: Account = account_factory.create()
    first: Question = chat_factory.exchange(owner, "세션 A", at=at(0))
    second: Question = chat_factory.exchange(owner, "세션 B", at=at(1))
    for n in range(3):
        chat_factory.exchange(owner, f"A 질문 {n}", session_id=first.session_id, at=at(10 + n))
        chat_factory.exchange(owner, f"B 질문 {n}", session_id=second.session_id, at=at(20 + n))
    headers: dict[str, str] = auth(token_of(app_client, owner))
    sessions_cursor: str = app_client.get(SESSIONS_URL, params={"limit": 1}, headers=headers).json()["nextCursor"]
    questions_a: str = app_client.get(
        f"{SESSIONS_URL}/{first.session_id}/questions", params={"limit": 1}, headers=headers
    ).json()["nextCursor"]
    wrong_uses: list[tuple[str, str]] = [
        (f"{SESSIONS_URL}/{first.session_id}/questions", sessions_cursor),  # 세션 목록의 커서를 질문 목록에
        (SESSIONS_URL, questions_a),  # 질문 목록의 커서를 세션 목록에
        (f"{SESSIONS_URL}/{second.session_id}/questions", questions_a),  # 다른 세션의 커서
    ]
    for url, cursor in wrong_uses:
        response: Response = app_client.get(url, params={"cursor": cursor}, headers=headers)
        assert (response.status_code, code_of(response)) == (422, "VALIDATION_FAILED")


@pytest.mark.parametrize("moment", ["0001-01-01T00:00:00+14:00", "9999-12-31T23:59:59-14:00"])
def test_a_crafted_cursor_with_an_extreme_time_is_a_validation_error_not_a_server_error(
    app_client: TestClient, account_factory: AccountFactory, moment: str
) -> None:
    owner: Account = account_factory.create()
    payload: dict[str, str] = {"t": moment, "id": str(uuid.uuid4()), "s": "sessions"}
    cursor: str = base64.urlsafe_b64encode(json.dumps(payload).encode()).decode().rstrip("=")
    response: Response = app_client.get(
        SESSIONS_URL, params={"cursor": cursor}, headers=auth(token_of(app_client, owner))
    )
    assert (response.status_code, code_of(response)) == (422, "VALIDATION_FAILED")


# --- 세션 열람 -------------------------------------------------------------------------


def test_questions_come_with_their_answers_newest_first(
    app_client: TestClient, account_factory: AccountFactory, chat_factory: ChatFactory
) -> None:
    owner: Account = account_factory.create()
    first: Question = chat_factory.exchange(owner, "질문 1", "답 1", at=at(0))
    chat_factory.exchange(
        owner, "질문 2", "받은 부분까지", session_id=first.session_id,
        status=AnswerStatus.STOPPED, at=at(1),
    )
    response: Response = app_client.get(
        f"{SESSIONS_URL}/{first.session_id}/questions", headers=auth(token_of(app_client, owner))
    )
    assert response.status_code == 200
    body: dict[str, Any] = response.json()
    assert set(body) == {"items"}
    newest, oldest = body["items"]
    assert set(newest) == {"id", "text", "createdAt", "answer"}
    assert set(newest["answer"]) == {"id", "text", "status", "createdAt"}
    assert (newest["text"], newest["answer"]["text"], newest["answer"]["status"]) == (
        "질문 2", "받은 부분까지", "stopped",
    )
    assert (oldest["text"], oldest["answer"]["text"], oldest["answer"]["status"]) == (
        "질문 1", "답 1", "completed",
    )


def test_question_pages_follow_next_cursor(
    app_client: TestClient, account_factory: AccountFactory, chat_factory: ChatFactory
) -> None:
    owner: Account = account_factory.create()
    first: Question = chat_factory.exchange(owner, "질문 0", at=at(0))
    for n in range(1, 5):
        chat_factory.exchange(owner, f"질문 {n}", session_id=first.session_id, at=at(n))
    headers: dict[str, str] = auth(token_of(app_client, owner))
    url: str = f"{SESSIONS_URL}/{first.session_id}/questions"
    texts: list[str] = []
    params: dict[str, Any] = {"limit": 2}
    while True:
        response: Response = app_client.get(url, params=params, headers=headers)
        texts.extend(item["text"] for item in response.json()["items"])
        next_cursor: str | None = response.json().get("nextCursor")
        if next_cursor is None:
            break
        params = {"limit": 2, "cursor": next_cursor}
    assert texts == [f"질문 {n}" for n in (4, 3, 2, 1, 0)]


# --- 다른 사용자의 세션 ----------------------------------------------------------------


def test_nobody_can_reach_another_users_session(
    app_client: TestClient, account_factory: AccountFactory, chat_factory: ChatFactory
) -> None:
    owner: Account = account_factory.create()
    stranger: Account = account_factory.create()
    mine: Question = chat_factory.exchange(owner, "내 비밀 질문", "내 비밀 답변", at=at(0))
    chat_factory.exchange(stranger, "남의 질문", at=at(1))
    stranger_headers: dict[str, str] = auth(token_of(app_client, stranger))

    listing: Response = app_client.get(SESSIONS_URL, headers=stranger_headers)
    assert str(mine.session_id) not in session_ids(listing)
    assert "내 비밀 질문" not in listing.text

    view: Response = app_client.get(
        f"{SESSIONS_URL}/{mine.session_id}/questions", headers=stranger_headers
    )
    assert (view.status_code, code_of(view)) == (404, "SESSION_NOT_FOUND")
    assert "내 비밀" not in view.text

    delete: Response = app_client.delete(f"{SESSIONS_URL}/{mine.session_id}", headers=stranger_headers)
    assert (delete.status_code, code_of(delete)) == (404, "SESSION_NOT_FOUND")
    still_there: Response = app_client.get(SESSIONS_URL, headers=auth(token_of(app_client, owner)))
    assert str(mine.session_id) in session_ids(still_there)


def test_unknown_and_malformed_session_ids_are_session_not_found(
    app_client: TestClient, account_factory: AccountFactory
) -> None:
    owner: Account = account_factory.create()
    headers: dict[str, str] = auth(token_of(app_client, owner))
    for session_id in (str(uuid.uuid4()), "not-a-uuid", "123"):
        view: Response = app_client.get(f"{SESSIONS_URL}/{session_id}/questions", headers=headers)
        delete: Response = app_client.delete(f"{SESSIONS_URL}/{session_id}", headers=headers)
        for response in (view, delete):
            assert response.status_code == 404
            assert response.json() == {
                "error": {"code": "SESSION_NOT_FOUND", "message": "세션을 찾을 수 없습니다."}
            }


# --- 삭제 ------------------------------------------------------------------------------


def test_deleted_session_disappears_from_list_and_view_but_stays_in_the_database(
    app_client: TestClient,
    account_factory: AccountFactory,
    chat_factory: ChatFactory,
    migrated_engine: Engine,
) -> None:
    owner: Account = account_factory.create()
    keep: Question = chat_factory.exchange(owner, "남길 세션", at=at(0))
    remove: Question = chat_factory.exchange(owner, "지울 세션", "지울 답변", at=at(1))
    headers: dict[str, str] = auth(token_of(app_client, owner))

    deleted: Response = app_client.delete(f"{SESSIONS_URL}/{remove.session_id}", headers=headers)
    assert (deleted.status_code, deleted.content) == (204, b"")
    listing: Response = app_client.get(SESSIONS_URL, headers=headers)
    assert session_ids(listing) == [str(keep.session_id)]
    view: Response = app_client.get(f"{SESSIONS_URL}/{remove.session_id}/questions", headers=headers)
    assert (view.status_code, code_of(view)) == (404, "SESSION_NOT_FOUND")
    again: Response = app_client.delete(f"{SESSIONS_URL}/{remove.session_id}", headers=headers)
    assert (again.status_code, code_of(again)) == (404, "SESSION_NOT_FOUND")

    with sessionmaker(migrated_engine)() as db:
        row: ChatSession = db.get(ChatSession, remove.session_id)
        assert row is not None and row.deleted_at is not None  # DB에는 남아 있다
        stored: Question = db.scalars(
            select(Question).where(Question.session_id == remove.session_id)
        ).one()
        assert (stored.text, stored.answer.text) == ("지울 세션", "지울 답변")
        kept: ChatSession = db.get(ChatSession, keep.session_id)
        assert kept.deleted_at is None  # 다른 세션은 그대로
