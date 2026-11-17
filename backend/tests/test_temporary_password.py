import pytest

from app.security import TEMPORARY_PASSWORD_ALPHABET, generate_temporary_password, validate_password

AMBIGUOUS: str = "0O1lIo"


def test_temporary_password_is_12_readable_characters() -> None:
    password: str = generate_temporary_password()
    assert len(password) == 12
    assert password.isalnum() and password.isascii()
    assert not any(char in password for char in AMBIGUOUS)


def test_temporary_password_satisfies_the_password_rule() -> None:
    assert validate_password(generate_temporary_password())


def test_temporary_passwords_do_not_repeat() -> None:
    passwords: set[str] = {generate_temporary_password() for _ in range(2000)}
    assert len(passwords) == 2000


def test_temporary_password_draws_from_the_whole_alphabet() -> None:
    seen: set[str] = set("".join(generate_temporary_password() for _ in range(500)))
    assert len(seen) >= 45  # 56자 중 대부분이 나온다(한쪽으로 치우치지 않았다)


def test_temporary_password_comes_from_the_secrets_module_not_a_predictable_generator(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    calls: list[int] = []

    def fake_choice(alphabet: str) -> str:
        calls.append(1)
        return alphabet[0]

    monkeypatch.setattr("app.security.secrets.choice", fake_choice)
    assert generate_temporary_password() == TEMPORARY_PASSWORD_ALPHABET[0] * 12
    assert len(calls) == 12
