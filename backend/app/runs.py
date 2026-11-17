import asyncio
import enum
import json
import logging
import uuid
from collections.abc import AsyncIterator
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any

from sqlalchemy.orm import Session, sessionmaker
from starlette.concurrency import run_in_threadpool

from app.chat import save_exchange
from app.errors import ErrorCode, session_busy
from app.hermes import ChatBackend, HermesError
from app.models import AnswerStatus, utc_now

logger: logging.Logger = logging.getLogger(__name__)

# 답변이 오래 걸리는 동안 터널이나 프록시가 연결을 끊지 않도록 이 간격마다 주석 줄을 보낸다.
KEEPALIVE_SECONDS: float = 15.0
KEEPALIVE: str = ": keepalive\n\n"
SERVER_ERROR_DATA: dict[str, str] = {
    "code": ErrorCode.SERVER_ERROR.value,
    "message": "서버 오류가 발생했습니다.",
}


def format_sse(event: str, data: dict[str, Any]) -> str:
    return f"event: {event}\ndata: {json.dumps(data, ensure_ascii=False)}\n\n"


@dataclass(eq=False)
class ChatRun:
    """질문 하나를 처리하는 작업. HTTP 요청과 따로 돌아서, 클라이언트가 끊겨도 끝까지 저장한다."""

    account_id: uuid.UUID
    session_id: uuid.UUID
    is_new_session: bool
    question_text: str
    messages: list[dict[str, str]]
    asked_at: datetime = field(default_factory=utc_now)  # 질문한 시각(답변이 끝난 시각이 아니다)
    events: asyncio.Queue[str | None] = field(default_factory=asyncio.Queue)
    stop_requested: asyncio.Event = field(default_factory=asyncio.Event)
    started: asyncio.Future[None] = field(
        default_factory=lambda: asyncio.get_running_loop().create_future()
    )
    parts: list[str] = field(default_factory=list)  # 지금까지 받은 답변 조각
    stream_opened: bool = False  # Hermes가 스트림을 열었는가(그 전의 실패는 일반 오류 응답으로 알린다)
    reader_attached: bool = True  # 이벤트를 읽는 SSE 응답이 아직 있는가
    task: asyncio.Task[None] | None = None

    def publish(self, event: str, data: dict[str, Any]) -> None:
        if self.reader_attached:
            self.events.put_nowait(format_sse(event, data))

    def end_stream(self) -> None:
        if self.reader_attached:
            self.events.put_nowait(None)


class RunRegistry:
    """진행 중인 작업을 세션 ID로 찾는 메모리 등록부. 서버 프로세스가 하나일 때만 정확하다."""

    def __init__(self) -> None:
        self._runs: dict[uuid.UUID, ChatRun] = {}

    def get(self, session_id: uuid.UUID) -> ChatRun | None:
        return self._runs.get(session_id)

    def add(self, run: ChatRun) -> None:
        if run.session_id in self._runs:
            raise session_busy()
        self._runs[run.session_id] = run

    def remove(self, run: ChatRun) -> None:
        if self._runs.get(run.session_id) is run:
            del self._runs[run.session_id]

    def active_count(self) -> int:
        return len(self._runs)

    async def shutdown(self, timeout: float) -> None:
        """서버를 끌 때 진행 중인 작업을 멈추게 하고(받은 부분은 "중단됨"으로 저장) 끝나기를 기다린다."""
        tasks: list[asyncio.Task[None]] = []
        for run in list(self._runs.values()):
            run.stop_requested.set()
            if run.task is not None:
                tasks.append(run.task)
        if not tasks:
            return
        _, pending = await asyncio.wait(tasks, timeout=timeout)
        for task in pending:
            task.cancel()  # 끝내 마무리하지 못한 작업. 읽는 쪽이 끝없이 기다리지 않도록 취소한다
        if pending:
            await asyncio.gather(*pending, return_exceptions=True)


class Outcome(enum.Enum):
    COMPLETED = "completed"
    STOPPED = "stopped"
    FAILED = "failed"


async def consume(run: ChatRun, backend: ChatBackend) -> None:
    """Hermes에서 답변 조각을 받아 이벤트로 내보낸다. 스트림이 열리면 `started`를 알린다."""
    try:
        async with backend.open_chat(run.messages) as stream:
            run.stream_opened = True
            if not run.started.done():
                run.started.set_result(None)
            async for text in stream:
                run.parts.append(text)
                run.publish("delta", {"text": text})
    except asyncio.CancelledError:
        if not run.started.done():
            # Hermes에 연결하는 중에 중지가 왔다. 오류가 아니라 받은 것이 없는 중지로 마무리한다.
            run.stream_opened = True
            run.started.set_result(None)
        raise
    except Exception as error:
        if not run.started.done():  # 스트림이 열리기 전의 실패: 요청 쪽이 일반 오류 응답으로 바꾼다
            run.started.set_exception(error)
            run.started.exception()  # 아무도 기다리지 않아도 경고가 나지 않게 가져간 것으로 표시
        raise


