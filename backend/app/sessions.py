import uuid
from datetime import datetime

from fastapi import APIRouter, Depends, Query, Response
from sqlalchemy.orm import Session

from app.auth import current_account, get_session
from app.chat import delete_session, list_questions, list_sessions
from app.errors import session_not_found
from app.models import Account, AnswerStatus, ChatSession, Question
from app.schemas import ApiModel

router: APIRouter = APIRouter(prefix="/api/v1/sessions", tags=["sessions"])


class SessionOut(ApiModel):
    id: uuid.UUID
    title: str
    updated_at: datetime


class SessionPage(ApiModel):
    items: list[SessionOut]
    next_cursor: str | None = None


class AnswerOut(ApiModel):
    id: uuid.UUID
    text: str
    status: AnswerStatus
    created_at: datetime


class QuestionOut(ApiModel):
    id: uuid.UUID
    text: str
    created_at: datetime
    answer: AnswerOut


class QuestionPage(ApiModel):
    items: list[QuestionOut]
    next_cursor: str | None = None


def parse_session_id(value: str) -> uuid.UUID:
    """UUID가 아닌 값은 있을 수 없는 세션이므로 없는 세션(404)으로 처리한다."""
    try:
        return uuid.UUID(value)
    except ValueError as error:
        raise session_not_found() from error


def to_session_out(chat: ChatSession) -> SessionOut:
    return SessionOut(id=chat.id, title=chat.title, updated_at=chat.updated_at)


def to_question_out(question: Question) -> QuestionOut:
    answer: AnswerOut = AnswerOut(
        id=question.answer.id,
        text=question.answer.text,
        status=question.answer.status,
        created_at=question.answer.created_at,
    )
    return QuestionOut(id=question.id, text=question.text, created_at=question.created_at, answer=answer)


@router.get("", response_model=SessionPage, response_model_exclude_none=True)
def get_sessions(
    account: Account = Depends(current_account),
    db: Session = Depends(get_session),
    cursor: str | None = Query(default=None),
    limit: int = Query(default=20, ge=1, le=100),
) -> SessionPage:
    result: tuple[list[ChatSession], str | None] = list_sessions(
        db, account.id, cursor=cursor, limit=limit
    )
    return SessionPage(items=[to_session_out(chat) for chat in result[0]], next_cursor=result[1])


@router.get("/{session_id}/questions", response_model=QuestionPage, response_model_exclude_none=True)
def get_questions(
    session_id: str,
    account: Account = Depends(current_account),
    db: Session = Depends(get_session),
    cursor: str | None = Query(default=None),
    limit: int = Query(default=20, ge=1, le=100),
) -> QuestionPage:
    result: tuple[list[Question], str | None] = list_questions(
        db, account.id, parse_session_id(session_id), cursor=cursor, limit=limit
    )
    return QuestionPage(items=[to_question_out(q) for q in result[0]], next_cursor=result[1])


@router.delete("/{session_id}", status_code=204)
def remove_session(
    session_id: str,
    account: Account = Depends(current_account),
    db: Session = Depends(get_session),
) -> Response:
    delete_session(db, account.id, parse_session_id(session_id))
    db.commit()
    return Response(status_code=204)
