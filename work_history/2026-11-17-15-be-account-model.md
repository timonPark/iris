# [be] 계정 모델과 초기 관리자 계정 주입

| 항목 | 내용 |
|---|---|
| 이슈 | #15 (https://github.com/timonPark/iris/issues/15) |
| 브랜치 | 2026-11-17-15-be-account-model |
| 상태 | 검증 대기 |
| 시작일자 | 2026-11-17 |
| 종료일자 | |

## 작업 내용

계정은 관리자만 만든다. 첫 관리자 계정은 설정(.env)으로 주입한다.

### 범위
- [x] 계정 저장 모델(아이디, 비밀번호 해시, 역할, 상태, 비밀번호 변경 시각, 임시 비밀번호 사용 여부)
- [x] 아이디 규칙: 영문 소문자·숫자 4~20자, 중복 불가
- [x] 비밀번호 규칙: 8자 이상, 복잡도 규칙 없음
- [x] .env로 첫 관리자 계정 생성

제외: 회원가입, 계정 삭제

### 완료 조건
- [x] 마이그레이션이 적용된다.
- [x] 첫 기동 시 .env의 관리자 계정이 생성된다.
- [x] 아이디와 비밀번호 규칙 검증 테스트가 통과한다.

### 결정 필요
없음 (이슈 기준)

