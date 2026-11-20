import httpx
import pytest
from fastapi.testclient import TestClient

from app.config import Settings, get_settings
from app.cors import configured_origins
from app.main import create_app
from tests.conftest import LiveServer, install_test_routes
from tests.factories import AccountFactory
from tests.fakes import FakeHermes

LOGIN: str = "/api/v1/auth/login"
ALLOWED: list[str] = ["http://localhost:5173", "http://localhost:3000", "http://127.0.0.1:8080", "http://localhost"]
PREFLIGHT_HEADERS: str = "authorization,content-type,ngrok-skip-browser-warning"


def preflight(client: TestClient, origin: str, path: str = LOGIN, method: str = "POST") -> httpx.Response:
    return client.options(
        path,
        headers={
            "Origin": origin,
            "Access-Control-Request-Method": method,
            "Access-Control-Request-Headers": PREFLIGHT_HEADERS,
        },
    )


@pytest.mark.parametrize("origin", ALLOWED)
def test_a_preflight_from_a_local_dev_origin_is_allowed_with_the_headers_the_api_needs(
    app_client: TestClient, origin: str
) -> None:
    response = preflight(app_client, origin)
    assert response.status_code == 200
    assert response.headers["access-control-allow-origin"] == origin  # `*`가 아니라 보낸 주소를 그대로
    allowed: str = response.headers["access-control-allow-headers"].lower()
    for header in PREFLIGHT_HEADERS.split(","):
        assert header in allowed
    assert "POST" in response.headers["access-control-allow-methods"]
    assert "access-control-allow-credentials" not in response.headers  # 쿠키를 쓰지 않으므로 켜지 않는다


@pytest.mark.parametrize("method", ["GET", "POST", "DELETE"])
def test_every_method_the_api_uses_passes_the_preflight(app_client: TestClient, method: str) -> None:
    response = preflight(app_client, "http://localhost:5173", "/api/v1/sessions", method)
    assert response.status_code == 200
    assert method in response.headers["access-control-allow-methods"]


@pytest.mark.parametrize(
    "origin", ["https://evil.example", "http://localhost.evil.example", "http://evil.example:5173", "null"]
)
def test_other_origins_get_no_cors_headers(app_client: TestClient, origin: str) -> None:
    pre = preflight(app_client, origin)
    assert pre.status_code == 400  # 허용하지 않은 주소의 사전 요청은 거절된다
    assert "access-control-allow-origin" not in pre.headers
    real = app_client.post(LOGIN, json={"loginId": "x", "password": "y"}, headers={"Origin": origin})
    assert "access-control-allow-origin" not in real.headers


def test_real_responses_including_errors_carry_the_cors_header(app_client: TestClient) -> None:
    origin: str = "http://localhost:5173"
    unauthorized = app_client.get("/api/v1/sessions", headers={"Origin": origin})
    assert unauthorized.status_code == 401
    assert unauthorized.headers["access-control-allow-origin"] == origin  # 오류 응답도 브라우저가 읽을 수 있어야 한다
    invalid = app_client.post(LOGIN, json={"loginId": "x", "password": "y"}, headers={"Origin": origin})
    assert invalid.status_code == 401 and invalid.headers["access-control-allow-origin"] == origin
    bad_body = app_client.post(LOGIN, json={"nope": 1}, headers={"Origin": origin})
    assert bad_body.status_code == 422 and bad_body.headers["access-control-allow-origin"] == origin


def test_an_unexpected_server_error_still_carries_the_cors_header_so_the_browser_can_read_it(
    app_client: TestClient,
) -> None:
    allowed = app_client.get("/_test/boom", headers={"Origin": "http://localhost:5173"})
    assert allowed.status_code == 500
    assert allowed.json()["error"]["code"] == "SERVER_ERROR"
    assert allowed.headers["access-control-allow-origin"] == "http://localhost:5173"
    other = app_client.get("/_test/boom", headers={"Origin": "https://evil.example"})
    assert other.status_code == 500 and "access-control-allow-origin" not in other.headers


