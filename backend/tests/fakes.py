import asyncio
from collections.abc import AsyncIterator, Callable, Sequence
from contextlib import asynccontextmanager
from pathlib import Path

from app.hermes import HermesError


class Marker:
    def __init__(self, name: str) -> None:
        self.name: str = name

    def __repr__(self) -> str:
        return self.name


HANG: Marker = Marker("HANG")  # 여기서 멈춰서 더 이상 아무것도 보내지 않는다(취소될 때까지)
FAIL: Marker = Marker("FAIL")  # 여기서 Hermes 오류가 난다
CRASH: Marker = Marker("CRASH")  # 여기서 HermesError가 아닌 예외가 난다


class FakeHermes:
    """Hermes 대신 정해진 조각을 보내는 가짜. 받은 요청(맥락)과 취소 여부를 기록한다."""

    def __init__(
        self,
        chunks: Sequence[str | Marker] = ("안녕", "하세요"),
        *,
        delay: float = 0.0,
        fail_on_open: bool = False,
        hang_on_open: bool = False,
    ) -> None:
        self.chunks: list[str | Marker] = list(chunks)
        self.delay: float = delay
        self.fail_on_open: bool = fail_on_open
        self.hang_on_open: bool = hang_on_open  # 연결하는 중에 멈춘다(열리지 않는다)
        self.calls: list[list[dict[str, str]]] = []
        self.cancelled: bool = False  # 끝까지 가기 전에 연결이 닫혔는가(중지로 취소됨)
        self.finished: bool = False  # 조각을 끝까지 보냈는가
        self.failed: bool = False  # 오류로 끝났는가

    @asynccontextmanager
    async def open_chat(self, messages: list[dict[str, str]]) -> AsyncIterator[AsyncIterator[str]]:
        self.calls.append(messages)
        if self.fail_on_open:
            raise HermesError("Hermes가 꺼져 있다")
        if self.hang_on_open:
            await asyncio.Event().wait()
        try:
            yield self._stream()
        finally:
            # 취소가 `_stream` 안에서 일어났는지 `yield` 지점에서 일어났는지와 상관없이 결정적으로 판정한다.
            self.cancelled = not (self.finished or self.failed)

    async def _stream(self) -> AsyncIterator[str]:
        try:
            for chunk in self.chunks:
                if chunk is HANG:
                    await asyncio.Event().wait()
                if chunk is FAIL:
                    self.failed = True
                    raise HermesError("Hermes 오류")
                if chunk is CRASH:
                    self.failed = True
                    raise RuntimeError("예상하지 못한 오류")
                if self.delay:
                    await asyncio.sleep(self.delay)
                assert isinstance(chunk, str)
                yield chunk
            self.finished = True
        except asyncio.CancelledError:
            raise


class FakeVoice:
    """녹음을 텍스트로 바꾸는 파이프라인 대신 정해진 문장을 돌려주는 가짜. 받은 녹음 파일과 그 내용을 기록한다."""

    def __init__(
        self,
        text: str = "오늘 서울 날씨가 어때요",
        *,
        error: Exception | None = None,
        delay: float = 0.0,
        probe: Callable[[], object] | None = None,
    ) -> None:
        self.text: str = text
        self.error: Exception | None = error
        self.delay: float = delay
        self.probe: Callable[[], object] | None = probe  # 처리 도중에 호출해 상태를 기록한다
        self.probed: list[object] = []
        self.active: int = 0  # 지금 처리 중인 녹음 수
        self.max_active: int = 0  # 동시에 처리된 최대 수
        self.calls: list[Path] = []
        self.contents: list[bytes] = []  # 호출 시점에 파일이 실제로 있었는지, 무엇이 올라왔는지

    async def process(self, audio: Path) -> str:
        self.calls.append(audio)
        self.contents.append(audio.read_bytes())
        if self.probe is not None:
            self.probed.append(self.probe())
        self.active += 1
        self.max_active = max(self.max_active, self.active)
        try:
            if self.delay:
                await asyncio.sleep(self.delay)
            if self.error is not None:
                raise self.error
            return self.text
        finally:
            self.active -= 1
