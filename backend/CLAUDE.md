# backend

## 기준 문서

- 용어와 개념은 `../ssot/`를 기준으로 작업합니다. backend의 코드, 변수명, 화면 문구도 `../ssot/`의 용어를 따릅니다.
- `../ssot/`에 정의가 없거나 모호하면 임의로 정하지 말고 먼저 묻습니다.

## 행동 지침

루트 CLAUDE.md의 행동 지침을 따르며, backend에서는 이렇게 적용합니다.

- **먼저 묻기**: API 규격이 비어 있거나 모호하면 추측으로 구현하지 않고 `docs/` 규격부터 확인합니다. 대화 맥락 전달 방식, 동시 요청 처리, 대화 보관 기간은 미결정이므로 임의로 정하지 않습니다.
- **단순하게**: 문서에 없는 기능(회원가입, 관리자의 대화 열람)은 만들지 않습니다. 동시 요청 제한 같은 것은 요청이 있을 때 추가합니다.
- **필요한 곳만**: 관리자 API와 사용자 API의 경로 분리, 관리자 권한 검사 구조를 임의로 바꾸지 않습니다.
- **검증 먼저**: 인증과 권한 검사는 테스트부터 씁니다. 음성 파이프라인(변환 → 인식 → 보정 → Hermes 전송 → 파일 삭제)은 단계별 검증 기준을 정하고 구현합니다.

## 명령어

Python 프로젝트는 `uv`로 관리합니다. 아래 `backend/` 명령은 모두 `backend/` 폴더에서 실행합니다.

### 처음 한 번

```bash
cp .env.example .env        # 그리고 POSTGRES_PASSWORD, ADMIN_LOGIN_ID, ADMIN_PASSWORD 를 정한다 (.env 는 커밋하지 않는다)
chmod 600 .env              # 비밀값이 들어 있으니 본인만 읽게 한다
uv sync                     # 의존성 설치
```

### PostgreSQL (저장소 루트에서)

```bash
docker compose --env-file backend/.env up -d db    # 시작 (iris-postgres, 127.0.0.1:5433)
docker compose --env-file backend/.env down        # 중지 (데이터는 iris-postgres-data 볼륨에 남는다)
```

이 PC에는 다른 프로젝트의 PostgreSQL(n8n)이 있어서 호스트 포트 5433, 컨테이너 `iris-postgres`, 볼륨 `iris-postgres-data`를 씁니다. 다른 컨테이너는 건드리지 않습니다.

### 실행, 테스트, 마이그레이션

```bash
uv run uvicorn app.main:app --reload --port 8000   # 실행. http://127.0.0.1:8000/docs
uv run pytest                                      # 전체 테스트 (integration 테스트는 PostgreSQL이 떠 있어야 한다)
uv run pytest -m "not integration"                 # 외부 시스템(DB, Hermes) 없이 돌릴 수 있는 테스트만
uv run pytest -m "not hermes"                      # 실제 Hermes 모델 호출(비용)만 빼고 전부
uv run alembic revision -m "설명"                  # 마이그레이션 파일 만들기
uv run alembic upgrade head                        # 마이그레이션 적용
uv run alembic current                             # 현재 적용된 버전 확인
```

- 셸에 `VIRTUAL_ENV`가 다른 환경으로 잡혀 있으면 `uv`가 경고를 내고 무시합니다. 동작에는 문제가 없습니다.
- DB 접속 정보는 `backend/.env`에만 둡니다(`alembic.ini`에 쓰지 않습니다). 변수 이름은 `app/config.py`와 `docker-compose.yml`이 같이 씁니다.

### 계정과 첫 관리자

