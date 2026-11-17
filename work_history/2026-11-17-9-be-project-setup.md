# [be] 프로젝트 세팅 (FastAPI, docker-compose PostgreSQL)

| 항목 | 내용 |
|---|---|
| 이슈 | #9 (https://github.com/timonPark/iris/issues/9) |
| 브랜치 | 2026-11-17-9-be-project-setup |
| 상태 | 검증 대기 |
| 시작일자 | 2026-11-17 |
| 종료일자 | |

## 작업 내용

백엔드는 이 PC에서 직접 실행하고, PostgreSQL만 docker-compose로 실행한다(whisper, Claude, Hermes 접근을 그대로 쓰기 위해).

### 범위
- [x] `backend/` FastAPI 프로젝트 구조
- [x] 실행 방법
- [x] 루트 `docker-compose.yml` (PostgreSQL만)
- [x] 환경 변수(.env) 구성
- [x] `backend/CLAUDE.md`에 실행·테스트 명령 채우기

제외: 도메인 로직(계정, 세션 등)

### 완료 조건
- [x] 백엔드가 로컬에서 실행된다.
- [x] PostgreSQL이 docker-compose로 뜨고 백엔드가 연결된다.
- [x] `backend/CLAUDE.md`에 명령어가 적혀 있다.

### 결정 필요
- [x] DB 마이그레이션 도구: Alembic(SQLAlchemy 2.0)으로 정함. 이슈와 규칙에서 근거를 찾아 Claude가 정했고(사용자는 "추천을 가져오라"고 지시), `ssot/adr/0002-db-migration-alembic.md`에 기록함.

### 사용자 요청 (대화에서)
- 기존 Docker 컨테이너(`n8n-n8n-1`: 호스트 5678, `n8n-postgres-1`: 내부 5432)와 포트가 겹치지 않게 한다. PostgreSQL 호스트 포트는 5433, 컨테이너와 볼륨 이름은 `iris-` 접두어(`iris-postgres`, `iris-postgres-data`)를 쓴다. 기존 컨테이너는 건드리지 않는다. → 반영함.

## 진행 기록
- 2026-11-17 브랜치와 작업 파일 생성. 선행 이슈 없음. 호스트 5433 포트가 비어 있음을 확인.
- 2026-11-17 결정: 마이그레이션 도구는 Alembic(SQLAlchemy 2.0). 근거는 #15, #22(계정·세션 모델과 "마이그레이션이 적용된다"), 규칙(타입 힌트, Pydantic, TDD), 소규모 PostgreSQL 하나.
- 2026-11-17 `uv`로 프로젝트 초기화(`uv init --bare`)와 의존성 설치. 테스트를 먼저 써서 실패(수집 오류)를 확인한 뒤 구현해 통과시킴(TDD).
- 2026-11-17 pytest가 `app`을 못 찾는 문제를 `pyproject.toml`의 `pythonpath = ["."]`로 해결.
- 2026-11-17 `docker compose`로 `iris-postgres` 실행(127.0.0.1:5433, healthy). 기존 n8n 컨테이너는 그대로.
- 2026-11-17 Alembic 연결: `migrations/env.py`가 `app.config`의 DB 정보와 `Base.metadata`를 쓴다. `alembic.ini`에는 접속 정보를 적지 않는다. 기준 마이그레이션 `0001`(비어 있음) 적용.
- 2026-11-17 코드 리뷰: `codex`, `agy`가 없어 `/code-review`(medium)로 대신함(이전 이슈에서 사용자가 승인한 방식).

## 결과

### 변경한 파일
- 신규: `.gitignore`, `docker-compose.yml`, `backend/pyproject.toml`, `backend/uv.lock`, `backend/.env.example`, `backend/alembic.ini`, `backend/app/{__init__,config,db,main}.py`, `backend/migrations/{env.py,script.py.mako,README,versions/0001_baseline.py}`, `backend/tests/{test_config,test_app,test_db}.py`, `ssot/adr/0002-db-migration-alembic.md`, 이 파일
- 수정: `backend/CLAUDE.md`(명령어), `backend/README.md`(상태), `README.md`(docker-compose 표기)
- 커밋하지 않음: `backend/.env`(비밀번호 포함, `.gitignore`로 제외)

