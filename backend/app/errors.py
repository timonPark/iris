import enum
import logging

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

logger: logging.Logger = logging.getLogger(__name__)


class ErrorCode(enum.StrEnum):
    """오류 코드. `docs/api/openapi.yaml`의 `ErrorCode`와 같은 값이다."""

    UNAUTHORIZED = "UNAUTHORIZED"
    INVALID_CREDENTIALS = "INVALID_CREDENTIALS"
    ACCOUNT_BLOCKED = "ACCOUNT_BLOCKED"
    PASSWORD_CHANGE_REQUIRED = "PASSWORD_CHANGE_REQUIRED"
    FORBIDDEN = "FORBIDDEN"
    VALIDATION_FAILED = "VALIDATION_FAILED"
    QUESTION_TOO_LONG = "QUESTION_TOO_LONG"
    SESSION_NOT_FOUND = "SESSION_NOT_FOUND"
    USER_NOT_FOUND = "USER_NOT_FOUND"
    LOGIN_ID_TAKEN = "LOGIN_ID_TAKEN"
    NOT_STREAMING = "NOT_STREAMING"
    SESSION_BUSY = "SESSION_BUSY"
    AUDIO_TOO_LONG = "AUDIO_TOO_LONG"
    SPEECH_NOT_RECOGNIZED = "SPEECH_NOT_RECOGNIZED"
    VOICE_PROCESSING_FAILED = "VOICE_PROCESSING_FAILED"
    SERVER_ERROR = "SERVER_ERROR"


class ApiError(Exception):
    """API가 클라이언트에 돌려주는 오류. `{"error": {"code", "message"}}` 형식으로 응답한다."""

    def __init__(self, status_code: int, code: ErrorCode, message: str) -> None:
        super().__init__(message)
        self.status_code: int = status_code
        self.code: ErrorCode = code
        self.message: str = message


# 문구는 docs/api/openapi.yaml 의 예시와 같다.
def unauthorized() -> ApiError:
    return ApiError(401, ErrorCode.UNAUTHORIZED, "다시 로그인해 주세요.")


def invalid_credentials() -> ApiError:
    return ApiError(401, ErrorCode.INVALID_CREDENTIALS, "아이디 또는 비밀번호가 올바르지 않습니다.")


def account_blocked() -> ApiError:
    return ApiError(403, ErrorCode.ACCOUNT_BLOCKED, "차단된 계정입니다.")


def password_change_required() -> ApiError:
    return ApiError(403, ErrorCode.PASSWORD_CHANGE_REQUIRED, "비밀번호를 먼저 변경해 주세요.")


def forbidden() -> ApiError:
    return ApiError(403, ErrorCode.FORBIDDEN, "권한이 없습니다.")


def validation_failed(message: str = "입력 값을 확인해 주세요.") -> ApiError:
    return ApiError(422, ErrorCode.VALIDATION_FAILED, message)


def session_not_found() -> ApiError:
    return ApiError(404, ErrorCode.SESSION_NOT_FOUND, "세션을 찾을 수 없습니다.")


def question_too_long() -> ApiError:
    return ApiError(422, ErrorCode.QUESTION_TOO_LONG, "질문이 너무 깁니다.")


def error_response(status_code: int, code: ErrorCode, message: str) -> JSONResponse:
    return JSONResponse(
        status_code=status_code, content={"error": {"code": code.value, "message": message}}
    )


async def handle_api_error(request: Request, error: Exception) -> JSONResponse:
    assert isinstance(error, ApiError)
    return error_response(error.status_code, error.code, error.message)


async def handle_validation_error(request: Request, error: Exception) -> JSONResponse:
    return error_response(422, ErrorCode.VALIDATION_FAILED, "입력 값을 확인해 주세요.")


async def handle_unexpected_error(request: Request, error: Exception) -> JSONResponse:
    logger.exception("처리하지 못한 오류: %s %s", request.method, request.url.path, exc_info=error)
    return error_response(500, ErrorCode.SERVER_ERROR, "서버 오류가 발생했습니다.")


def register_error_handlers(app: FastAPI) -> None:
    app.add_exception_handler(ApiError, handle_api_error)
    app.add_exception_handler(RequestValidationError, handle_validation_error)
    app.add_exception_handler(Exception, handle_unexpected_error)
