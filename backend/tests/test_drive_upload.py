import json
import re
from pathlib import Path
from typing import Any

import pytest

from hermes_tools.drive_upload import (
    MAX_BYTES,
    ROOT_FOLDER,
    Root,
    UploadRefused,
    allowed_roots,
    drive_parts,
    resolve_upload_path,
    run,
    upload_and_share,
)

FOLDER: str = "application/vnd.google-apps.folder"


class Req:
    def __init__(self, result: Any) -> None:
        self._result: Any = result

    def execute(self) -> Any:
        return self._result


class FakeDrive:
    """구글 드라이브를 메모리에서 흉내 낸다(폴더 트리, 파일, 공유 설정)."""

    def __init__(self) -> None:
        self.items: dict[str, dict[str, Any]] = {}
        self.perms: dict[str, list[dict[str, Any]]] = {}
        self.writes: list[str] = []  # 만들기 또는 덮어쓰기 기록
        self._n: int = 0

    def files(self) -> "FakeDrive":
        return self

    def permissions(self) -> "FakePerms":
        return FakePerms(self)

    def _new(self, name: str, parent: str, mime: str) -> dict[str, Any]:
        self._n += 1
        item: dict[str, Any] = {
            "id": f"id{self._n}", "name": name, "parent": parent, "mimeType": mime,
            "webViewLink": f"https://drive.google.com/file/d/id{self._n}/view",
        }  # fmt: skip
        self.items[item["id"]] = item
        return item

    def list(self, q: str, fields: str = "") -> Req:
        name: str = re.search(r"name='((?:[^'\\]|\\.)*)'", q).group(1).replace("\\'", "'")  # type: ignore[union-attr]
        parent: str = re.search(r"'([^']+)' in parents", q).group(1)  # type: ignore[union-attr]
        folders_only: bool = f"mimeType='{FOLDER}'" in q
        found: list[dict[str, Any]] = [
            i for i in self.items.values()
            if i["name"] == name and i["parent"] == parent and (i["mimeType"] == FOLDER) == folders_only
        ]  # fmt: skip
        return Req({"files": found})

    def create(self, body: dict[str, Any], media_body: Any = None, fields: str = "") -> Req:
        item: dict[str, Any] = self._new(body["name"], body["parents"][0], body.get("mimeType", "text/plain"))
        if media_body is not None:
            self.writes.append(f"create:{item['id']}")
        return Req(item)

    def update(self, fileId: str, media_body: Any, fields: str = "") -> Req:
        self.writes.append(f"update:{fileId}")
        return Req(self.items[fileId])

    def path_of(self, item_id: str) -> str:
        names: list[str] = []
        while item_id != "root":
            names.append(self.items[item_id]["name"])
            item_id = self.items[item_id]["parent"]
        return "/".join(reversed(names))


class FakePerms:
    def __init__(self, drive: FakeDrive) -> None:
        self._d: FakeDrive = drive

    def list(self, fileId: str, fields: str = "") -> Req:
        return Req({"permissions": self._d.perms.get(fileId, [{"type": "user", "role": "owner"}])})  # noqa: E501

    def create(self, fileId: str, body: dict[str, Any], fields: str = "") -> Req:
        self._d.perms.setdefault(fileId, [{"type": "user", "role": "owner"}]).append(body)
        return Req({"id": "p"})


@pytest.fixture
def roots(tmp_path: Path) -> list[Root]:
    vault: Path = tmp_path / "vault"
    outbox: Path = tmp_path / "outbox"
    vault.mkdir()
    outbox.mkdir()
    return [Root(vault, ()), Root(outbox, ("_보관함",))]


def make_file(folder: Path, name: str = "note.md", text: str = "내용") -> Path:
    folder.mkdir(parents=True, exist_ok=True)
    path: Path = folder / name
    path.write_text(text)
    return path


# --- 올려도 되는 파일인가 ----------------------------------------------------------------


def test_a_file_inside_an_allowed_folder_is_accepted(roots: list[Root]) -> None:
    note: Path = make_file(roots[0].path / "90-Hermes")
    assert resolve_upload_path(str(note), roots) == note.resolve()
    assert resolve_upload_path(str(make_file(roots[1].path, "x.html")), roots).name == "x.html"


def test_a_file_outside_the_allowed_folders_is_refused(roots: list[Root], tmp_path: Path) -> None:
    with pytest.raises(UploadRefused):
        resolve_upload_path(str(make_file(tmp_path, "secret.txt")), roots)