### 확인 방법과 결과
- 테스트: `cd backend && uv run pytest` → 7 passed (설정 4, 앱 2, DB 연결 1).
- 백엔드 실행: `uv run uvicorn app.main:app --port 8000` 실행 후 `GET /openapi.json` → 200(`info.title` = "Iris"), `GET /docs` → 200. 확인 뒤 서버 종료.
- PostgreSQL: `docker compose --env-file backend/.env up -d db` → `iris-postgres` healthy, `127.0.0.1:5433->5432`. `docker ps`에서 `n8n-n8n-1`(5678), `n8n-postgres-1`이 그대로 실행 중임을 확인.
- 백엔드와 DB 연결: `test_backend_connects_to_postgres`(`SELECT 1`) 통과. `alembic upgrade head` 성공, `alembic current` → `0001 (head)`, DB에 `alembic_version` 테이블 생성 확인.
- 비밀번호 유출 검사: `.env` 밖 파일에서 비밀번호 문자열 검색 → 0건, `git add -n .` 대상에 `.env` 없음.
- 확인하지 못한 것: `alembic downgrade`(기준 마이그레이션이 비어 있어 의미가 없음), 컨테이너 재시작 후 데이터 유지(볼륨 설정은 있으나 재시작 시험은 하지 않음).

### 코드 리뷰 반영 내역
지적 10건 중 6건 반영, 4건 넘어감.
- 반영: `.env` 경로를 실행 위치가 아니라 `app/config.py` 파일 위치 기준으로 고정 (저장소 루트에서 실행해도 읽힘을 확인)
- 반영: 설정 테스트가 셸의 `POSTGRES_*` 값에 영향받지 않도록 환경 변수를 비우는 fixture 추가 (`POSTGRES_PASSWORD=leak POSTGRES_PORT=9999`를 주고 돌려 4개 통과 확인)
- 반영: DB 테스트에 `integration` 표시를 달고 `pytest -m "not integration"`으로 DB 없이 6개만 돌릴 수 있게 함
- 반영: `migrations/env.py`의 `fileConfig(..., disable_existing_loggers=False)`, 엔진 `dispose`(`try/finally`)
- 반영: 변수 타입 표기 추가(`response: Response`, `engine: Engine`, `config: Config`). `with ... as` 변수는 문법상 표기할 수 없어 그대로 둠
- 반영: `.env.example`에 비밀번호에 `$`를 쓰지 말라는 주의 추가
- 넘어감: `compare_type=True` 추가. Alembic 1.20은 기본값이 이미 켜져 있어 사실과 다름
- 넘어감: 작업 파일이 오래되었다는 지적. 리뷰가 파일을 고치기 전 버전을 읽은 것이고 지금은 채워져 있음
- 넘어감: 기준 마이그레이션의 미사용 import. Alembic 템플릿이 만든 파일이고 린트 규칙이 없음
- 넘어감: 엔진을 호출마다 생성하는 `create_db_engine`을 공유 엔진, 세션 팩토리로 바꾸기. DB를 쓰는 코드가 아직 없어 요청하지 않은 추상화이므로 첫 사용처인 #15에서 만든다
- 넘어감: `docker compose`에 `--env-file`이 필요하다는 지적. 의도한 설계이고 빠뜨리면 안내 문구와 함께 중단됨(명령어는 `backend/CLAUDE.md`에 있음)

### PR
- (PR 생성 후 기입)

### 남은 일 / 관찰
- `fastapi.testclient`가 `httpx` 사용은 deprecated이고 `httpx2`를 설치하라는 경고를 낸다. 테스트는 통과하며 이 이슈 범위 밖이라 그대로 두었다.
- GitHub Project 상태와 일정은 `gh` 토큰에 `project` 권한이 없어 갱신하지 못했다.
