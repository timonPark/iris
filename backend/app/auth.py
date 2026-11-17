from collections.abc import Iterator

from fastapi import APIRouter, Depends, Request
from pydantic import Field, field_validator
from sqlalchemy.orm import Session, sessionmaker

from app.accounts import find_account
from app.errors import (
    account_blocked,
    forbidden,
    invalid_credentials,
    password_change_required,
    unauthorized,
    validation_failed,
)
from app.models import Account, AccountStatus, Role, utc_now
from app.schemas import ApiModel
from app.security import (
    LOGIN_ID_PATTERN,
    MAX_PASSWORD_LENGTH,
    hash_password,
    validate_password,
    verify_password,
)
from app.tokens import InvalidTokenError, TokenClaims, decode_token, issue_token

router: APIRouter = APIRouter(prefix="/api/v1/auth", tags=["auth"])


class LoginRequest(ApiModel):
    login_id: str
    password: str = Field(max_length=MAX_PASSWORD_LENGTH)


class LoginResponse(ApiModel):
    access_token: str
    role: Role
    password_change_required: bool


class ChangePasswordRequest(ApiModel):
    current_password: str | None = Field(default=None, max_length=MAX_PASSWORD_LENGTH)
    new_password: str

    @field_validator("new_password")
    @classmethod
    def check_new_password(cls, value: str) -> str:
        return validate_password(value)


class ChangePasswordResponse(ApiModel):
    access_token: str


def get_session(request: Request) -> Iterator[Session]:
    factory: sessionmaker[Session] = request.app.state.session_factory
    with factory() as session:
        yield session


def authorize(account: Account, claims: TokenClaims, *, allow_password_change: bool) -> None:
    """요청마다 계정 상태를 확인한다. 만료가 없는 토큰이라 이 검사가 즉시 차단을 담당한다."""
    if claims.issued_at < account.password_changed_at:
        raise unauthorized()  # 비밀번호를 바꾸기 전에 발급된 토큰
    if account.status == AccountStatus.BLOCKED:
        raise account_blocked()
    if account.password_change_required and not allow_password_change:
        raise password_change_required()


def bearer_token(request: Request) -> str:
    header: str = request.headers.get("authorization", "")
    parts: tuple[str, str, str] = header.partition(" ")
    if parts[0].lower() != "bearer" or not parts[2].strip():
        raise unauthorized()
    return parts[2].strip()


def load_account(request: Request, session: Session, *, allow_password_change: bool) -> Account:
    try:
        claims: TokenClaims = decode_token(bearer_token(request), request.app.state.token_secret)
    except InvalidTokenError as error:
        raise unauthorized() from error
    account: Account | None = session.get(Account, claims.account_id)
    if account is None:
        raise unauthorized()
    authorize(account, claims, allow_password_change=allow_password_change)
    return account


def current_account(request: Request, session: Session = Depends(get_session)) -> Account:
    """로그인한 계정. 임시 비밀번호 상태이면 거부한다(비밀번호 변경 API만 예외)."""
    return load_account(request, session, allow_password_change=False)


def current_account_for_password_change(
    request: Request, session: Session = Depends(get_session)
) -> Account:
    """비밀번호 변경 API 전용. 임시 비밀번호 상태여도 통과시킨다(차단과 낡은 토큰은 그대로 거부)."""
    return load_account(request, session, allow_password_change=True)


# 없는 아이디도 이 해시를 검증해, 응답 시간으로 계정이 있는지 알 수 없게 한다.
# 처음 쓸 때 만들면 그 요청만 느려지므로 모듈을 불러올 때 미리 만든다.
DUMMY_PASSWORD_HASH: str = hash_password("dummy-password-for-constant-time")


def lookup_account(request: Request, login_id: str) -> Account | None:
    """아이디로 계정을 찾고 DB 연결을 바로 돌려준다(이후 argon2 검증 동안 연결을 붙잡지 않는다)."""
    if LOGIN_ID_PATTERN.fullmatch(login_id) is None:
        return None  # 형식상 있을 수 없는 아이디는 DB를 조회하지 않는다
    factory: sessionmaker[Session] = request.app.state.session_factory
    with factory() as session:
        account: Account | None = find_account(session, login_id)
        if account is not None:
            session.expunge(account)
        return account


@router.post("/login", response_model=LoginResponse)
def login(body: LoginRequest, request: Request) -> LoginResponse:
    account: Account | None = lookup_account(request, body.login_id)
    password_hash: str = account.password_hash if account is not None else DUMMY_PASSWORD_HASH
    password_ok: bool = verify_password(body.password, password_hash)
    if account is None or not password_ok:
        raise invalid_credentials()
    if account.status == AccountStatus.BLOCKED:
        raise account_blocked()  # 비밀번호가 맞은 뒤에만 차단 여부를 알린다
    return LoginResponse(
        access_token=issue_token(account.id, request.app.state.token_secret),
        role=account.role,
        password_change_required=account.password_change_required,
    )


def verify_current_password(account: Account, current_password: str | None) -> None:
    if not current_password:  # 없거나 빈 문자열
        raise validation_failed("현재 비밀번호를 입력해 주세요.")
    if not verify_password(current_password, account.password_hash):
        raise invalid_credentials()


def ensure_password_really_changes(account: Account, new_password: str) -> None:
    """새 비밀번호는 지금 비밀번호와 달라야 한다. 임시 비밀번호를 그대로 쓰는 것도 변경이 아니다."""
    if verify_password(new_password, account.password_hash):
        raise validation_failed("현재 비밀번호와 다른 비밀번호를 입력해 주세요.")


@router.post("/password", response_model=ChangePasswordResponse)
def change_password(
    body: ChangePasswordRequest,
    request: Request,
    account: Account = Depends(current_account_for_password_change),
    session: Session = Depends(get_session),
) -> ChangePasswordResponse:
    """비밀번호를 바꾼다. 임시 비밀번호 직후(강제 변경)에는 새 비밀번호만 받는다."""
    if account.role == Role.ADMIN:
        raise forbidden()  # 관리자 비밀번호는 설정으로만 바꾼다
    # 같은 계정의 동시 변경을 순서대로 처리한다. 잠근 뒤 다시 읽어서, 먼저 끝난 변경을 반영한 값으로 검사한다.
    session.refresh(account, with_for_update=True)
    if not account.password_change_required:
        verify_current_password(account, body.current_password)
    ensure_password_really_changes(account, body.new_password)
    account.password_hash = hash_password(body.new_password)
    account.password_changed_at = utc_now()  # 이 시각보다 일찍 발급된 토큰은 모두 거부된다
    account.password_change_required = False
    session.commit()
    # 변경 시각 이후에 발급해야 새 토큰이 같은 시각 비교로 거부되지 않는다.
    return ChangePasswordResponse(access_token=issue_token(account.id, request.app.state.token_secret))
