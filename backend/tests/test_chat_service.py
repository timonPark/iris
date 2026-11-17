import uuid
from datetime import UTC, datetime, timedelta

import pytest
from sqlalchemy import func, select, text
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.chat import (
    EMPTY_ANSWER_PLACEHOLDER,
    QUESTION_MAX_LENGTH,
    delete_session,
    list_questions,
    list_sessions,
    load_context,
    save_exchange,
    session_title,
    validate_question_text,
)
from app.errors import ApiError, ErrorCode
from app.models import Account, AnswerStatus, ChatSession, Question, Role
from app.pagination import decode_cursor

BASE: datetime = datetime(2026, 11, 17, 9, 0, 0, tzinfo=UTC)


def at(minutes: int) -> datetime:
    return BASE + timedelta(minutes=minutes)


def make_account(db: Session) -> Account:
    account: Account = Account(
        login_id="t" + uuid.uuid4().hex[:10], password_hash="hash", role=Role.USER
    )
    db.add(account)
    db.flush()
    return account


def count(db: Session, model: type) -> int:
    return db.scalar(select(func.count()).select_from(model)) or 0


# --- 순수 규칙 -------------------------------------------------------------------------


@pytest.mark.parametrize(
    ("text", "title"),
    [
        ("안녕하세요", "안녕하세요"),
        ("한" * 100, "한" * 30),
        ("  첫째 줄\n둘째 줄\t셋째  ", "첫째 줄 둘째 줄 셋째"),
        # 30자째가 공백이면 끝 공백은 지운다.
        ("가" * 29 + "\n" + "나" * 10, "가" * 29),
    ],
)
def test_session_title_is_the_first_30_characters_on_one_line(text: str, title: str) -> None:
    assert session_title(text) == title


def test_question_up_to_the_limit_is_accepted() -> None:
    assert validate_question_text("가" * QUESTION_MAX_LENGTH) == "가" * QUESTION_MAX_LENGTH
    assert QUESTION_MAX_LENGTH == 65_536


def test_question_over_the_limit_is_rejected_as_too_long() -> None:
    with pytest.raises(ApiError) as info:
        validate_question_text("가" * (QUESTION_MAX_LENGTH + 1))
    assert (info.value.status_code, info.value.code) == (422, ErrorCode.QUESTION_TOO_LONG)
    assert info.value.message == "질문이 너무 깁니다."


@pytest.mark.parametrize("empty", ["", "   ", "\n\t "])
def test_empty_question_is_a_validation_error(empty: str) -> None:
    with pytest.raises(ApiError) as info:
        validate_question_text(empty)
    assert (info.value.status_code, info.value.code) == (422, ErrorCode.VALIDATION_FAILED)


# --- 저장 ------------------------------------------------------------------------------


@pytest.mark.integration
def test_first_question_creates_the_session_with_a_title_and_stores_the_pair(
    db_session: Session,
) -> None:
    owner: Account = make_account(db_session)
    question: Question = save_exchange(
        db_session, owner.id, session_id=None, question_text="오늘 서울 날씨 어때?",
        answer_text="맑아요.", status=AnswerStatus.COMPLETED, now=at(0),
    )
    chat: ChatSession = db_session.get(ChatSession, question.session_id)
    assert chat.account_id == owner.id
    assert chat.title == "오늘 서울 날씨 어때?"
    assert chat.created_at == chat.updated_at == at(0)
    assert chat.deleted_at is None
    assert question.text == "오늘 서울 날씨 어때?"
    assert question.answer.text == "맑아요."
    assert question.answer.status == AnswerStatus.COMPLETED


