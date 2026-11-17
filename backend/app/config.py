from functools import lru_cache
from pathlib import Path
from urllib.parse import quote

from pydantic import SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """환경 변수(.env)로 읽는 백엔드 설정. 변수 이름은 docker-compose와 같다."""

    # 실행 위치와 상관없이 backend/.env 를 읽도록 파일 위치를 기준으로 잡는다.
    model_config = SettingsConfigDict(
        env_file=Path(__file__).resolve().parents[1] / ".env", extra="ignore"
    )

    postgres_user: str
    postgres_password: SecretStr
    postgres_db: str
    postgres_host: str = "127.0.0.1"
    # 이 PC의 다른 PostgreSQL(n8n 등)과 겹치지 않도록 5433을 기본으로 쓴다.
    postgres_port: int = 5433

    @property
    def database_url(self) -> str:
        password: str = quote(self.postgres_password.get_secret_value(), safe="")
        return (
            f"postgresql+psycopg://{self.postgres_user}:{password}"
            f"@{self.postgres_host}:{self.postgres_port}/{self.postgres_db}"
        )


@lru_cache
def get_settings() -> Settings:
    return Settings()
