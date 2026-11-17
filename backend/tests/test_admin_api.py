import logging
import re
import threading
import uuid
from typing import Any

import pytest
from fastapi.testclient import TestClient
from httpx import Response
from sqlalchemy import select
from sqlalchemy.engine import Engine
from sqlalchemy.orm import sessionmaker

from app.models import Account, AccountStatus, Role
from app.security import verify_password
from tests.factories import AccountFactory

pytestmark = pytest.mark.integration

USERS: str = "/api/v1/admin/users"
USER_KEYS: set[str] = {"id", "loginId", "status", "passwordChangeRequired", "createdAt"}


def token_of(client: TestClient, account: Account, password: str = "correct-password") -> str:
    response: Response = client.post(
        "/api/v1/auth/login", json={"loginId": account.login_id, "password": password}
    )
    assert response.status_code == 200, response.text
    return response.json()["accessToken"]


def auth(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def code_of(response: Response) -> str:
    return response.json()["error"]["code"]


def admin_headers(client: TestClient, account_factory: AccountFactory) -> dict[str, str]:
    admin: Account = account_factory.create(role=Role.ADMIN)
    return auth(token_of(client, admin))


def stored(engine: Engine, login_id: str) -> Account | None:
    with sessionmaker(engine, expire_on_commit=False)() as db:
        return db.scalars(select(Account).where(Account.login_id == login_id)).first()


def register(client: TestClient, headers: dict[str, str], account_factory: AccountFactory,
             login_id: str | None = None) -> tuple[str, str, str]:
    """사용자를 등록하고 (아이디, 사용자 id, 임시 비밀번호)를 돌려준다."""
    login_id = login_id or "u" + uuid.uuid4().hex[:10]
    response: Response = client.post(USERS, json={"loginId": login_id}, headers=headers)
    assert response.status_code == 201, response.text
    account_factory.track(login_id)
    body: dict[str, Any] = response.json()
    return login_id, body["user"]["id"], body["temporaryPassword"]


# --- 관리자 권한 -----------------------------------------------------------------------


def test_every_admin_path_in_the_api_document_refuses_a_non_admin(
    app_client: TestClient, account_factory: AccountFactory
) -> None:
    """OpenAPI 문서에 올라온 /api/v1/admin 아래의 모든 경로와 메서드를 일반 사용자로 호출해 전부 403인지 본다.

    새 관리자 API를 어디에 만들든 권한 검사를 빠뜨리면 이 테스트가 실패한다.
    """
    ordinary: Account = account_factory.create()
    headers: dict[str, str] = auth(token_of(app_client, ordinary))
    document: dict[str, Any] = app_client.app.openapi()
    admin_paths: dict[str, dict[str, Any]] = {
        path: methods for path, methods in document["paths"].items() if path.startswith("/api/v1/admin")
    }
    calls: int = 0
    for path, methods in admin_paths.items():
        concrete: str = re.sub(r"\{[^}]+\}", str(uuid.uuid4()), path)
        for method in methods:
            response: Response = app_client.request(method.upper(), concrete, headers=headers, json={})
            assert response.status_code == 403, f"{method.upper()} {path} 가 일반 사용자를 막지 않는다"
            calls += 1
    assert calls == 5  # 지금 있는 관리자 API 5개를 모두 확인했다(경로를 찾지 못해 통과하는 일이 없도록)


@pytest.fixture
def some_user_id() -> str:
    return str(uuid.uuid4())


def admin_calls(client: TestClient, headers: dict[str, str], target: str) -> list[Response]:
    return [
        client.get(USERS, headers=headers),
        client.post(USERS, json={"loginId": "newuser1"}, headers=headers),
        client.post(f"{USERS}/{target}/block", headers=headers),
        client.post(f"{USERS}/{target}/unblock", headers=headers),
        client.post(f"{USERS}/{target}/password-reset", headers=headers),
    ]


def test_a_non_admin_account_is_refused_by_every_admin_api_and_nothing_changes(
    app_client: TestClient, account_factory: AccountFactory, migrated_engine: Engine
) -> None:
    ordinary: Account = account_factory.create()
    victim: Account = account_factory.create()
    token: str = token_of(app_client, ordinary)
    for response in admin_calls(app_client, auth(token), str(victim.id)):
        assert response.status_code == 403
        assert response.json() == {"error": {"code": "FORBIDDEN", "message": "권한이 없습니다."}}
    unchanged: Account = stored(migrated_engine, victim.login_id)
    assert unchanged.status == AccountStatus.ACTIVE
    assert unchanged.password_hash == victim.password_hash
    assert stored(migrated_engine, "newuser1") is None


def test_no_token_and_unusable_admin_accounts_are_refused(
    app_client: TestClient, account_factory: AccountFactory, some_user_id: str
) -> None:
    for response in admin_calls(app_client, {}, some_user_id):
        assert (response.status_code, code_of(response)) == (401, "UNAUTHORIZED")
    blocked_admin: Account = account_factory.create(role=Role.ADMIN)
    token: str = token_of(app_client, blocked_admin)
    account_factory.update(blocked_admin.login_id, status=AccountStatus.BLOCKED)
    response: Response = app_client.get(USERS, headers=auth(token))
    assert (response.status_code, code_of(response)) == (403, "ACCOUNT_BLOCKED")


def test_the_admin_role_is_checked_on_every_request_not_only_at_login(
    app_client: TestClient, account_factory: AccountFactory
) -> None:
    admin: Account = account_factory.create(role=Role.ADMIN)
    token: str = token_of(app_client, admin)
    assert app_client.get(USERS, headers=auth(token)).status_code == 200
    account_factory.update(admin.login_id, role=Role.USER)  # 권한이 회수된 경우
    response: Response = app_client.get(USERS, headers=auth(token))
    assert (response.status_code, code_of(response)) == (403, "FORBIDDEN")


# --- 대상은 사용자 계정만 ----------------------------------------------------------------


def test_admin_accounts_cannot_be_targeted_not_even_by_themselves(
    app_client: TestClient, account_factory: AccountFactory, migrated_engine: Engine
) -> None:
    admin: Account = account_factory.create(role=Role.ADMIN, password="admin-password-1")
    other_admin: Account = account_factory.create(role=Role.ADMIN, password="other-admin-1")
    headers: dict[str, str] = auth(token_of(app_client, admin, "admin-password-1"))
    for target in (other_admin, admin):
        for action in ("block", "unblock", "password-reset"):
            response: Response = app_client.post(f"{USERS}/{target.id}/{action}", headers=headers)
            assert response.status_code == 404
            assert response.json() == {
                "error": {"code": "USER_NOT_FOUND", "message": "계정을 찾을 수 없습니다."}
            }
    for target in (other_admin, admin):
        after: Account = stored(migrated_engine, target.login_id)
        assert (after.status, after.password_hash) == (AccountStatus.ACTIVE, target.password_hash)
    assert app_client.get(USERS, headers=headers).status_code == 200  # 자기 토큰도 그대로 유효


def test_unknown_and_malformed_user_ids_are_user_not_found(
    app_client: TestClient, account_factory: AccountFactory
) -> None:
    headers: dict[str, str] = admin_headers(app_client, account_factory)
    for user_id in (str(uuid.uuid4()), "not-a-uuid", "123"):
        for action in ("block", "unblock", "password-reset"):
            response: Response = app_client.post(f"{USERS}/{user_id}/{action}", headers=headers)
            assert (response.status_code, code_of(response)) == (404, "USER_NOT_FOUND")


def test_only_the_canonical_spelling_of_a_user_id_finds_the_user(
    app_client: TestClient, account_factory: AccountFactory
) -> None:
    headers: dict[str, str] = admin_headers(app_client, account_factory)
    user: Account = account_factory.create()
    canonical: str = str(user.id)
    spellings: list[str] = [
        "{" + canonical + "}",
        "urn:uuid:" + canonical,
        canonical.replace("-", ""),
        canonical[:8] + "_" + canonical[8:],
    ]
    for spelling in spellings:
        response: Response = app_client.post(f"{USERS}/{spelling}/block", headers=headers)
        assert (response.status_code, code_of(response)) == (404, "USER_NOT_FOUND"), spelling
    assert app_client.post(f"{USERS}/{canonical.upper()}/block", headers=headers).status_code == 200


# --- 목록 ------------------------------------------------------------------------------


def test_list_shows_only_users_including_blocked_newest_first(
    app_client: TestClient, account_factory: AccountFactory
) -> None:
    headers: dict[str, str] = admin_headers(app_client, account_factory)
    first = account_factory.create()
    second = account_factory.create(status=AccountStatus.BLOCKED, password_change_required=True)
    account_factory.create(role=Role.ADMIN)  # 관리자는 목록에 나오지 않는다
    response: Response = app_client.get(USERS, params={"limit": 100}, headers=headers)
    assert response.status_code == 200
    items: list[dict[str, Any]] = response.json()["items"]
    mine: list[dict[str, Any]] = [i for i in items if i["id"] in (str(first.id), str(second.id))]
    assert [i["id"] for i in mine] == [str(second.id), str(first.id)]
    assert all(set(item) == USER_KEYS for item in items)
    assert mine[0]["status"] == "blocked" and mine[0]["passwordChangeRequired"] is True
    assert mine[1]["status"] == "active" and mine[1]["passwordChangeRequired"] is False
    assert all(item["loginId"] != "testadmin1" for item in items)


def test_list_pages_follow_next_cursor_without_duplicates_or_gaps(
    app_client: TestClient, account_factory: AccountFactory
) -> None:
    headers: dict[str, str] = admin_headers(app_client, account_factory)
    created: list[str] = [str(account_factory.create().id) for _ in range(5)]
    seen: list[str] = []
    params: dict[str, Any] = {"limit": 2}
    while True:
        body: dict[str, Any] = app_client.get(USERS, params=params, headers=headers).json()
        seen.extend(item["id"] for item in body["items"])
        if "nextCursor" not in body:
            break
        params = {"limit": 2, "cursor": body["nextCursor"]}
    assert len(seen) == len(set(seen))
    assert [i for i in seen if i in created] == list(reversed(created))


@pytest.mark.parametrize("limit", ["0", "101", "abc"])
def test_list_limit_outside_1_to_100_is_a_validation_error(
    app_client: TestClient, account_factory: AccountFactory, limit: str
) -> None:
    response: Response = app_client.get(
        USERS, params={"limit": limit}, headers=admin_headers(app_client, account_factory)
    )
    assert (response.status_code, code_of(response)) == (422, "VALIDATION_FAILED")


def test_list_rejects_a_bad_cursor_and_a_cursor_from_another_list(
    app_client: TestClient, account_factory: AccountFactory, chat_factory: Any
) -> None:
    admin: Account = account_factory.create(role=Role.ADMIN)
    headers: dict[str, str] = auth(token_of(app_client, admin))
    for _ in range(2):
        chat_factory.exchange(admin, "질문")
    sessions_cursor: str = app_client.get(
        "/api/v1/sessions", params={"limit": 1}, headers=headers
    ).json()["nextCursor"]
    for cursor in ("garbage", sessions_cursor):
        response: Response = app_client.get(USERS, params={"cursor": cursor}, headers=headers)
        assert (response.status_code, code_of(response)) == (422, "VALIDATION_FAILED")


# --- 등록 ------------------------------------------------------------------------------


def test_registering_returns_the_user_and_the_temporary_password_once(
    app_client: TestClient, account_factory: AccountFactory, migrated_engine: Engine
) -> None:
    headers: dict[str, str] = admin_headers(app_client, account_factory)
    login_id: str = "newuser" + uuid.uuid4().hex[:6]
    response: Response = app_client.post(USERS, json={"loginId": login_id}, headers=headers)
    account_factory.track(login_id)
    assert response.status_code == 201
    assert response.headers["cache-control"] == "no-store"
    body: dict[str, Any] = response.json()
    assert set(body) == {"user", "temporaryPassword"}
    assert set(body["user"]) == USER_KEYS
    assert (body["user"]["loginId"], body["user"]["status"], body["user"]["passwordChangeRequired"]) == (
        login_id, "active", True,
    )
    temporary: str = body["temporaryPassword"]
    assert len(temporary) == 12
    account: Account = stored(migrated_engine, login_id)
    assert account.role == Role.USER
    assert account.password_hash.startswith("$argon2") and temporary not in account.password_hash
    assert verify_password(temporary, account.password_hash)


def test_a_registered_user_logs_in_with_the_temporary_password_and_must_change_it(
    app_client: TestClient, account_factory: AccountFactory
) -> None:
    headers: dict[str, str] = admin_headers(app_client, account_factory)
    login_id, _, temporary = register(app_client, headers, account_factory)
    login: Response = app_client.post(
        "/api/v1/auth/login", json={"loginId": login_id, "password": temporary}
    )
    assert (login.status_code, login.json()["passwordChangeRequired"], login.json()["role"]) == (200, True, "user")
    token: str = login.json()["accessToken"]
    blocked: Response = app_client.get("/api/v1/sessions", headers=auth(token))
    assert (blocked.status_code, code_of(blocked)) == (403, "PASSWORD_CHANGE_REQUIRED")
    changed: Response = app_client.post(
        "/api/v1/auth/password", json={"newPassword": "my-own-password"}, headers=auth(token)
    )
    assert changed.status_code == 200
    fresh: str = changed.json()["accessToken"]
    assert app_client.get("/api/v1/sessions", headers=auth(fresh)).status_code == 200


def test_registering_ignores_a_role_in_the_request(
    app_client: TestClient, account_factory: AccountFactory, migrated_engine: Engine
) -> None:
    headers: dict[str, str] = admin_headers(app_client, account_factory)
    login_id: str = "sneaky" + uuid.uuid4().hex[:6]
    response: Response = app_client.post(USERS, json={"loginId": login_id, "role": "admin"}, headers=headers)
    account_factory.track(login_id)
    assert response.status_code == 201
    assert stored(migrated_engine, login_id).role == Role.USER  # 이 API로 관리자를 만들 수 없다


def test_registering_an_existing_login_id_is_login_id_taken(
    app_client: TestClient, account_factory: AccountFactory
) -> None:
    headers: dict[str, str] = admin_headers(app_client, account_factory)
    existing: Account = account_factory.create()
    admin: Account = account_factory.create(role=Role.ADMIN)
    for login_id in (existing.login_id, admin.login_id):
        response: Response = app_client.post(USERS, json={"loginId": login_id}, headers=headers)
        assert response.status_code == 409
        assert response.json() == {
            "error": {"code": "LOGIN_ID_TAKEN", "message": "이미 사용 중인 아이디입니다."}
        }


def test_a_duplicate_login_id_is_refused_before_any_hashing_is_done(
    app_client: TestClient, account_factory: AccountFactory, monkeypatch: pytest.MonkeyPatch
) -> None:
    """중복이면 임시 비밀번호를 만들고 해시하는 일(느린 argon2)을 하지 않고 바로 거부한다."""
    headers: dict[str, str] = admin_headers(app_client, account_factory)
    existing: Account = account_factory.create()

    def forbidden_hash(password: str) -> str:
        raise AssertionError("중복 아이디인데 해시를 만들었다")

    monkeypatch.setattr("app.accounts.hash_password", forbidden_hash)
    response: Response = app_client.post(USERS, json={"loginId": existing.login_id}, headers=headers)
    assert (response.status_code, code_of(response)) == (409, "LOGIN_ID_TAKEN")


@pytest.mark.parametrize(
    "login_id", ["", "abc", "a" * 21, "UPPER123", "has space", "under_score", "한글아이디1", "ab\x00cd1"]
)
def test_registering_a_login_id_that_breaks_the_rule_is_a_validation_error(
    app_client: TestClient, account_factory: AccountFactory, migrated_engine: Engine, login_id: str
) -> None:
    headers: dict[str, str] = admin_headers(app_client, account_factory)
    response: Response = app_client.post(USERS, json={"loginId": login_id}, headers=headers)
    assert (response.status_code, code_of(response)) == (422, "VALIDATION_FAILED")
    assert stored(migrated_engine, login_id.replace("\x00", "")) is None


def test_registering_without_a_login_id_is_a_validation_error(
    app_client: TestClient, account_factory: AccountFactory
) -> None:
    headers: dict[str, str] = admin_headers(app_client, account_factory)
    assert code_of(app_client.post(USERS, json={}, headers=headers)) == "VALIDATION_FAILED"


def test_two_simultaneous_registrations_of_one_login_id_create_only_one(
    app_client: TestClient, account_factory: AccountFactory, migrated_engine: Engine
) -> None:
    headers: dict[str, str] = admin_headers(app_client, account_factory)
    login_id: str = "race" + uuid.uuid4().hex[:8]
    account_factory.track(login_id)
    barrier: threading.Barrier = threading.Barrier(2)
    statuses: list[int] = []

    def attempt() -> None:
        barrier.wait()
        statuses.append(app_client.post(USERS, json={"loginId": login_id}, headers=headers).status_code)

    threads: list[threading.Thread] = [threading.Thread(target=attempt) for _ in range(2)]
    for thread in threads:
        thread.start()
    for thread in threads:
        thread.join(timeout=30)
    assert sorted(statuses) == [201, 409]  # 서버 오류(500)가 아니라 한쪽은 아이디 중복으로 처리된다


# --- 차단과 해제 -----------------------------------------------------------------------


def test_blocking_rejects_the_users_live_token_and_login_and_unblocking_restores_them(
    app_client: TestClient, account_factory: AccountFactory
) -> None:
    headers: dict[str, str] = admin_headers(app_client, account_factory)
    user: Account = account_factory.create()
    user_token: str = token_of(app_client, user)
    assert app_client.get("/api/v1/sessions", headers=auth(user_token)).status_code == 200

    blocked: Response = app_client.post(f"{USERS}/{user.id}/block", headers=headers)
    assert blocked.status_code == 200
    assert set(blocked.json()) == USER_KEYS and blocked.json()["status"] == "blocked"
    rejected: Response = app_client.get("/api/v1/sessions", headers=auth(user_token))
    assert (rejected.status_code, code_of(rejected)) == (403, "ACCOUNT_BLOCKED")
    login: Response = app_client.post(
        "/api/v1/auth/login", json={"loginId": user.login_id, "password": "correct-password"}
    )
    assert (login.status_code, code_of(login)) == (403, "ACCOUNT_BLOCKED")

    unblocked: Response = app_client.post(f"{USERS}/{user.id}/unblock", headers=headers)
    assert (unblocked.status_code, unblocked.json()["status"]) == (200, "active")
    assert app_client.get("/api/v1/sessions", headers=auth(user_token)).status_code == 200  # 같은 토큰이 다시 통한다


def test_blocking_and_unblocking_twice_is_harmless(
    app_client: TestClient, account_factory: AccountFactory
) -> None:
    headers: dict[str, str] = admin_headers(app_client, account_factory)
    user: Account = account_factory.create()
    for action, expected in (("block", "blocked"), ("block", "blocked"), ("unblock", "active"), ("unblock", "active")):
        response: Response = app_client.post(f"{USERS}/{user.id}/{action}", headers=headers)
        assert (response.status_code, response.json()["status"]) == (200, expected)


# --- 비밀번호 초기화 -------------------------------------------------------------------


def test_reset_gives_a_new_temporary_password_and_ends_every_old_session_of_the_user(
    app_client: TestClient, account_factory: AccountFactory, migrated_engine: Engine
) -> None:
    headers: dict[str, str] = admin_headers(app_client, account_factory)
    user: Account = account_factory.create(password="old-password-1")
    old_token: str = token_of(app_client, user, "old-password-1")
    before: Account = stored(migrated_engine, user.login_id)

    response: Response = app_client.post(f"{USERS}/{user.id}/password-reset", headers=headers)
    assert response.status_code == 200
    assert response.headers["cache-control"] == "no-store"
    body: dict[str, Any] = response.json()
    assert set(body) == {"user", "temporaryPassword"}
    assert body["user"]["passwordChangeRequired"] is True
    temporary: str = body["temporaryPassword"]

    after: Account = stored(migrated_engine, user.login_id)
    assert after.password_changed_at > before.password_changed_at
    assert verify_password(temporary, after.password_hash) and after.password_change_required
    rejected: Response = app_client.get("/api/v1/sessions", headers=auth(old_token))
    assert (rejected.status_code, code_of(rejected)) == (401, "UNAUTHORIZED")
    old_login: Response = app_client.post(
        "/api/v1/auth/login", json={"loginId": user.login_id, "password": "old-password-1"}
    )
    assert old_login.status_code == 401
    new_login: Response = app_client.post(
        "/api/v1/auth/login", json={"loginId": user.login_id, "password": temporary}
    )
    assert (new_login.status_code, new_login.json()["passwordChangeRequired"]) == (200, True)


def test_resetting_twice_invalidates_the_first_temporary_password(
    app_client: TestClient, account_factory: AccountFactory
) -> None:
    headers: dict[str, str] = admin_headers(app_client, account_factory)
    user: Account = account_factory.create()
    first: str = app_client.post(f"{USERS}/{user.id}/password-reset", headers=headers).json()["temporaryPassword"]
    second: str = app_client.post(f"{USERS}/{user.id}/password-reset", headers=headers).json()["temporaryPassword"]
    assert first != second
    login = lambda password: app_client.post(  # noqa: E731
        "/api/v1/auth/login", json={"loginId": user.login_id, "password": password}
    ).status_code
    assert (login(first), login(second)) == (401, 200)


def test_resetting_a_blocked_user_keeps_the_user_blocked(
    app_client: TestClient, account_factory: AccountFactory
) -> None:
    headers: dict[str, str] = admin_headers(app_client, account_factory)
    user: Account = account_factory.create(status=AccountStatus.BLOCKED)
    response: Response = app_client.post(f"{USERS}/{user.id}/password-reset", headers=headers)
    assert (response.status_code, response.json()["user"]["status"]) == (200, "blocked")
    login: Response = app_client.post(
        "/api/v1/auth/login",
        json={"loginId": user.login_id, "password": response.json()["temporaryPassword"]},
    )
    assert (login.status_code, code_of(login)) == (403, "ACCOUNT_BLOCKED")


# --- 임시 비밀번호는 등록·초기화 응답에만 -------------------------------------------------


def test_the_temporary_password_appears_only_in_the_register_and_reset_responses(
    app_client: TestClient, account_factory: AccountFactory, migrated_engine: Engine,
    caplog: pytest.LogCaptureFixture,
) -> None:
    headers: dict[str, str] = admin_headers(app_client, account_factory)
    with caplog.at_level(logging.DEBUG):
        login_id, user_id, registered = register(app_client, headers, account_factory)
        reset: str = app_client.post(f"{USERS}/{user_id}/password-reset", headers=headers).json()["temporaryPassword"]
        others: list[Response] = [
            app_client.get(USERS, params={"limit": 100}, headers=headers),
            app_client.post(f"{USERS}/{user_id}/block", headers=headers),
            app_client.post(f"{USERS}/{user_id}/unblock", headers=headers),
        ]
    for response in others:
        assert response.status_code == 200
        text: str = response.text
        assert registered not in text and reset not in text
        assert "temporaryPassword" not in text and "passwordHash" not in text and "argon2" not in text
    account: Account = stored(migrated_engine, login_id)
    assert registered not in account.password_hash and reset not in account.password_hash
    assert registered not in caplog.text and reset not in caplog.text  # 로그에도 남지 않는다
