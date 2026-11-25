from pathlib import Path

# Hermes가 구글 드라이브에 올릴 때 쓰는 고정 도구(옵시디언 폴더 안의 파일만 올리고 링크를 돌려준다).
UPLOAD_TOOL: Path = Path(__file__).resolve().parents[1] / "hermes_tools" / "drive-upload.sh"


def material_instruction() -> str:
    """사용자가 자료를 요청했을 때 Hermes가 따를 순서. 질문마다 맨 앞에 붙이고 저장하지는 않는다(`ssot/GLOSSARY.md` "자료 링크")."""
    return (
        "[Iris 자료 요청 규칙]\n"
        "사용자가 자료(파일, 문서, 노트)를 보여 달라거나 찾아 달라고 요청하면 아래 순서로만 처리한다.\n"
        "1. 옵시디언에서 그 자료를 찾는다(파일 검색 도구를 쓴다).\n"
        "2. 찾지 못했으면 \"해당 자료를 찾지 못했습니다.\"라고만 답하고 아무것도 올리지 않는다.\n"
        "3. 비슷한 후보가 여러 개이면 아무것도 올리지 말고 후보의 이름만 번호로 보여 준 뒤, 어느 것을 열지 사용자에게 되묻는다.\n"
        "4. 정확히 하나이면 그 파일의 절대 경로로 아래 명령을 정확히 이 모양 그대로 한 번 실행한다.\n"
        f"   {UPLOAD_TOOL} \"<파일의 절대 경로>\"\n"
        "   출력된 JSON의 link 값(구글 드라이브 링크)을 답변에 넣어 알려 준다(주소를 바꾸거나 줄이지 않는다). 오류(error)가 나오면 그 사실만 알린다.\n"
        "금지: 위 명령 말고 다른 방법으로 구글 드라이브에 올리거나, 파일 삭제, 공유 설정 변경, 메일 전송을 하지 않는다.\n"
        "그 밖의 질문에는 이 규칙을 무시하고 평소처럼 답한다."
    )


def with_instruction(messages: list[dict[str, str]]) -> list[dict[str, str]]:
    """Hermes에 보낼 메시지의 맨 앞에 자료 요청 규칙을 붙인다(원래 목록은 바꾸지 않는다)."""
    return [{"role": "system", "content": material_instruction()}, *messages]
