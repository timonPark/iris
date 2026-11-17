# [be] Hermes API 서버 활성화와 연동 확인

| 항목 | 내용 |
|---|---|
| 이슈 | #10 (https://github.com/timonPark/iris/issues/10) |
| 브랜치 | 2026-11-17-10-be-hermes-api-server |
| 상태 | 검증 대기 |
| 시작일자 | 2026-11-17 |
| 종료일자 | |

## 작업 내용

Hermes API 서버는 기본으로 꺼져 있다. 백엔드가 Hermes를 호출하려면 켜야 한다.

### 범위
- [x] `API_SERVER_ENABLED`, `API_SERVER_KEY` 설정과 게이트웨이 재시작
- [x] 백엔드에서 `/v1/chat/completions` 스트림 호출 성공 확인
- [x] 키는 백엔드 `.env`에만 보관
- [x] 확인 항목 1: API 서버를 거친 요청에서도 옵시디언 스킬이 동작하는지 (저장 요청 후 조회까지)
- [x] 확인 항목 2: 메시지가 65,536자를 넘으면 Hermes가 조용히 자르는지 (실제 호출 검증)
- [x] 확인 항목 3: 호출 연결을 끊으면 Hermes 쪽 실행도 멈추는지 (답변 중지의 전제)

제외: 사용자 화면