## 설계 (Claude가 정함)
- 테이블 `accounts`: `id`(UUID), `login_id`(unique, 영문 소문자·숫자 4~20자 CHECK), `password_hash`, `role`(`admin`/`user`), `status`(`active`/`blocked`), `password_changed_at`(발급 시각이 이보다 이르면 토큰 거부, #16), `password_change_required`(임시 비밀번호 상태), `created_at`. 이름과 값은 `docs/api/openapi.yaml`(`Role`, `UserStatus`, `User`)과 `ssot/GLOSSARY.md`를 따른다.
- 비밀번호 해시는 argon2(`argon2-cffi`).
- 아이디와 비밀번호 규칙은 `app/security.py` 함수로 검증하고, 아이디 규칙은 DB CHECK로도 막는다(이중 방어).
- 첫 관리자는 앱 시작(lifespan)에서 `ADMIN_LOGIN_ID`, `ADMIN_PASSWORD`로 만든다. 같은 아이디가 이미 있으면 만들지 않는다(그 아이디가 사용자 계정이면 오류). 둘 다 없으면 경고만 남기고 건너뛴다. 하나만 있거나 규칙에 맞지 않으면 시작을 중단한다.
- 첫 사용처라서 앞의 리뷰에서 미뤄 둔 "엔진과 세션 팩토리 공유"를 이번에 만들었다(앱 시작 때 하나를 만들어 `app.state.session_factory`에 둔다).
- DB 테스트는 개발 DB(`iris`)가 아니라 같은 서버의 `iris_test` DB에서 돌린다(없으면 테스트가 만들고 마이그레이션을 적용한다). 대부분 매번 트랜잭션을 되돌리고, 앱 시작 테스트만 직접 저장하고 지운다. (처음에는 개발 DB를 썼다가 코드 리뷰 지적으로 분리함.)

## 진행 기록
- 2026-11-17 브랜치와 작업 파일 생성. 선행 #8, #9 닫힘 확인.
- 2026-11-17 `argon2-cffi` 추가. 테스트를 먼저 써서 실패(수집 오류)를 확인한 뒤 구현해 통과시킴(TDD).
- 2026-11-17 `alembic revision --autogenerate`로 `0002_create_accounts`를 만들고 내용을 읽어 확인. 적용, `downgrade -1`, 다시 적용까지 확인.
- 2026-11-17 20자 초과 아이디 테스트가 `IntegrityError`가 아니라 `DataError`로 실패. 제품 문제가 아니라(열 길이 제한이 막음) 테스트 기대값 문제라서 두 예외를 모두 허용하도록 고침.
- 2026-11-17 `backend/.env`에 `ADMIN_LOGIN_ID=admin`과 무작위 `ADMIN_PASSWORD`를 추가(화면에 출력하지 않음). 앱을 실제로 두 번 시작해 확인.
- 2026-11-17 코드 리뷰: `codex`, `agy`가 없어 `/code-review`(medium)로 대신함(이전 이슈에서 사용자가 승인한 방식). 지적을 판단해 반영(테스트를 먼저 추가해 실패 3개를 확인한 뒤 구현)하고 PR 생성, 상태를 `검증 대기`로 변경.

## 결과

### 변경한 파일
- 신규: `backend/app/{models,security,accounts}.py`, `backend/migrations/versions/0002_create_accounts.py`, `backend/tests/{conftest,test_security,test_accounts}.py`, 이 파일
- 수정: `backend/app/{config,db,main}.py`, `backend/migrations/env.py`, `backend/pyproject.toml`/`uv.lock`(argon2-cffi), `backend/.env.example`, `backend/CLAUDE.md`
- 커밋하지 않음: `backend/.env`(관리자 비밀번호 포함, 권한 600)

### 확인 방법과 결과
- 테스트: `cd backend && uv run pytest` → 61 passed. `-m "not integration"` → 45 passed. 테스트는 `iris_test` DB에서 돌고, 테스트 후 `iris_test.accounts`가 0건, 개발 DB(`iris`)에는 실제 관리자 `admin` 1건만 그대로 있음을 확인.
- **마이그레이션이 적용된다**: `alembic upgrade head` → `0002 (head)`, `\d accounts`로 열, 유일 제약, CHECK 3개(아이디 형식, 역할, 상태) 확인. `downgrade -1`로 `0001`까지 되돌렸다가 다시 `0002`로 적용.
- **첫 기동 시 관리자 계정이 생성된다**: 계정이 0개인 상태에서 `uvicorn`을 시작 → 1개 생성. 다시 시작해도 1개(중복 없음). 생성된 계정: 아이디 `admin`, 역할 `admin`, 상태 `active`, 임시 비밀번호 상태 false, 해시는 `$argon2id$` 형식이고 평문이 아니며 `.env`의 비밀번호로 검증되고 틀린 비밀번호는 거부됨.
- **규칙 검증 테스트**: 아이디(유효 5, 무효 10 케이스)와 비밀번호(복잡도 없는 8자 허용, 7자 이하 거부) 테스트 통과. 해시 테스트(평문 아님, 같은 비밀번호도 매번 다른 해시, 잘못된 해시는 예외 없이 거부) 통과.
- 비밀값: 관리자 비밀번호 문자열이 `.env` 밖 파일에 0건, `git add -n` 대상에 `.env` 없음.
- 리뷰 반영 후 재확인: 개발 DB에 대해 앱을 다시 시작 → 경고와 오류 없이 시작, 계정 1개 유지.
- 확인하지 못한 것: (1) 앱 시작 로그(`관리자 계정 '...': 만들었습니다`)가 화면에 나오는지. 앱 로거에 로깅 설정이 없어 INFO 로그가 uvicorn 출력에 나타나지 않는다(동작에는 영향 없음, 경고 로그는 출력됨). (2) `ADMIN_*`를 비운 채 실제로 앱을 띄우는 시나리오. 실행 명령이 불완전해 실제로는 돌리지 못했고, 단위 테스트(`test_create_initial_admin_*`)로만 확인했다. (3) 경고 로그가 실제 uvicorn 출력에 어떻게 보이는지(테스트는 `caplog`로 확인).

### 코드 리뷰 반영 내역
지적 9건 중 6건 반영, 3건 넘어감.
- 반영(보안): `.env.example`의 관리자 계정을 주석 처리. 예시 값을 그대로 복사하면 공개된 비밀번호(`change-me-please`)로 관리자가 만들어지는 문제. `CLAUDE.md`의 처음 설정 단계에 `ADMIN_*`와 `chmod 600` 안내 추가
- 반영: 동시 기동 경합. 저장을 `begin_nested()`로 감싸고 유일 제약 오류(`IntegrityError`)를 "이미 있음"으로 처리. `find_account`를 분리해 경합 상황을 테스트(조회는 못 찾았는데 이미 있는 경우)
- 반영: 이미 있는 관리자가 차단되었거나 `.env` 비밀번호와 다르면 경고 로그(비밀번호 값은 로그에 남기지 않음을 테스트). 복구 방법 자체는 범위 밖(아래 남은 일)
- 반영: `database_url`을 `URL.create`로 만들어 사용자·호스트·DB 이름도 안전하게 인코딩. 다만 리뷰가 든 구체적 실패 상황은 기존 코드로도 재현되지 않았다(회귀 방지 테스트만 추가)
- 반영: 별도 테스트 DB `iris_test`로 분리(개발 DB에 진짜 관리자가 생겼기 때문). `ensure_test_database` fixture가 없으면 만든다
- 반영: 시작 시 `create_initial_admin`을 `run_in_threadpool`로 실행(이벤트 루프를 막지 않음), 엔진을 `app.state.engine`에 보관
- 넘어감: 비밀번호 최대 길이와 `check_needs_rehash`. 규칙은 이슈와 `openapi.yaml`에 "8자 이상"으로 정해져 있어 임의로 바꾸지 않음. 요청 크기 제한과 재해시는 로그인·비밀번호 변경을 만드는 #16, #17에서 다룸
- 넘어감: DB 서버 기본값(`server_default`) 없음. 모든 쓰기가 ORM을 거치고 직접 SQL 삽입은 현재 없음
- 넘어감: `compare_type`, `compare_server_default`. Alembic 1.20은 `compare_type`이 이미 기본으로 켜져 있고 서버 기본값은 아직 없음

### PR
- (PR 생성 후 기입)

### 남은 일 / 관찰
- **관리자 비밀번호를 설정으로 바꾸는 방법이 없다.** 문서(`openapi.yaml`의 비밀번호 변경 설명, #20)는 "관리자 계정의 비밀번호는 설정으로만 변경"이라고 하는데, 이 이슈는 "첫 생성"까지만 정의한다. 계정이 만들어진 뒤 `.env`의 `ADMIN_PASSWORD`를 바꿔도 반영되지 않는다. 별도 이슈가 필요하다.
- 차단된 관리자를 되살리는 방법도 없다. 관리자는 관리자 웹에서 다루지 않고(용어집) 계정 삭제도 없어서, 유일한 관리자가 차단되면 DB를 직접 고치는 방법밖에 없다.
- 로그인(#16)과 비밀번호 변경(#17)을 만들 때 비밀번호 요청 크기 제한과 argon2 재해시(`check_needs_rehash`)를 다뤄야 한다(리뷰 지적).
- 앱 로거 설정이 없어 INFO 로그가 보이지 않는다.
- GitHub Project 상태는 `gh` 토큰에 `project` 권한이 없어 갱신하지 못했다.
