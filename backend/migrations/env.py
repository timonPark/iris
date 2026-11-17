from logging.config import fileConfig

from alembic import context
from alembic.config import Config
from sqlalchemy import MetaData
from sqlalchemy.engine import Engine

from app.config import get_settings
from app.db import Base, create_db_engine

config: Config = context.config

if config.config_file_name is not None:
    fileConfig(config.config_file_name, disable_existing_loggers=False)

# 새 테이블 모델을 만들면 app.db 의 Base 를 상속하고, 여기서 import 해서 metadata 에 등록한다.
target_metadata: MetaData = Base.metadata


def run_migrations_offline() -> None:
    context.configure(
        url=get_settings().database_url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    engine: Engine = create_db_engine(get_settings())
    try:
        with engine.connect() as connection:
            context.configure(connection=connection, target_metadata=target_metadata)
            with context.begin_transaction():
                context.run_migrations()
    finally:
        engine.dispose()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
