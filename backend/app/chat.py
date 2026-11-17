import re
import uuid
from datetime import datetime

from sqlalchemy import Select, func, select, update
from sqlalchemy.orm import Session, selectinload

from app.errors import question_too_long, session_not_found, validation_failed
from app.models import Answer, AnswerStatus, ChatSession, Question, utc_now
from app.pagination import keyset_page

# PostgreSQL 텍스트에 저장할 수 없는 문자: NUL, 그리고 UTF-8로 바꿀 수 없는 짝 없는 서로게이트
UNSTORABLE: re.Pattern[str] = re.compile("[\x00\ud800-\udfff]")
# 곧바로 중지해서 빈 답변이 저장된 질문의 맥락 표시. 빈 assistant 메시지는 모델 API가 거부할 수 있다.
EMPTY_ANSWER_PLACEHOLDER: str = "(답변 없이 중단됨)"
SESSIONS_SCOPE: str = "sessions"  # 세션 목록의 커서 범위. 질문 목록은 questions_scope()

QUESTION_MAX_LENGTH: int = 65_536  # 질문 한 개의 최대 길이. 넘으면 Hermes가 오류 없이 끝을 자른다(#10)
TITLE_LENGTH: int = 30  # 세션 이름은 첫 질문의 앞 30자


def session_title(question_text: str) -> str:
    """첫 질문의 앞 30자를 한 줄로 만든다(줄바꿈과 연속 공백은 공백 하나로)."""
    return " ".join(question_text.split())[:TITLE_LENGTH].rstrip()


def questions_scope(session_id: uuid.UUID) -> str:
    return f"questions:{session_id}"


def validate_question_text(text: str) -> str:
    if not text.strip():
        raise validation_failed("질문을 입력해 주세요.")
    if len(text) > QUESTION_MAX_LENGTH:
        raise question_too_long()
    if UNSTORABLE.search(text):
        raise validation_failed("질문에 사용할 수 없는 문자가 있습니다.")
    return text


def clean_answer_text(text: str) -> str:
    """Hermes가 이미 답한 뒤에는 문제 문자 하나 때문에 답변 전체를 잃으면 안 되므로 정리해서 저장한다."""
    return UNSTORABLE.sub(lambda match: "" if match.group() == "\x00" else "\ufffd", text)


def find_own_session(db: Session, account_id: uuid.UUID, session_id: uuid.UUID) -> ChatSession | None:
    """내 세션만 찾는다. 삭제된 세션과 다른 사용자의 세션은 없는 것과 같다."""
    return db.scalars(
        select(ChatSession).where(
            ChatSession.id == session_id,
            ChatSession.account_id == account_id,
            ChatSession.deleted_at.is_(None),
        )
    ).first()


def require_own_session(db: Session, account_id: uuid.UUID, session_id: uuid.UUID) -> ChatSession:
    chat: ChatSession | None = find_own_session(db, account_id, session_id)
    if chat is None:
        raise session_not_found()
    return chat


def save_exchange(
    db: Session,
    account_id: uuid.UUID,
    *,
    session_id: uuid.UUID | None,
    question_text: str,
    answer_text: str,
    status: AnswerStatus,
    now: datetime | None = None,
    new_session_id: uuid.UUID | None = None,
    asked_at: datetime | None = None,
) -> Question:
    """질문과 답변 한 쌍을 저장한다. session_id가 없으면(첫 질문) 세션도 만든다.

    새 세션의 ID는 `new_session_id`로 미리 정할 수 있다(답변이 저장되기 전에 클라이언트에 알려 주기 위해).
    질문한 시각(`asked_at`)과 답변이 끝난 시각(`now`)은 다르다. 질문과 새 세션은 질문한 시각으로, 답변과 최근 활동은
    끝난 시각으로 저장한다. `asked_at`을 주지 않으면 같은 시각이다.

    저장(commit)은 호출한 쪽이 한다. 검사에 실패하면 아무것도 저장하지 않는다.
    """
    validate_question_text(question_text)
    moment: datetime = now or utc_now()
    asked: datetime = asked_at or moment
    if session_id is None:
        chat: ChatSession = ChatSession(
            account_id=account_id,
            title=session_title(question_text),
            created_at=asked,
            updated_at=moment,
        )
        if new_session_id is not None:
            chat.id = new_session_id
        db.add(chat)
    else:
        chat = require_own_session(db, account_id, session_id)
        # 최근 활동 시각은 뒤로 가지 않는다(늦게 끝난 오래된 질문, 동시 저장). DB에서 원자적으로 갱신한다.
        db.execute(
            update(ChatSession)
            .where(ChatSession.id == chat.id)
            .values(updated_at=func.greatest(ChatSession.updated_at, moment))
        )
        db.expire(chat, ["updated_at"])
    db.flush()
    question: Question = Question(session_id=chat.id, text=question_text, created_at=asked)
    question.answer = Answer(
        text=clean_answer_text(answer_text), status=status, created_at=moment
    )
    db.add(question)
    db.flush()
    return question


def load_context(db: Session, account_id: uuid.UUID, session_id: uuid.UUID) -> list[dict[str, str]]:
    """세션의 이전 질문과 답변을 오래된 순으로 모두 모델 메시지로 만든다(길이 한도는 두지 않는다).

    맥락은 Iris DB가 기준이라서 질문마다 이 전체를 Hermes에 함께 보낸다.
    """
    require_own_session(db, account_id, session_id)
    questions: list[Question] = list(
        db.scalars(
            select(Question)
            .where(Question.session_id == session_id)
            .options(selectinload(Question.answer))
            .order_by(Question.created_at, Question.id)
        )
    )
    messages: list[dict[str, str]] = []
    for question in questions:
        messages.append({"role": "user", "content": question.text})
        messages.append(
            {"role": "assistant", "content": question.answer.text or EMPTY_ANSWER_PLACEHOLDER}
        )
    return messages


def list_sessions(
    db: Session, account_id: uuid.UUID, *, cursor: str | None, limit: int
) -> tuple[list[ChatSession], str | None]:
    """내 세션을 최근 활동 순으로 나눠서 돌려준다. 다음 페이지가 있으면 그 커서도 준다."""
    query: Select[tuple[ChatSession]] = select(ChatSession).where(
        ChatSession.account_id == account_id, ChatSession.deleted_at.is_(None)
    )
    return keyset_page(
        db, query, ChatSession.updated_at, ChatSession.id,
        cursor=cursor, limit=limit, scope=SESSIONS_SCOPE,
    )


def list_questions(
    db: Session, account_id: uuid.UUID, session_id: uuid.UUID, *, cursor: str | None, limit: int
) -> tuple[list[Question], str | None]:
    """세션의 질문을 답변과 함께 최신 질문부터 나눠서 돌려준다."""
    require_own_session(db, account_id, session_id)
    query: Select[tuple[Question]] = (
        select(Question).where(Question.session_id == session_id).options(selectinload(Question.answer))
    )
    return keyset_page(
        db, query, Question.created_at, Question.id,
        cursor=cursor, limit=limit, scope=questions_scope(session_id),
    )


def delete_session(
    db: Session, account_id: uuid.UUID, session_id: uuid.UUID, now: datetime | None = None
) -> None:
    """세션을 삭제한 것으로 표시한다(soft delete). 질문과 답변은 DB에 남고 복구나 영구 삭제는 없다."""
    chat: ChatSession = require_own_session(db, account_id, session_id)
    chat.deleted_at = now or utc_now()
    db.flush()
