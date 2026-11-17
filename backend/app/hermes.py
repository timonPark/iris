import json
from collections.abc import AsyncIterator
from contextlib import AbstractAsyncContextManager, asynccontextmanager
from typing import Any, Protocol

import httpx

from app.config import Settings

# Hermes는 긴 작업 중에도 10초마다 keepalive를 보내므로, 60초 동안 아무것도 오지 않으면 멈춘 것으로 본다.
TIMEOUT: httpx.Timeout = httpx.Timeout(10.0, read=60.0)


class HermesError(Exception):
    """Hermes 호출이 실패했다(연결 실패, 인증 실패, 오류 응답, 끝나지 않고 끊긴 스트림)."""


def parse_delta(data: str) -> str | None:
    """SSE `data:` 한 줄에서 답변 조각을 꺼낸다. 조각이 없으면 None."""
    try:
        payload: dict[str, Any] = json.loads(data)
        if "error" in payload:
            raise HermesError(f"Hermes 오류: {payload['error']}")
        choices: list[dict[str, Any]] = payload.get("choices") or []
        return choices[0].get("delta", {}).get("content") or None if choices else None
    except (json.JSONDecodeError, AttributeError, TypeError, IndexError) as error:
        raise HermesError(f"Hermes가 올바르지 않은 데이터를 보냈다: {data[:100]}") from error


class ChatBackend(Protocol):
    """질문을 보내고 답변 조각을 스트리밍으로 받는 쪽. 실제로는 HermesClient이고 테스트에서는 가짜를 쓴다."""

    def open_chat(
        self, messages: list[dict[str, str]]
    ) -> AbstractAsyncContextManager[AsyncIterator[str]]: ...


class HermesClient:
    """Hermes API 서버의 `/v1/chat/completions`를 스트리밍으로 호출한다."""

    def __init__(
        self, base_url: str, api_key: str, transport: httpx.AsyncBaseTransport | None = None
    ) -> None:
        self._base_url: str = base_url
        self._api_key: str = api_key
        self._transport: httpx.AsyncBaseTransport | None = transport

    @asynccontextmanager
    async def open_chat(self, messages: list[dict[str, str]]) -> AsyncIterator[AsyncIterator[str]]:
        """연결을 열고 응답 상태를 확인한 뒤에 답변 조각의 스트림을 준다.

        Hermes가 꺼져 있거나 요청을 거부하면 `async with`에 들어갈 때 HermesError가 난다(스트림은 시작되지 않는다).
        `async with`를 벗어나면 연결을 닫고, 연결이 닫히면 Hermes도 실행을 멈춘다(#10에서 확인).
        """
        payload: dict[str, object] = {"model": "hermes-agent", "messages": messages, "stream": True}
        headers: dict[str, str] = {"Authorization": f"Bearer {self._api_key}"}
        try:
            async with httpx.AsyncClient(
                base_url=self._base_url, transport=self._transport, timeout=TIMEOUT
            ) as client:
                async with client.stream(
                    "POST", "/v1/chat/completions", json=payload, headers=headers
                ) as response:
                    if response.is_error:
                        await response.aread()
                        raise HermesError(f"Hermes가 {response.status_code} 응답: {response.text[:200]}")
                    yield self._guarded(response)
        except httpx.HTTPError as error:
            raise HermesError(f"Hermes 호출 실패: {error}") from error

    async def stream_chat(self, messages: list[dict[str, str]]) -> AsyncIterator[str]:
        async with self.open_chat(messages) as stream:
            async for text in stream:
                yield text

    async def _guarded(self, response: httpx.Response) -> AsyncIterator[str]:
        """스트림을 읽는 도중 연결이 끊기면 HermesError로 바꿔서 전한다."""
        try:
            async for text in self._deltas(response):
                yield text
        except httpx.HTTPError as error:
            raise HermesError(f"Hermes 응답을 받는 중 연결이 끊겼다: {error}") from error

    @staticmethod
    async def _deltas(response: httpx.Response) -> AsyncIterator[str]:
        skip_data: bool = False
        async for line in response.aiter_lines():
            if line.startswith("event:"):
                # `hermes.tool.progress` 같은 Hermes 전용 이벤트는 답변이 아니다.
                skip_data = line.removeprefix("event:").strip().startswith("hermes.")
            elif line.startswith("data:") and not skip_data:
                data: str = line.removeprefix("data:").strip()
                if data == "[DONE]":
                    return
                text: str | None = parse_delta(data)
                if text is not None:
                    yield text
            elif line == "":
                skip_data = False
        # [DONE] 없이 끝났다: Hermes 재시작 등으로 답변이 중간에 잘렸다.
        raise HermesError("Hermes 응답이 끝나기 전에 연결이 닫혔다")


def create_hermes_client(settings: Settings) -> HermesClient:
    if settings.hermes_api_key is None:
        raise HermesError("HERMES_API_KEY가 설정되지 않았다. backend/.env를 확인하세요.")
    return HermesClient(settings.hermes_api_url, settings.hermes_api_key.get_secret_value())
