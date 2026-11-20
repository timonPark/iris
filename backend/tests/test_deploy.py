import os
import re
import shutil
import socket
import subprocess
import threading
import time
from pathlib import Path

import pytest

BACKEND: Path = Path(__file__).resolve().parents[1]
DEPLOY: Path = BACKEND / "deploy"
TEMPLATES: list[str] = ["com.iris.backend.plist.template", "com.iris.tunnel.plist.template"]


def render(name: str, tmp_path: Path) -> Path:
    text: str = (DEPLOY / "launchd" / name).read_text()
    for key, value in {
        "@REPO@": "/repo", "@HOME@": "/home/u", "@NGROK@": "/bin/ngrok", "@DOMAIN@": "x.ngrok-free.dev", "@LOGDIR@": "/logs",
    }.items():
        text = text.replace(key, value)
    assert not re.search(r"@[A-Z_]+@", text), "채워지지 않은 자리가 남았다"
    target: Path = tmp_path / name.removesuffix(".template")
    target.write_text(text)
    return target


@pytest.mark.skipif(shutil.which("plutil") is None, reason="macOS의 plutil이 필요하다")
@pytest.mark.parametrize("name", TEMPLATES)
def test_the_launchd_templates_render_into_valid_plists(name: str, tmp_path: Path) -> None:
    result: subprocess.CompletedProcess[str] = subprocess.run(
        ["plutil", "-lint", str(render(name, tmp_path))], capture_output=True, text=True
    )
    assert result.returncode == 0, result.stdout + result.stderr


@pytest.mark.parametrize("name", TEMPLATES)
def test_each_service_starts_at_login_and_is_restarted_when_it_dies(name: str, tmp_path: Path) -> None:
    import plistlib

    plist: dict[str, object] = plistlib.loads(render(name, tmp_path).read_bytes())
    assert plist["RunAtLoad"] is True and plist["KeepAlive"] is True
    assert str(plist["Label"]).startswith("com.iris.")
    assert int(str(plist["ThrottleInterval"])) >= 5  # 계속 죽는 경우 바로 다시 시작하며 자원을 쓰지 않게


def test_the_tunnel_uses_the_given_domain_and_the_backend_port(tmp_path: Path) -> None:
    import plistlib

    plist: dict[str, object] = plistlib.loads(render("com.iris.tunnel.plist.template", tmp_path).read_bytes())
    arguments: list[str] = list(plist["ProgramArguments"])  # type: ignore[call-overload]
    assert "--url=x.ngrok-free.dev" in arguments
    assert arguments[-1] == "8000"


def test_the_templates_hold_no_secrets() -> None:
    for name in TEMPLATES:
        text: str = (DEPLOY / "launchd" / name).read_text()
        for word in ("PASSWORD", "SECRET", "API_KEY", "authtoken"):
            assert word.lower() not in text.lower()


# --- 시작 스크립트 -----------------------------------------------------------------------


def stub(path: Path, body: str) -> str:
    path.write_text("#!/bin/bash\n" + body)
    path.chmod(0o755)
    return str(path)


def run_script(
    tmp_path: Path, *, docker_up_after: int, db_port: int, wait: int, hang_seconds: int = 0
) -> subprocess.CompletedProcess[str]:
    """가짜 docker, open, uvicorn으로 시작 스크립트를 돌린다. `docker info`는 `docker_up_after`번째 호출부터 성공한다."""
    log: Path = tmp_path / "calls.log"
    counter: Path = tmp_path / "count"
    counter.write_text("0")
    docker: str = stub(
        tmp_path / "docker",
        f'echo "docker $*" >> {log}\n'
        'if [ "$1" = "info" ]; then n=$(($(cat ' + str(counter) + ')+1)); echo $n > ' + str(counter)
        + (f"; sleep {hang_seconds}" if hang_seconds else "") + f'; [ $n -ge {docker_up_after} ]; exit $?; fi\n',
    )
    opener: str = stub(tmp_path / "opener", f'echo "open $*" >> {log}\n')
    uvicorn: str = stub(tmp_path / "uvicorn", f'echo "uvicorn $*" >> {log}\n')
    env: dict[str, str] = {
        **os.environ, "IRIS_DOCKER": docker, "IRIS_OPEN_DOCKER": opener, "IRIS_UVICORN": uvicorn,
        "IRIS_DB_PORT": str(db_port), "IRIS_WAIT_SECONDS": str(wait), "IRIS_POLL_SECONDS": "0.2", "IRIS_PROBE_SECONDS": "1",
    }
    return subprocess.run(["/bin/bash", str(DEPLOY / "run-backend.sh")], env=env, capture_output=True, text=True, timeout=60)


