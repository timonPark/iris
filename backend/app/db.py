from sqlalchemy import create_engine
from sqlalchemy.engine import Engine
from sqlalchemy.orm import DeclarativeBase

from app.config import Settings


class Base(DeclarativeBase):
    """모든 테이블 모델의 부모. Alembic이 이 metadata를 기준으로 변경을 만든다."""


def create_db_engine(settings: Settings) -> Engine:
    return create_engine(settings.database_url, pool_pre_ping=True)
