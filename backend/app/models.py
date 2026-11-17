import enum
import uuid
from datetime import UTC, datetime

from sqlalchemy import CheckConstraint, DateTime, Enum, ForeignKey, Index, String, Text, text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db import Base


class Role(enum.StrEnum):
    """계정이 가진 권한 구분. 관리자 또는 사용자 중 하나(ssot/GLOSSARY.md)."""

    ADMIN = "admin"
    USER = "user"


class AccountStatus(enum.StrEnum):
    """계정의 활성 여부. 활성 또는 차단 중 하나(ssot/GLOSSARY.md)."""

    ACTIVE = "active"
    BLOCKED = "blocked"


class AnswerStatus(enum.StrEnum):
    """답변이 끝까지 왔는지(완료) 사용자가 중간에 멈췄는지(중단됨)."""

    COMPLETED = "completed"
    STOPPED = "stopped"


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


class ChatSession(Base):
    """사이드바 목록에 나열되는 대화 하나(ssot/GLOSSARY.md의 세션). 삭제는 `deleted_at`만 채운다."""

    __tablename__ = "chat_sessions"
    __table_args__ = (
        # 내 세션을 최근 활동 순으로 나눠서 읽는 쿼리(목록)용. 삭제된 세션은 목록에 나오지 않으므로 인덱스에서도 뺀다
        # (삭제는 영구적이고 행이 지워지지 않으므로, 빼지 않으면 삭제가 쌓일수록 목록이 느려진다).
        Index(
            "ix_chat_sessions_account_activity",
            "account_id",
            "updated_at",
            "id",
            postgresql_where=text("deleted_at IS NULL"),
        ),
    )

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    account_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("accounts.id"))
    title: Mapped[str] = mapped_column(String(100))  # 첫 질문의 앞 30자 정도
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)  # 최근 활동
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), default=None)


class Question(Base):
    """사용자가 보낸 텍스트 메시지. 직접 입력했든 음성 입력으로 변환했든 구분하지 않는다."""

    __tablename__ = "questions"
    __table_args__ = (
        # 질문 길이 규칙(1~65,536자)을 DB에서도 막는다. 앱의 app.chat 과 같은 규칙이다.
        CheckConstraint("char_length(text) BETWEEN 1 AND 65536", name="ck_questions_text_length"),
        Index("ix_questions_session_created", "session_id", "created_at", "id"),
    )

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    session_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("chat_sessions.id", ondelete="CASCADE"))
    text: Mapped[str] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    answer: Mapped["Answer"] = relationship(
        back_populates="question", uselist=False, cascade="all, delete-orphan"
    )


class Answer(Base):
    """질문에 대해 Hermes가 스트리밍으로 돌려준 텍스트. 질문과 한 쌍으로 저장된다."""

    __tablename__ = "answers"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    question_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("questions.id", ondelete="CASCADE"), unique=True
    )
    text: Mapped[str] = mapped_column(Text)  # 곧바로 멈추면 빈 문자열일 수 있다
    status: Mapped[AnswerStatus] = mapped_column(
        Enum(
            AnswerStatus,
            native_enum=False,
            length=10,
            create_constraint=True,
            name="ck_answers_status",
            values_callable=enum_values,
        )
    )
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    question: Mapped[Question] = relationship(back_populates="answer")