@pytest.mark.integration
def test_next_question_joins_the_session_and_moves_it_to_the_top(db_session: Session) -> None:
    owner: Account = make_account(db_session)
    first: Question = save_exchange(
        db_session, owner.id, session_id=None, question_text="첫 질문", answer_text="a",
        status=AnswerStatus.COMPLETED, now=at(0),
    )
    second: Question = save_exchange(
        db_session, owner.id, session_id=first.session_id, question_text="두 번째 질문",
        answer_text="b", status=AnswerStatus.COMPLETED, now=at(5),
    )
    assert second.session_id == first.session_id
    chat: ChatSession = db_session.get(ChatSession, first.session_id)
    assert chat.title == "첫 질문"  # 이름은 첫 질문으로 고정
    assert chat.updated_at == at(5)
    assert chat.created_at == at(0)
    assert count(db_session, Question) == 2


@pytest.mark.integration
def test_stopped_answer_is_stored_as_stopped(db_session: Session) -> None:
    owner: Account = make_account(db_session)
    question: Question = save_exchange(
        db_session, owner.id, session_id=None, question_text="긴 답이 필요한 질문",
        answer_text="받은 부분까지", status=AnswerStatus.STOPPED,
    )
    assert question.answer.status == AnswerStatus.STOPPED
    assert question.answer.text == "받은 부분까지"


@pytest.mark.integration
def test_question_over_the_limit_stores_nothing(db_session: Session) -> None:
    owner: Account = make_account(db_session)
    before: int = count(db_session, ChatSession)
    with pytest.raises(ApiError) as info:
        save_exchange(
            db_session, owner.id, session_id=None, question_text="가" * (QUESTION_MAX_LENGTH + 1),
            answer_text="a", status=AnswerStatus.COMPLETED,
        )
    assert info.value.code == ErrorCode.QUESTION_TOO_LONG
    assert count(db_session, ChatSession) == before
    assert count(db_session, Question) == 0


@pytest.mark.integration
def test_database_also_refuses_a_question_over_the_limit(db_session: Session) -> None:
    owner: Account = make_account(db_session)
    chat: ChatSession = ChatSession(account_id=owner.id, title="t")
    db_session.add(chat)
    db_session.flush()
    db_session.add(Question(session_id=chat.id, text="가" * (QUESTION_MAX_LENGTH + 1)))
    with pytest.raises(IntegrityError):
        db_session.flush()


@pytest.mark.integration
def test_saving_into_a_missing_foreign_or_deleted_session_is_session_not_found(
    db_session: Session,
) -> None:
    owner: Account = make_account(db_session)
    stranger: Account = make_account(db_session)
    mine: Question = save_exchange(
        db_session, owner.id, session_id=None, question_text="내 세션", answer_text="a",
        status=AnswerStatus.COMPLETED,
    )
    deleted: Question = save_exchange(
        db_session, owner.id, session_id=None, question_text="지울 세션", answer_text="a",
        status=AnswerStatus.COMPLETED,
    )
    delete_session(db_session, owner.id, deleted.session_id)
    attempts: list[tuple[uuid.UUID, uuid.UUID]] = [
        (stranger.id, mine.session_id),  # 다른 사용자의 세션
        (owner.id, deleted.session_id),  # 삭제된 세션은 없는 세션으로 처리
        (owner.id, uuid.uuid4()),  # 없는 세션
    ]
    before: int = count(db_session, Question)
    for account_id, session_id in attempts:
        with pytest.raises(ApiError) as info:
            save_exchange(
                db_session, account_id, session_id=session_id, question_text="들어가면 안 됨",
                answer_text="a", status=AnswerStatus.COMPLETED,
            )
        assert (info.value.status_code, info.value.code) == (404, ErrorCode.SESSION_NOT_FOUND)
    assert count(db_session, Question) == before


@pytest.mark.integration
@pytest.mark.parametrize("bad_text", ["hi\x00there", "\x00", "깨진 문자 \ud800 포함"])
def test_question_with_characters_the_database_cannot_store_is_a_validation_error(
    db_session: Session, bad_text: str
) -> None:
    owner: Account = make_account(db_session)
    with pytest.raises(ApiError) as info:
        save_exchange(
            db_session, owner.id, session_id=None, question_text=bad_text, answer_text="a",
            status=AnswerStatus.COMPLETED,
        )
    assert (info.value.status_code, info.value.code) == (422, ErrorCode.VALIDATION_FAILED)
    assert count(db_session, Question) == 0