@pytest.mark.parametrize("trick", ["../outside.txt", "sub/../../outside.txt"])
def test_dotdot_paths_that_escape_the_folder_are_refused(roots: list[Root], tmp_path: Path, trick: str) -> None:
    make_file(tmp_path, "outside.txt")
    (roots[0].path / "sub").mkdir()
    with pytest.raises(UploadRefused):
        resolve_upload_path(str(roots[0].path / trick), roots)


def test_a_symlink_that_points_outside_is_refused(roots: list[Root], tmp_path: Path) -> None:
    link: Path = roots[0].path / "innocent.md"
    link.symlink_to(make_file(tmp_path, "secret.txt"))
    with pytest.raises(UploadRefused):
        resolve_upload_path(str(link), roots)


def test_a_sibling_folder_with_the_same_prefix_is_not_inside(roots: list[Root], tmp_path: Path) -> None:
    with pytest.raises(UploadRefused):
        resolve_upload_path(str(make_file(tmp_path / "vault-evil")), roots)


@pytest.mark.parametrize(
    "relative", [".git/config", ".obsidian/plugins/x/data.json", ".env", "notes/.secret.md", "sub/.hidden/ok.md"]
)
def test_hidden_files_and_folders_are_never_uploaded(roots: list[Root], relative: str) -> None:
    secret: Path = make_file(roots[0].path / Path(relative).parent, Path(relative).name)
    with pytest.raises(UploadRefused):
        resolve_upload_path(str(secret), roots)


@pytest.mark.parametrize("name", ["id_rsa", "server.pem", "backup.sql", "run.sh", "token.json", "data.sqlite", "noextension"])
def test_only_document_like_file_types_are_uploaded(roots: list[Root], name: str) -> None:
    with pytest.raises(UploadRefused):
        resolve_upload_path(str(make_file(roots[0].path, name)), roots)


@pytest.mark.parametrize("name", ["a.md", "b.html", "c.pdf", "d.txt", "e.csv", "f.png", "g.docx", "h.xlsx", "i.pptx", "J.MD"])
def test_notes_documents_and_images_are_allowed(roots: list[Root], name: str) -> None:
    assert resolve_upload_path(str(make_file(roots[0].path, name)), roots).name == name


def test_a_link_share_that_is_not_view_only_or_is_searchable_is_corrected(roots: list[Root]) -> None:
    drive: FakeDrive = FakeDrive()
    note: Path = make_file(roots[0].path, "자료.md")
    parts: list[str] = drive_parts(note.resolve(), roots)
    upload_and_share(drive, note.resolve(), parts, media=object())
    file_id: str = next(i for i, v in drive.items.items() if v["name"] == "자료.md")
    drive.perms[file_id] = [{"type": "user", "role": "owner"}, {"type": "anyone", "role": "writer", "allowFileDiscovery": True}]
    upload_and_share(drive, note.resolve(), parts, media=object())
    assert {"type": "anyone", "role": "reader", "allowFileDiscovery": False} in drive.perms[file_id]


def test_missing_files_folders_and_oversized_files_are_refused(roots: list[Root]) -> None:
    for bad in (roots[0].path / "없음.md", roots[0].path):
        with pytest.raises(UploadRefused):
            resolve_upload_path(str(bad), roots)
    big: Path = roots[0].path / "big.bin"
    with big.open("wb") as handle:
        handle.truncate(MAX_BYTES + 1)
    with pytest.raises(UploadRefused):
        resolve_upload_path(str(big), roots)


# --- 드라이브 폴더 구조: 옵시디언 구조 그대로 ------------------------------------------------


def test_the_drive_folders_mirror_the_obsidian_structure(roots: list[Root]) -> None:
    note: Path = make_file(roots[0].path / "90-Hermes" / "교육", "SSOT 교육자료.md")
    assert drive_parts(note.resolve(), roots) == [ROOT_FOLDER, "90-Hermes", "교육"]
    assert drive_parts(make_file(roots[0].path, "루트노트.md").resolve(), roots) == [ROOT_FOLDER]


def test_files_from_the_iris_outbox_go_under_their_own_folder(roots: list[Root]) -> None:
    assert drive_parts(make_file(roots[1].path / "a", "x.txt").resolve(), roots) == [ROOT_FOLDER, "_보관함", "a"]


def test_the_default_roots_are_the_vault_and_the_outbox_with_a_prefix_that_cannot_clash() -> None:
    vault, outbox = allowed_roots()
    assert vault.prefix == () and outbox.prefix == ("_보관함",)


