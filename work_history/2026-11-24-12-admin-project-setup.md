# [admin] 프로젝트 세팅

| 항목 | 내용 |
|---|---|
| 이슈 | #12 (https://github.com/timonPark/iris/issues/12) |
| 브랜치 | 2026-11-24-12-admin-project-setup |
| 상태 | 검증 대기 |
| 시작일자 | 2026-11-24 |
| 종료일자 | |

## 작업 내용

범위: `admin/` 프로젝트, `primer/react` 적용(#2 방침), 라이트·다크, API 호출 준비, 서버 주소 설정, `admin/CLAUDE.md`에 실행 명령 채우기. 화면 구현은 제외(#20, #28).

완료 조건
- [x] 관리자 웹이 실행되고 Primer 테마가 적용된다.
- [x] `admin/CLAUDE.md`에 명령어가 적혀 있다.

할 일
- [x] Vite + React + TypeScript 프로젝트(`web/`과 같은 버전, npm)
- [x] `@primer/react` 38.46.0, `@primer/primitives` 11.10.0 고정, 토큰 CSS, 기기 설정을 따르는 라이트·다크
- [x] 서버 주소 `VITE_API_BASE_URL`(`.env.example`), 기본 `http://localhost:8000`
- [x] `openapi-fetch` API 클라이언트와 `gen:api`(관리자 API 타입), 테스트(Vitest)
- [x] 개발 서버 포트를 `web/`(5173)과 겹치지 않게
- [x] `admin/CLAUDE.md`, `admin/README.md` 갱신

## 진행 기록

- 2026-11-24 브랜치와 작업 파일 생성. 선행 이슈 #2 닫힘 확인. 결정 필요 "사용자 웹과 같은 스택인지" → 사용자와 정함: 같은 스택(Vite + React + TypeScript + Primer React).

- 2026-11-24 테스트(서버 주소, API 클라이언트, 화면·테마 속성)를 먼저 쓰고 실패를 확인한 뒤 구현. `web/`의 #11 세팅을 기준으로 하고, 의존성은 `web/package-lock.json`을 그대로 써서 같은 버전으로 맞춤. 개발 서버는 5174(사용자 웹 5173과 함께 띄울 수 있게).
- 2026-11-24 코드 리뷰(codex, agy) 반영 후 PR을 올리고 상태를 `검증 대기`로 변경.

## 결과

### 변경한 파일
- 설정: `admin/package.json`, `admin/package-lock.json`, `admin/vite.config.ts`(포트 5174, Vitest), `admin/tsconfig*.json`, `admin/eslint.config.js`, `admin/.gitignore`, `admin/.env.example`, `admin/index.html`
- 코드: `admin/src/main.tsx`(Primer 토큰 CSS), `admin/src/App.tsx`(ThemeProvider, BaseStyles, 자리 화면), `admin/src/index.css`, `admin/src/config.ts`(서버 주소), `admin/src/api/client.ts`(API 클라이언트), `admin/src/api/schema.d.ts`(생성), `admin/src/vite-env.d.ts`
- 테스트: `admin/src/config.test.ts`, `admin/src/api/client.test.ts`, `admin/src/App.test.tsx`, `admin/src/test/setup.ts`
- 문서: `admin/CLAUDE.md`(명령어, 백엔드 주소, API 호출, Primer와 테마), `admin/README.md`(기술 스택, 상태)

### 확인 방법과 결과
- `npm test` 7개 통과(서버 주소 기본값과 끝 슬래시, 관리자 API 경로와 Bearer·ngrok 헤더, 토큰 없으면 Authorization 없음, 오류 응답 `error.code`, BaseStyles 안에서 그림, `<html>` 테마 속성). `npm run lint`, `npm run build`(tsc 포함) 오류 없음.
- 설치된 버전: `@primer/react` 38.46.0, `@primer/primitives` 11.10.0, React 19.3.1(사용자 웹과 같음).
- 완료 조건 1: `npm run dev` 후 Chrome headless(playwright-core)로 `http://localhost:5174/`을 열었다.
  - 라이트: `<html>` 속성 `ko/auto/light/dark`, 제목 `Iris 관리자`, `--bgColor-default` `#ffffff`, 배경 `rgb(255,255,255)`, 글자 `rgb(31,35,40)`, 제목이 BaseStyles 안, 여백 24px, 본문 글꼴 14px/21px Primer 글꼴 스택.
  - 같은 페이지에서 기기 설정만 다크로 바꾸자(새로고침 없음) `#0d1117`, 배경 `rgb(13,17,23)`, 글자 `rgb(240,246,252)`. 다시 라이트로 바꾸면 원래 값. 다크 스크린샷을 눈으로 확인.
  - 콘솔 오류는 `/favicon.ico` 404 하나(사용자 웹과 같음).
- API 호출 준비: 원격 백엔드(ngrok)에 `Origin: http://localhost:5174`로 사전 요청하면 그 출처와 `Authorization`, `ngrok-skip-browser-warning` 헤더를 허용한다. 토큰 없이 `GET /api/v1/admin/users`는 401 `UNAUTHORIZED`(규격 모양).
- 완료 조건 2: `admin/CLAUDE.md`에 설치, 실행, 테스트, 린트, 빌드, 타입 생성 명령을 적었다.

### 코드 리뷰 반영 내역
- codex(`codex review --uncommitted`): 지적 없음.
- agy(`agy -p`, diff를 프롬프트에 넣음. lock 파일과 생성된 schema 제외): 11건
  - 반영: 테스트의 가짜 응답을 규격 모양으로(`UserPage`의 `nextCursor`는 null 대신 생략, `LoginResponse`에 `role`, `passwordChangeRequired`)
  - 반영: 토큰이 없을 때도 `ngrok-skip-browser-warning` 헤더를 보내는지 확인
  - 반영: `body` 글자를 Primer 토큰(`--text-body-shorthand-medium`)으로. 사용자 웹(#18 이후)과 같다.
  - 넘어감: 구조분해 변수(`{ data }`, `{ error }`)의 타입 명시. 타입은 규격에서 생성한 `paths`로 정해지고, 사용자 웹도 같다.
  - 넘어감: 관리자 등록·차단 POST 경로 테스트. 화면 구현(#28) 범위다.
  - 넘어감: `apiBaseUrl` 상수 테스트, ThemeProvider 옵션 테스트. 상수는 `resolveApiBaseUrl` 결과이고, 테마는 jsdom이 CSS 미디어 쿼리를 계산하지 않아 실제 브라우저로 확인했다.
  - 넘어감: 빈 문자열 토큰. 토큰 저장은 #20에서 정하며 지금은 빈 문자열이 나올 곳이 없다.
  - 넘어감: `.gitignore`에 `.env` 추가. 사용자 웹과 같은 Vite 기본값이며 주소 설정은 커밋하지 않는 `.env.local`을 쓴다.

### 남은 일
- 관리자 로그인, 토큰 저장, 인증 오류 처리는 #20, 사용자 계정 관리 화면은 #28.
- 파비콘은 정하지 않았다(사용자 웹과 같음).
