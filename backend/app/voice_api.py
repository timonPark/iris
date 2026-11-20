import logging
import shutil
import tempfile
import uuid
from pathlib import Path

from fastapi import APIRouter, Depends, File, Form, Request, UploadFile
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session
from starlette.concurrency import run_in_threadpool

from app.auth import current_account, get_session
from app.chat import find_own_session, validate_question_text
from app.errors import (
    ApiError,
    audio_too_long,
    server_error,
    session_not_found,
    validation_failed,
    voice_processing_failed,
)
from app.models import Account, ChatSession
from app.sessions import ensure_session_free, parse_session_id, submit_question
from app.voice import LEFTOVER_PREFIX, VoicePipeline, VoiceQueue

logger: logging.Logger = logging.getLogger(__name__)

# 2분짜리 무압축(PCM) 스테레오 녹음이 약 23MB이므로 그보다 여유 있게 잡는다. 넘으면 2분을 넘는 녹음으로 본다.
MAX_UPLOAD_BYTES: int = 32 * 1024 * 1024

router: APIRouter = APIRouter(prefix="/api/v1/voice", tags=["voice"])


def save_upload(upload: UploadFile, target: Path) -> None:
    with target.open("wb") as out:
        shutil.copyfileobj(upload.file, out)


async def recognize(pipeline: VoicePipeline, upload: UploadFile) -> str:
    """녹음을 임시 폴더에 받아 질문 텍스트로 바꾼다. 성공하든 실패하든 처리가 끝나면 폴더째 지운다."""
    with tempfile.TemporaryDirectory(prefix=LEFTOVER_PREFIX) as folder:
        audio: Path = Path(folder) / "upload.bin"
        await run_in_threadpool(save_upload, upload, audio)
        try:
            return await pipeline.process(audio)
        except ApiError:
            raise
        except Exception as error:  # 파이프라인의 예상하지 못한 오류. 내용은 로그에만 남긴다
            logger.exception("음성 처리 중 오류가 났다")
            raise voice_processing_failed() from error


async def reject_unusable_session(
    request: Request, db: Session, account_id: uuid.UUID, session_id: uuid.UUID | None
) -> None:
    """내 세션이 아니거나(404) 이미 답변 중이면(409) 녹음을 처리하기 전에 거절한다. 등록할 때 한 번 더 확인한다."""
    own: ChatSession | None = None
    if session_id is not None:
        ensure_session_free(request.app.state.runs, account_id, session_id)
        own = await run_in_threadpool(find_own_session, db, account_id, session_id)
    await run_in_threadpool(db.rollback)  # 계정 확인 때 열린 트랜잭션도 닫아, 녹음을 처리하는 동안 DB 연결을 붙잡지 않는다
    if session_id is not None and own is None:
        raise session_not_found()


@router.post("/questions")
async def send_voice_question(
    request: Request,
    audio: UploadFile = File(),
    session_id: str | None = Form(default=None, alias="sessionId"),
    account: Account = Depends(current_account),
    db: Session = Depends(get_session),
) -> StreamingResponse:
    """녹음을 질문 텍스트로 바꿔 Hermes에 보내고 답변을 SSE로 돌려준다(첫 이벤트가 보정된 질문)."""
    parsed: uuid.UUID | None = None if session_id is None else parse_session_id(session_id)
    pipeline: VoicePipeline | None = request.app.state.voice
    if pipeline is None or request.app.state.hermes is None:
        logger.error("음성 처리 도구나 Hermes 키가 없어 음성 질문을 처리할 수 없다")
        raise server_error()
    if audio.size is None or audio.size == 0:
        raise validation_failed("녹음 파일을 확인해 주세요.")
    if audio.size > MAX_UPLOAD_BYTES:
        raise audio_too_long()
    account_id: uuid.UUID = account.id
    await reject_unusable_session(request, db, account_id, parsed)  # 오래 걸리는 처리 전에 먼저 거절한다
    queue: VoiceQueue = request.app.state.voice_queue
    async with queue.turn():  # 음성 처리는 동시에 한 건. 나머지는 순서대로 기다린다
        await reject_unusable_session(request, db, account_id, parsed)  # 기다리는 동안 세션이 바뀌었을 수 있다
        if await request.is_disconnected():
            logger.info("녹음을 보낸 클라이언트가 기다리는 동안 끊어서 처리하지 않는다")
            raise voice_processing_failed()
        text: str = validate_question_text(await recognize(pipeline, audio))
    return await submit_question(request, account_id, db, text, parsed, announce_text=True)
