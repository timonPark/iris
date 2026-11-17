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
cp .env.example .env        # 그리고 POSTGRES_PASSWORD 를 바꾼다 (.env 는 커밋하지 않는다)
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
uv run pytest -m "not integration"                 # DB 없이 돌릴 수 있는 테스트만
uv run alembic revision -m "설명"                  # 마이그레이션 파일 만들기
uv run alembic upgrade head                        # 마이그레이션 적용
uv run alembic current                             # 현재 적용된 버전 확인
```

- 셸에 `VIRTUAL_ENV`가 다른 환경으로 잡혀 있으면 `uv`가 경고를 내고 무시합니다. 동작에는 문제가 없습니다.
- DB 접속 정보는 `backend/.env`에만 둡니다(`alembic.ini`에 쓰지 않습니다). 변수 이름은 `app/config.py`와 `docker-compose.yml`이 같이 씁니다.

### 마이그레이션 도구

마이그레이션은 Alembic(SQLAlchemy)을 씁니다. 새 테이블 모델은 `app/db.py`의 `Base`를 상속하고 `migrations/env.py`에서 import해서 `Base.metadata`에 등록합니다. 기준 마이그레이션(`0001`)은 비어 있고, 계정 테이블은 #15에서 만듭니다.