### 완료 조건
- [x] 백엔드에서 스트리밍 답변을 받는다.
- [x] 위 확인 항목 3개의 결과가 이슈에 적혀 있다. (이슈 #10 댓글)

### 결정 필요
- [x] 게이트웨이를 재시작하면 같은 게이트웨이를 쓰는 다른 연동에 영향이 있는지 재시작 전에 확인한다. → 아래 "재시작 영향 조사" 참고. 진행 중 작업이 0일 때 재시작하기로 Claude가 정함(사용자는 "대안을 가져와 판단하라"고 지시).

## 재시작 영향 조사 (2026-11-17, 읽기 전용)
- 기본 게이트웨이: pid 96881, 11월 5일부터 실행, launchd `ai.hermes.gateway`. 연결된 플랫폼은 Slack(connected)과 Google Chat(10월 19일부터 disconnected). `active_agents` 0.
- `news` 프로필 게이트웨이(`ai.hermes.gateway-news`)와 데스크톱 앱(`Hermes.app`, `hermes serve`)은 별도 프로세스라 기본 게이트웨이 재시작의 영향을 받지 않는다.
- `hermes gateway restart`는 진행 중인 작업을 마무리한 뒤 멈추고 새로 시작한다(문서). 실행 중이던 API 실행은 `interrupted`로 기록된다.
- 결과: 재시작 후 새 pid 14754, Slack은 `connected`로 복귀, `api_server`가 `127.0.0.1:8642`에서만 `connected`. `news` 게이트웨이(launchd 64037)는 그대로.

## 위험 (사용자에게 알림)
- Hermes 문서: API 서버는 **terminal 명령을 포함한 Hermes의 전체 도구**에 접근한다. 실제로 `/v1/toolsets`에서 `terminal`, `file`, `browser`, `code_execution`, `memory`, `delegation`, `cronjob`이 켜져 있음을 확인했다. Iris는 이 PC 밖의 사용자도 백엔드를 거쳐 이 Hermes에 질문하게 하므로, Iris 로그인과 키 보관이 곧 이 PC의 명령 실행 권한 경계가 된다.
- 이 키가 들어 있는 `backend/.env`는 권한 644로 만들어져 있어 600으로 바꿨다(이전 이슈에서 만든 파일의 권한이 느슨했다).

## 진행 기록
- 2026-11-17 브랜치와 작업 파일 생성. 선행 이슈 없음.
- 2026-11-17 재시작 영향 조사 후 재시작하기로 정함(위 참고).
- 2026-11-17 TDD: `tests/test_hermes.py`를 먼저 써서 실패(`app.hermes` 없음)를 확인한 뒤 `app/hermes.py`를 구현해 통과시킴. `httpx`를 일반 의존성으로 옮김.
- 2026-11-17 `~/.hermes/.env`를 `~/.hermes/backups/.env.before-iris-20261117`(권한 600)로 백업한 뒤 `API_SERVER_ENABLED=true`, `API_SERVER_KEY`(무작위 64자 hex)를 추가. 같은 키를 `backend/.env`에 `HERMES_API_KEY`로 저장. 키는 화면에 출력하지 않았고, 커밋 대상 파일에 키가 없음을 검사로 확인.
- 2026-11-17 `hermes gateway restart` 실행(재시작 직전 `active_agents` 0 확인).
- 2026-11-17 확인 항목 3개 실험(아래 결과 참고). 실험 스크립트는 임시 폴더에서 실행했고 저장소에는 넣지 않음.
- 2026-11-17 이슈 #10에 확인 결과 댓글 게시.
- 2026-11-17 코드 리뷰: `codex`, `agy`가 없어 `/code-review`(medium)로 대신함(이전 이슈에서 사용자가 승인한 방식). 지적을 판단해 반영하고(테스트를 먼저 추가해 실패를 확인한 뒤 구현) PR 생성, 상태를 `검증 대기`로 변경.

## 결과

### 변경한 파일
- 신규: `backend/app/hermes.py`, `backend/tests/test_hermes.py`, 이 파일
- 수정: `backend/app/config.py`(`hermes_api_url`, `hermes_api_key`), `backend/pyproject.toml`/`uv.lock`(httpx), `backend/.env.example`, `backend/CLAUDE.md`(Hermes 연동 섹션)
- 이 PC의 Hermes 설정 변경(저장소 밖): `~/.hermes/.env`에 `API_SERVER_ENABLED`, `API_SERVER_KEY` 추가. 백업은 `~/.hermes/backups/.env.before-iris-20261117`.
- 커밋하지 않음: `backend/.env`(키 포함, 권한 600)

### 확인 방법과 결과
- 테스트: `cd backend && uv run pytest` → 17 passed(단위 15, 통합 2: DB 연결, 실제 Hermes 스트리밍). `-m "not integration"` → 15 passed, `-m "not hermes"` → 16 passed. 실제 Hermes 테스트가 `[DONE]` 필수 규칙으로도 통과해 Hermes가 답변 끝에 `[DONE]`을 실제로 보낸다는 것을 확인.
- **스트리밍 호출**: `HermesClient.stream_chat()`으로 실제 Hermes에 "1부터 15까지" 요청 → 조각 4개, 첫 조각 0.9초, 마지막 1.3초.
- **확인 항목 1 (옵시디언)**: 성공. API 서버 요청으로 고유 이름의 테스트 노트를 저장하고 조회까지 했다. 파일 `/Users/jeong/hermes-obsidian/90-Hermes/Iris-API-연동-테스트-1794895407.md`가 실제로 생성되었고 내용(`IRIS-OBSIDIAN-TEST-1794895407`)이 일치. **부수 효과**: Hermes의 `obsidian-notion-sync`가 Notion `90-Hermes` 페이지 아래에 같은 제목의 페이지를 만들었다고 답했고, `90-Hermes/.notion-sync-state.json`이 갱신되었다. 동기화에 영향을 줄 수 있어 아무것도 지우지 않았다. (참고: `/v1/skills`는 "Failed to enumerate skills" 오류를 돌려줘서 스킬 목록 확인에는 쓸 수 없었다.)
- **확인 항목 2 (65,536자)**: 질문을 맨 앞에 두고 시작 코드와 끝 코드를 심어 확인. 60,000자는 두 코드를 모두 찾았고, 70,000자는 시작 코드만 찾고 끝 코드는 "없음"이었다. Hermes가 "메시지가 `alpha beta ga`에서 끊겨 있다"고 답했다. 즉 **한도를 넘으면 오류 없이 끝이 잘린다.** 확인하지 못한 것: 여러 메시지의 합이 한도를 넘을 때나, 과거 답변(65,536자를 넘을 수 있음)이 이력으로 들어갈 때의 동작.
- **확인 항목 3 (연결 끊기)**: `/health/detailed`의 `active_api_runs`로 비교. 대조군(끝까지 받음)은 약 20초 동안 1이었다가 답변이 끝난 시점에 0. 실험군(1.3초에 연결 끊음)은 약 2초 안에 0이 되었고 끝까지 0. 즉 **연결을 끊으면 Hermes 실행도 멈춘다.** 근거는 `active_api_runs` 지표이며 모델 토큰 사용량까지는 확인하지 못했다.
- 비밀값: `.env` 밖 파일에서 키 문자열 검색 0건, `git add -n` 대상에 `.env` 없음.
- 확인하지 못한 것: Hermes 재시작 후 Slack의 실제 메시지 수신(상태가 `connected`로 돌아온 것까지만 확인), `/v1/runs` 계열 엔드포인트(이번 범위가 아님).

### 이슈 #10 댓글
- https://github.com/timonPark/iris/issues/10#issuecomment-6940259791

### 코드 리뷰 반영 내역
지적 11건 중 8건 반영, 3건 넘어감.
- 반영: 스트림이 `[DONE]` 없이 끝나면 정상 완료가 아니라 `HermesError`(Hermes 재시작 등으로 잘린 답이 완성된 것처럼 보이는 문제). 스트림 안의 `{"error": ...}` 청크도 `HermesError`
- 반영: 잘못된 `data:` 줄(JSON 아님 등)을 원시 예외가 아니라 `HermesError`로 변환
- 반영: 읽기 제한 시간을 없음에서 60초로(Hermes가 10초마다 keepalive를 보내 긴 답변은 영향 없음)
- 반영: 오류 응답일 때 상태 코드와 본문 앞 200자를 `HermesError` 메시지에 담음
- 반영: 키가 없으면 클라이언트를 만들 때 `HermesError`(`create_hermes_client`)
- 반영: `integration` 마커 설명을 "외부 시스템(PostgreSQL, Hermes)"으로 고치고, 실제 모델을 호출하는 테스트에 `hermes` 마커를 추가. 키가 없으면 건너뜀. `CLAUDE.md`의 테스트 명령 갱신
- 반영: 실패 경로 테스트 추가(`[DONE]` 없음, 잘못된 JSON, 오류 청크, 오류 상태 본문, 키 없음), 테스트 변수 타입 표기
- 반영(리뷰 외): `parse_delta`의 `type: ignore`를 `Any` 타입으로 없앰
- 넘어감: `httpx.InvalidURL`, `StreamError` 래핑. Hermes의 실패가 아니라 설정이나 코드 오류
- 넘어감: 요청마다 `AsyncClient`를 만드는 것을 하나로 공유. 아직 동시 요청이 없어 #23에서 FastAPI lifespan과 함께 정함
- 넘어감: anyio pytest 플러그인 미선언. `httpx`가 가져오는 의존성이라 따로 선언하지 않음

### PR
- https://github.com/timonPark/iris/pull/45

### 정리가 필요한 테스트 흔적 (사용자 확인 필요)
- 로컬 노트: `/Users/jeong/hermes-obsidian/90-Hermes/Iris-API-연동-테스트-1794895407.md`
- 동기화 기록: `/Users/jeong/hermes-obsidian/90-Hermes/.notion-sync-state.json`에 이 노트 항목
- Notion: `90-Hermes` 페이지 아래 같은 제목의 페이지

### 남은 일 / 관찰
- #23(Hermes 호출과 SSE 중계)의 "중지를 별도 API로 받을지, 연결을 끊는 것으로 처리할지" 결정에는 확인 항목 3(연결을 끊으면 멈춘다)이 근거가 된다. 다만 모바일은 앱이 백그라운드로 가면 연결이 끊길 수 있어 의도하지 않은 중지가 생길 수 있다.
- GitHub Project 상태는 `gh` 토큰에 `project` 권한이 없어 갱신하지 못했다.
