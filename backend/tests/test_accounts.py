import logging
import uuid
from collections.abc import Iterator

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import delete, select
from sqlalchemy.engine import Engine
from sqlalchemy.exc import DataError, IntegrityError
from sqlalchemy.orm import Session, sessionmaker

from app.accounts import create_initial_admin, ensure_initial_admin
from app.config import Settings, get_settings
from app.main import create_app
from app.models import Account, AccountStatus, Role
from app.security import verify_password


def unique_login_id() -> str:
    return "t" + uuid.uuid4().hex[:10]


@pytest.mark.integration
def test_new_account_gets_defaults(db_session: Session) -> None:
    account: Account = Account(login_id=unique_login_id(), password_hash="hash", role=Role.USER)
    db_session.add(account)
    db_session.flush()
    assert account.id is not None
    assert account.status == AccountStatus.ACTIVE
    assert account.password_change_required is False
    assert account.password_changed_at is not None
    assert account.created_at is not None


@pytest.mark.integration
def test_login_id_must_be_unique(db_session: Session) -> None:
    login_id: str = unique_login_id()
    db_session.add(Account(login_id=login_id, password_hash="h", role=Role.USER))
    db_session.flush()
    db_session.add(Account(login_id=login_id, password_hash="h", role=Role.USER))
    with pytest.raises(IntegrityError):
        db_session.flush()


@pytest.mark.integration
@pytest.mark.parametrize("bad_login_id", ["abc", "ABCD1234", "ab_cd123", "a" * 21])
def test_database_rejects_login_ids_that_break_the_rule(
    db_session: Session, bad_login_id: str
) -> None:
    db_session.add(Account(login_id=bad_login_id, password_hash="h", role=Role.USER))
    # 형식이 틀리면 CHECK 제약(IntegrityError), 20자를 넘으면 열 길이 제한(DataError)이 막는다.
    with pytest.raises((IntegrityError, DataError)):
        db_session.flush()


@pytest.mark.integration
def test_ensure_initial_admin_creates_an_admin_once(db_session: Session) -> None:
    login_id: str = unique_login_id()
    assert ensure_initial_admin(db_session, login_id, "admin-password") is True
    admin: Account = db_session.scalars(select(Account).where(Account.login_id == login_id)).one()
    assert admin.role == Role.ADMIN
    assert admin.status == AccountStatus.ACTIVE
    assert admin.password_change_required is False
    assert verify_password("admin-password", admin.password_hash) is True
    assert ensure_initial_admin(db_session, login_id, "another-password") is False
    count: int = len(db_session.scalars(select(Account).where(Account.login_id == login_id)).all())
    assert count == 1


@pytest.mark.integration
def test_ensure_initial_admin_refuses_an_id_already_used_by_a_user(db_session: Session) -> None:
    login_id: str = unique_login_id()
    db_session.add(Account(login_id=login_id, password_hash="h", role=Role.USER))
    db_session.flush()
    with pytest.raises(ValueError, match="사용자"):
        ensure_initial_admin(db_session, login_id, "admin-password")


@pytest.mark.integration
def test_ensure_initial_admin_warns_when_the_env_password_differs(
    db_session: Session, caplog: pytest.LogCaptureFixture
) -> None:
    login_id: str = unique_login_id()
    ensure_initial_admin(db_session, login_id, "admin-password")
    with caplog.at_level(logging.WARNING, logger="app.accounts"):
        assert ensure_initial_admin(db_session, login_id, "different-password") is False
    assert "비밀번호" in caplog.text
    assert "different-password" not in caplog.text


@pytest.mark.integration
def test_ensure_initial_admin_warns_when_the_existing_admin_is_blocked(
    db_session: Session, caplog: pytest.LogCaptureFixture
) -> None:
    login_id: str = unique_login_id()
    ensure_initial_admin(db_session, login_id, "admin-password")
    admin: Account = db_session.scalars(select(Account).where(Account.login_id == login_id)).one()
    admin.status = AccountStatus.BLOCKED
    db_session.flush()
    with caplog.at_level(logging.WARNING, logger="app.accounts"):
        assert ensure_initial_admin(db_session, login_id, "admin-password") is False
    assert "차단" in caplog.text


@pytest.mark.integration
def test_ensure_initial_admin_treats_a_concurrent_insert_as_already_existing(
    db_session: Session, monkeypatch: pytest.MonkeyPatch
) -> None:
    login_id: str = unique_login_id()
    ensure_initial_admin(db_session, login_id, "admin-password")
    # 다른 프로세스가 그 사이에 먼저 만든 상황: 조회는 못 찾았는데 저장하려니 이미 있다.
    monkeypatch.setattr("app.accounts.find_account", lambda session, value: None)
    assert ensure_initial_admin(db_session, login_id, "admin-password") is False


@pytest.mark.integration
@pytest.mark.parametrize(
    ("login_id", "password"), [("ABC", "admin-password"), ("admin1", "short")]
)
def test_ensure_initial_admin_rejects_values_that_break_the_rules(
    db_session: Session, login_id: str, password: str
) -> None:
    with pytest.raises(ValueError):
        ensure_initial_admin(db_session, login_id, password)
    assert db_session.scalars(select(Account).where(Account.login_id == login_id)).first() is None


def make_settings(**overrides: str) -> Settings:
    values: dict[str, str] = {
        "postgres_user": "iris",
        "postgres_password": "pw",
        "postgres_db": "irisdb",
    }
    values.update(overrides)
    return Settings(_env_file=None, **values)


def test_create_initial_admin_skips_when_nothing_is_configured(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    for name in ("ADMIN_LOGIN_ID", "ADMIN_PASSWORD"):
        monkeypatch.delenv(name, raising=False)
    assert create_initial_admin(sessionmaker(), make_settings()) is False


@pytest.mark.parametrize("only", [{"admin_login_id": "admin1"}, {"admin_password": "admin-password"}])
def test_create_initial_admin_requires_both_settings(
    monkeypatch: pytest.MonkeyPatch, only: dict[str, str]
) -> None:
    for name in ("ADMIN_LOGIN_ID", "ADMIN_PASSWORD"):
        monkeypatch.delenv(name, raising=False)
    with pytest.raises(ValueError, match="함께"):
        create_initial_admin(sessionmaker(), make_settings(**only))


@pytest.fixture
def cleanup_admin(migrated_engine: Engine) -> Iterator[list[str]]:
    login_ids: list[str] = []
    yield login_ids
    with sessionmaker(migrated_engine).begin() as session:
        session.execute(delete(Account).where(Account.login_id.in_(login_ids)))
    get_settings.cache_clear()


@pytest.mark.integration
def test_app_startup_creates_the_admin_from_the_environment(
    monkeypatch: pytest.MonkeyPatch, migrated_engine: Engine, cleanup_admin: list[str]
) -> None:
    login_id: str = unique_login_id()
    cleanup_admin.append(login_id)
    monkeypatch.setenv("ADMIN_LOGIN_ID", login_id)
    monkeypatch.setenv("ADMIN_PASSWORD", "startup-password")
    get_settings.cache_clear()
    with TestClient(create_app()):
        pass
    with sessionmaker(migrated_engine)() as session:
        admin: Account = session.scalars(select(Account).where(Account.login_id == login_id)).one()
    assert admin.role == Role.ADMIN
    assert verify_password("startup-password", admin.password_hash) is True
