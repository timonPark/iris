import uuid
from datetime import UTC, datetime, timedelta

import pytest

from app.auth import authorize
from app.errors import ApiError, ErrorCode
from app.models import Account, AccountStatus, Role
from app.tokens import TokenClaims

CHANGED_AT: datetime = datetime(2026, 11, 17, 6, 0, 0, tzinfo=UTC)


def make_account(**overrides: object) -> Account:
    values: dict[str, object] = {
        "login_id": "user1234",
        "password_hash": "hash",
        "role": Role.USER,
        "status": AccountStatus.ACTIVE,
        "password_changed_at": CHANGED_AT,
        "password_change_required": False,
    }
    values.update(overrides)
    return Account(**values)


def claims_issued(offset: timedelta) -> TokenClaims:
    return TokenClaims(account_id=uuid.uuid4(), issued_at=CHANGED_AT + offset)


def reject(account: Account, claims: TokenClaims, *, allow_password_change: bool = False) -> ApiError:
    with pytest.raises(ApiError) as info:
        authorize(account, claims, allow_password_change=allow_password_change)
    return info.value


def test_active_account_with_a_token_issued_after_the_password_change_is_allowed() -> None:
    authorize(make_account(), claims_issued(timedelta(minutes=5)), allow_password_change=False)


def test_token_issued_at_the_moment_of_the_password_change_is_allowed() -> None:
    authorize(make_account(), claims_issued(timedelta(0)), allow_password_change=False)


def test_token_issued_before_the_password_change_is_rejected_as_unauthorized() -> None:
    error: ApiError = reject(make_account(), claims_issued(-timedelta(microseconds=1)))
    assert (error.status_code, error.code) == (401, ErrorCode.UNAUTHORIZED)


def test_blocked_account_is_rejected_even_with_a_valid_token() -> None:
    error: ApiError = reject(
        make_account(status=AccountStatus.BLOCKED), claims_issued(timedelta(minutes=5))
    )
    assert (error.status_code, error.code) == (403, ErrorCode.ACCOUNT_BLOCKED)


def test_temporary_password_account_is_rejected_for_other_apis() -> None:
    error: ApiError = reject(
        make_account(password_change_required=True), claims_issued(timedelta(minutes=5))
    )
    assert (error.status_code, error.code) == (403, ErrorCode.PASSWORD_CHANGE_REQUIRED)


def test_temporary_password_account_is_allowed_for_the_password_change_api() -> None:
    authorize(
        make_account(password_change_required=True),
        claims_issued(timedelta(minutes=5)),
        allow_password_change=True,
    )


def test_blocked_account_stays_blocked_on_the_password_change_api() -> None:
    error: ApiError = reject(
        make_account(status=AccountStatus.BLOCKED, password_change_required=True),
        claims_issued(timedelta(minutes=5)),
        allow_password_change=True,
    )
    assert error.code == ErrorCode.ACCOUNT_BLOCKED


def test_blocked_is_reported_before_password_change_required() -> None:
    error: ApiError = reject(
        make_account(status=AccountStatus.BLOCKED, password_change_required=True),
        claims_issued(timedelta(minutes=5)),
    )
    assert error.code == ErrorCode.ACCOUNT_BLOCKED


def test_stale_token_is_reported_before_the_account_state() -> None:
    error: ApiError = reject(
        make_account(status=AccountStatus.BLOCKED), claims_issued(-timedelta(minutes=5))
    )
    assert error.code == ErrorCode.UNAUTHORIZED