- 계정 모델은 `app/models.py`의 `Account`(테이블 `accounts`)입니다. 역할은 `admin`/`user`, 상태는 `active`/`blocked`이고 `docs/api/openapi.yaml`, `ssot/GLOSSARY.md`와 이름이 같습니다. 계정 삭제는 없습니다.
- 아이디(영문 소문자·숫자 4~20자)와 비밀번호(8자 이상, 복잡도 규칙 없음) 규칙은 `app/security.py`가 검증하고, 아이디 규칙은 DB CHECK로도 막습니다. 비밀번호는 argon2 해시로만 저장합니다.
- 첫 관리자는 `backend/.env`의 `ADMIN_LOGIN_ID`, `ADMIN_PASSWORD`로 앱을 시작할 때 만들어집니다(`app/accounts.py`). 같은 아이디가 이미 있으면 만들지 않고, 둘 중 하나만 있거나 규칙에 맞지 않으면 시작이 중단됩니다.
- **주의**: 관리자 계정이 만들어진 뒤에 `.env`의 `ADMIN_PASSWORD`를 바꿔도 반영되지 않습니다(이슈 #15는 "첫 생성"까지). 시작할 때 비밀번호가 다르거나 관리자가 차단되어 있으면 경고 로그를 남기지만, 관리자 비밀번호를 설정으로 바꾸거나 차단된 관리자를 되살리는 방법은 아직 없습니다.
- DB를 쓰는 테스트는 개발 DB(`iris`)가 아니라 같은 서버의 `iris_test` DB에서 돕니다(없으면 테스트가 만들고 마이그레이션을 적용합니다). 대부분 매번 변경을 되돌리고, 앱 시작 테스트만 직접 저장하고 지웁니다. 그래서 `.env`의 실제 관리자 계정은 테스트에 영향을 받지 않습니다.
- 앱 로거에 설정이 없어 INFO 로그(`관리자 계정 '...': 만들었습니다`)는 uvicorn 출력에 나오지 않고, 경고는 나옵니다.

### 로그인과 요청마다 하는 검사

- `POST /api/v1/auth/login`(`app/auth.py`)이 아이디·비밀번호를 확인하고 accessToken(JWT, HS256)을 줍니다. 토큰에는 `sub`(계정 id)와 `iat`(발급 시각, 마이크로초까지)만 있고 **만료(`exp`)가 없습니다**. 서명 키는 `backend/.env`의 `JWT_SECRET`(32자 이상)이며, 없거나 짧으면 앱이 시작하지 않습니다. 키를 바꾸면 발급된 모든 토큰이 무효가 됩니다.
- 만료가 없으므로 **요청마다** 계정을 DB에서 조회해 검사합니다(`authorize`). 순서: 토큰 오류·계정 없음·발급 시각이 `password_changed_at`보다 이름 → 401 `UNAUTHORIZED`, 차단 → 403 `ACCOUNT_BLOCKED`, 임시 비밀번호 상태 → 403 `PASSWORD_CHANGE_REQUIRED`.
- 보호할 경로에는 `Depends(current_account)`를 씁니다. 비밀번호 변경 API(#17)만 `Depends(current_account_for_password_change)`를 써서 임시 비밀번호 상태를 통과시킵니다.
- 비밀번호 변경은 `POST /api/v1/auth/password`입니다. 임시 비밀번호 상태에서는 새 비밀번호만, 평소에는 현재 비밀번호와 새 비밀번호를 받고, 관리자 계정은 403 `FORBIDDEN`입니다(관리자 비밀번호는 설정으로만 바꿉니다). 변경하면 `password_changed_at`이 갱신되어 이전 토큰이 모두 무효가 되고 응답으로 새 토큰을 줍니다. 비밀번호는 8자 이상 1024자 이하입니다(`app/security.py`, 요청 크기 제한). 새 비밀번호는 지금 비밀번호(임시 비밀번호 포함)와 달라야 하고, 같은 계정의 동시 변경은 행 잠금으로 순서대로 처리됩니다.
- 오류는 `raise ApiError(...)`(또는 `app/errors.py`의 `unauthorized()` 같은 함수)로 던지면 `{"error": {"code", "message"}}` 형식이 됩니다. 코드와 문구는 `docs/api/openapi.yaml`과 같습니다. 입력 값 오류는 422 `VALIDATION_FAILED`, 처리하지 못한 예외는 500 `SERVER_ERROR`입니다. 단, 없는 경로(404)와 허용하지 않는 메서드(405)는 규격에 오류 코드가 없어서 프레임워크 기본 응답(`{"detail": ...}`)을 그대로 씁니다.
- 로그인은 비밀번호를 먼저 확인한 뒤에만 "차단됨"을 알리고, 없는 아이디도 해시 검증을 거칩니다(계정 존재 여부와 차단 여부를 응답으로 알 수 없게).
- 테스트에서는 `app_client`(앱 시작까지 실행), `account_factory`(저장되는 계정 생성), 테스트 전용 경로(`/_test/...`, `tests/conftest.py`)를 씁니다. 제품 엔드포인트가 아닙니다.
- **알려진 빈틈**: 로그인 시도 횟수 제한이 없습니다. 서버 쪽 로그아웃이 없어 토큰을 폐기하려면 비밀번호를 바꾸거나 계정을 차단해야 합니다(이슈 범위 밖).

### 세션, 질문, 답변 (대화 기록)

- 테이블은 `chat_sessions`(세션), `questions`, `answers`입니다(`app/models.py`). 세션 모델 이름은 SQLAlchemy의 `Session`과 겹치지 않게 `ChatSession`입니다. 질문 하나에 답변은 하나이고 둘은 한 트랜잭션으로 저장합니다. 답변 상태는 `completed`/`stopped`입니다.
- **질문을 저장하는 길은 `app/chat.py`의 `save_exchange()` 하나입니다.** 세션이 없으면(첫 질문) 세션도 만들고 이름은 첫 질문의 앞 30자입니다. 질문이 65,536자를 넘으면 `QUESTION_TOO_LONG`, 비어 있으면 `VALIDATION_FAILED`로 아무것도 저장하지 않습니다(질문 길이는 DB CHECK로도 막습니다). 질문을 받는 엔드포인트와 Hermes 호출은 #23의 몫이고, 그쪽이 이 함수를 씁니다.
- **내 세션만** 다룹니다(`find_own_session`). 다른 사용자의 세션, 삭제된 세션, 없는 세션, UUID가 아닌 값은 모두 같은 404 `SESSION_NOT_FOUND`입니다(존재 여부를 알려 주지 않음). 삭제된 세션에 질문을 저장하려 해도 같습니다.
- 삭제는 `deleted_at`만 채웁니다(soft delete). 목록·열람·삭제·질문 저장에서 보이지 않을 뿐 질문과 답변은 DB에 남고, 복구나 영구 삭제는 없습니다.
- 목록은 위치 기준(keyset) 커서로 나눠서 호출합니다(`app/pagination.py`). 세션은 최근 활동 순(`updated_at`, 같으면 `id` 내림차순), 세션 안의 질문은 최신 질문부터입니다. 같은 시각의 항목도 정렬 보조키(`id`) 덕분에 한 번씩만 나옵니다. 잘못된 `cursor`나 범위 밖 `limit`(1~100, 기본 20)는 422 `VALIDATION_FAILED`입니다. 커서에는 어느 목록의 것인지(범위)가 들어 있어서 다른 목록이나 다른 세션에 쓰면 같은 오류이고, 극단적인 시각 값도 서버 오류가 아니라 422입니다. 새 목록은 `keyset_page()`를 쓰면 이 규칙을 그대로 얻습니다.
- 질문에 NUL 문자나 UTF-8로 바꿀 수 없는 문자가 있으면 저장 단계에서 서버 오류가 나므로 422로 거부합니다. 반대로 **답변**은 Hermes가 이미 답한 뒤라서 거부하지 않고 문제 문자만 정리해서 저장합니다(NUL은 지우고 나머지는 `\\ufffd`). 최근 활동 시각은 DB에서 `GREATEST`로 갱신해 뒤로 가지 않습니다.
- 테스트에서는 `chat_factory`(저장되는 대화 기록 생성기, `at=`으로 시각 지정)를 씁니다.

### 질문 전송(SSE)과 중지 (`app/runs.py`, `app/sessions.py`)

- `POST /api/v1/sessions/questions`는 질문을 받아 Hermes에 보내고 답변을 SSE로 돌려줍니다. **질문 하나의 처리는 요청과 분리된 작업(`ChatRun`)입니다.** SSE 응답은 그 작업이 내보내는 이벤트를 읽어 흘려보내기만 해서, 클라이언트가 끊겨도(모바일 앱이 백그라운드로 가도) 작업은 Hermes 답변을 끝까지 받아 저장합니다. 답변을 멈추는 길은 `POST /sessions/{id}/stop` 하나입니다.
- 맥락은 이 서버가 기준입니다. 질문마다 `load_context()`가 그 세션의 이전 질문과 답변을 모두 오래된 순으로 꺼내 새 질문과 함께 Hermes에 보냅니다(길이 한도 없음). 빈 답변(곧바로 중지한 것)은 `(답변 없이 중단됨)`으로 대신합니다.
- 처리 순서: 질문 검사(422) → 같은 세션에 진행 중인 작업이 있으면 `SESSION_BUSY`(409, 남의 세션이면 없는 세션 404) → **작업을 먼저 등록**(확인과 등록 사이에 `await`가 없어서 동시에 온 두 요청 중 하나만 등록됨) → 내 세션인지 확인하고 맥락을 읽은 뒤 DB 연결을 바로 반납 → 작업 시작 → Hermes가 스트림을 열 때까지 기다림(실패하면 500 JSON, 아무것도 저장하지 않음) → SSE 시작. 새 세션의 ID는 미리 정해 `session` 이벤트로 알리고 DB 행은 답변을 저장할 때 만들어집니다.
- 결과별 저장: 완료는 `completed`로 `done`, 중지는 받은 부분(비어 있어도)을 `stopped`로 `stopped`. Hermes 오류는(`HermesError`가 아닌 전송 계층 예외도 포함) 받은 조각이 있으면 `stopped`로 저장하고 `error` 이벤트, 없으면 저장하지 않고 `error` 이벤트만. Hermes에 연결하는 중에 중지하면 오류가 아니라 빈 `stopped` 답변입니다. 질문은 **질문한 시각**(`asked_at`)으로 저장하고 답변과 세션의 최근 활동은 답변이 끝난 시각입니다. Hermes가 답을 하나도 보내지 않고 끝나면 오류입니다(빈 답변을 저장하면 이후 맥락이 깨집니다).
- 작업 등록부(`RunRegistry`)는 메모리에 있어서 **서버 프로세스가 하나일 때만 정확합니다.** `uvicorn --workers`로 여러 개를 띄우면 `SESSION_BUSY`와 중지가 어긋납니다. 서버를 끄면 진행 중인 작업은 멈추고 받은 부분을 저장합니다.
- 15초마다 `: keepalive` 주석 줄을 보냅니다(터널이 조용한 연결을 끊지 않도록).
- Hermes를 부르는 쪽은 `ChatBackend`(`open_chat`)입니다. 테스트에서는 `tests/fakes.py`의 `FakeHermes`(조각, 지연, 멈춤, 오류를 지정)를 `app.state.hermes`에 넣습니다. 스트리밍 도중의 동작(중지, 연결 끊김, 동시 요청)은 `TestClient`가 응답을 끝까지 모아서 확인할 수 없으므로 실제 소켓으로 접속하는 `live_server` fixture(`tests/conftest.py`)로 검증합니다.
- 알려진 한계: 맥락 길이에 한도를 두지 않습니다(이슈의 지시). 긴 세션에서 이전 질문·답변 전체가 모델의 한도를 넘으면 Hermes 오류로 질문이 500 `SERVER_ERROR`가 됩니다. 요청 본문 크기도 제한하지 않습니다(65,536자 검사는 읽은 뒤에 합니다). 응답이 시작되기도 전에 클라이언트가 끊기면 작업은 계속되고 이벤트 큐가 답변 하나의 크기만큼 쌓였다가 사라집니다. Hermes의 동시 실행 한도(기본 10, 넘으면 429)에 걸리면 질문은 500 `SERVER_ERROR`가 됩니다.

### Hermes 연동

- 백엔드는 이 PC의 Hermes API 서버(`http://127.0.0.1:8642`)를 `app/hermes.py`의 `HermesClient.stream_chat()`으로 호출합니다(`/v1/chat/completions`, 스트림).
- 키(`HERMES_API_KEY`)는 `backend/.env`에만 둡니다. Hermes 쪽은 `~/.hermes/.env`에 `API_SERVER_ENABLED=true`와 `API_SERVER_KEY`를 두고 `hermes gateway restart`로 적용합니다. 설정과 재시작 전에는 `~/.hermes/gateway_state.json`의 `active_agents`가 0인지 확인합니다.
- Hermes 통합 테스트(`hermes` 표시)는 API 서버가 떠 있어야 하고 실제 모델을 호출하므로 비용이 듭니다. `HERMES_API_KEY`가 없으면 건너뜁니다.
- 스트림이 `[DONE]` 없이 끝나면(Hermes 재시작 등) 정상 완료가 아니라 `HermesError`입니다. 클라이언트는 `create_hermes_client(settings)`로 만들며, 키가 없으면 `HermesError`가 납니다.
- 이 키는 Hermes의 terminal 명령 실행까지 열어 줍니다. 키와 `backend/.env`(권한 600)를 클라이언트나 저장소에 노출하지 않습니다.
- 확인된 동작(#10, 2026-11-17): (1) 메시지 하나가 65,536자를 넘으면 Hermes가 오류 없이 끝부분을 자릅니다. 질문 길이 한도는 백엔드가 막아야 합니다. (2) 스트림 연결을 끊으면 Hermes의 실행도 약 2초 안에 멈춥니다. (3) Hermes에 옵시디언 저장을 시키면 `obsidian-notion-sync`가 Notion에도 반영합니다. 테스트에서 저장 요청을 보낼 때 주의합니다.

### 마이그레이션 도구

마이그레이션은 Alembic(SQLAlchemy)을 씁니다. 새 테이블 모델은 `app/db.py`의 `Base`를 상속해 `app/models.py`에 두면 `migrations/env.py`가 등록합니다(`uv run alembic revision --autogenerate -m "설명"`으로 변경분을 만들고, 만들어진 파일을 반드시 읽어서 확인합니다). 기준 마이그레이션(`0001`)은 비어 있고, `0002`가 `accounts` 테이블을 만듭니다.
