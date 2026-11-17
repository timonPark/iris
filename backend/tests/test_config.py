import pytest

from app.config import Settings

POSTGRES_ENV_NAMES: tuple[str, ...] = (
    "POSTGRES_USER",
    "POSTGRES_PASSWORD",
    "POSTGRES_DB",
    "POSTGRES_HOST",
    "POSTGRES_PORT",
)


@pytest.fixture(autouse=True)
def clean_postgres_env(monkeypatch: pytest.MonkeyPatch) -> None:
    """셸이나 CI에 설정된 값이 테스트 결과에 영향을 주지 않게 한다."""
    for name in POSTGRES_ENV_NAMES:
        monkeypatch.delenv(name, raising=False)


def make_settings(**overrides: str) -> Settings:
    values: dict[str, str] = {
        "postgres_user": "iris",
        "postgres_password": "pw",
        "postgres_db": "irisdb",
        "postgres_host": "127.0.0.1",
        "postgres_port": "5433",
    }
    values.update(overrides)
    return Settings(_env_file=None, **values)


def test_database_url_is_built_from_parts() -> None:
    settings: Settings = make_settings()
    assert settings.database_url == "postgresql+psycopg://iris:pw@127.0.0.1:5433/irisdb"


def test_database_url_escapes_special_characters_in_password() -> None:
    settings: Settings = make_settings(postgres_password="p@ss/w:rd")
    assert "p%40ss%2Fw%3Ard" in settings.database_url


def test_missing_password_is_rejected() -> None:
    with pytest.raises(ValueError):
        Settings(_env_file=None, postgres_user="iris", postgres_db="irisdb")


def test_default_port_does_not_collide_with_other_postgres() -> None:
    settings: Settings = Settings(
        _env_file=None, postgres_user="iris", postgres_password="pw", postgres_db="irisdb"
    )
    assert settings.postgres_port == 5433
