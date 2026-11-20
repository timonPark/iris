import logging
import re
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

logger: logging.Logger = logging.getLogger(__name__)

# 개발 중인 웹은 포트가 바뀌고 https로 띄울 수도 있어서 localhost, 127.0.0.1, [::1]의 모든 포트를 허용한다.
LOCAL_ORIGIN_PATTERN: str = r"https?://(localhost|127\.0\.0\.1|\[::1\])(:\d+)?"
ALLOWED_HEADERS: list[str] = ["Authorization", "Content-Type", "ngrok-skip-browser-warning"]
ALLOWED_METHODS: list[str] = ["GET", "POST", "DELETE"]


class CorsSettings(BaseSettings):
    """CORS 설정만 읽는다. 앱을 만들 때(가져올 때) 데이터베이스 설정 같은 필수 값을 요구하지 않으려고 `Settings`와 분리했다."""

    model_config = SettingsConfigDict(env_file=Path(__file__).resolve().parents[1] / ".env", extra="ignore")

    # 브라우저(사용자 웹, 관리자 웹)가 호출할 수 있는 추가 주소(쉼표로 구분). 로컬 개발 주소는 항상 허용한다.
    cors_allow_origins: str = ""


def configured_origins() -> list[str]:
    """`CORS_ALLOW_ORIGINS`의 주소 목록. 끝의 `/`는 지우고(브라우저의 Origin에는 없다) `*`는 쓰지 않는다."""
    origins: list[str] = []
    for raw in CorsSettings().cors_allow_origins.split(","):
        origin: str = raw.strip().rstrip("/")
        if origin == "*":
            logger.warning("CORS_ALLOW_ORIGINS의 *는 쓰지 않는다. 허용할 주소를 하나씩 적는다.")
        elif origin:
            origins.append(origin)
    return origins


def is_allowed_origin(origin: str | None, extra_origins: list[str]) -> bool:
    """이 주소(`Origin` 헤더)의 브라우저가 API를 호출해도 되는가(CORS 미들웨어와 같은 기준)."""
    return origin is not None and (origin in extra_origins or re.fullmatch(LOCAL_ORIGIN_PATTERN, origin) is not None)
