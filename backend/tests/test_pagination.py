import base64
import json
import uuid
from datetime import UTC, datetime

import pytest

from app.errors import ApiError, ErrorCode
from app.pagination import decode_cursor, encode_cursor


def test_cursor_round_trips_the_position_with_microsecond_precision() -> None:
    moment: datetime = datetime(2026, 11, 17, 9, 30, 15, 123456, tzinfo=UTC)
    item_id: uuid.UUID = uuid.uuid4()
    assert decode_cursor(encode_cursor(moment, item_id, "sessions"), "sessions") == (moment, item_id)


def test_cursor_is_an_opaque_url_safe_string() -> None:
    cursor: str = encode_cursor(datetime(2026, 11, 17, tzinfo=UTC), uuid.uuid4(), "sessions")
    assert cursor.isascii()
    assert not any(char in cursor for char in " +/?&=\n")


def b64(payload: object) -> str:
    return base64.urlsafe_b64encode(json.dumps(payload).encode()).decode().rstrip("=")


@pytest.mark.parametrize(
    "garbage",
    [
        "",
        "not-a-cursor",
        "####",
        b64("just a string"),
        b64({"t": "2026-11-17T00:00:00+00:00", "s": "sessions"}),
        b64({"id": str(uuid.uuid4()), "s": "sessions"}),
        b64({"t": "yesterday", "id": str(uuid.uuid4()), "s": "sessions"}),
        b64({"t": "2026-11-17T00:00:00+00:00", "id": "not-a-uuid", "s": "sessions"}),
        b64({"t": "2026-11-17T00:00:00", "id": str(uuid.uuid4()), "s": "sessions"}),
        b64({"t": 123, "id": str(uuid.uuid4()), "s": "sessions"}),
        b64({"t": "2026-11-17T00:00:00+00:00", "id": str(uuid.uuid4())}),  # 범위(s) 없음
    ],
)
def test_bad_cursor_is_a_validation_error(garbage: str) -> None:
    with pytest.raises(ApiError) as info:
        decode_cursor(garbage, "sessions")
    assert (info.value.status_code, info.value.code) == (422, ErrorCode.VALIDATION_FAILED)


def test_cursor_made_for_another_list_is_rejected() -> None:
    cursor: str = encode_cursor(datetime(2026, 11, 17, tzinfo=UTC), uuid.uuid4(), "sessions")
    with pytest.raises(ApiError) as info:
        decode_cursor(cursor, f"questions:{uuid.uuid4()}")
    assert (info.value.status_code, info.value.code) == (422, ErrorCode.VALIDATION_FAILED)


@pytest.mark.parametrize(
    "moment", ["0001-01-01T00:00:00+14:00", "9999-12-31T23:59:59-14:00", "9999-12-31T23:59:59-00:01"]
)
def test_times_that_overflow_after_conversion_to_utc_are_a_validation_error(moment: str) -> None:
    with pytest.raises(ApiError) as info:
        decode_cursor(b64({"t": moment, "id": str(uuid.uuid4()), "s": "sessions"}), "sessions")
    assert info.value.code == ErrorCode.VALIDATION_FAILED


def test_the_earliest_and_latest_representable_times_are_still_valid() -> None:
    for moment in ("0001-01-01T00:00:00+00:00", "9999-12-31T23:59:59+00:00"):
        decoded, _ = decode_cursor(b64({"t": moment, "id": str(uuid.uuid4()), "s": "sessions"}), "sessions")
        assert decoded.tzinfo is not None
