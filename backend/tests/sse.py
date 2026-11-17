import json
from collections.abc import Iterator
from typing import Any

import httpx

Event = tuple[str, dict[str, Any]]


def iter_events(response: httpx.Response) -> Iterator[Event]:
    """SSE 응답을 (이벤트 이름, 데이터)로 하나씩 읽는다. `:`로 시작하는 주석 줄(keepalive)은 건너뛴다."""
    name: str = ""
    for line in response.iter_lines():
        if line.startswith(":") or not line:
            continue
        if line.startswith("event:"):
            name = line.removeprefix("event:").strip()
        elif line.startswith("data:"):
            yield name, json.loads(line.removeprefix("data:").strip())


def read_events(response: httpx.Response) -> list[Event]:
    return list(iter_events(response))


def names(events: list[Event]) -> list[str]:
    return [name for name, _ in events]
