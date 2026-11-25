import os
from pathlib import Path

from app.instructions import material_instruction, with_instruction


def test_the_instruction_names_the_fixed_upload_tool_by_its_absolute_path() -> None:
    text: str = material_instruction()
    tool: Path = Path(__file__).resolve().parents[1] / "hermes_tools" / "drive-upload.sh"
    assert str(tool) in text
    assert tool.exists() and os.access(tool, os.X_OK)  # 지시문이 가리키는 도구가 실제로 있고 실행할 수 있다


def test_the_instruction_covers_the_whole_flow_and_the_edge_cases() -> None:
    text: str = material_instruction()
    for needle in ("옵시디언", "링크", "찾지 못", "여러 개", "되묻"):
        assert needle in text, needle
    assert "자료" in text and "그 밖의 질문" in text  # 자료 요청이 아닌 질문은 평소처럼 답하게 한다


def test_the_instruction_forbids_other_ways_of_uploading_or_changing_drive() -> None:
    text: str = material_instruction()
    assert "다른 방법" in text and "삭제" in text and "공유" in text


def test_the_instruction_is_put_first_and_the_conversation_is_left_untouched() -> None:
    conversation: list[dict[str, str]] = [
        {"role": "user", "content": "이전 질문"},
        {"role": "assistant", "content": "이전 답변"},
        {"role": "user", "content": "자료 보여줘"},
    ]
    sent: list[dict[str, str]] = with_instruction(conversation)
    assert sent[0]["role"] == "system" and sent[0]["content"] == material_instruction()
    assert sent[1:] == conversation
    assert len(conversation) == 3  # 원래 목록은 바뀌지 않는다
