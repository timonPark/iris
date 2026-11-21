# [fe] 프로젝트 세팅 (Vite + React)

| 항목 | 내용 |
|---|---|
| 이슈 | #11 (https://github.com/timonPark/iris/issues/11) |
| 브랜치 | 2026-11-21-11-fe-project-setup |
| 상태 | 검증 대기 |
| 시작일자 | 2026-11-21 |
| 종료일자 | |

## 작업 내용

사용자 웹 프로젝트를 만든다.

### 범위
- 포함
  - [x] `web/` Vite + React
  - [x] `@primer/react` 적용(#2 방침, `ssot/PRIMER.md`)
  - [x] 라이트·다크
  - [x] `docs/api/openapi.yaml` 기반 API 호출 준비
  - [x] 서버 주소 설정
  - [x] `web/CLAUDE.md`에 실행 명령 채우기
- 제외: 화면 구현

### 완료 조건
- [x] 웹이 실행되고 Primer 테마가 적용된다.
- [x] 라이트와 다크 전환을 확인했다.
- [x] `web/CLAUDE.md`에 명령어가 적혀 있다.

### 선행 이슈와 결정 필요
- [x] 선행 #2 닫힘 확인 (2026-11-21)
- [x] 결정 필요: 없음

### 이번에 정한 것 (Claude가 정함)
- 언어와 도구: TypeScript, npm(lock 파일 커밋), 테스트는 Vitest + Testing Library. 루트 코드 규칙(웹은 interface와 type)과 TDD 절차에 맞춘다.
- Primer: `@primer/react` 38.46.0, `@primer/primitives` 11.10.0을 `--save-exact`로 설치한다(`ssot/PRIMER.md`). 38.46.0의 루트 `ThemeProvider`는 deprecated라서 `@primer/react/next`의 `ThemeProvider`를 쓴다.
- 테마: 기기 설정을 따른다(`auto`). 샘플(#3)에 테마를 바꾸는 버튼이 없었으므로 화면에 버튼은 두지 않는다. 테마 속성은 `<html>`에 두어 `body` 배경까지 테마를 따르게 한다.
- API 호출 준비: `openapi-typescript`로 `docs/api/openapi.yaml`에서 타입을 생성하고, 같은 타입을 쓰는 `openapi-fetch` 클라이언트를 둔다. 클라이언트는 요청마다 `Authorization: Bearer`(토큰이 있을 때)와 `ngrok-skip-browser-warning` 헤더를 붙인다. 토큰을 어디에 저장할지는 로그인 화면(#18)에서 정한다. SSE 처리는 채팅 화면(#24)에서 만든다.
- 서버 주소: `VITE_API_BASE_URL`(`web/.env.local`), 없으면 `http://localhost:8000`. 백엔드에 CORS가 있어(#56) Vite 프록시는 쓰지 않는다.

## 진행 기록
- 2026-11-21 브랜치와 작업 파일 생성. 선행 #2 닫힘, 결정 필요 없음 확인. GitHub Project 상태 `In Progress`, `Start date`·`Target date` 2026-11-21.
- 2026-11-21 `@primer/react@38.46.0` 패키지를 받아 확인: 루트 `ThemeProvider`는 deprecated, `@primer/react/next`의 `ThemeProvider`는 `colorMode="auto"`면 `prefers-color-scheme`을 따르고 `data-color-mode`, `data-light-theme`, `data-dark-theme`를 감싸는 `div`에 붙인다(`contextOnly`면 붙이지 않음).
- 2026-11-21 Vite(react-ts 템플릿)로 `web/`을 만들고 데모 파일(App.css, 로고 등)은 넣지 않았다. 테스트를 먼저 쓰고(서버 주소, API 클라이언트 헤더와 오류 모양, BaseStyles 적용, `<html>` 테마 속성) 실패를 확인한 뒤 구현했다.
- 2026-11-21 테스트에서 `@primer/react`의 CSS import를 Node가 읽지 못해 실패 → `test.server.deps.inline`에 넣어 해결. `index.html` 읽기는 `?raw` import로 바꿔 `@types/node`를 넣지 않았다.
- 2026-11-21 개발 서버를 띄워 Chrome에서 라이트·다크 확인(결과 참고). 코드 리뷰(codex, agy) 반영.
- 2026-11-21 PR을 올리고 상태를 `검증 대기`로 변경.

## 결과

### 변경한 파일
- 설정: `web/package.json`, `web/package-lock.json`, `web/vite.config.ts`(Vitest 포함), `web/tsconfig*.json`, `web/eslint.config.js`, `web/.gitignore`, `web/.env.example`, `web/index.html`
- 코드: `web/src/main.tsx`(Primer 토큰 CSS), `web/src/App.tsx`(ThemeProvider, BaseStyles), `web/src/index.css`, `web/src/config.ts`(서버 주소), `web/src/api/client.ts`(API 클라이언트), `web/src/api/schema.d.ts`(생성), `web/src/vite-env.d.ts`
- 테스트: `web/src/config.test.ts`, `web/src/api/client.test.ts`, `web/src/App.test.tsx`, `web/src/test/setup.ts`
- 문서: `web/CLAUDE.md`(명령어, 백엔드 주소, API 호출, Primer와 테마), `web/README.md`(상태)

### 확인 방법과 결과
- `npm test`: 7개 통과(서버 주소 기본값과 끝 슬래시, Bearer 헤더와 ngrok 헤더, 토큰 없으면 Authorization 없음, 오류 응답 `error.code`, BaseStyles 안에서 그림, `<html>` 테마 속성). `npm run build`(tsc 포함)와 `npm run lint` 오류 없음.
- 설치된 버전: `@primer/react` 38.46.0, `@primer/primitives` 11.10.0(정확히 고정), React 19.3.1. `@primer/react`의 peer 범위(react 18.x || 19.x) 안이다.
- 완료 조건 1, 2: `npm run dev` 후 Chrome headless(playwright-core)로 `http://localhost:5173/`을 열었다.
  - 라이트: `<html>` 속성 `auto/light/dark`, `--bgColor-default` `#ffffff`, `body` 배경 `rgb(255,255,255)`, 글자 `rgb(31,35,40)`, 제목이 BaseStyles 안, 글꼴 스택이 Primer `--fontStack-sansSerif`.
  - 같은 페이지에서 기기 설정만 다크로 바꾸자(새로고침 없음) `--bgColor-default` `#0d1117`, 배경 `rgb(13,17,23)`, 글자 `rgb(240,246,252)`. 다시 라이트로 바꾸면 원래 값. 스크린샷도 눈으로 확인했다.
  - 콘솔 오류는 `/favicon.ico` 404 하나뿐이다(아이콘을 아직 정하지 않음).
- 완료 조건 3: `web/CLAUDE.md`에 설치, 실행, 테스트, 린트, 빌드, 타입 생성 명령을 적었다.
- 한계: 이 PC의 백엔드가 꺼져 있어 실제 API 호출은 확인하지 못했다. 헤더와 주소는 테스트로, CORS는 #56에서 확인했다.
- 참고: npm 11의 설치 스크립트 승인 기능 때문에 `esbuild`, `fsevents`의 설치 스크립트가 실행되지 않았다는 경고가 나온다. 개발 서버, 테스트, 빌드는 정상 동작한다.

### 코드 리뷰 반영 내역
- codex(`codex review --uncommitted`): 지적 없음.
- agy(`agy -p`, diff를 프롬프트에 넣음. lock 파일과 생성된 schema 제외): 12건
  - 반영: `client.ts`의 `onRequest` 매개변수 타입(`MiddlewareCallbackParams`) 명시
  - 반영: 테스트의 변수 타입 명시(`ApiClient`, `ErrorResponse`, `HTMLElement`)
  - 넘어감: `styled-components` 누락. 38.46.0의 dependencies와 peerDependencies에 없다(패키지에서 확인).
  - 넘어감: React 19와 peer 충돌. peer 범위가 `18.x || 19.x`다.
  - 넘어감: `composite` 누락으로 `tsc -b` 실패. 빌드가 통과한다(Vite 템플릿 그대로).
  - 넘어감: `dark.css`가 `light.css`를 덮어써 테마 전환이 안 된다. 두 파일의 선택자는 `data-*` 속성 조건이 붙어 서로 덮지 않고, `auto`는 CSS 미디어 쿼리로 처리된다. Chrome에서 전환을 확인했다.
  - 넘어감: `--stack-padding-spacious`가 없는 토큰. `primitives.css`가 불러오는 `functional/size/size.css`에 `1.5rem`으로 있고 빌드 결과에도 있다.
  - 넘어감: 테스트 콜백(`describe`, `it`)의 반환 타입. 프레임워크 콜백이라 타입이 정해져 있다.
  - 넘어감: 테마 전환 단위 테스트, `matchMedia` 흉내의 리스너 구현. jsdom은 CSS 미디어 쿼리를 계산하지 않으므로 실제 브라우저로 확인했다.
  - 넘어감: `ngrok-skip-browser-warning` 헤더로 사전 요청이 막힌다. 백엔드 CORS가 이 헤더를 허용한다(#56).
  - 넘어감: import 확장자 일관성. `main.tsx`는 Vite 템플릿 그대로다.

### PR
- (작성 후 추가)

### 남은 일
- 토큰 저장 방법과 로그인 흐름은 #18, SSE 수신은 #24에서 만든다.
- 파비콘은 정하지 않았다(필요하면 따로 정함).
- `web/README.md`의 `primer/react` 표기와 "openapi.yaml 작성 예정(#8)" 문구는 이번 범위 밖이라 그대로 두었다.
