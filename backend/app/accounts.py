import logging
import uuid

from sqlalchemy import Select, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session, sessionmaker

from app.config import Settings
from app.errors import login_id_taken, user_not_found, validation_failed
from app.models import Account, AccountStatus, Role, utc_now
from app.pagination import keyset_page
from app.security import (
    generate_temporary_password,
    hash_password,
    validate_login_id,
    validate_password,
    verify_password,
)

logger: logging.Logger = logging.getLogger(__name__)


def find_account(session: Session, login_id: str) -> Account | None:
    return session.scalars(select(Account).where(Account.login_id == login_id)).first()


def warn_if_admin_is_unusable(admin: Account, password: str) -> None:
    """이미 있는 관리자 계정이 .env 설정과 어긋나 있으면 알린다. .env 값은 첫 생성에만 쓰인다."""
    if admin.status == AccountStatus.BLOCKED:
        logger.warning("관리자 계정 '%s'가 차단되어 있어 로그인할 수 없습니다.", admin.login_id)
    if not verify_password(password, admin.password_hash):
        logger.warning(
            "관리자 계정 '%s'의 비밀번호가 .env의 ADMIN_PASSWORD와 다릅니다. "
            ".env 값은 계정을 처음 만들 때만 쓰이고, 이후 변경은 반영되지 않습니다.",
            admin.login_id,
        )


def ensure_initial_admin(session: Session, login_id: str, password: str) -> bool:
    """같은 아이디가 없으면 관리자 계정을 만든다. 만들었으면 True, 이미 있으면 False.

    저장(commit)은 호출한 쪽이 한다. 다른 프로세스가 동시에 먼저 만들었으면 이미 있는 것으로 본다.
    """
    validate_login_id(login_id)
    validate_password(password)
    existing: Account | None = find_account(session, login_id)
    if existing is not None:
        if existing.role != Role.ADMIN:
            raise ValueError(f"'{login_id}'는 이미 사용자 계정으로 쓰이고 있어 관리자로 만들 수 없습니다.")
        warn_if_admin_is_unusable(existing, password)
        return False
    try:
        with session.begin_nested():
            session.add(
                Account(login_id=login_id, password_hash=hash_password(password), role=Role.ADMIN)
            )
    except IntegrityError:
        return False
    return True


def create_initial_admin(factory: sessionmaker[Session], settings: Settings) -> bool:
    """설정(.env)의 ADMIN_LOGIN_ID, ADMIN_PASSWORD로 첫 관리자 계정을 만든다."""
    login_id: str | None = settings.admin_login_id
    password: str | None = (
        None if settings.admin_password is None else settings.admin_password.get_secret_value()
    )
    if login_id is None and password is None:
        logger.warning("ADMIN_LOGIN_ID, ADMIN_PASSWORD가 없어 관리자 계정을 만들지 않았습니다.")
        return False
    if login_id is None or password is None:
        raise ValueError("ADMIN_LOGIN_ID와 ADMIN_PASSWORD는 함께 설정해야 합니다.")
    with factory.begin() as session:
        created: bool = ensure_initial_admin(session, login_id, password)
    logger.info("관리자 계정 '%s': %s", login_id, "만들었습니다" if created else "이미 있습니다")
    return created


# --- 관리자가 사용자 계정을 다루는 일(app/admin.py가 쓴다). 저장(commit)은 호출한 쪽이 한다. ---

ADMIN_USERS_SCOPE: str = "admin-users"  # 사용자 계정 목록의 커서 범위


def require_user(db: Session, user_id: uuid.UUID, *, lock: bool = False) -> Account:
    """사용자 역할의 계정만 찾는다. 관리자 계정과 없는 계정은 같은 USER_NOT_FOUND다(존재 여부도 알리지 않는다)."""
    query: Select[tuple[Account]] = select(Account).where(
        Account.id == user_id, Account.role == Role.USER
    )
    user: Account | None = db.scalars(query.with_for_update() if lock else query).first()
    if user is None:
        raise user_not_found()
    return user


def list_users(
    db: Session, *, cursor: str | None, limit: int
) -> tuple[list[Account], str | None]:
    """사용자 역할 계정을 최신 등록 순으로 나눠서 돌려준다(차단된 계정 포함, 검색 없음)."""
    query: Select[tuple[Account]] = select(Account).where(Account.role == Role.USER)
    return keyset_page(
        db, query, Account.created_at, Account.id, cursor=cursor, limit=limit, scope=ADMIN_USERS_SCOPE
    )


def create_user(db: Session, login_id: str) -> tuple[Account, str]:
    """사용자 계정을 만들고 (계정, 임시 비밀번호)를 돌려준다. 임시 비밀번호는 DB에 해시로만 남는다."""
    try:
        validate_login_id(login_id)
    except ValueError as error:
        raise validation_failed(str(error)) from error
    if find_account(db, login_id) is not None:
        raise login_id_taken()
    temporary: str = generate_temporary_password()
    account: Account = Account(
        login_id=login_id,
        password_hash=hash_password(temporary),
        role=Role.USER,
        password_change_required=True,  # 임시 비밀번호로 로그인하면 바로 바꿔야 한다
    )
    try:
        with db.begin_nested():
            db.add(account)
    except IntegrityError as error:  # 동시에 같은 아이디가 등록된 경우
        raise login_id_taken() from error
    return account, temporary


def set_user_blocked(db: Session, user_id: uuid.UUID, *, blocked: bool) -> Account:
    """차단하거나 해제한다. 이미 그 상태여도 그대로 성공한다."""
    user: Account = require_user(db, user_id)
    user.status = AccountStatus.BLOCKED if blocked else AccountStatus.ACTIVE
    db.flush()
    return user


def reset_user_password(db: Session, user_id: uuid.UUID) -> tuple[Account, str]:
    """임시 비밀번호를 새로 만든다. 이전 토큰은 모두 무효가 되고 계정은 임시 비밀번호 상태가 된다(차단 상태는 그대로)."""
    temporary: str = generate_temporary_password()
    password_hash: str = hash_password(temporary)  # 느린 해시는 행을 잠그기 전에 끝낸다
    user: Account = require_user(db, user_id, lock=True)  # 사용자의 동시 비밀번호 변경과 순서대로 처리한다
    user.password_hash = password_hash
    user.password_changed_at = utc_now()
    user.password_change_required = True
    db.flush()
    return user, temporary

