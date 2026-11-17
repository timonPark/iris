from functools import lru_cache
from pathlib import Path

from pydantic import SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict
from sqlalchemy.engine import URL


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

    # 첫 관리자 계정. 둘 다 설정하면 앱을 처음 시작할 때 이 계정을 만든다(이미 있으면 만들지 않는다).
    admin_login_id: str | None = None
    admin_password: SecretStr | None = None

    # Hermes API 서버. 키는 백엔드만 보관하고 클라이언트에 노출하지 않는다.
    hermes_api_url: str = "http://127.0.0.1:8642"
    hermes_api_key: SecretStr | None = None

    @property
    def database_url(self) -> str:
        url: URL = URL.create(
            "postgresql+psycopg",
            username=self.postgres_user,
            password=self.postgres_password.get_secret_value(),
            host=self.postgres_host,
            port=self.postgres_port,
            database=self.postgres_db,
        )
        return url.render_as_string(hide_password=False)


@lru_cache
def get_settings() -> Settings:
    return Settings()