@pytest.mark.integration
def test_answer_with_unstorable_characters_is_cleaned_instead_of_lost(db_session: Session) -> None:
    """Hermes가 이미 답한 뒤에는 문제 문자 하나 때문에 답변 전체를 잃으면 안 된다."""
    owner: Account = make_account(db_session)
    question: Question = save_exchange(
        db_session, owner.id, session_id=None, question_text="질문", answer_text="가\x00나\ud800다",
        status=AnswerStatus.COMPLETED,
    )
    db_session.refresh(question.answer)
    assert question.answer.text == "가나\ufffd다"


@pytest.mark.integration
def test_activity_time_never_moves_backwards(db_session: Session) -> None:
    owner: Account = make_account(db_session)
    first: Question = save_exchange(
        db_session, owner.id, session_id=None, question_text="질문 1", answer_text="a",
        status=AnswerStatus.COMPLETED, now=at(10),
    )
    save_exchange(
        db_session, owner.id, session_id=first.session_id, question_text="늦게 끝난 오래된 질문",
        answer_text="a", status=AnswerStatus.COMPLETED, now=at(5),
    )
    chat: ChatSession = db_session.get(ChatSession, first.session_id)
    db_session.refresh(chat)
    assert chat.updated_at == at(10)


# --- 세션 목록 -------------------------------------------------------------------------


def new_session(db: Session, owner: Account, title: str, minutes: int) -> uuid.UUID:
    question: Question = save_exchange(
        db, owner.id, session_id=None, question_text=title, answer_text="a",
        status=AnswerStatus.COMPLETED, now=at(minutes),
    )
    return question.session_id


@pytest.mark.integration
def test_sessions_are_listed_most_recently_active_first(db_session: Session) -> None:
    owner: Account = make_account(db_session)
    old: uuid.UUID = new_session(db_session, owner, "오래된 세션", 0)
    middle: uuid.UUID = new_session(db_session, owner, "중간 세션", 10)
    new: uuid.UUID = new_session(db_session, owner, "새 세션", 20)
    save_exchange(  # 오래된 세션에 새 질문이 오면 맨 위로 올라온다
        db_session, owner.id, session_id=old, question_text="또 질문", answer_text="a",
        status=AnswerStatus.COMPLETED, now=at(30),
    )
    page, next_cursor = list_sessions(db_session, owner.id, cursor=None, limit=20)
    assert [chat.id for chat in page] == [old, new, middle]
    assert next_cursor is None


@pytest.mark.integration
def test_listing_shows_only_my_undeleted_sessions(db_session: Session) -> None:
    owner: Account = make_account(db_session)
    stranger: Account = make_account(db_session)
    kept: uuid.UUID = new_session(db_session, owner, "남길 세션", 0)
    removed: uuid.UUID = new_session(db_session, owner, "지울 세션", 1)
    new_session(db_session, stranger, "남의 세션", 2)
    delete_session(db_session, owner.id, removed)
    page, _ = list_sessions(db_session, owner.id, cursor=None, limit=20)
    assert [chat.id for chat in page] == [kept]


@pytest.mark.integration
def test_pages_follow_the_cursor_without_duplicates_or_gaps(db_session: Session) -> None:
    owner: Account = make_account(db_session)
    created: list[uuid.UUID] = [new_session(db_session, owner, f"세션 {n}", n) for n in range(5)]
    seen: list[uuid.UUID] = []
    cursor: str | None = None
    pages: int = 0
    while True:
        page, cursor = list_sessions(db_session, owner.id, cursor=cursor, limit=2)
        seen.extend(chat.id for chat in page)
        pages += 1
        if cursor is None:
            break
    assert pages == 3
    assert seen == list(reversed(created))


