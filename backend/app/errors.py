import enum
import logging

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

from app.cors import is_allowed_origin

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


def audio_too_long() -> ApiError:
    return ApiError(422, ErrorCode.AUDIO_TOO_LONG, "녹음은 2분까지 가능합니다.")


def speech_not_recognized() -> ApiError:
    return ApiError(422, ErrorCode.SPEECH_NOT_RECOGNIZED, "음성을 인식하지 못했습니다. 다시 녹음해 주세요.")


def voice_processing_failed() -> ApiError:
    return ApiError(500, ErrorCode.VOICE_PROCESSING_FAILED, "음성을 처리하지 못했습니다. 다시 시도해 주세요.")


def login_id_taken() -> ApiError:
    return ApiError(409, ErrorCode.LOGIN_ID_TAKEN, "이미 사용 중인 아이디입니다.")


def user_not_found() -> ApiError:
    return ApiError(404, ErrorCode.USER_NOT_FOUND, "계정을 찾을 수 없습니다.")


def session_busy() -> ApiError:
    return ApiError(409, ErrorCode.SESSION_BUSY, "답변이 끝난 뒤에 질문해 주세요.")


def not_streaming() -> ApiError:
    return ApiError(409, ErrorCode.NOT_STREAMING, "진행 중인 답변이 없습니다.")


def server_error() -> ApiError:
    return ApiError(500, ErrorCode.SERVER_ERROR, "서버 오류가 발생했습니다.")


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
    response: JSONResponse = error_response(500, ErrorCode.SERVER_ERROR, "서버 오류가 발생했습니다.")
    origin: str | None = request.headers.get("origin")
    if is_allowed_origin(origin, getattr(request.app.state, "cors_origins", [])):
        # 처리하지 못한 오류는 CORS 미들웨어 바깥에서 만들어지므로, 브라우저가 오류 내용을 읽을 수 있게 여기서 헤더를 붙인다.
        response.headers["Access-Control-Allow-Origin"] = str(origin)
        response.headers.append("Vary", "Origin")
    return response


def register_error_handlers(app: FastAPI) -> None:
    app.add_exception_handler(ApiError, handle_api_error)
    app.add_exception_handler(RequestValidationError, handle_validation_error)
    app.add_exception_handler(Exception, handle_unexpected_error)
