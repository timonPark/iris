from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session, sessionmaker
from starlette.concurrency import run_in_threadpool

from app.accounts import create_initial_admin
from app.config import Settings, get_settings
from app.db import create_db_engine, create_session_factory


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    """앱이 시작할 때 DB 엔진을 하나 만들어 공유하고, 첫 관리자 계정을 만든다."""
    settings: Settings = get_settings()
    engine: Engine = create_db_engine(settings)
    session_factory: sessionmaker[Session] = create_session_factory(engine)
    app.state.engine = engine
    app.state.session_factory = session_factory
    try:
        # DB 조회와 argon2 해시는 이벤트 루프를 막으므로 스레드에서 실행한다.
        await run_in_threadpool(create_initial_admin, session_factory, settings)
        yield
    finally:
        engine.dispose()


def create_app() -> FastAPI:
    return FastAPI(title="Iris", lifespan=lifespan)


app: FastAPI = create_app()
