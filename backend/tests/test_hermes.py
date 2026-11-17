import json

import httpx
import pytest

from app.config import Settings, get_settings
from app.hermes import HermesClient, HermesError, create_hermes_client


@pytest.fixture
def anyio_backend() -> str:
    return "asyncio"


def sse(*events: str) -> bytes:
    return ("\n\n".join(events) + "\n\n").encode()


def chunk(text: str | None) -> str:
    delta: dict[str, str] = {} if text is None else {"content": text}
    return "data: " + json.dumps({"choices": [{"delta": delta}]}, ensure_ascii=False)


def make_client(handler: httpx.MockTransport) -> HermesClient:
    return HermesClient("http://hermes.test", "test-key", transport=handler)


async def collect(client: HermesClient) -> list[str]:
    return [text async for text in client.stream_chat([{"role": "user", "content": "hi"}])]


@pytest.mark.anyio
async def test_stream_chat_yields_text_deltas_and_skips_empty_ones() -> None:
    body: bytes = sse(chunk(None), chunk("안녕"), chunk("하세요"), "data: [DONE]")
    client: HermesClient = make_client(
        httpx.MockTransport(lambda request: httpx.Response(200, content=body))
    )
    assert await collect(client) == ["안녕", "하세요"]


@pytest.mark.anyio
async def test_stream_chat_skips_hermes_tool_progress_events() -> None:
    progress: str = 'event: hermes.tool.progress\ndata: {"tool": "terminal"}'
    body: bytes = sse(progress, chunk("답"), "data: [DONE]")
    client: HermesClient = make_client(
        httpx.MockTransport(lambda request: httpx.Response(200, content=body))
    )
    assert await collect(client) == ["답"]


@pytest.mark.anyio
async def test_stream_chat_sends_bearer_key_and_stream_flag() -> None:
    seen: list[httpx.Request] = []

    def handler(request: httpx.Request) -> httpx.Response:
        seen.append(request)
        return httpx.Response(200, content=sse("data: [DONE]"))

    await collect(make_client(httpx.MockTransport(handler)))
    payload: dict[str, object] = json.loads(seen[0].content)
    assert seen[0].url.path == "/v1/chat/completions"
    assert seen[0].headers["authorization"] == "Bearer test-key"
    assert payload["stream"] is True
    assert payload["messages"] == [{"role": "user", "content": "hi"}]


@pytest.mark.anyio
async def test_stream_chat_raises_hermes_error_on_bad_status_and_keeps_the_body() -> None:
    client: HermesClient = make_client(
        httpx.MockTransport(lambda request: httpx.Response(500, content=b'{"error": "boom"}'))
    )
    with pytest.raises(HermesError, match="500.*boom"):
        await collect(client)


@pytest.mark.anyio
async def test_stream_that_ends_without_done_is_an_error_not_a_complete_answer() -> None:
    body: bytes = sse(chunk("안녕"))
    client: HermesClient = make_client(
        httpx.MockTransport(lambda request: httpx.Response(200, content=body))
    )
    with pytest.raises(HermesError, match="끝나기 전에"):
        await collect(client)


@pytest.mark.anyio
async def test_malformed_data_line_is_a_hermes_error() -> None:
    body: bytes = sse("data: this-is-not-json", "data: [DONE]")
    client: HermesClient = make_client(
        httpx.MockTransport(lambda request: httpx.Response(200, content=body))
    )
    with pytest.raises(HermesError):
        await collect(client)


@pytest.mark.anyio
async def test_error_chunk_in_the_stream_is_a_hermes_error() -> None:
    body: bytes = sse(chunk("안녕"), 'data: {"error": {"message": "boom"}}', "data: [DONE]")
    client: HermesClient = make_client(
        httpx.MockTransport(lambda request: httpx.Response(200, content=body))
    )
    with pytest.raises(HermesError, match="boom"):
        await collect(client)


def test_create_hermes_client_requires_the_api_key(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.delenv("HERMES_API_KEY", raising=False)
    settings: Settings = Settings(
        _env_file=None, postgres_user="iris", postgres_password="pw", postgres_db="irisdb"
    )
    with pytest.raises(HermesError, match="HERMES_API_KEY"):
        create_hermes_client(settings)


@pytest.mark.anyio
async def test_stream_chat_raises_hermes_error_when_hermes_is_down() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        raise httpx.ConnectError("connection refused")

    with pytest.raises(HermesError):
        await collect(make_client(httpx.MockTransport(handler)))


@pytest.mark.integration
@pytest.mark.hermes
@pytest.mark.anyio
async def test_real_hermes_streams_an_answer() -> None:
    settings: Settings = get_settings()
    if settings.hermes_api_key is None:
        pytest.skip("backend/.env에 HERMES_API_KEY가 없다")
    client: HermesClient = create_hermes_client(settings)
    messages: list[dict[str, str]] = [{"role": "user", "content": "한 단어로만 답해줘: 안녕"}]
    texts: list[str] = [text async for text in client.stream_chat(messages)]
    assert "".join(texts).strip() != ""
