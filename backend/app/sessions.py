import asyncio
import logging
import uuid
from datetime import datetime

from fastapi import APIRouter, Depends, Query, Request, Response
from fastapi.responses import StreamingResponse
from pydantic import Field
from sqlalchemy.orm import Session, sessionmaker
from starlette.concurrency import run_in_threadpool

from app.auth import current_account, get_session
from app.chat import (
    delete_session,
    find_own_session,
    list_questions,
    list_sessions,
    load_context,
    validate_question_text,
)
from app.errors import not_streaming, server_error, session_busy, session_not_found
from app.hermes import ChatBackend
from app.instructions import with_instruction
from app.models import Account, AnswerStatus, ChatSession, Question
from app.runs import ChatRun, RunRegistry, format_sse, launch_run, stream_events
from app.schemas import ApiModel

logger: logging.Logger = logging.getLogger(__name__)

router: APIRouter = APIRouter(prefix="/api/v1/sessions", tags=["sessions"])


class QuestionRequest(ApiModel):
    session_id: str | None = Field(default=None)
    text: str


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


def read_context(
    db: Session, account_id: uuid.UUID, session_id: uuid.UUID | None
) -> list[dict[str, str]]:
    """이전 질문과 답변을 읽고 DB 연결을 바로 돌려준다(스트리밍 동안 붙잡지 않는다). 새 세션이면 비어 있다."""
    try:
        return [] if session_id is None else load_context(db, account_id, session_id)
    finally:
        db.rollback()


def ensure_session_free(
    registry: RunRegistry, account_id: uuid.UUID, session_id: uuid.UUID | None
) -> None:
    """내 세션에 진행 중인 답변이 있으면 BUSY. 남의 세션이면 내 세션이 아니므로 없는 세션과 같다."""
    active: ChatRun | None = None if session_id is None else registry.get(session_id)
    if active is not None:
        raise session_busy() if active.account_id == account_id else session_not_found()


@router.post("/questions")
async def send_question(
    body: QuestionRequest,
    request: Request,
    account: Account = Depends(current_account),
    db: Session = Depends(get_session),
) -> StreamingResponse:
    """질문을 Hermes에 보내고 답변을 SSE로 돌려준다. 이 요청이 끊겨도 답변은 끝까지 받아 저장한다."""
    text: str = validate_question_text(body.text)
    session_id: uuid.UUID | None = None if body.session_id is None else parse_session_id(body.session_id)
    return await submit_question(request, account.id, db, text, session_id)


async def submit_question(
    request: Request,
    account_id: uuid.UUID,
    db: Session,
    text: str,
    session_id: uuid.UUID | None,
    *,
    announce_text: bool = False,
) -> StreamingResponse:
    """검사를 마친 질문 텍스트를 작업으로 등록하고 SSE 응답을 연다(텍스트 질문과 음성 질문이 같이 쓴다).

    `announce_text`가 참이면 보정된 질문 텍스트를 `question` 이벤트로 먼저 알린다(음성 질문).
    """
    registry: RunRegistry = request.app.state.runs
    backend: ChatBackend | None = request.app.state.hermes
    if backend is None:
        logger.error("HERMES_API_KEY가 없어 질문을 처리할 수 없다")
        raise server_error()
    ensure_session_free(registry, account_id, session_id)
    is_new: bool = session_id is None
    run: ChatRun = ChatRun(account_id, uuid.uuid4() if session_id is None else session_id, is_new, text, [])
    registry.add(run)  # 위의 확인과 이 등록 사이에 await가 없어서, 동시에 온 두 요청 중 하나만 등록된다
    try:
        context: list[dict[str, str]] = await run_in_threadpool(read_context, db, account_id, session_id)
    except BaseException:
        registry.remove(run)  # 없는 세션(404)이거나 응답을 시작하기 전에 끊긴 경우
        raise
    run.messages = with_instruction([*context, {"role": "user", "content": text}])  # 지시문은 보내기만 하고 저장하지 않는다
    launch_run(registry, backend, request.app.state.session_factory, run)
    return await open_stream(run, is_new, text if announce_text else None)


async def open_stream(run: ChatRun, is_new_session: bool, question_text: str | None = None) -> StreamingResponse:
    """Hermes가 스트림을 열 때까지 기다린 뒤 SSE 응답을 시작한다. 그 전에 실패하면 일반 오류 응답이다."""
    try:
        await run.started
    except asyncio.CancelledError:
        run.reader_attached = False  # 응답을 시작하기도 전에 클라이언트가 끊겼다. 작업은 계속된다
        raise
    except Exception as error:
        logger.warning("Hermes 호출을 시작하지 못했다: %s", error)
        raise server_error() from error
    first: list[str] = [format_sse("session", {"id": str(run.session_id)})] if is_new_session else []
    if question_text is not None:
        first.append(format_sse("question", {"text": question_text}))
    return StreamingResponse(
        stream_events(run, first),
        media_type="text/event-stream",
        headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"},
    )


@router.post("/{session_id}/stop", status_code=204)
async def stop_answer(
    session_id: str,
    request: Request,
    account: Account = Depends(current_account),
    db: Session = Depends(get_session),
) -> Response:
    """진행 중인 답변을 멈추라고 알린다. 저장은 그 뒤에 일어나고, 질문 전송 SSE가 `stopped`로 끝난다."""
    parsed: uuid.UUID = parse_session_id(session_id)
    run: ChatRun | None = request.app.state.runs.get(parsed)
    if run is not None and run.account_id == account.id:
        run.stop_requested.set()
        return Response(status_code=204)
    own: ChatSession | None = await run_in_threadpool(find_own_session, db, account.id, parsed)
    if own is None:
        raise session_not_found()  # 남의 진행 중인 답변이 있는지도 알려 주지 않는다
    raise not_streaming()
