import uuid
from datetime import datetime

from fastapi import APIRouter, Depends, Query, Response
from sqlalchemy.orm import Session

from app.accounts import (
    create_user,
    list_users,
    reset_user_password,
    set_user_blocked,
)
from app.auth import current_account, get_session
from app.errors import forbidden, user_not_found
from app.models import Account, AccountStatus, Role
from app.schemas import ApiModel


def require_admin(account: Account = Depends(current_account)) -> Account:
    """관리자 역할만 통과시킨다. 역할은 요청마다 DB에서 읽으므로 권한이 회수되면 바로 막힌다."""
    if account.role != Role.ADMIN:
        raise forbidden()
    return account


# 권한 검사를 라우터 전체에 걸어서, 이 경로 아래에 새로 만드는 API가 검사를 빠뜨릴 수 없다.
router: APIRouter = APIRouter(
    prefix="/api/v1/admin", tags=["admin"], dependencies=[Depends(require_admin)]
)


class UserOut(ApiModel):
    id: uuid.UUID
    login_id: str
    status: AccountStatus
    password_change_required: bool
    created_at: datetime


class UserPage(ApiModel):
    items: list[UserOut]
    next_cursor: str | None = None


class CreateUserRequest(ApiModel):
    login_id: str


class UserWithTemporaryPassword(ApiModel):
    user: UserOut
    temporary_password: str


def to_user_out(account: Account) -> UserOut:
    return UserOut(
        id=account.id,
        login_id=account.login_id,
        status=account.status,
        password_change_required=account.password_change_required,
        created_at=account.created_at,
    )


def parse_user_id(value: str) -> uuid.UUID:
    """UUID가 아닌 값은 있을 수 없는 계정이므로 없는 계정(404)으로 처리한다."""
    try:
        parsed: uuid.UUID = uuid.UUID(value)
    except ValueError as error:
        raise user_not_found() from error
    if str(parsed) != value.lower():  # 중괄호, urn:, 하이픈 없는 표기 등은 같은 id로 취급하지 않는다
        raise user_not_found()
    return parsed


def no_store(response: Response) -> None:
    """임시 비밀번호가 든 응답은 브라우저나 프록시가 저장하지 않게 한다."""
    response.headers["Cache-Control"] = "no-store"


@router.get("/users", response_model=UserPage, response_model_exclude_none=True)
def get_users(
    db: Session = Depends(get_session),
    cursor: str | None = Query(default=None),
    limit: int = Query(default=20, ge=1, le=100),
) -> UserPage:
    users: list[Account]
    next_cursor: str | None
    users, next_cursor = list_users(db, cursor=cursor, limit=limit)
    return UserPage(items=[to_user_out(user) for user in users], next_cursor=next_cursor)


@router.post("/users", response_model=UserWithTemporaryPassword, status_code=201)
def post_user(
    body: CreateUserRequest, response: Response, db: Session = Depends(get_session)
) -> UserWithTemporaryPassword:
    account: Account
    temporary: str
    account, temporary = create_user(db, body.login_id)
    db.commit()
    no_store(response)
    return UserWithTemporaryPassword(user=to_user_out(account), temporary_password=temporary)


@router.post("/users/{user_id}/block", response_model=UserOut)
def block_user(user_id: str, db: Session = Depends(get_session)) -> UserOut:
    user: Account = set_user_blocked(db, parse_user_id(user_id), blocked=True)
    db.commit()
    return to_user_out(user)


@router.post("/users/{user_id}/unblock", response_model=UserOut)
def unblock_user(user_id: str, db: Session = Depends(get_session)) -> UserOut:
    user: Account = set_user_blocked(db, parse_user_id(user_id), blocked=False)
    db.commit()
    return to_user_out(user)


@router.post("/users/{user_id}/password-reset", response_model=UserWithTemporaryPassword)
def reset_password(
    user_id: str, response: Response, db: Session = Depends(get_session)
) -> UserWithTemporaryPassword:
    user: Account
    temporary: str
    user, temporary = reset_user_password(db, parse_user_id(user_id))
    db.commit()
    no_store(response)
    return UserWithTemporaryPassword(user=to_user_out(user), temporary_password=temporary)
