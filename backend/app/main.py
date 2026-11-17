from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

import logging

from fastapi import FastAPI
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session, sessionmaker
from starlette.concurrency import run_in_threadpool

from app.accounts import create_initial_admin
from app.auth import router as auth_router
from app.config import Settings, get_settings
from app.db import create_db_engine, create_session_factory
from app.errors import register_error_handlers
from app.hermes import ChatBackend, HermesError, create_hermes_client
from app.runs import RunRegistry
from app.sessions import router as sessions_router
from app.tokens import require_jwt_secret


logger: logging.Logger = logging.getLogger(__name__)


def hermes_backend(settings: Settings) -> ChatBackend | None:
    """Hermes 키가 없으면 None(다른 기능은 쓸 수 있고, 질문 전송만 서버 오류가 난다)."""
    try:
        return create_hermes_client(settings)
    except HermesError as error:
        logger.warning("%s 질문 전송은 동작하지 않는다.", error)
        return None


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    """앱이 시작할 때 DB 엔진을 하나 만들어 공유하고, 첫 관리자 계정을 만든다."""
    settings: Settings = get_settings()
    app.state.token_secret = require_jwt_secret(settings.jwt_secret)  # 없으면 시작하지 않는다
    engine: Engine = create_db_engine(settings)
    session_factory: sessionmaker[Session] = create_session_factory(engine)
    app.state.engine = engine
    app.state.session_factory = session_factory
    app.state.runs = RunRegistry()
    app.state.hermes = hermes_backend(settings)
    try:
        # DB 조회와 argon2 해시는 이벤트 루프를 막으므로 스레드에서 실행한다.
        await run_in_threadpool(create_initial_admin, session_factory, settings)
        yield
    finally:
        await app.state.runs.shutdown(timeout=5)  # 진행 중인 답변은 받은 부분까지 저장한다
        engine.dispose()


def create_app() -> FastAPI:
    app: FastAPI = FastAPI(title="Iris", lifespan=lifespan)
    register_error_handlers(app)
    app.include_router(auth_router)
    app.include_router(sessions_router)
    return app


app: FastAPI = create_app()
