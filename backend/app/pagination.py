import base64
import json
import uuid
from datetime import UTC, datetime
from typing import Any, TypeVar

from sqlalchemy import Select, tuple_
from sqlalchemy.orm import InstrumentedAttribute, Session

from app.errors import ApiError, validation_failed

T = TypeVar("T")


def encode_cursor(moment: datetime, item_id: uuid.UUID, scope: str) -> str:
    """마지막으로 내려준 항목의 위치(시각, id)와 어느 목록의 커서인지(scope)를 담은 문자열.

    클라이언트는 이 값을 해석하지 않고 그대로 돌려보낸다.
    """
    payload: str = json.dumps(
        {"t": moment.isoformat(), "id": str(item_id), "s": scope}, separators=(",", ":")
    )
    return base64.urlsafe_b64encode(payload.encode()).decode().rstrip("=")


def decode_cursor(value: str, scope: str) -> tuple[datetime, uuid.UUID]:
    """커서를 푼다. 형식이 틀리거나 다른 목록의 커서이거나 시각이 범위를 벗어나면 422."""
    try:
        padded: str = value + "=" * (-len(value) % 4)
        data: dict[str, str] = json.loads(base64.urlsafe_b64decode(padded))
        if data["s"] != scope:
            raise ValueError("다른 목록의 커서")
        moment: datetime = datetime.fromisoformat(data["t"])
        if moment.tzinfo is None:
            raise ValueError("시간대가 없는 시각")
        # UTC로 바꿀 때 표현 범위를 넘는 시각은 OverflowError가 난다(DB에 보내기 전에 걸러낸다).
        return moment.astimezone(UTC), uuid.UUID(data["id"])
    except (ValueError, KeyError, TypeError, OverflowError) as error:
        raise validation_failed("올바르지 않은 cursor입니다.") from error


def keyset_page(
    db: Session,
    query: Select[tuple[T]],
    moment_column: InstrumentedAttribute[datetime],
    id_column: InstrumentedAttribute[uuid.UUID],
    *,
    cursor: str | None,
    limit: int,
    scope: str,
) -> tuple[list[T], str | None]:
    """(시각, id) 내림차순으로 나눠서 읽는다. 커서는 마지막 항목의 위치이고 다음 페이지가 있을 때만 준다.

    같은 시각의 항목도 id로 순서가 정해져서 한 번씩만 나온다.
    """
    if cursor is not None:
        moment, item_id = decode_cursor(cursor, scope)
        query = query.where(tuple_(moment_column, id_column) < tuple_(moment, item_id))
    rows: list[T] = list(
        db.scalars(query.order_by(moment_column.desc(), id_column.desc()).limit(limit + 1))
    )
    page: list[T] = rows[:limit]
    if len(rows) <= limit:
        return page, None
    last: Any = page[-1]
    return page, encode_cursor(getattr(last, moment_column.key), getattr(last, id_column.key), scope)