async def wait_for_outcome(run: ChatRun, consumer: asyncio.Task[None]) -> tuple[Outcome, Exception | None]:
    """Hermes 쪽이 먼저 끝나는지, 중지 요청이 먼저 오는지를 기다린다. 중지면 Hermes 연결을 끊는다."""
    stopper: asyncio.Future[bool] = asyncio.ensure_future(run.stop_requested.wait())
    try:
        await asyncio.wait({consumer, stopper}, return_when=asyncio.FIRST_COMPLETED)
        if consumer.done():
            error: BaseException | None = consumer.exception()
            if error is None:
                return Outcome.COMPLETED, None
            if isinstance(error, Exception):  # HermesError든 전송 계층 예외든 받은 부분은 지킨다
                return Outcome.FAILED, error
            raise error
        consumer.cancel()  # async with를 벗어나며 Hermes 연결이 닫히고, Hermes도 멈춘다
        await asyncio.gather(consumer, return_exceptions=True)
        return Outcome.STOPPED, None
    finally:
        stopper.cancel()


def save_run(
    factory: sessionmaker[Session], run: ChatRun, answer_text: str, status: AnswerStatus
) -> uuid.UUID:
    with factory.begin() as db:
        question = save_exchange(
            db,
            run.account_id,
            session_id=None if run.is_new_session else run.session_id,
            new_session_id=run.session_id if run.is_new_session else None,
            question_text=run.question_text,
            answer_text=answer_text,
            status=status,
            asked_at=run.asked_at,
        )
        return question.answer.id


async def conclude(
    run: ChatRun, factory: sessionmaker[Session], outcome: Outcome, error: Exception | None
) -> tuple[str, dict[str, Any]]:
    """결과에 맞게 저장하고 마지막 이벤트를 만든다.

    완료와 중지는 저장한다. Hermes 오류는 이미 받은 조각이 있으면 "중단됨"으로 저장하고, 없으면 저장하지 않는다.
    Hermes가 답을 하나도 보내지 않고 끝난 것도 오류다(빈 답변을 저장하면 이후 맥락이 깨진다).
    """
    text: str = "".join(run.parts)
    if outcome is Outcome.COMPLETED and not text:
        outcome, error = Outcome.FAILED, HermesError("Hermes가 답변을 보내지 않고 끝났다")
    if outcome is Outcome.FAILED:
        logger.warning("Hermes 오류로 답변이 끝나지 못했다(받은 글자 %d): %s", len(text), error)
        if not text:
            return "error", SERVER_ERROR_DATA
    status: AnswerStatus = AnswerStatus.COMPLETED if outcome is Outcome.COMPLETED else AnswerStatus.STOPPED
    answer_id: uuid.UUID = await run_in_threadpool(save_run, factory, run, text, status)
    if outcome is Outcome.FAILED:
        return "error", SERVER_ERROR_DATA
    return ("done" if outcome is Outcome.COMPLETED else "stopped"), {"answerId": str(answer_id)}


async def supervise(
    run: ChatRun, registry: RunRegistry, backend: ChatBackend, factory: sessionmaker[Session]
) -> None:
    consumer: asyncio.Task[None] = asyncio.create_task(consume(run, backend))
    final: tuple[str, dict[str, Any]] | None = None
    try:
        outcome, error = await wait_for_outcome(run, consumer)
        if run.stream_opened:
            final = await conclude(run, factory, outcome, error)
    except Exception:
        logger.exception("질문 처리 중 오류가 났다")
        final = ("error", SERVER_ERROR_DATA) if run.stream_opened else None
    finally:
        # 이 작업이 취소되어도(서버가 꺼질 때 등) Hermes 연결을 닫고, 읽는 쪽이 끝없이 기다리지 않게 스트림을 닫는다.
        if not consumer.done():
            consumer.cancel()
        registry.remove(run)
        if final is not None:
            run.publish(*final)
        run.end_stream()


def launch_run(
    registry: RunRegistry, backend: ChatBackend, factory: sessionmaker[Session], run: ChatRun
) -> None:
    """이미 등록된 작업을 시작한다."""
    run.task = asyncio.create_task(supervise(run, registry, backend, factory))


def start_run(
    registry: RunRegistry, backend: ChatBackend, factory: sessionmaker[Session], run: ChatRun
) -> None:
    """작업을 등록하고 시작한다. 같은 세션에 이미 진행 중인 작업이 있으면 SESSION_BUSY."""
    registry.add(run)
    launch_run(registry, backend, factory, run)


async def stream_events(run: ChatRun, first_events: list[str]) -> AsyncIterator[str]:
    """작업이 내보내는 이벤트를 SSE로 흘려보낸다. 응답이 끊겨도 작업은 계속된다."""
    try:
        for event in first_events:
            yield event
        while True:
            try:
                item: str | None = await asyncio.wait_for(run.events.get(), timeout=KEEPALIVE_SECONDS)
            except TimeoutError:
                yield KEEPALIVE
                continue
            if item is None:
                return
            yield item
    finally:
        run.reader_attached = False
