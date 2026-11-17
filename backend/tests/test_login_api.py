import uuid
from collections.abc import Callable
from typing import Any

import pytest
from fastapi.testclient import TestClient
from httpx import Response
from sqlalchemy.engine import Engine

import app.auth as auth_module
from app.config import get_settings
from app.main import create_app
from app.models import Account, AccountStatus, Role, utc_now
from app.security import hash_password
from app.tokens import decode_token, issue_token, require_jwt_secret
from tests.factories import AccountFactory

pytestmark = pytest.mark.integration

LOGIN_URL: str = "/api/v1/auth/login"
INVALID_CREDENTIALS: dict[str, Any] = {
    "error": {"code": "INVALID_CREDENTIALS", "message": "아이디 또는 비밀번호가 올바르지 않습니다."}
}


def login(client: TestClient, login_id: str, password: str) -> Response:
    return client.post(LOGIN_URL, json={"loginId": login_id, "password": password})


def bearer(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def access_token(client: TestClient, login_id: str, password: str = "correct-password") -> str:
    response: Response = login(client, login_id, password)
    assert response.status_code == 200
    return response.json()["accessToken"]


def error_code(response: Response) -> str:
    return response.json()["error"]["code"]


def test_login_returns_the_token_role_and_password_change_flag(
    app_client: TestClient, account_factory: AccountFactory
) -> None:
    account: Account = account_factory.create()
    response: Response = login(app_client, account.login_id, "correct-password")
    assert response.status_code == 200
    body: dict[str, Any] = response.json()
    assert set(body) == {"accessToken", "role", "passwordChangeRequired"}
    assert body["role"] == "user"
    assert body["passwordChangeRequired"] is False
    secret: str = require_jwt_secret(get_settings().jwt_secret)
    assert decode_token(body["accessToken"], secret).account_id == account.id


def test_login_reports_the_admin_role(
    app_client: TestClient, account_factory: AccountFactory
) -> None:
    account: Account = account_factory.create(role=Role.ADMIN)
    assert login(app_client, account.login_id, "correct-password").json()["role"] == "admin"


def test_login_with_a_temporary_password_tells_the_client_to_change_it(
    app_client: TestClient, account_factory: AccountFactory
) -> None:
    account: Account = account_factory.create(password_change_required=True)
    response: Response = login(app_client, account.login_id, "correct-password")
    assert response.status_code == 200
    assert response.json()["passwordChangeRequired"] is True


def test_wrong_password_is_rejected(
    app_client: TestClient, account_factory: AccountFactory
) -> None:
    account: Account = account_factory.create()
    response: Response = login(app_client, account.login_id, "wrong-password")
    assert response.status_code == 401
    assert response.json() == INVALID_CREDENTIALS


def test_unknown_login_id_gets_the_same_answer_as_a_wrong_password(
    app_client: TestClient,
) -> None:
    response: Response = login(app_client, "nosuchuser1", "whatever-password")
    assert response.status_code == 401
    assert response.json() == INVALID_CREDENTIALS


def test_blocked_account_is_told_it_is_blocked_only_with_the_right_password(
    app_client: TestClient, account_factory: AccountFactory
) -> None:
    account: Account = account_factory.create(status=AccountStatus.BLOCKED)
    blocked: Response = login(app_client, account.login_id, "correct-password")
    assert blocked.status_code == 403
    assert blocked.json() == {"error": {"code": "ACCOUNT_BLOCKED", "message": "차단된 계정입니다."}}
    # 틀린 비밀번호로는 계정이 있는지, 차단됐는지 알 수 없다.
    guessed: Response = login(app_client, account.login_id, "wrong-password")
    assert guessed.status_code == 401
    assert guessed.json() == INVALID_CREDENTIALS


@pytest.mark.parametrize(
    "impossible_login_id", ["abc\u0000def", "A" * 50, "", "ab cd", "x" * 10_000, "한글아이디1"]
)
def test_login_ids_that_can_never_exist_get_the_normal_401_not_a_server_error(
    app_client: TestClient, impossible_login_id: str
) -> None:
    response: Response = login(app_client, impossible_login_id, "whatever-password")
    assert response.status_code == 401
    assert response.json() == INVALID_CREDENTIALS


def test_login_releases_the_db_connection_before_hashing_the_password(
    app_client: TestClient, account_factory: AccountFactory, monkeypatch: pytest.MonkeyPatch
) -> None:
    account: Account = account_factory.create()
    engine: Engine = app_client.app.state.engine
    checked_out: list[int] = []
    real_verify: Callable[[str, str], bool] = auth_module.verify_password

    def spy(password: str, password_hash: str) -> bool:
        checked_out.append(engine.pool.checkedout())
        return real_verify(password, password_hash)

    monkeypatch.setattr(auth_module, "verify_password", spy)
    assert login(app_client, account.login_id, "correct-password").status_code == 200
    assert checked_out == [0]


def test_dummy_hash_exists_before_the_first_login_so_the_first_unknown_id_is_not_slower() -> None:
    assert auth_module.DUMMY_PASSWORD_HASH.startswith("$argon2")


def test_login_request_missing_a_field_is_a_validation_error(app_client: TestClient) -> None:
    response: Response = app_client.post(LOGIN_URL, json={"loginId": "user1234"})
    assert response.status_code == 422
    assert error_code(response) == "VALIDATION_FAILED"
    assert response.json()["error"]["message"] == "입력 값을 확인해 주세요."


def test_protected_route_requires_a_valid_token(
    app_client: TestClient, account_factory: AccountFactory
) -> None:
    account: Account = account_factory.create()
    token: str = access_token(app_client, account.login_id)
    ok: Response = app_client.get("/_test/protected", headers=bearer(token))
    assert ok.status_code == 200
    assert ok.json() == {"loginId": account.login_id}
    for headers in ({}, bearer("garbage"), {"Authorization": f"Basic {token}"}, {"Authorization": token}):
        rejected: Response = app_client.get("/_test/protected", headers=headers)
        assert rejected.status_code == 401
        assert rejected.json() == {
            "error": {"code": "UNAUTHORIZED", "message": "다시 로그인해 주세요."}
        }


def test_token_signed_with_another_secret_or_for_no_account_is_rejected(
    app_client: TestClient,
) -> None:
    forged: str = issue_token(uuid.uuid4(), "x" * 32)
    no_account: str = issue_token(uuid.uuid4(), require_jwt_secret(get_settings().jwt_secret))
    for token in (forged, no_account):
        response: Response = app_client.get("/_test/protected", headers=bearer(token))
        assert (response.status_code, error_code(response)) == (401, "UNAUTHORIZED")


def test_blocking_an_account_rejects_its_token_on_the_next_request(
    app_client: TestClient, account_factory: AccountFactory
) -> None:
    account: Account = account_factory.create()
    token: str = access_token(app_client, account.login_id)
    assert app_client.get("/_test/protected", headers=bearer(token)).status_code == 200
    account_factory.update(account.login_id, status=AccountStatus.BLOCKED)
    blocked: Response = app_client.get("/_test/protected", headers=bearer(token))
    assert (blocked.status_code, error_code(blocked)) == (403, "ACCOUNT_BLOCKED")
    # 해제하면 같은 토큰이 다시 통한다(토큰은 그대로이고 계정 상태만 본다).
    account_factory.update(account.login_id, status=AccountStatus.ACTIVE)
    assert app_client.get("/_test/protected", headers=bearer(token)).status_code == 200


def test_changing_the_password_rejects_every_older_token(
    app_client: TestClient, account_factory: AccountFactory
) -> None:
    account: Account = account_factory.create()
    first: str = access_token(app_client, account.login_id)
    second: str = access_token(app_client, account.login_id)
    account_factory.update(
        account.login_id, password_hash=hash_password("new-password-1"), password_changed_at=utc_now()
    )
    for old_token in (first, second):
        response: Response = app_client.get("/_test/protected", headers=bearer(old_token))
        assert (response.status_code, error_code(response)) == (401, "UNAUTHORIZED")
    assert login(app_client, account.login_id, "correct-password").status_code == 401
    fresh: str = access_token(app_client, account.login_id, "new-password-1")
    assert app_client.get("/_test/protected", headers=bearer(fresh)).status_code == 200


def test_temporary_password_state_blocks_every_api_except_the_password_change_api(
    app_client: TestClient, account_factory: AccountFactory
) -> None:
    account: Account = account_factory.create(password_change_required=True)
    token: str = access_token(app_client, account.login_id)
    other: Response = app_client.get("/_test/protected", headers=bearer(token))
    assert other.status_code == 403
    assert other.json() == {
        "error": {"code": "PASSWORD_CHANGE_REQUIRED", "message": "비밀번호를 먼저 변경해 주세요."}
    }
    change: Response = app_client.post("/_test/password-change", headers=bearer(token))
    assert change.status_code == 200


def test_unexpected_errors_use_the_common_error_format(app_client: TestClient) -> None:
    response: Response = app_client.get("/_test/boom")
    assert response.status_code == 500
    assert response.json() == {
        "error": {"code": "SERVER_ERROR", "message": "서버 오류가 발생했습니다."}
    }


def test_app_refuses_to_start_without_a_long_enough_jwt_secret(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setenv("JWT_SECRET", "too-short")
    get_settings.cache_clear()
    try:
        with pytest.raises(ValueError, match="JWT_SECRET"):
            with TestClient(create_app()):
                pass
    finally:
        get_settings.cache_clear()
