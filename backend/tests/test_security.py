import pytest

from app.security import hash_password, validate_login_id, validate_password, verify_password


@pytest.mark.parametrize("login_id", ["abcd", "user1234", "a1b2", "a" * 20, "0000"])
def test_valid_login_ids_are_accepted(login_id: str) -> None:
    assert validate_login_id(login_id) == login_id


@pytest.mark.parametrize(
    "login_id",
    ["", "abc", "a" * 21, "Abcd", "ABCD1234", "ab_cd", "ab-cd", "ab cd", "abcd\n", "한글아이디1"],
)
def test_invalid_login_ids_are_rejected(login_id: str) -> None:
    with pytest.raises(ValueError):
        validate_login_id(login_id)


@pytest.mark.parametrize("password", ["12345678", "aaaaaaaa", "password", "비밀번호는여덟자이상"])
def test_passwords_of_eight_or_more_characters_are_accepted_without_complexity_rules(
    password: str,
) -> None:
    assert validate_password(password) == password


@pytest.mark.parametrize("password", ["", "1234567", "abc"])
def test_passwords_shorter_than_eight_characters_are_rejected(password: str) -> None:
    with pytest.raises(ValueError):
        validate_password(password)


def test_password_length_is_limited_to_1024_characters() -> None:
    assert validate_password("a" * 1024) == "a" * 1024
    with pytest.raises(ValueError, match="1024"):
        validate_password("a" * 1025)


def test_hash_is_not_the_plain_password_and_verifies() -> None:
    password_hash: str = hash_password("correct-horse")
    assert password_hash != "correct-horse"
    assert verify_password("correct-horse", password_hash) is True


def test_wrong_password_does_not_verify() -> None:
    assert verify_password("wrong-password", hash_password("correct-horse")) is False


def test_same_password_gets_a_different_hash_each_time() -> None:
    assert hash_password("correct-horse") != hash_password("correct-horse")


def test_malformed_hash_does_not_verify_and_does_not_raise() -> None:
    assert verify_password("correct-horse", "not-a-real-hash") is False