def test_a_vault_folder_named_like_the_outbox_does_not_collide_with_it(roots: list[Root]) -> None:
    vault_file: Path = make_file(roots[0].path / "보관함", "a.md")
    outbox_file: Path = make_file(roots[1].path, "a.md")
    assert drive_parts(vault_file.resolve(), roots) != drive_parts(outbox_file.resolve(), roots)


def test_uploading_builds_the_same_folders_in_drive_and_shares_for_anyone_with_the_link(roots: list[Root]) -> None:
    drive: FakeDrive = FakeDrive()
    note: Path = make_file(roots[0].path / "90-Hermes", "자료.md")
    result: dict[str, Any] = upload_and_share(drive, note.resolve(), drive_parts(note.resolve(), roots), media=object())
    assert result["name"] == "자료.md" and result["link"].startswith("https://drive.google.com/")
    assert result["path"] == f"{ROOT_FOLDER}/90-Hermes/자료.md"
    file_id: str = next(i for i, v in drive.items.items() if v["name"] == "자료.md")
    assert drive.path_of(file_id) == f"{ROOT_FOLDER}/90-Hermes/자료.md"
    assert {"type": "anyone", "role": "reader", "allowFileDiscovery": False} in drive.perms[file_id]


def test_uploading_the_same_path_again_overwrites_instead_of_piling_up_copies(roots: list[Root]) -> None:
    drive: FakeDrive = FakeDrive()
    note: Path = make_file(roots[0].path / "90-Hermes", "자료.md")
    parts: list[str] = drive_parts(note.resolve(), roots)
    first: dict[str, Any] = upload_and_share(drive, note.resolve(), parts, media=object())
    second: dict[str, Any] = upload_and_share(drive, note.resolve(), parts, media=object())
    assert first["link"] == second["link"]  # 같은 파일이라 링크도 그대로
    assert [v["name"] for v in drive.items.values()].count("자료.md") == 1
    assert [v["name"] for v in drive.items.values() if v["mimeType"] == FOLDER] == [ROOT_FOLDER, "90-Hermes"]
    assert drive.writes[0].startswith("create:") and drive.writes[1].startswith("update:")
    file_id: str = next(i for i, v in drive.items.items() if v["name"] == "자료.md")
    assert len([p for p in drive.perms[file_id] if p.get("type") == "anyone"]) == 1  # 공유를 두 번 만들지 않는다


def test_names_with_quotes_do_not_break_the_search(roots: list[Root]) -> None:
    drive: FakeDrive = FakeDrive()
    note: Path = make_file(roots[0].path / "Bob's 노트", "it's.md")
    result: dict[str, Any] = upload_and_share(drive, note.resolve(), drive_parts(note.resolve(), roots), media=object())
    assert result["path"] == f"{ROOT_FOLDER}/Bob's 노트/it's.md"


# --- 실행 ----------------------------------------------------------------------------------


def test_run_prints_the_link_as_json_and_exits_zero(roots: list[Root], capsys: pytest.CaptureFixture[str]) -> None:
    note: Path = make_file(roots[0].path / "90-Hermes")
    code: int = run([str(note)], roots=roots, service=FakeDrive(), make_media=lambda path: object())
    out: dict[str, str] = json.loads(capsys.readouterr().out)
    assert code == 0 and out["link"].startswith("https://drive.google.com/") and "90-Hermes" in out["path"]


def test_run_refuses_without_touching_drive_when_the_path_is_not_allowed(
    tmp_path: Path, roots: list[Root], capsys: pytest.CaptureFixture[str]
) -> None:
    drive: FakeDrive = FakeDrive()
    code: int = run([str(make_file(tmp_path, "secret.txt"))], roots=roots, service=drive, make_media=lambda path: object())
    assert code != 0 and "error" in json.loads(capsys.readouterr().out) and drive.items == {}


def test_run_needs_exactly_one_path(roots: list[Root], capsys: pytest.CaptureFixture[str]) -> None:
    for args in ([], ["a", "b"]):
        assert run(args, roots=roots, service=FakeDrive(), make_media=lambda path: object()) != 0
    assert "error" in json.loads(capsys.readouterr().out.splitlines()[0])


def test_a_drive_failure_is_reported_as_an_error_without_a_traceback(
    roots: list[Root], capsys: pytest.CaptureFixture[str]
) -> None:
    class Broken(FakeDrive):
        def list(self, q: str, fields: str = "") -> Req:
            raise RuntimeError("quota exceeded")

    code: int = run([str(make_file(roots[0].path))], roots=roots, service=Broken(), make_media=lambda path: object())
    out: str = capsys.readouterr().out
    assert code != 0 and "Traceback" not in out and "error" in json.loads(out)
