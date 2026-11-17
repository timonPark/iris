import enum
import uuid
from datetime import UTC, datetime

from sqlalchemy import CheckConstraint, DateTime, Enum, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db import Base


class Role(enum.StrEnum):
    """계정이 가진 권한 구분. 관리자 또는 사용자 중 하나(ssot/GLOSSARY.md)."""

    ADMIN = "admin"
    USER = "user"


class AccountStatus(enum.StrEnum):
    """계정의 활성 여부. 활성 또는 차단 중 하나(ssot/GLOSSARY.md)."""

    ACTIVE = "active"
    BLOCKED = "blocked"


def utc_now() -> datetime:
    return datetime.now(UTC)


def enum_values(enum_class: type[enum.StrEnum]) -> list[str]:
    return [member.value for member in enum_class]


class Account(Base):
    """로그인할 수 있는 주체. 계정은 관리자만 만들고, 삭제는 없다."""

    __tablename__ = "accounts"
    __table_args__ = (
        # 아이디 규칙(영문 소문자와 숫자 4~20자)을 DB에서도 막는다. 앱의 app.security 와 같은 규칙이다.
        CheckConstraint("login_id ~ '^[a-z0-9]{4,20}$'", name="ck_accounts_login_id_format"),
    )

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    login_id: Mapped[str] = mapped_column(String(20), unique=True)
    password_hash: Mapped[str] = mapped_column(String(255))
    role: Mapped[Role] = mapped_column(
        Enum(
            Role,
            native_enum=False,
            length=10,
            create_constraint=True,
            name="ck_accounts_role",
            values_callable=enum_values,
        )
    )
    status: Mapped[AccountStatus] = mapped_column(
        Enum(
            AccountStatus,
            native_enum=False,
            length=10,
            create_constraint=True,
            name="ck_accounts_status",
            values_callable=enum_values,
        ),
        default=AccountStatus.ACTIVE,
    )
    # 이 시각보다 일찍 발급된 토큰은 거부한다(비밀번호를 바꾸면 이전 토큰이 모두 무효가 된다).
    password_changed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    # 임시 비밀번호 상태. true면 비밀번호를 바꾸기 전에는 다른 기능을 쓸 수 없다.
    password_change_required: Mapped[bool] = mapped_column(default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
