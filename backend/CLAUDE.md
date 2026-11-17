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

### Hermes 연동

- 백엔드는 이 PC의 Hermes API 서버(`http://127.0.0.1:8642`)를 `app/hermes.py`의 `HermesClient.stream_chat()`으로 호출합니다(`/v1/chat/completions`, 스트림).
- 키(`HERMES_API_KEY`)는 `backend/.env`에만 둡니다. Hermes 쪽은 `~/.hermes/.env`에 `API_SERVER_ENABLED=true`와 `API_SERVER_KEY`를 두고 `hermes gateway restart`로 적용합니다. 설정과 재시작 전에는 `~/.hermes/gateway_state.json`의 `active_agents`가 0인지 확인합니다.
- Hermes 통합 테스트(`hermes` 표시)는 API 서버가 떠 있어야 하고 실제 모델을 호출하므로 비용이 듭니다. `HERMES_API_KEY`가 없으면 건너뜁니다.
- 스트림이 `[DONE]` 없이 끝나면(Hermes 재시작 등) 정상 완료가 아니라 `HermesError`입니다. 클라이언트는 `create_hermes_client(settings)`로 만들며, 키가 없으면 `HermesError`가 납니다.
- 이 키는 Hermes의 terminal 명령 실행까지 열어 줍니다. 키와 `backend/.env`(권한 600)를 클라이언트나 저장소에 노출하지 않습니다.
- 확인된 동작(#10, 2026-11-17): (1) 메시지 하나가 65,536자를 넘으면 Hermes가 오류 없이 끝부분을 자릅니다. 질문 길이 한도는 백엔드가 막아야 합니다. (2) 스트림 연결을 끊으면 Hermes의 실행도 약 2초 안에 멈춥니다. (3) Hermes에 옵시디언 저장을 시키면 `obsidian-notion-sync`가 Notion에도 반영합니다. 테스트에서 저장 요청을 보낼 때 주의합니다.

### 마이그레이션 도구

마이그레이션은 Alembic(SQLAlchemy)을 씁니다. 새 테이블 모델은 `app/db.py`의 `Base`를 상속해 `app/models.py`에 두면 `migrations/env.py`가 등록합니다(`uv run alembic revision --autogenerate -m "설명"`으로 변경분을 만들고, 만들어진 파일을 반드시 읽어서 확인합니다). 기준 마이그레이션(`0001`)은 비어 있고, `0002`가 `accounts` 테이블을 만듭니다.
