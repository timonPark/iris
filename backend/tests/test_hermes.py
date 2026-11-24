import json
from collections.abc import AsyncIterator

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


# 실제 Hermes가 보낸 승인 요청의 모양: 답변 조각이 아닌데 `choices`(문자열 목록)가 들어 있다.
APPROVAL_REQUEST: dict[str, object] = {
    "command": "PY=/x/python3; $PY script.py",
    "choices": ["once", "session", "always", "deny"],
}


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
@pytest.mark.parametrize(
    "name", ["approval.request", "hermes.status", "tool.progress", "status", "something.new", "approval"]
)
async def test_any_named_event_is_not_an_answer_chunk_and_is_skipped(name: str) -> None:
    # 실제 Hermes가 보낸 모양: 터미널 명령 승인을 요청하는 이벤트(데이터가 답변 조각 모양이 아니다)
    named: str = f"event: {name}\ndata: " + json.dumps(APPROVAL_REQUEST)
    body: bytes = sse(chunk("앞"), named, chunk("뒤"), "data: [DONE]")
    client: HermesClient = make_client(
        httpx.MockTransport(lambda request: httpx.Response(200, content=body))
    )
    assert await collect(client) == ["앞", "뒤"]


@pytest.mark.anyio
async def test_a_chunk_after_a_named_event_is_read_again_once_the_event_ends() -> None:
    named: str = "event: approval.request\ndata: " + json.dumps(APPROVAL_REQUEST)
    body: bytes = sse(named, chunk("답"), named, named, chunk("변"), "data: [DONE]")
    client: HermesClient = make_client(
        httpx.MockTransport(lambda request: httpx.Response(200, content=body))
    )
    assert await collect(client) == ["답", "변"]


@pytest.mark.anyio
async def test_the_default_event_name_message_is_an_ordinary_chunk() -> None:
    body: bytes = sse("event: message\n" + chunk("안녕"), "data: [DONE]")
    client: HermesClient = make_client(
        httpx.MockTransport(lambda request: httpx.Response(200, content=body))
    )
    assert await collect(client) == ["안녕"]


@pytest.mark.anyio
async def test_an_error_event_is_a_hermes_error_not_a_silently_skipped_event() -> None:
    body: bytes = sse(chunk("안녕"), 'event: error\ndata: {"message": "boom"}', "data: [DONE]")
    client: HermesClient = make_client(
        httpx.MockTransport(lambda request: httpx.Response(200, content=body))
    )
    with pytest.raises(HermesError):
        await collect(client)


@pytest.mark.anyio
async def test_done_ends_the_stream_even_when_it_arrives_under_a_named_event() -> None:
    body: bytes = sse(chunk("안녕"), "event: hermes.status\ndata: [DONE]")
    client: HermesClient = make_client(
        httpx.MockTransport(lambda request: httpx.Response(200, content=body))
    )
    assert await collect(client) == ["안녕"]


@pytest.mark.anyio
async def test_an_event_line_without_a_space_after_the_colon_is_read_the_same() -> None:
    named: str = "event:approval.request\ndata: " + json.dumps(APPROVAL_REQUEST)
    body: bytes = sse(named, chunk("답"), "data: [DONE]")
    client: HermesClient = make_client(
        httpx.MockTransport(lambda request: httpx.Response(200, content=body))
    )
    assert await collect(client) == ["답"]


@pytest.mark.anyio
async def test_an_error_event_with_a_body_that_is_not_json_is_still_a_hermes_error() -> None:
    body: bytes = sse("event: error\ndata: not json at all", "data: [DONE]")
    client: HermesClient = make_client(
        httpx.MockTransport(lambda request: httpx.Response(200, content=body))
    )
    with pytest.raises(HermesError):
        await collect(client)


@pytest.mark.anyio
async def test_a_stream_that_ends_inside_a_named_event_is_an_unfinished_answer() -> None:
    body: bytes = sse(chunk("안녕"), "event: approval.request\ndata: " + json.dumps(APPROVAL_REQUEST))
    client: HermesClient = make_client(
        httpx.MockTransport(lambda request: httpx.Response(200, content=body))
    )
    with pytest.raises(HermesError, match="끝나기 전에"):
        await collect(client)


@pytest.mark.anyio
async def test_skipped_events_are_logged_and_an_approval_request_is_a_warning(
    caplog: pytest.LogCaptureFixture,
) -> None:
    named: str = "event: approval.request\ndata: " + json.dumps(APPROVAL_REQUEST)
    body: bytes = sse(named, "event: hermes.status\ndata: {}", chunk("답"), "data: [DONE]")
    client: HermesClient = make_client(
        httpx.MockTransport(lambda request: httpx.Response(200, content=body))
    )
    with caplog.at_level("DEBUG", logger="app.hermes"):
        assert await collect(client) == ["답"]
    warnings: list[str] = [r.getMessage() for r in caplog.records if r.levelname == "WARNING"]
    assert any("approval.request" in message for message in warnings)  # 승인을 기다리느라 답변이 늦어지는 원인을 알 수 있게
    assert "$PY script.py" not in caplog.text  # 명령 내용은 로그에 남기지 않는다


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


# --- open_chat: 연결이 열린 뒤에야 스트림을 준다 -----------------------------------------


class BrokenStream(httpx.AsyncByteStream):
    """첫 조각을 보낸 뒤 연결이 끊기는 응답 본문."""

    async def __aiter__(self) -> AsyncIterator[bytes]:
        yield sse(chunk("부분"))
        raise httpx.ReadError("연결이 끊겼다")


@pytest.mark.anyio
async def test_open_chat_fails_when_entering_if_hermes_refuses() -> None:
    client: HermesClient = make_client(httpx.MockTransport(lambda request: httpx.Response(401)))
    with pytest.raises(HermesError):
        async with client.open_chat([{"role": "user", "content": "hi"}]):
            raise AssertionError("연결이 거부되었는데 블록 안으로 들어왔다")


@pytest.mark.anyio
async def test_open_chat_fails_when_entering_if_hermes_is_down() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        raise httpx.ConnectError("connection refused")

    with pytest.raises(HermesError):
        async with make_client(httpx.MockTransport(handler)).open_chat([]):
            raise AssertionError("연결할 수 없는데 블록 안으로 들어왔다")


@pytest.mark.anyio
async def test_open_chat_yields_the_deltas_once_open() -> None:
    body: bytes = sse(chunk("안녕"), chunk("하세요"), "data: [DONE]")
    client: HermesClient = make_client(
        httpx.MockTransport(lambda request: httpx.Response(200, content=body))
    )
    async with client.open_chat([{"role": "user", "content": "hi"}]) as stream:
        assert [text async for text in stream] == ["안녕", "하세요"]


@pytest.mark.anyio
async def test_a_connection_that_breaks_mid_stream_is_a_hermes_error() -> None:
    client: HermesClient = make_client(
        httpx.MockTransport(lambda request: httpx.Response(200, stream=BrokenStream()))
    )
    received: list[str] = []
    with pytest.raises(HermesError):
        async with client.open_chat([]) as stream:
            async for text in stream:
                received.append(text)
    assert received == ["부분"]  # 끊기기 전에 받은 조각은 전달된다
