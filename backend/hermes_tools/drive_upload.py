"""Hermes가 부르는 구글 드라이브 업로드 전용 도구.

옵시디언 폴더(또는 Iris 보관함) 안의 파일 하나를 구글 드라이브에 **옵시디언과 같은 폴더 구조로** 올리고(`Iris 자료/<옵시디언 안의 경로>`),
링크가 있는 누구나 열 수 있게 공유한 뒤 링크를 JSON으로 출력한다. 같은 경로의 파일을 다시 올리면 덮어써서 링크가 그대로다.
아무 파일이나 올릴 수 없고(비밀 키 같은 파일이 링크로 새지 않게), 삭제는 하지 않는다.

    python drive_upload.py <파일 경로>   →   {"name": "...", "path": "Iris 자료/...", "link": "https://drive.google.com/..."}  (실패하면 {"error": "..."})
"""

import json
import os
import sys
from collections.abc import Callable
from dataclasses import dataclass
from pathlib import Path
from typing import Any

MAX_BYTES: int = 50 * 1024 * 1024
# 올릴 수 있는 문서와 이미지 형식. 키, 설정, 데이터베이스, 스크립트 같은 파일은 확장자로 막는다.
ALLOWED_SUFFIXES: frozenset[str] = frozenset(
    {".md", ".markdown", ".txt", ".html", ".htm", ".pdf", ".csv", ".png", ".jpg", ".jpeg", ".gif", ".webp",
     ".doc", ".docx", ".xls", ".xlsx", ".ppt", ".pptx"}
)  # fmt: skip
ROOT_FOLDER: str = "Iris 자료"  # 드라이브(내 드라이브 맨 바깥)에 만드는 폴더. 옵시디언 구조가 이 아래로 그대로 들어간다
FOLDER_MIME: str = "application/vnd.google-apps.folder"
TOKEN_PATH: Path = Path.home() / ".hermes" / "google_token.json"


class UploadRefused(Exception):
    """올릴 수 없는 파일이다(허용한 폴더 밖, 없는 파일, 폴더, 너무 큼)."""


@dataclass(frozen=True)
class Root:
    path: Path  # 올려도 되는 폴더
    prefix: tuple[str, ...]  # 드라이브에서 `Iris 자료` 아래에 붙일 폴더 이름(옵시디언은 없음, Iris 보관함은 "_보관함")


def allowed_roots() -> list[Root]:
    vault: str = os.environ.get("IRIS_VAULT_DIR", str(Path.home() / "hermes-obsidian"))
    outbox: str = os.environ.get("IRIS_OUTBOX_DIR", str(Path.home() / ".hermes" / "iris-outbox"))
    return [Root(Path(vault), ()), Root(Path(outbox), ("_보관함",))]  # 옵시디언에 `보관함` 폴더가 있어도 겹치지 않게 `_`를 붙인다


def resolve_upload_path(raw: str, roots: list[Root]) -> Path:
    """올려도 되는 파일이면 실제 경로를 돌려준다. `..`와 심볼릭 링크로 허용한 폴더 밖을 가리키는 것은 거절한다."""
    path: Path = Path(raw).expanduser().resolve()
    root: Root | None = next((r for r in roots if path.is_relative_to(r.path.resolve())), None)
    if root is None:
        raise UploadRefused("허용한 폴더(옵시디언, Iris 보관함) 안의 파일만 올릴 수 있습니다.")
    if any(part.startswith(".") for part in path.relative_to(root.path.resolve()).parts):
        raise UploadRefused("숨김 폴더와 숨김 파일(.git, .obsidian, .env 등)은 올릴 수 없습니다.")
    if path.suffix.lower() not in ALLOWED_SUFFIXES:
        raise UploadRefused("올릴 수 있는 형식(노트, 문서, 이미지)이 아닙니다.")
    if not path.is_file():
        raise UploadRefused("파일이 없거나 폴더입니다.")
    if path.stat().st_size > MAX_BYTES:
        raise UploadRefused(f"파일이 너무 큽니다(최대 {MAX_BYTES // (1024 * 1024)}MB).")
    return path


def drive_parts(path: Path, roots: list[Root]) -> list[str]:
    """드라이브에서 이 파일이 들어갈 폴더 경로. `Iris 자료`와 옵시디언 안의 하위 폴더를 그대로 따른다."""
    for root in roots:
        base: Path = root.path.resolve()
        if path.is_relative_to(base):
            return [ROOT_FOLDER, *root.prefix, *path.parent.relative_to(base).parts]
    raise UploadRefused("허용한 폴더 밖입니다.")


def quote(value: str) -> str:
    return value.replace("\\", "\\\\").replace("'", "\\'")