@pytest.mark.integration
def test_sessions_with_the_same_activity_time_are_each_listed_exactly_once(
    db_session: Session,
) -> None:
    owner: Account = make_account(db_session)
    created: set[uuid.UUID] = {new_session(db_session, owner, f"동시 {n}", 0) for n in range(5)}
    seen: list[uuid.UUID] = []
    cursor: str | None = None
    while True:
        page, cursor = list_sessions(db_session, owner.id, cursor=cursor, limit=2)
        seen.extend(chat.id for chat in page)
        if cursor is None:
            break
    assert len(seen) == 5
    assert set(seen) == created


@pytest.mark.integration
def test_ties_are_ordered_by_id_even_when_the_database_does_not_use_the_index(
    db_session: Session,
) -> None:
    """같은 시각의 세션을 id로 정렬하는 것은 DB가 인덱스를 쓰는 우연에 기대면 안 된다. 인덱스를 끄고 확인한다."""
    db_session.execute(text("SET LOCAL enable_indexscan = off"))
    db_session.execute(text("SET LOCAL enable_bitmapscan = off"))
    db_session.execute(text("SET LOCAL enable_indexonlyscan = off"))
    owner: Account = make_account(db_session)
    created: set[uuid.UUID] = {new_session(db_session, owner, f"동시 {n}", 0) for n in range(8)}
    seen: list[uuid.UUID] = []
    cursor: str | None = None
    while True:
        page, cursor = list_sessions(db_session, owner.id, cursor=cursor, limit=3)
        seen.extend(chat.id for chat in page)
        if cursor is None:
            break
    assert len(seen) == 8
    assert set(seen) == created
    assert seen == sorted(seen, reverse=True)


@pytest.mark.integration
def test_listing_cursor_is_only_returned_when_there_is_a_next_page(db_session: Session) -> None:
    owner: Account = make_account(db_session)
    for n in range(3):
        new_session(db_session, owner, f"세션 {n}", n)
    _, exact = list_sessions(db_session, owner.id, cursor=None, limit=3)
    _, more = list_sessions(db_session, owner.id, cursor=None, limit=2)
    assert exact is None
    assert more is not None
    assert decode_cursor(more, "sessions")[0] == at(1)  # 이 페이지의 마지막 항목 위치


@pytest.mark.integration
def test_listing_with_a_bad_cursor_is_a_validation_error(db_session: Session) -> None:
    owner: Account = make_account(db_session)
    with pytest.raises(ApiError) as info:
        list_sessions(db_session, owner.id, cursor="garbage", limit=20)
    assert info.value.code == ErrorCode.VALIDATION_FAILED


# --- 세션 열람(질문과 답변) -------------------------------------------------------------


@pytest.mark.integration
def test_questions_are_listed_newest_first_with_their_answers(db_session: Session) -> None:
    owner: Account = make_account(db_session)
    first: Question = save_exchange(
        db_session, owner.id, session_id=None, question_text="질문 1", answer_text="답 1",
        status=AnswerStatus.COMPLETED, now=at(0),
    )
    for n in (2, 3):
        save_exchange(
            db_session, owner.id, session_id=first.session_id, question_text=f"질문 {n}",
            answer_text=f"답 {n}",
            status=AnswerStatus.STOPPED if n == 3 else AnswerStatus.COMPLETED, now=at(n),
        )
    page, next_cursor = list_questions(
        db_session, owner.id, first.session_id, cursor=None, limit=20
    )
    assert [(q.text, q.answer.text, q.answer.status) for q in page] == [
        ("질문 3", "답 3", AnswerStatus.STOPPED),
        ("질문 2", "답 2", AnswerStatus.COMPLETED),
        ("질문 1", "답 1", AnswerStatus.COMPLETED),
    ]
    assert next_cursor is None


