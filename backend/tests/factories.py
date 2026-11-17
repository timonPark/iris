import uuid
from datetime import datetime

from sqlalchemy import delete, select
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session, sessionmaker

from app.chat import delete_session, save_exchange
from app.models import Account, AccountStatus, AnswerStatus, ChatSession, Question, Role
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
            # 앱이 HTTP로 만든 대화 기록(세션, 질문, 답변)도 계정보다 먼저 지운다. 질문과 답변은 DB의 CASCADE로 함께 지워진다.
            owners = select(Account.id).where(Account.login_id.in_(self.login_ids))
            session.execute(delete(ChatSession).where(ChatSession.account_id.in_(owners)))
            session.execute(delete(Account).where(Account.login_id.in_(self.login_ids)))


class ChatFactory:
    """대화 기록을 저장(commit)해서 앱이 다른 연결로 읽게 하는 생성기. 지우는 일은 account_factory와 함께 한다."""

    def __init__(self, engine: Engine) -> None:
        self._factory: sessionmaker[Session] = sessionmaker(engine, expire_on_commit=False)
        self._login_ids: list[str] = []

    def exchange(
        self,
        account: Account,
        question: str,
        answer: str = "답변",
        *,
        session_id: uuid.UUID | None = None,
        status: AnswerStatus = AnswerStatus.COMPLETED,
        at: datetime | None = None,
    ) -> Question:
        """질문과 답변 한 쌍을 저장한다. session_id가 없으면 새 세션이 만들어진다."""
        self._login_ids.append(account.login_id)
        with self._factory.begin() as db:
            return save_exchange(
                db, account.id, session_id=session_id, question_text=question,
                answer_text=answer, status=status, now=at,
            )

    def soft_delete(self, account: Account, session_id: uuid.UUID) -> None:
        with self._factory.begin() as db:
            delete_session(db, account.id, session_id)

    def delete_all(self) -> None:
        with self._factory.begin() as db:
            owners = select(Account.id).where(Account.login_id.in_(self._login_ids))
            # 질문과 답변은 DB의 ON DELETE CASCADE로 함께 지워진다.
            db.execute(delete(ChatSession).where(ChatSession.account_id.in_(owners)))
