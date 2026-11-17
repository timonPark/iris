import os
from collections.abc import Iterator
from pathlib import Path

import pytest

# 테스트는 개발 DB(iris)가 아니라 별도 DB에서 돌린다. 환경 변수가 .env보다 우선하므로
# 설정(app.config)을 처음 읽기 전에 정해 둔다.
TEST_DATABASE_NAME: str = "iris_test"
os.environ["POSTGRES_DB"] = TEST_DATABASE_NAME

from alembic import command  # noqa: E402
from alembic.config import Config  # noqa: E402
from sqlalchemy import create_engine, text  # noqa: E402
from sqlalchemy.engine import Connection, Engine, RootTransaction, make_url  # noqa: E402
from sqlalchemy.orm import Session  # noqa: E402

from app.config import get_settings  # noqa: E402
from app.db import create_db_engine  # noqa: E402

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
