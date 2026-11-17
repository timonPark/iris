# backend

Iris의 백엔드입니다. 모든 클라이언트(사용자 웹, 관리자 웹, 모바일 앱)의 유일한 입구이고, 질문을 이 PC의 Hermes에 전달해 답변을 SSE로 돌려줍니다.

## 기술 스택

- Python, FastAPI
- PostgreSQL (루트 `docker-compose.yml`로 실행)
- 음성 처리: ffmpeg, whisper.cpp(`ggml-large-v3-turbo`), `claude -p`(맞춤법 보정)

## 하는 일

- 인증: 아이디/비밀번호 로그인, accessToken(만료 없음), 요청마다 계정 상태 확인(차단, 비밀번호 변경 후 이전 토큰 거부)
- 세션, 질문, 답변 저장과 조회, 세션 삭제(soft delete)
- Hermes API 서버 호출과 SSE 중계, 답변 중지
- 관리자 API (사용자 계정 등록, 차단, 해제, 비밀번호 초기화)
- 모바일 전용 음성 업로드와 변환, 인식, 보정

## 기준 문서

- 용어와 개념: [`../ssot/GLOSSARY.md`](../ssot/GLOSSARY.md)
- API 규격: `../docs/api/openapi.yaml` (작성 예정, 이슈 #8)
- 작업 규칙: [`CLAUDE.md`](CLAUDE.md), 루트 [`../CLAUDE.md`](../CLAUDE.md)

## 관련 이슈

#9 프로젝트 세팅, #10 Hermes API 서버 연동, #15~#17 인증, #22~#23 세션과 Hermes 중계, #27 관리자 API, #30~#31 음성, #34~#35 외부 접속

## 상태

프로젝트 세팅(#9)을 마쳤습니다. 빈 FastAPI 앱, PostgreSQL(docker-compose), Alembic 기준 마이그레이션이 동작합니다. 실행과 테스트 방법은 [`CLAUDE.md`](CLAUDE.md)의 "명령어"를 보세요. 도메인 로직(계정, 세션 등)은 아직 없습니다.