def test_a_request_without_an_origin_is_unaffected(app_client: TestClient) -> None:
    response = app_client.post(LOGIN, json={"loginId": "x", "password": "y"})
    assert response.status_code == 401
    assert "access-control-allow-origin" not in response.headers


def test_extra_origins_come_from_the_environment(monkeypatch: pytest.MonkeyPatch, migrated_engine: object) -> None:
    monkeypatch.setenv("CORS_ALLOW_ORIGINS", "https://iris.example.com, https://admin.example.com")
    get_settings.cache_clear()
    try:
        with TestClient(create_app(), raise_server_exceptions=False) as client:
            for origin in ("https://iris.example.com", "https://admin.example.com"):
                assert preflight(client, origin).headers["access-control-allow-origin"] == origin
            assert preflight(client, "https://other.example.com").status_code == 400
            assert preflight(client, "http://localhost:5173").status_code == 200  # 기본 허용도 그대로
    finally:
        get_settings.cache_clear()


def test_an_event_stream_response_carries_the_cors_header(
    live_server: LiveServer, account_factory: AccountFactory
) -> None:
    owner = account_factory.create()
    live_server.app.state.hermes = FakeHermes(["안녕"])
    login = httpx.post(
        f"{live_server.base_url}/api/v1/auth/login", json={"loginId": owner.login_id, "password": "correct-password"}
    )
    headers: dict[str, str] = {"Authorization": f"Bearer {login.json()['accessToken']}", "Origin": "http://localhost:5173"}
    with httpx.Client(timeout=20) as client:
        with client.stream(
            "POST", f"{live_server.base_url}/api/v1/sessions/questions", json={"text": "질문"}, headers=headers
        ) as response:
            assert response.headers["content-type"].startswith("text/event-stream")
            assert response.headers["access-control-allow-origin"] == "http://localhost:5173"
            response.read()


@pytest.mark.parametrize(
    "origin", ["https://localhost:5173", "http://[::1]:5173", "https://127.0.0.1", "http://localhost:5173"]
)
def test_https_and_ipv6_loopback_dev_servers_are_allowed_too(app_client: TestClient, origin: str) -> None:
    assert preflight(app_client, origin).headers["access-control-allow-origin"] == origin


@pytest.mark.parametrize("origin", ["http://localhost:5173\n", "http://localhost:abc", "http://localhost.evil.example"])
def test_lookalike_origins_are_refused_on_both_the_normal_and_the_500_path(app_client: TestClient, origin: str) -> None:
    assert preflight(app_client, origin).status_code == 400
    assert "access-control-allow-origin" not in app_client.get("/_test/boom", headers={"Origin": origin}).headers


def test_configured_origins_are_cleaned_and_a_wildcard_is_ignored(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("CORS_ALLOW_ORIGINS", " https://a.example.com/ , * ,https://b.example.com,, ")
    assert configured_origins() == ["https://a.example.com", "https://b.example.com"]  # 끝의 `/`는 지우고 `*`는 버린다


def test_configured_origins_also_apply_to_unexpected_server_errors(
    monkeypatch: pytest.MonkeyPatch, migrated_engine: object
) -> None:
    monkeypatch.setenv("CORS_ALLOW_ORIGINS", "https://iris.example.com")
    get_settings.cache_clear()
    try:
        app = create_app()
        install_test_routes(app)
        with TestClient(app, raise_server_exceptions=False) as client:
            response = client.get("/_test/boom", headers={"Origin": "https://iris.example.com"})
            assert response.status_code == 500
            assert response.headers["access-control-allow-origin"] == "https://iris.example.com"
            assert "Origin" in response.headers["vary"]
    finally:
        get_settings.cache_clear()


def test_the_app_can_be_created_without_the_database_settings(monkeypatch: pytest.MonkeyPatch) -> None:
    for name in ("POSTGRES_USER", "POSTGRES_PASSWORD", "POSTGRES_DB"):
        monkeypatch.delenv(name, raising=False)
    monkeypatch.setitem(Settings.model_config, "env_file", None)
    get_settings.cache_clear()
    try:
        create_app()  # 앱을 만들기만 해도(가져오기만 해도) 데이터베이스 설정을 요구하지 않는다
    finally:
        get_settings.cache_clear()
