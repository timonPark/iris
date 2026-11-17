import threading
from concurrent.futures import Future, ThreadPoolExecutor
from typing import Any

import pytest
from fastapi.testclient import TestClient
from httpx import Response
from sqlalchemy import select
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session, sessionmaker

from app.models import Account, AccountStatus, Role
from app.security import verify_password
from tests.factories import AccountFactory

pytestmark = pytest.mark.integration

LOGIN_URL: str = "/api/v1/auth/login"
CHANGE_URL: str = "/api/v1/auth/password"


def login(client: TestClient, login_id: str, password: str) -> Response:
    return client.post(LOGIN_URL, json={"loginId": login_id, "password": password})


def access_token(client: TestClient, login_id: str, password: str) -> str:
    response: Response = login(client, login_id, password)
    assert response.status_code == 200
    return response.json()["accessToken"]


def bearer(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def change(client: TestClient, token: str, body: dict[str, Any]) -> Response:
    return client.post(CHANGE_URL, json=body, headers=bearer(token))


def code_of(response: Response) -> str:
    return response.json()["error"]["code"]


def stored(engine: Engine, login_id: str) -> Account:
    with sessionmaker(engine, expire_on_commit=False)() as session:
        return session.scalars(select(Account).where(Account.login_id == login_id)).one()


def test_normal_change_returns_a_new_token_and_invalidates_the_old_ones(
    app_client: TestClient, account_factory: AccountFactory
) -> None:
    account: Account = account_factory.create(password="old-password-1")
    first: str = access_token(app_client, account.login_id, "old-password-1")
    second: str = access_token(app_client, account.login_id, "old-password-1")
    response: Response = change(
        app_client, first, {"currentPassword": "old-password-1", "newPassword": "new-password-2"}
    )
    assert response.status_code == 200
    assert set(response.json()) == {"accessToken"}
    for old_token in (first, second):
        rejected: Response = app_client.get("/_test/protected", headers=bearer(old_token))
        assert (rejected.status_code, code_of(rejected)) == (401, "UNAUTHORIZED")
    fresh: str = response.json()["accessToken"]
    assert app_client.get("/_test/protected", headers=bearer(fresh)).status_code == 200


def test_after_a_change_only_the_new_password_logs_in(
    app_client: TestClient, account_factory: AccountFactory, migrated_engine: Engine
) -> None:
    account: Account = account_factory.create(password="old-password-1")
    token: str = access_token(app_client, account.login_id, "old-password-1")
    before: Account = stored(migrated_engine, account.login_id)
    change(app_client, token, {"currentPassword": "old-password-1", "newPassword": "new-password-2"})
    assert login(app_client, account.login_id, "old-password-1").status_code == 401
    assert login(app_client, account.login_id, "new-password-2").status_code == 200
    after: Account = stored(migrated_engine, account.login_id)
    assert after.password_changed_at > before.password_changed_at
    assert after.password_hash.startswith("$argon2")
    assert verify_password("new-password-2", after.password_hash) is True
    assert after.password_change_required is False


def test_wrong_current_password_is_rejected_and_nothing_changes(
    app_client: TestClient, account_factory: AccountFactory
) -> None:
    account: Account = account_factory.create(password="old-password-1")
    token: str = access_token(app_client, account.login_id, "old-password-1")
    response: Response = change(
        app_client, token, {"currentPassword": "not-the-password", "newPassword": "new-password-2"}
    )
    assert (response.status_code, code_of(response)) == (401, "INVALID_CREDENTIALS")
    assert app_client.get("/_test/protected", headers=bearer(token)).status_code == 200
    assert login(app_client, account.login_id, "old-password-1").status_code == 200


def test_normal_change_without_the_current_password_is_a_validation_error(
    app_client: TestClient, account_factory: AccountFactory
) -> None:
    account: Account = account_factory.create(password="old-password-1")
    token: str = access_token(app_client, account.login_id, "old-password-1")
    response: Response = change(app_client, token, {"newPassword": "new-password-2"})
    assert (response.status_code, code_of(response)) == (422, "VALIDATION_FAILED")
    assert login(app_client, account.login_id, "old-password-1").status_code == 200


def test_forced_change_needs_only_the_new_password_and_clears_the_temporary_state(
    app_client: TestClient, account_factory: AccountFactory, migrated_engine: Engine
) -> None:
    account: Account = account_factory.create(password="temp-password-1", password_change_required=True)
    token: str = access_token(app_client, account.login_id, "temp-password-1")
    blocked: Response = app_client.get("/_test/protected", headers=bearer(token))
    assert (blocked.status_code, code_of(blocked)) == (403, "PASSWORD_CHANGE_REQUIRED")
    response: Response = change(app_client, token, {"newPassword": "brand-new-pass"})
    assert response.status_code == 200
    assert stored(migrated_engine, account.login_id).password_change_required is False
    fresh: str = response.json()["accessToken"]
    assert app_client.get("/_test/protected", headers=bearer(fresh)).status_code == 200
    relogin: Response = login(app_client, account.login_id, "brand-new-pass")
    assert relogin.json()["passwordChangeRequired"] is False
    assert app_client.get("/_test/protected", headers=bearer(token)).status_code == 401
    assert login(app_client, account.login_id, "temp-password-1").status_code == 401


def test_forced_change_ignores_a_current_password_that_is_sent_anyway(
    app_client: TestClient, account_factory: AccountFactory
) -> None:
    account: Account = account_factory.create(password="temp-password-1", password_change_required=True)
    token: str = access_token(app_client, account.login_id, "temp-password-1")
    response: Response = change(
        app_client, token, {"currentPassword": "anything-at-all", "newPassword": "brand-new-pass"}
    )
    assert response.status_code == 200


@pytest.mark.parametrize("new_password", ["", "1234567", "x" * 1025])
def test_new_password_outside_the_length_rule_is_a_validation_error(
    app_client: TestClient, account_factory: AccountFactory, new_password: str
) -> None:
    account: Account = account_factory.create(password="old-password-1")
    token: str = access_token(app_client, account.login_id, "old-password-1")
    response: Response = change(
        app_client, token, {"currentPassword": "old-password-1", "newPassword": new_password}
    )
    assert (response.status_code, code_of(response)) == (422, "VALIDATION_FAILED")
    assert app_client.get("/_test/protected", headers=bearer(token)).status_code == 200


def test_new_password_without_complexity_rules_is_accepted_up_to_1024_characters(
    app_client: TestClient, account_factory: AccountFactory
) -> None:
    account: Account = account_factory.create(password="old-password-1")
    token: str = access_token(app_client, account.login_id, "old-password-1")
    response: Response = change(
        app_client, token, {"currentPassword": "old-password-1", "newPassword": "a" * 1024}
    )
    assert response.status_code == 200
    assert login(app_client, account.login_id, "a" * 1024).status_code == 200


def test_oversized_password_in_a_request_is_a_validation_error(
    app_client: TestClient, account_factory: AccountFactory
) -> None:
    account: Account = account_factory.create(password="old-password-1")
    token: str = access_token(app_client, account.login_id, "old-password-1")
    too_long: Response = change(
        app_client, token, {"currentPassword": "x" * 1025, "newPassword": "new-password-2"}
    )
    assert (too_long.status_code, code_of(too_long)) == (422, "VALIDATION_FAILED")
    oversized_login: Response = login(app_client, account.login_id, "x" * 1025)
    assert (oversized_login.status_code, code_of(oversized_login)) == (422, "VALIDATION_FAILED")


def test_admin_cannot_change_the_password_with_this_api(
    app_client: TestClient, account_factory: AccountFactory
) -> None:
    account: Account = account_factory.create(role=Role.ADMIN, password="admin-password-1")
    token: str = access_token(app_client, account.login_id, "admin-password-1")
    response: Response = change(
        app_client, token, {"currentPassword": "admin-password-1", "newPassword": "new-password-2"}
    )
    assert response.status_code == 403
    assert response.json() == {"error": {"code": "FORBIDDEN", "message": "권한이 없습니다."}}
    assert login(app_client, account.login_id, "admin-password-1").status_code == 200


def test_blocked_account_cannot_change_the_password(
    app_client: TestClient, account_factory: AccountFactory
) -> None:
    account: Account = account_factory.create(password="old-password-1")
    token: str = access_token(app_client, account.login_id, "old-password-1")
    account_factory.update(account.login_id, status=AccountStatus.BLOCKED)
    response: Response = change(
        app_client, token, {"currentPassword": "old-password-1", "newPassword": "new-password-2"}
    )
    assert (response.status_code, code_of(response)) == (403, "ACCOUNT_BLOCKED")


def test_change_requires_a_valid_token(app_client: TestClient) -> None:
    body: dict[str, str] = {"currentPassword": "old-password-1", "newPassword": "new-password-2"}
    no_token: Response = app_client.post(CHANGE_URL, json=body)
    garbage: Response = change(app_client, "garbage", body)
    for response in (no_token, garbage):
        assert (response.status_code, code_of(response)) == (401, "UNAUTHORIZED")


def test_token_issued_right_after_the_change_is_never_rejected_as_stale(
    app_client: TestClient, account_factory: AccountFactory
) -> None:
    """변경 직후 받은 토큰이 같은 시각 비교 때문에 거부되면 안 된다. 여러 번 반복해 확인한다."""
    account: Account = account_factory.create(password="pass-number-0")
    password: str = "pass-number-0"
    token: str = access_token(app_client, account.login_id, password)
    for round_number in range(1, 6):
        new_password: str = f"pass-number-{round_number}"
        response: Response = change(
            app_client, token, {"currentPassword": password, "newPassword": new_password}
        )
        assert response.status_code == 200
        token, password = response.json()["accessToken"], new_password
        assert app_client.get("/_test/protected", headers=bearer(token)).status_code == 200


def test_new_password_must_differ_from_the_current_one(
    app_client: TestClient, account_factory: AccountFactory
) -> None:
    account: Account = account_factory.create(password="old-password-1")
    token: str = access_token(app_client, account.login_id, "old-password-1")
    response: Response = change(
        app_client, token, {"currentPassword": "old-password-1", "newPassword": "old-password-1"}
    )
    assert (response.status_code, code_of(response)) == (422, "VALIDATION_FAILED")
    assert app_client.get("/_test/protected", headers=bearer(token)).status_code == 200


def test_forced_change_to_the_temporary_password_itself_is_rejected(
    app_client: TestClient, account_factory: AccountFactory
) -> None:
    account: Account = account_factory.create(password="temp-password-1", password_change_required=True)
    token: str = access_token(app_client, account.login_id, "temp-password-1")
    response: Response = change(app_client, token, {"newPassword": "temp-password-1"})
    assert (response.status_code, code_of(response)) == (422, "VALIDATION_FAILED")
    # 아직 임시 비밀번호 상태라서 다른 API는 계속 막혀 있다.
    assert login(app_client, account.login_id, "temp-password-1").json()["passwordChangeRequired"] is True
    blocked: Response = app_client.get("/_test/protected", headers=bearer(token))
    assert code_of(blocked) == "PASSWORD_CHANGE_REQUIRED"


def test_empty_current_password_is_treated_like_a_missing_one(
    app_client: TestClient, account_factory: AccountFactory
) -> None:
    account: Account = account_factory.create(password="old-password-1")
    token: str = access_token(app_client, account.login_id, "old-password-1")
    response: Response = change(
        app_client, token, {"currentPassword": "", "newPassword": "new-password-2"}
    )
    assert (response.status_code, code_of(response)) == (422, "VALIDATION_FAILED")


def test_a_token_issued_before_the_last_password_change_cannot_change_it_again(
    app_client: TestClient, account_factory: AccountFactory
) -> None:
    account: Account = account_factory.create(password="old-password-1")
    old_token: str = access_token(app_client, account.login_id, "old-password-1")
    new_token: str = access_token(app_client, account.login_id, "old-password-1")
    change(app_client, new_token, {"currentPassword": "old-password-1", "newPassword": "new-password-2"})
    response: Response = change(
        app_client, old_token, {"currentPassword": "new-password-2", "newPassword": "third-password-3"}
    )
    assert (response.status_code, code_of(response)) == (401, "UNAUTHORIZED")


def test_admin_in_the_temporary_password_state_is_still_refused(
    app_client: TestClient, account_factory: AccountFactory
) -> None:
    account: Account = account_factory.create(
        role=Role.ADMIN, password="admin-password-1", password_change_required=True
    )
    token: str = access_token(app_client, account.login_id, "admin-password-1")
    response: Response = change(app_client, token, {"newPassword": "new-password-2"})
    assert (response.status_code, code_of(response)) == (403, "FORBIDDEN")


def test_blocked_account_in_the_temporary_password_state_is_still_refused(
    app_client: TestClient, account_factory: AccountFactory
) -> None:
    account: Account = account_factory.create(password="temp-password-1", password_change_required=True)
    token: str = access_token(app_client, account.login_id, "temp-password-1")
    account_factory.update(account.login_id, status=AccountStatus.BLOCKED)
    response: Response = change(app_client, token, {"newPassword": "new-password-2"})
    assert (response.status_code, code_of(response)) == (403, "ACCOUNT_BLOCKED")


def test_two_simultaneous_changes_do_not_both_succeed(
    app_client: TestClient, account_factory: AccountFactory
) -> None:
    """같은 계정의 동시 변경은 순서대로 처리된다. 하나만 성공하고, 성공한 쪽의 토큰은 바로 쓸 수 있다."""
    account: Account = account_factory.create(password="old-password-1")
    token: str = access_token(app_client, account.login_id, "old-password-1")
    barrier: threading.Barrier = threading.Barrier(2)

    def attempt(new_password: str) -> Response:
        barrier.wait()
        return change(
            app_client, token, {"currentPassword": "old-password-1", "newPassword": new_password}
        )

    with ThreadPoolExecutor(max_workers=2) as pool:
        futures: list[Future[Response]] = [
            pool.submit(attempt, "winner-pass-1"),
            pool.submit(attempt, "winner-pass-2"),
        ]
        responses: list[Response] = [future.result() for future in futures]
    assert sorted(response.status_code for response in responses) == [200, 401]
    winner: Response = next(response for response in responses if response.status_code == 200)
    fresh: Response = app_client.get(
        "/_test/protected", headers=bearer(winner.json()["accessToken"])
    )
    assert fresh.status_code == 200
