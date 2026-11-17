import logging

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session, sessionmaker

from app.config import Settings
from app.models import Account, AccountStatus, Role
from app.security import hash_password, validate_login_id, validate_password, verify_password

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
