import os
from collections.abc import Iterator
from pathlib import Path

import pytest

# 테스트는 개발 DB(iris)가 아니라 별도 DB에서 돌린다. 환경 변수가 .env보다 우선하므로
# 설정(app.config)을 처음 읽기 전에 정해 둔다.
TEST_DATABASE_NAME: str = "iris_test"
os.environ["POSTGRES_DB"] = TEST_DATABASE_NAME
# 토큰 서명 키도 테스트 전용 값을 쓴다(실제 키는 backend/.env 에만 있다).
TEST_JWT_SECRET: str = "test-only-secret-never-used-outside-pytest-0123456789"
os.environ["JWT_SECRET"] = TEST_JWT_SECRET

from alembic import command  # noqa: E402
from alembic.config import Config  # noqa: E402
from fastapi import APIRouter, Depends, FastAPI  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402
from sqlalchemy import create_engine, text  # noqa: E402
from sqlalchemy.engine import Connection, Engine, RootTransaction, make_url  # noqa: E402
from sqlalchemy.orm import Session  # noqa: E402

from app.auth import current_account, current_account_for_password_change  # noqa: E402
from app.config import get_settings  # noqa: E402
from app.db import create_db_engine  # noqa: E402
from app.main import create_app  # noqa: E402
from app.models import Account  # noqa: E402
from tests.factories import AccountFactory  # noqa: E402

BACKEND_DIR: Path = Path(__file__).resolve().parents[1]


@pytest.fixture(scope="session")
def ensure_test_database() -> None:
    """테스트 DB가 없으면 만든다. 서버의 기본 DB(postgres)에 접속해서 만든다."""
    server_url: str = make_url(get_settings().database_url).set(database="postgres").render_as_string(
        hide_password=False
    )
    server_engine: Engine = create_engine(server_url, isolation_level="AUTOCOMMIT")
    with server_engine.connect() as connection:
        exists: bool = (
            connection.execute(
                text("SELECT 1 FROM pg_database WHERE datname = :name"), {"name": TEST_DATABASE_NAME}
            ).scalar()
            is not None
        )
        if not exists:
            connection.execute(text(f'CREATE DATABASE "{TEST_DATABASE_NAME}"'))
    server_engine.dispose()


@pytest.fixture(scope="session")
def migrated_engine(ensure_test_database: None) -> Iterator[Engine]:
    """마이그레이션을 최신으로 적용한 테스트 DB 엔진."""
    config: Config = Config(str(BACKEND_DIR / "alembic.ini"))
    config.set_main_option("script_location", str(BACKEND_DIR / "migrations"))
    command.upgrade(config, "head")
    engine: Engine = create_db_engine(get_settings())
    yield engine
    engine.dispose()


@pytest.fixture
def db_session(migrated_engine: Engine) -> Iterator[Session]:
    """테스트가 끝나면 모든 변경을 되돌리는 세션."""
    connection: Connection = migrated_engine.connect()
    transaction: RootTransaction = connection.begin()
    session: Session = Session(bind=connection, join_transaction_mode="create_savepoint")
    yield session
    session.close()
    transaction.rollback()
    connection.close()


def install_test_routes(app: FastAPI) -> None:
    """요청마다 하는 검사를 확인하기 위한 테스트 전용 경로. 제품 엔드포인트가 아니다."""
    router: APIRouter = APIRouter(prefix="/_test")

    @router.get("/protected")
    def protected(account: Account = Depends(current_account)) -> dict[str, str]:
        return {"loginId": account.login_id}

    @router.post("/password-change")
    def password_change(
        account: Account = Depends(current_account_for_password_change),
    ) -> dict[str, str]:
        return {"loginId": account.login_id}

    @router.get("/boom")
    def boom() -> None:
        raise RuntimeError("boom")

    app.include_router(router)


@pytest.fixture
def app_client(monkeypatch: pytest.MonkeyPatch, migrated_engine: Engine) -> Iterator[TestClient]:
    """앱 시작(lifespan)까지 실행하는 클라이언트. 실제 관리자 설정은 쓰지 않는다."""
    for name in ("ADMIN_LOGIN_ID", "ADMIN_PASSWORD"):
        monkeypatch.delenv(name, raising=False)
    get_settings.cache_clear()
    app: FastAPI = create_app()
    install_test_routes(app)
    with TestClient(app, raise_server_exceptions=False) as client:
        yield client
    get_settings.cache_clear()


@pytest.fixture
def account_factory(migrated_engine: Engine) -> Iterator[AccountFactory]:
    factory: AccountFactory = AccountFactory(migrated_engine)
    yield factory
    factory.delete_all()
