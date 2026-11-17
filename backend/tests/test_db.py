"""PostgreSQL이 떠 있어야 한다: 저장소 루트에서 `docker compose --env-file backend/.env up -d db`."""

import pytest
from sqlalchemy import text
from sqlalchemy.engine import Engine

from app.config import get_settings
from app.db import create_db_engine


@pytest.mark.integration
def test_backend_connects_to_postgres() -> None:
    engine: Engine = create_db_engine(get_settings())
    with engine.connect() as connection:
        assert connection.execute(text("SELECT 1")).scalar_one() == 1