def find_child(service: Any, name: str, parent: str, *, folder: bool) -> dict[str, Any] | None:
    mime: str = f" and mimeType='{FOLDER_MIME}'" if folder else f" and mimeType!='{FOLDER_MIME}'"
    query: str = f"name='{quote(name)}' and '{parent}' in parents and trashed=false{mime}"
    found: list[dict[str, Any]] = service.files().list(q=query, fields="files(id,name,webViewLink)").execute()["files"]
    return found[0] if found else None


def ensure_folders(service: Any, parts: list[str]) -> str:
    """드라이브에 폴더 경로를 만들고(이미 있으면 그대로 쓴다) 맨 안쪽 폴더의 ID를 돌려준다."""
    parent: str = "root"
    for name in parts:
        folder: dict[str, Any] | None = find_child(service, name, parent, folder=True)
        if folder is None:
            body: dict[str, Any] = {"name": name, "mimeType": FOLDER_MIME, "parents": [parent]}
            folder = service.files().create(body=body, fields="id,name").execute()
        parent = folder["id"]
    return parent


def share_for_link(service: Any, file_id: str) -> None:
    """링크가 있는 누구나 볼 수 있게(검색에는 안 잡히게) 공유한다. 이미 공유되어 있으면 다시 만들지 않는다."""
    fields: str = "permissions(type,role,allowFileDiscovery)"
    perms: list[dict[str, Any]] = service.permissions().list(fileId=file_id, fields=fields).execute()["permissions"]
    already: bool = any(
        p.get("type") == "anyone" and p.get("role") == "reader" and not p.get("allowFileDiscovery") for p in perms
    )  # 보기 전용이고 검색에 안 잡히는 링크 공유가 이미 있어야 건너뛴다
    if not already:
        body: dict[str, Any] = {"type": "anyone", "role": "reader", "allowFileDiscovery": False}
        service.permissions().create(fileId=file_id, body=body, fields="id").execute()


def upload_and_share(service: Any, path: Path, parts: list[str], media: Any) -> dict[str, str]:
    """옵시디언과 같은 폴더에 파일을 올리고(이미 있으면 덮어쓴다) 링크를 공유한 뒤 이름, 드라이브 경로, 링크를 돌려준다."""
    parent: str = ensure_folders(service, parts)
    existing: dict[str, Any] | None = find_child(service, path.name, parent, folder=False)
    fields: str = "id,name,webViewLink"
    if existing is None:
        uploaded: dict[str, Any] = service.files().create(body={"name": path.name, "parents": [parent]}, media_body=media, fields=fields).execute()
    else:
        uploaded = service.files().update(fileId=existing["id"], media_body=media, fields=fields).execute()
    share_for_link(service, uploaded["id"])
    return {"name": uploaded["name"], "path": "/".join([*parts, uploaded["name"]]), "link": uploaded["webViewLink"]}


def emit(payload: dict[str, str]) -> None:
    print(json.dumps(payload, ensure_ascii=False))


def run(
    argv: list[str], *, roots: list[Root], service: Any, make_media: Callable[[Path], Any]
) -> int:
    if len(argv) != 1:
        emit({"error": "사용법: drive_upload.py <파일 경로> (파일 하나만)"})
        return 2
    try:
        path: Path = resolve_upload_path(argv[0], roots)
        emit(upload_and_share(service, path, drive_parts(path, roots), make_media(path)))
        return 0
    except UploadRefused as refusal:
        emit({"error": str(refusal)})
    except Exception as error:  # 구글 오류 등. 토큰이나 내부 경로가 새지 않게 종류만 알린다
        emit({"error": f"드라이브에 올리지 못했습니다({type(error).__name__})."})
    return 1


def build_service() -> Any:
    from google.oauth2.credentials import Credentials
    from googleapiclient.discovery import build

    info: dict[str, Any] = json.loads(TOKEN_PATH.read_text())
    credentials: Credentials = Credentials.from_authorized_user_info(info, info.get("scopes"))
    return build("drive", "v3", credentials=credentials, cache_discovery=False)


def make_media(path: Path) -> Any:
    from googleapiclient.http import MediaFileUpload

    return MediaFileUpload(str(path), resumable=False)


def main() -> int:
    argv: list[str] = sys.argv[1:]
    try:
        service: Any = build_service() if len(argv) == 1 else None  # 인자가 잘못되면 구글에 연결하지 않는다
    except Exception as error:  # 토큰이 없거나 라이브러리가 없는 경우
        emit({"error": f"구글 연결을 준비하지 못했습니다({type(error).__name__})."})
        return 1
    return run(argv, roots=allowed_roots(), service=service, make_media=make_media)


if __name__ == "__main__":
    sys.exit(main())
