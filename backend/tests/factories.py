import uuid

from sqlalchemy import delete, select
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session, sessionmaker

from app.models import Account, AccountStatus, Role
from app.security import hash_password


class AccountFactory:
    """앱이 다른 연결로 읽을 수 있게 저장(commit)하는 계정 생성기. 테스트가 끝나면 지운다."""

    def __init__(self, engine: Engine) -> None:
        self._factory: sessionmaker[Session] = sessionmaker(engine, expire_on_commit=False)
        self.login_ids: list[str] = []

    def create(
        self,
        *,
        password: str = "correct-password",
        role: Role = Role.USER,
        status: AccountStatus = AccountStatus.ACTIVE,
        password_change_required: bool = False,
    ) -> Account:
        login_id: str = "t" + uuid.uuid4().hex[:10]
        account: Account = Account(
            login_id=login_id,
            password_hash=hash_password(password),
            role=role,
            status=status,
            password_change_required=password_change_required,
        )
        with self._factory.begin() as session:
            session.add(account)
        self.login_ids.append(login_id)
        return account

    def update(self, login_id: str, **fields: object) -> None:
        with self._factory.begin() as session:
            account: Account = session.scalars(
                select(Account).where(Account.login_id == login_id)
            ).one()
            for name, value in fields.items():
                setattr(account, name, value)

    def delete_all(self) -> None:
        with self._factory.begin() as session:
            session.execute(delete(Account).where(Account.login_id.in_(self.login_ids)))
