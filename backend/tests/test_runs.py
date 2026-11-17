import asyncio
import uuid
from contextlib import suppress

import pytest
from sqlalchemy import select
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session, sessionmaker

from app.models import Account, Answer, AnswerStatus, Question
from app.runs import ChatRun, RunRegistry, start_run
from tests.factories import AccountFactory
from tests.fakes import HANG, FakeHermes

pytestmark = pytest.mark.integration


@pytest.fixture
def anyio_backend() -> str:
    return "asyncio"


def new_run(owner: Account, text: str = "질문") -> ChatRun:
    return ChatRun(owner.id, uuid.uuid4(), True, text, [{"role": "user", "content": text}])


async def wait_for_text(run: ChatRun) -> None:
    for _ in range(200):
        if run.parts:
            return
        await asyncio.sleep(0.01)
    raise AssertionError("답변 조각이 오지 않았다")


def stored_answers(engine: Engine, owner: Account) -> list[tuple[str, AnswerStatus]]:
    with sessionmaker(engine)() as db:
        rows = db.execute(
            select(Answer.text, Answer.status)
            .join(Question, Question.id == Answer.question_id)
            .where(Question.session_id.in_(select(Question.session_id)))
        ).all()
        return [(row[0], row[1]) for row in rows]


def last_event(run: ChatRun) -> str | None:
    items: list[str | None] = []
    while not run.events.empty():
        items.append(run.events.get_nowait())
    return items[-1] if items else "비어 있음"


@pytest.mark.anyio
async def test_shutdown_stops_running_answers_saves_the_received_part_and_ends_the_stream(
    account_factory: AccountFactory, migrated_engine: Engine
) -> None:
    owner: Account = account_factory.create()
    registry: RunRegistry = RunRegistry()
    run: ChatRun = new_run(owner)
    factory: sessionmaker[Session] = sessionmaker(migrated_engine, expire_on_commit=False)
    start_run(registry, FakeHermes(["받은 부분", HANG]), factory, run)
    await run.started
    await wait_for_text(run)
    await registry.shutdown(timeout=5)
    assert registry.active_count() == 0
    assert ("받은 부분", AnswerStatus.STOPPED) in stored_answers(migrated_engine, owner)
    assert last_event(run) is None  # 읽는 쪽이 끝없이 기다리지 않도록 스트림이 닫혔다


@pytest.mark.anyio
async def test_a_cancelled_supervisor_still_ends_the_stream_and_leaves_the_registry(
    account_factory: AccountFactory, migrated_engine: Engine
) -> None:
    owner: Account = account_factory.create()
    registry: RunRegistry = RunRegistry()
    run: ChatRun = new_run(owner)
    fake: FakeHermes = FakeHermes(["진행", HANG])
    factory: sessionmaker[Session] = sessionmaker(migrated_engine, expire_on_commit=False)
    start_run(registry, fake, factory, run)
    await run.started
    await wait_for_text(run)
    assert run.task is not None
    run.task.cancel()  # 이벤트 루프가 끝나면서 작업이 취소되는 경우
    with suppress(asyncio.CancelledError):
        await run.task
    await asyncio.sleep(0.05)
    assert registry.active_count() == 0
    assert last_event(run) is None
    assert fake.cancelled is True  # Hermes를 읽던 작업도 함께 취소되어 연결이 닫혔다