@pytest.mark.integration
def test_question_pages_follow_the_cursor_without_duplicates_or_gaps(db_session: Session) -> None:
    owner: Account = make_account(db_session)
    first: Question = save_exchange(
        db_session, owner.id, session_id=None, question_text="질문 0", answer_text="a",
        status=AnswerStatus.COMPLETED, now=at(0),
    )
    for n in range(1, 5):
        save_exchange(
            db_session, owner.id, session_id=first.session_id, question_text=f"질문 {n}",
            answer_text="a", status=AnswerStatus.COMPLETED, now=at(n),
        )
    texts: list[str] = []
    cursor: str | None = None
    while True:
        page, cursor = list_questions(db_session, owner.id, first.session_id, cursor=cursor, limit=2)
        texts.extend(q.text for q in page)
        if cursor is None:
            break
    assert texts == [f"질문 {n}" for n in (4, 3, 2, 1, 0)]


@pytest.mark.integration
def test_questions_of_a_foreign_deleted_or_unknown_session_are_session_not_found(
    db_session: Session,
) -> None:
    owner: Account = make_account(db_session)
    stranger: Account = make_account(db_session)
    mine: uuid.UUID = new_session(db_session, owner, "내 세션", 0)
    gone: uuid.UUID = new_session(db_session, owner, "지운 세션", 1)
    delete_session(db_session, owner.id, gone)
    for account_id, session_id in [(stranger.id, mine), (owner.id, gone), (owner.id, uuid.uuid4())]:
        with pytest.raises(ApiError) as info:
            list_questions(db_session, account_id, session_id, cursor=None, limit=20)
        assert (info.value.status_code, info.value.code) == (404, ErrorCode.SESSION_NOT_FOUND)


# --- 삭제 ------------------------------------------------------------------------------


@pytest.mark.integration
def test_delete_only_marks_the_session_and_keeps_every_row(db_session: Session) -> None:
    owner: Account = make_account(db_session)
    question: Question = save_exchange(
        db_session, owner.id, session_id=None, question_text="지울 세션", answer_text="a",
        status=AnswerStatus.COMPLETED, now=at(0),
    )
    delete_session(db_session, owner.id, question.session_id, now=at(9))
    chat: ChatSession = db_session.get(ChatSession, question.session_id)
    assert chat.deleted_at == at(9)
    assert db_session.get(Question, question.id) is not None
    assert question.answer is not None
    assert count(db_session, ChatSession) >= 1


@pytest.mark.integration
def test_deleting_twice_or_deleting_someone_elses_session_is_session_not_found(
    db_session: Session,
) -> None:
    owner: Account = make_account(db_session)
    stranger: Account = make_account(db_session)
    mine: uuid.UUID = new_session(db_session, owner, "내 세션", 0)
    with pytest.raises(ApiError) as foreign:
        delete_session(db_session, stranger.id, mine)
    assert foreign.value.code == ErrorCode.SESSION_NOT_FOUND
    assert db_session.get(ChatSession, mine).deleted_at is None  # 남의 삭제 시도는 아무것도 바꾸지 않는다
    delete_session(db_session, owner.id, mine)
    with pytest.raises(ApiError) as again:
        delete_session(db_session, owner.id, mine)
    assert again.value.code == ErrorCode.SESSION_NOT_FOUND
    with pytest.raises(ApiError) as unknown:
        delete_session(db_session, owner.id, uuid.uuid4())
    assert unknown.value.code == ErrorCode.SESSION_NOT_FOUND


# --- 맥락(이전 질문과 답변) --------------------------------------------------------------


@pytest.mark.integration
def test_context_lists_every_previous_pair_oldest_first(db_session: Session) -> None:
    owner: Account = make_account(db_session)
    first: Question = save_exchange(
        db_session, owner.id, session_id=None, question_text="내 이름은 철수야", answer_text="반가워요",
        status=AnswerStatus.COMPLETED, now=at(0),
    )
    for n, (q, a) in enumerate([("내 이름이 뭐지?", "철수님이죠"), ("고마워", "천만에요")], start=1):
        save_exchange(
            db_session, owner.id, session_id=first.session_id, question_text=q, answer_text=a,
            status=AnswerStatus.COMPLETED, now=at(n),
        )
    assert load_context(db_session, owner.id, first.session_id) == [
        {"role": "user", "content": "내 이름은 철수야"},
        {"role": "assistant", "content": "반가워요"},
        {"role": "user", "content": "내 이름이 뭐지?"},
        {"role": "assistant", "content": "철수님이죠"},
        {"role": "user", "content": "고마워"},
        {"role": "assistant", "content": "천만에요"},
    ]