@pytest.fixture
def fake_database() -> tuple[int, threading.Event]:
    """PostgreSQL 포트를 흉내 내는 열린 포트."""
    server: socket.socket = socket.socket()
    server.bind(("127.0.0.1", 0))
    server.listen()
    stop: threading.Event = threading.Event()
    threading.Thread(target=lambda: (stop.wait(), server.close()), daemon=True).start()
    yield server.getsockname()[1], stop
    stop.set()


def test_the_script_starts_the_backend_once_docker_and_the_database_are_up(
    tmp_path: Path, fake_database: tuple[int, threading.Event]
) -> None:
    result = run_script(tmp_path, docker_up_after=1, db_port=fake_database[0], wait=10)
    calls: list[str] = (tmp_path / "calls.log").read_text().splitlines()
    assert result.returncode == 0, result.stderr
    assert not any(line.startswith("open ") for line in calls)  # Docker가 이미 켜져 있으면 다시 켜지 않는다
    assert "docker start iris-postgres" in calls
    assert "uvicorn app.main:app --host 127.0.0.1 --port 8000" in calls


def test_the_script_starts_docker_when_it_is_off_and_waits_for_it(
    tmp_path: Path, fake_database: tuple[int, threading.Event]
) -> None:
    result = run_script(tmp_path, docker_up_after=4, db_port=fake_database[0], wait=20)
    calls: list[str] = (tmp_path / "calls.log").read_text().splitlines()
    assert result.returncode == 0, result.stderr
    assert "open -ga Docker" in calls
    assert calls.index("open -ga Docker") < calls.index("uvicorn app.main:app --host 127.0.0.1 --port 8000")


def test_the_script_gives_up_when_the_database_never_opens_so_launchd_retries(tmp_path: Path) -> None:
    closed: socket.socket = socket.socket()
    closed.bind(("127.0.0.1", 0))
    port: int = closed.getsockname()[1]
    closed.close()  # 아무도 듣지 않는 포트
    result = run_script(tmp_path, docker_up_after=1, db_port=port, wait=2)
    assert result.returncode != 0
    assert "uvicorn" not in (tmp_path / "calls.log").read_text()


def test_the_script_gives_up_when_docker_never_comes_up(tmp_path: Path) -> None:
    result = run_script(tmp_path, docker_up_after=10_000, db_port=1, wait=2)
    assert result.returncode != 0
    assert "uvicorn" not in (tmp_path / "calls.log").read_text()


def test_a_docker_that_hangs_while_starting_does_not_stall_the_script_forever(tmp_path: Path) -> None:
    started: float = time.monotonic()
    result = run_script(tmp_path, docker_up_after=10_000, db_port=1, wait=3, hang_seconds=30)
    assert result.returncode != 0
    assert time.monotonic() - started < 20  # `docker info`가 멈춰도 제한 시간 안에 포기한다(launchd가 다시 시도)


# --- 설치 스크립트: 잘못된 입력은 launchd를 건드리기 전에 거절한다(이 테스트는 실제로 설치하지 않는다) ------


def run_installer(script: Path, tmp_home: Path, *arguments: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["/bin/bash", str(script), *arguments],
        env={**os.environ, "HOME": str(tmp_home)},
        capture_output=True,
        text=True,
        timeout=30,
    )


@pytest.mark.parametrize(
    "domain", ["https://x.ngrok-free.dev", "x.ngrok-free.dev/path", "no_dot", "--url=evil", "a b.dev", "-x.dev", ""]
)
def test_the_installer_refuses_a_domain_that_is_not_a_bare_host_name(domain: str, tmp_path: Path) -> None:
    result = run_installer(DEPLOY / "install-launchd.sh", tmp_path, domain)
    assert result.returncode == 2
    assert not (tmp_path / "Library").exists()  # 아무것도 만들지 않았다


def test_the_installer_refuses_paths_that_would_break_the_plist(tmp_path: Path) -> None:
    repo: Path = tmp_path / "R&D" / "iris"
    shutil.copytree(DEPLOY, repo / "backend" / "deploy")
    result = run_installer(repo / "backend" / "deploy" / "install-launchd.sh", tmp_path / "home", "x.ngrok-free.dev")
    assert result.returncode == 3
    assert not (tmp_path / "home" / "Library").exists()
