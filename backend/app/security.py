import re

from argon2 import PasswordHasher
from argon2.exceptions import InvalidHashError, VerificationError

# 아이디 규칙: 영문 소문자와 숫자 4~20자. DB의 CHECK(app/models.py)와 같은 규칙이다.
LOGIN_ID_PATTERN: re.Pattern[str] = re.compile(r"[a-z0-9]{4,20}")
# 비밀번호 규칙: 8자 이상, 복잡도 규칙 없음. 요청 크기를 제한하려고 1024자까지만 받는다(openapi.yaml 과 같다).
MIN_PASSWORD_LENGTH: int = 8
MAX_PASSWORD_LENGTH: int = 1024

_hasher: PasswordHasher = PasswordHasher()


def validate_login_id(value: str) -> str:
    if LOGIN_ID_PATTERN.fullmatch(value) is None:
        raise ValueError("아이디는 영문 소문자와 숫자 4~20자여야 합니다.")
    return value


def validate_password(value: str) -> str:
    if not MIN_PASSWORD_LENGTH <= len(value) <= MAX_PASSWORD_LENGTH:
        raise ValueError(
            f"비밀번호는 {MIN_PASSWORD_LENGTH}자 이상 {MAX_PASSWORD_LENGTH}자 이하여야 합니다."
        )
    return value


def hash_password(password: str) -> str:
    return _hasher.hash(password)


def verify_password(password: str, password_hash: str) -> bool:
    try:
        return _hasher.verify(password_hash, password)
    except (VerificationError, InvalidHashError):
        return False
