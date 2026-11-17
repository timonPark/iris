import uuid
from datetime import UTC, datetime

import jwt
import pytest
from pydantic import SecretStr

from app.tokens import InvalidTokenError, TokenClaims, decode_token, issue_token, require_jwt_secret

SECRET: str = "s" * 32


def test_issued_token_decodes_to_the_same_claims_with_microsecond_precision() -> None:
    account_id: uuid.UUID = uuid.uuid4()
    issued_at: datetime = datetime(2026, 11, 17, 6, 30, 0, 123456, tzinfo=UTC)
    claims: TokenClaims = decode_token(issue_token(account_id, SECRET, issued_at), SECRET)
    assert claims.account_id == account_id
    # 같은 초 안에서 일어난 비밀번호 변경과 새 토큰 발급을 구분하려면 초 단위로는 부족하다.
    assert abs((claims.issued_at - issued_at).total_seconds()) < 1e-6


def test_token_without_issued_at_argument_uses_the_current_time() -> None:
    before: datetime = datetime.now(UTC)
    claims: TokenClaims = decode_token(issue_token(uuid.uuid4(), SECRET), SECRET)
    assert 0 <= (claims.issued_at - before).total_seconds() < 5


def test_token_never_expires() -> None:
    payload: dict[str, object] = jwt.decode(
        issue_token(uuid.uuid4(), SECRET), options={"verify_signature": False}
    )
    assert "exp" not in payload


def test_token_signed_with_another_secret_is_rejected() -> None:
    token: str = issue_token(uuid.uuid4(), "x" * 32)
    with pytest.raises(InvalidTokenError):
        decode_token(token, SECRET)


def test_tampered_token_is_rejected() -> None:
    token: str = issue_token(uuid.uuid4(), SECRET)
    tampered: str = token[:-2] + ("AA" if not token.endswith("AA") else "BB")
    with pytest.raises(InvalidTokenError):
        decode_token(tampered, SECRET)


def test_unsigned_token_is_rejected() -> None:
    payload: dict[str, object] = {"sub": str(uuid.uuid4()), "iat": 1.0}
    unsigned: str = jwt.encode(payload, key="", algorithm="none")
    with pytest.raises(InvalidTokenError):
        decode_token(unsigned, SECRET)


@pytest.mark.parametrize("garbage", ["", "not-a-token", "a.b.c"])
def test_garbage_is_rejected(garbage: str) -> None:
    with pytest.raises(InvalidTokenError):
        decode_token(garbage, SECRET)


def test_token_missing_a_claim_is_rejected() -> None:
    without_iat: str = jwt.encode({"sub": str(uuid.uuid4())}, SECRET, algorithm="HS256")
    without_sub: str = jwt.encode({"iat": 1.0}, SECRET, algorithm="HS256")
    for token in (without_iat, without_sub):
        with pytest.raises(InvalidTokenError):
            decode_token(token, SECRET)


def test_token_with_a_subject_that_is_not_an_account_id_is_rejected() -> None:
    token: str = jwt.encode({"sub": "not-a-uuid", "iat": 1.0}, SECRET, algorithm="HS256")
    with pytest.raises(InvalidTokenError):
        decode_token(token, SECRET)


@pytest.mark.parametrize(
    "payload",
    [
        {"sub": 12345, "iat": 1.0},
        {"sub": str(uuid.uuid4()), "iat": 1e20},
        {"sub": str(uuid.uuid4()), "iat": "yesterday"},
        {"sub": None, "iat": 1.0},
    ],
)
def test_signed_token_with_unusable_claims_is_rejected_not_crashed(
    payload: dict[str, object],
) -> None:
    token: str = jwt.encode(payload, SECRET, algorithm="HS256")
    with pytest.raises(InvalidTokenError):
        decode_token(token, SECRET)


def test_issued_at_without_a_timezone_is_refused() -> None:
    with pytest.raises(ValueError, match="시간대"):
        issue_token(uuid.uuid4(), SECRET, datetime(2026, 11, 17, 6, 0, 0))


def test_secret_is_required() -> None:
    with pytest.raises(ValueError, match="JWT_SECRET"):
        require_jwt_secret(None)


def test_short_secret_is_rejected() -> None:
    with pytest.raises(ValueError, match="32"):
        require_jwt_secret(SecretStr("short"))


def test_long_enough_secret_is_returned() -> None:
    assert require_jwt_secret(SecretStr(SECRET)) == SECRET
