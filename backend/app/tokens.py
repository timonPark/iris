import uuid
from dataclasses import dataclass
from datetime import UTC, datetime
from typing import Any

import jwt
from pydantic import SecretStr

ALGORITHM: str = "HS256"
MIN_SECRET_LENGTH: int = 32


class InvalidTokenError(Exception):
    """토큰이 없거나 서명이 틀렸거나 내용이 올바르지 않다."""


@dataclass(frozen=True)
class TokenClaims:
    account_id: uuid.UUID
    issued_at: datetime


def require_jwt_secret(secret: SecretStr | None) -> str:
    """토큰 서명 키를 꺼낸다. 없거나 짧으면 오류(앱 시작 때 호출해서 일찍 알린다)."""
    if secret is None:
        raise ValueError("JWT_SECRET이 설정되지 않았습니다. backend/.env를 확인하세요.")
    value: str = secret.get_secret_value()
    if len(value) < MIN_SECRET_LENGTH:
        raise ValueError(f"JWT_SECRET은 {MIN_SECRET_LENGTH}자 이상이어야 합니다.")
    return value


def issue_token(account_id: uuid.UUID, secret: str, issued_at: datetime | None = None) -> str:
    """만료 없는 accessToken을 만든다. 발급 시각은 소수 초(마이크로초)까지 담는다."""
    moment: datetime = issued_at or datetime.now(UTC)
    if moment.tzinfo is None:
        # 시간대가 없으면 서버의 지역 시간으로 해석되어 비밀번호 변경 시각과의 비교가 어긋난다.
        raise ValueError("issued_at에는 시간대(timezone)가 있어야 합니다.")
    payload: dict[str, Any] = {"sub": str(account_id), "iat": moment.timestamp()}
    return jwt.encode(payload, secret, algorithm=ALGORITHM)


def decode_token(token: str, secret: str) -> TokenClaims:
    try:
        payload: dict[str, Any] = jwt.decode(
            token,
            secret,
            algorithms=[ALGORITHM],
            options={"require": ["sub", "iat"], "verify_exp": False, "verify_iat": False},
        )
        return TokenClaims(
            account_id=uuid.UUID(payload["sub"]),
            issued_at=datetime.fromtimestamp(float(payload["iat"]), UTC),
        )
    except (jwt.PyJWTError, ValueError, TypeError, AttributeError, OverflowError, OSError) as error:
        raise InvalidTokenError("올바르지 않은 토큰입니다.") from error
