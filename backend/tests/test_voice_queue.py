import glob
import os
import tempfile
import threading
import time
from pathlib import Path

import httpx
import pytest
from sqlalchemy.engine import Engine

from app.models import Account
from app.voice import VoiceQueue, sweep_leftover_folders
from tests.conftest import LiveServer
from tests.factories import AccountFactory
from tests.factories import ChatFactory
from tests.fakes import HANG, FakeHermes, FakeVoice
from tests.test_voice_api import error_code, speak, token_of

pytestmark = pytest.mark.integration


def leftovers() -> set[str]:
    return set(glob.glob(os.path.join(tempfile.gettempdir(), "iris-voice-*")))


@pytest.fixture
def queued(
    live_server: LiveServer, account_factory: AccountFactory, monkeypatch: pytest.MonkeyPatch, tmp_path: Path
) -> tuple[LiveServer, str]:
    monkeypatch.setattr(tempfile, "tempdir", str(tmp_path))  # 다른 테스트나 서버의 폴더와 섞이지 않게 이 테스트만의 임시 폴더를 쓴다
    owner: Account = account_factory.create()
    live_server.app.state.hermes = FakeHermes(["ok"])
    live_server.app.state.voice_queue = VoiceQueue(wait_seconds=30)
    return live_server, token_of(live_server, owner)


def start_speaking(
    live: LiveServer, token: str, results: list[tuple[int, int]], index: int, session_id: object = None
) -> threading.Thread:
    thread: threading.Thread = threading.Thread(
        target=lambda: results.append(
            (index, speak(live, token, audio=f"recording-{index}".encode(), session_id=session_id)[0].status_code)  # type: ignore[arg-type]
        )
    )
    thread.start()
    return thread


def test_recordings_sent_together_are_processed_one_at_a_time_in_arrival_order(
    queued: tuple[LiveServer, str],
) -> None:
    live, token = queued
    fake: FakeVoice = FakeVoice(delay=0.4)
    live.app.state.voice = fake
    results: list[tuple[int, int]] = []
    threads: list[threading.Thread] = []
    for index in range(4):
        threads.append(start_speaking(live, token, results, index))
        time.sleep(0.1)  # 들어온 순서를 정한다
    for thread in threads:
        thread.join(timeout=30)
    assert sorted(results) == [(i, 200) for i in range(4)]  # 거절 없이 모두 처리된다
    assert fake.max_active == 1
    assert fake.contents == [f"recording-{i}".encode() for i in range(4)]  # 들어온 순서대로


def test_a_request_that_waits_too_long_is_told_to_retry_and_never_processed(
    queued: tuple[LiveServer, str],
) -> None:
    live, token = queued
    fake: FakeVoice = FakeVoice(delay=1.5)
    live.app.state.voice = fake
    live.app.state.voice_queue = VoiceQueue(wait_seconds=0.4)
    before: set[str] = leftovers()
    results: list[tuple[int, int]] = []
    first: threading.Thread = start_speaking(live, token, results, 0)
    time.sleep(0.2)
    response, _ = speak(live, token, audio=b"second")
    first.join(timeout=30)
    assert (response.status_code, error_code(response)) == (500, "VOICE_PROCESSING_FAILED")
    assert fake.contents == [b"recording-0"]  # 두 번째는 처리되지 않았다
    assert leftovers() == before  # 기다리다 끝난 요청도, 처리된 요청도 파일이 남지 않는다
    assert live.app.state.voice_queue.waiting == 0


def test_a_request_whose_client_left_while_waiting_is_not_processed(queued: tuple[LiveServer, str]) -> None:
    live, token = queued
    fake: FakeVoice = FakeVoice(delay=1.2)
    live.app.state.voice = fake
    results: list[tuple[int, int]] = []
    first: threading.Thread = start_speaking(live, token, results, 0)
    time.sleep(0.2)
    with pytest.raises(httpx.TimeoutException):  # 두 번째 클라이언트가 기다리다 끊는다
        with httpx.Client(base_url=live.base_url, timeout=0.3) as client:
            client.post(
                "/api/v1/voice/questions",
                files={"audio": ("rec.m4a", b"left", "audio/mp4")},
                headers={"Authorization": f"Bearer {token}"},
            )
    first.join(timeout=30)
    time.sleep(0.5)
    assert fake.contents == [b"recording-0"]


def test_a_session_that_became_busy_or_deleted_while_waiting_is_refused_without_processing(
    queued: tuple[LiveServer, str], account_factory: AccountFactory, chat_factory: ChatFactory
) -> None:
    live, token = queued
    owner_session = chat_factory.exchange(account_factory.create(), "x", "y")  # 남의 세션은 처음부터 404
    fake: FakeVoice = FakeVoice(delay=0.8)
    live.app.state.voice = fake
    live.app.state.hermes = FakeHermes(["부분", HANG])  # 첫 녹음의 답변이 끝나지 않아 세션이 계속 답변 중이다
    me: Account = account_factory.create()
    my_token: str = token_of(live, me)
    mine = chat_factory.exchange(me, "질문", "답변")
    first_result: list[tuple[int, int]] = []
    first: threading.Thread = start_speaking(live, my_token, first_result, 0, session_id=mine.session_id)
    time.sleep(0.2)
    second, _ = speak(live, my_token, audio=b"second", session_id=mine.session_id)  # 첫 녹음이 처리되는 동안 줄을 선다
    try:
        assert (second.status_code, error_code(second)) == (409, "SESSION_BUSY")
        assert fake.contents == [b"recording-0"]  # 두 번째 녹음은 처리되지 않았다
    finally:
        httpx.post(
            f"{live.base_url}/api/v1/sessions/{mine.session_id}/stop", headers={"Authorization": f"Bearer {my_token}"}
        )
        first.join(timeout=30)
    assert owner_session is not None


def test_the_turn_is_given_back_after_a_failure_so_the_next_recording_is_processed(
    queued: tuple[LiveServer, str],
) -> None:
    live, token = queued
    live.app.state.voice = FakeVoice(error=RuntimeError("boom"))
    assert speak(live, token)[0].status_code == 500
    live.app.state.voice = FakeVoice()
    assert speak(live, token)[0].status_code == 200
    assert live.app.state.voice_queue.waiting == 0


def test_folders_left_by_a_killed_server_are_swept_but_recent_ones_are_kept(tmp_path: Path) -> None:
    old: Path = tmp_path / "iris-voice-old"
    recent: Path = tmp_path / "iris-voice-recent"
    other: Path = tmp_path / "unrelated-folder"
    for folder in (old, recent, other):
        folder.mkdir()
        (folder / "upload.bin").write_bytes(b"x")
    two_hours_ago: float = time.time() - 7200
    for folder in (old, other):
        os.utime(folder, (two_hours_ago, two_hours_ago))
    assert sweep_leftover_folders(tmp_path) == 1
    assert not old.exists() and recent.exists() and other.exists()


def test_the_server_sweeps_old_leftover_folders_when_it_starts(
    monkeypatch: pytest.MonkeyPatch, migrated_engine: Engine, tmp_path: Path
) -> None:
    from fastapi.testclient import TestClient

    from app.config import get_settings
    from app.main import create_app

    old: Path = tmp_path / "iris-voice-old"
    old.mkdir()
    two_hours_ago: float = time.time() - 7200
    os.utime(old, (two_hours_ago, two_hours_ago))
    monkeypatch.setattr(tempfile, "tempdir", str(tmp_path))
    get_settings.cache_clear()
    try:
        with TestClient(create_app()):
            assert not old.exists()
    finally:
        get_settings.cache_clear()