@pytest.mark.integration
def test_context_keeps_a_stopped_answer_and_marks_an_empty_one(db_session: Session) -> None:
    owner: Account = make_account(db_session)
    first: Question = save_exchange(
        db_session, owner.id, session_id=None, question_text="긴 질문", answer_text="받은 부분까지",
        status=AnswerStatus.STOPPED, now=at(0),
    )
    save_exchange(
        db_session, owner.id, session_id=first.session_id, question_text="또 질문", answer_text="",
        status=AnswerStatus.STOPPED, now=at(1),
    )
    context: list[dict[str, str]] = load_context(db_session, owner.id, first.session_id)
    assert context[1] == {"role": "assistant", "content": "받은 부분까지"}
    # 빈 assistant 메시지는 모델 API가 거부할 수 있어 표시를 넣는다.
    assert context[3] == {"role": "assistant", "content": EMPTY_ANSWER_PLACEHOLDER}
    assert all(message["content"] for message in context)


@pytest.mark.integration
def test_context_contains_only_that_session(db_session: Session) -> None:
    owner: Account = make_account(db_session)
    other: uuid.UUID = new_session(db_session, owner, "다른 세션의 질문", 0)
    mine: uuid.UUID = new_session(db_session, owner, "내 세션의 질문", 1)
    contents: list[str] = [m["content"] for m in load_context(db_session, owner.id, mine)]
    assert "다른 세션의 질문" not in contents
    assert contents[0] == "내 세션의 질문"
    assert other != mine


@pytest.mark.integration
def test_context_of_a_foreign_deleted_or_unknown_session_is_session_not_found(
    db_session: Session,
) -> None:
    owner: Account = make_account(db_session)
    stranger: Account = make_account(db_session)
    mine: uuid.UUID = new_session(db_session, owner, "내 세션", 0)
    gone: uuid.UUID = new_session(db_session, owner, "지운 세션", 1)
    delete_session(db_session, owner.id, gone)
    for account_id, session_id in [(stranger.id, mine), (owner.id, gone), (owner.id, uuid.uuid4())]:
        with pytest.raises(ApiError) as info:
            load_context(db_session, account_id, session_id)
        assert (info.value.status_code, info.value.code) == (404, ErrorCode.SESSION_NOT_FOUND)


@pytest.mark.integration
def test_a_new_session_can_be_created_with_an_id_chosen_in_advance(db_session: Session) -> None:
    """첫 질문의 세션 ID를 답변이 저장되기 전에 클라이언트에 알려 주기 위해 미리 정한다."""
    owner: Account = make_account(db_session)
    chosen: uuid.UUID = uuid.uuid4()
    question: Question = save_exchange(
        db_session, owner.id, session_id=None, new_session_id=chosen, question_text="질문",
        answer_text="답", status=AnswerStatus.COMPLETED,
    )
    assert question.session_id == chosen
    assert db_session.get(ChatSession, chosen).account_id == owner.id


@pytest.mark.integration
def test_the_question_keeps_the_time_it_was_asked_and_the_answer_the_time_it_finished(
    db_session: Session,
) -> None:
    owner: Account = make_account(db_session)
    question: Question = save_exchange(
        db_session, owner.id, session_id=None, question_text="질문", answer_text="답",
        status=AnswerStatus.COMPLETED, now=at(5), asked_at=at(0),
    )
    chat: ChatSession = db_session.get(ChatSession, question.session_id)
    assert question.created_at == at(0)
    assert question.answer.created_at == at(5)
    assert (chat.created_at, chat.updated_at) == (at(0), at(5))
