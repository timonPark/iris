# [common] API 규격 설계

| 항목 | 내용 |
|---|---|
| 이슈 | #8 (https://github.com/timonPark/iris/issues/8) |
| 브랜치 | 2026-11-17-8-common-api-spec |
| 상태 | 검증 대기 |
| 시작일자 | 2026-11-17 |
| 종료일자 | |

## 작업 내용

웹과 모바일을 두 세션에서 동시에 개발하므로, `docs/api/openapi.yaml` 하나를 두 쪽의 기준으로 만든다. 규격을 바꿀 때는 이 파일을 먼저 고친다.

### 범위
- [x] 인증: 로그인, 비밀번호 변경(평소: 현재+새 비밀번호, 임시 비밀번호 직후: 새 비밀번호만)
- [x] 세션: 목록(나눠서 호출), 열람(질문·답변을 나눠서 호출), 삭제
- [x] 질문 전송: 응답은 SSE. 답변 조각, 완료, 중단됨을 구분. 첫 질문이면 세션을 만든다.
- [x] 답변 중지
- [x] 음성 질문 전송(모바일 전용): 응답 SSE의 첫 이벤트가 보정된 질문 텍스트, 이어서 답변
- [x] 관리자(경로 분리): 사용자 계정 목록(나눠서 호출), 등록, 차단, 해제, 비밀번호 초기화
- [x] 오류: 차단됨, 서버 오류, 비밀번호 변경 필요, 질문 길이 초과, 권한 없음
- [x] 공통 규칙: accessToken 하나(만료 없음), 질문은 65,536자까지
- [x] SSE는 OpenAPI로 표현이 어려워 설명문으로 적는다.

제외: 구현, 계정 삭제, 계정 검색, 세션 이름 변경

### 완료 조건
- [x] `docs/api/openapi.yaml`이 유효성 검사를 통과한다. (`redocly lint` 1.34.5: valid, 경고 2건은 info.license 없음과 localhost 서버 주소로 의도한 값)
- [x] 위 항목이 모두 들어 있다.
- [ ] 웹과 모바일 쪽이 읽고 확인했다.
- [x] `ssot/GLOSSARY.md`의 용어와 일치한다. (용어집에 없는 `턴`은 쓰지 않기로 하고 질문 목록 안에 답변을 넣는 방식으로 바꿈)

### 결정 필요 (규격을 쓰면서 기본안을 제시하고 검토받는다)
- [x] 경로 접두어: `/api/v1/auth`, `/api/v1/sessions`, `/api/v1/voice`, `/api/v1/admin` (사용자 승인)
- [x] 오류 응답 형식: `{"error": {"code", "message"}}`, code는 대문자 스네이크 (사용자 승인)
- [x] SSE 이벤트 이름: `session`, `question`, `delta`, `done`, `stopped`, `error`. 순서는 session(첫 질문) → question(음성) → delta 반복 → done/stopped/error (사용자 승인)

## 진행 기록
- 2026-11-17 브랜치와 작업 파일 생성. 선행 이슈 없음.
- 2026-11-17 결정: 경로 접두어는 `/api/v1/{auth,sessions,voice,admin}`. 관리자 API는 `/api/v1/admin/` 아래로 분리.
- 2026-11-17 결정: 오류 응답은 `{"error": {"code", "message"}}` 한 가지 모양. code로 분기, message는 화면 표시용 한국어.
- 2026-11-17 결정: SSE 이벤트는 `session`, `question`, `delta`, `done`, `stopped`, `error`. 질문 전송과 음성 질문 전송이 같은 이벤트를 쓴다.
- 2026-11-17 `docs/api/openapi.yaml` 초안 작성 (엔드포인트 13개). 범위 항목은 모두 들어감.
- 2026-11-17 초안에서 이슈에 명시되지 않은 선택(사용자가 초안 그대로 진행하기로 승인):
  - 답변 중지는 별도 API(`POST /sessions/{sessionId}/stop`)로 둠 (#23 결정 필요 항목과 연결)
  - 비밀번호 변경 응답에 새 accessToken을 담음 (#17 결정 필요 항목과 연결)
  - 목록은 `cursor`/`limit`/`nextCursor` 방식, 세션 열람은 최신 질문부터
  - 질문 전송은 `POST /sessions/questions`(sessionId 생략 시 첫 질문), 세션 열람은 `GET /sessions/{id}/questions`(각 질문에 답변이 들어 있음)
  - 추가 오류 코드: UNAUTHORIZED, INVALID_CREDENTIALS, VALIDATION_FAILED, SESSION_NOT_FOUND, USER_NOT_FOUND, LOGIN_ID_TAKEN, NOT_STREAMING, AUDIO_TOO_LONG, SPEECH_NOT_RECOGNIZED, VOICE_PROCESSING_FAILED
- 2026-11-17 `턴`은 용어집에 없는 말이라 쓰지 않기로 함. 세션 열람은 질문 목록 안에 답변을 넣는 `GET /sessions/{id}/questions`로 바꿈(사용자와 논의 후 결정). 바꾼 뒤 `redocly lint` 다시 통과.
- 2026-11-17 PR 생성, 상태를 `검증 대기`로 변경. 마지막 완료 조건(웹과 모바일 쪽 확인)은 웹과 모바일 구현을 진행한 뒤 규격대로 동작하는지 검증해서 확인하기로 함(사용자 결정).
- 2026-11-17 코드 리뷰: `codex`, `agy`가 설치되어 있지 않아 사용자 승인으로 `/code-review`(medium)로 대신함. 규칙과 다르게 진행한 것이다.
- 2026-11-17 코드 리뷰 반영으로 추가한 것(이슈에 없던 새 결정, 검토 필요): 세션당 스트리밍 답변은 하나, 스트리밍 중 같은 세션에 질문하면 `SESSION_BUSY`(409)로 거부.

## 결과

### 변경한 파일
- `docs/api/openapi.yaml` (신규)
- `work_history/2026-11-17-8-common-api-spec.md` (신규)

### 확인 방법과 결과
- Ruby YAML 파서: 문법 OK, `$ref` 37개 모두 정의됨, 안 쓰는 정의 없음, 오류 코드 enum과 사용처 일치.
- `npx --yes @redocly/cli@1.34.5 lint docs/api/openapi.yaml`: valid. 경고 2건(info.license 없음, localhost 서버 주소)은 의도한 값이라 그대로 둠.

### 코드 리뷰 반영 내역
- 반영: 세션당 스트리밍 하나와 `SESSION_BUSY` 추가(중지 대상 모호함 해소)
- 반영: 음성 API의 잘못된 파일에 대한 422 응답 추가
- 반영: `changePassword`에서 `currentPassword` 생략 조건과 오류 규칙 명시
- 반영: accessToken을 불투명한 값으로 다루도록 명시(JWT 해석 금지)
- 반영: 차단/해제 반복 호출 시 200, `Question.answer`가 항상 있다는 것과 #23 결정 대기 명시
- 반영: 커서를 위치 기준으로 정의하고 페이지 안 정렬을 최신 순으로 명시
- 반영: 이 작업 파일의 체크리스트 갱신
- 넘어감: `/sessions/questions`와 `/sessions/{sessionId}` 경로 충돌 지적. OpenAPI는 고정 경로를 템플릿 경로보다 먼저 매칭하고 메서드도 달라 문제가 없다고 판단함
- 넘어감: 음성 API에 401/403이 없다는 지적. 이미 정의되어 있어 사실과 다름

### 남은 일
- 웹과 모바일 쪽 확인
