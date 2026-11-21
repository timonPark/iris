# web

## 기준 문서

- 용어와 개념은 `../ssot/`를 기준으로 작업합니다. web의 코드, 변수명, 화면 문구도 `../ssot/`의 용어를 따릅니다.
- `../ssot/`에 정의가 없거나 모호하면 임의로 정하지 말고 먼저 묻습니다.

## 행동 지침

루트 CLAUDE.md의 행동 지침을 따르며, web에서는 이렇게 적용합니다.

- **먼저 묻기**: API 규격이 모호하면 추측으로 호출하지 않고 `docs/` 규격을 확인하고 묻습니다.
- **단순하게**: 가입 화면, 관리자 기능(`admin/` 담당), 음성 입력(모바일 전용)은 만들지 않습니다.
- **필요한 곳만**: 규격에 맞춰 호출만 합니다. 규격을 바꿔야 하면 `docs/`에 먼저 반영하고 모바일 세션에 알립니다.
- **검증 먼저**: 질문 입력 → 스트리밍 표시 → 완료 흐름을 확인 가능한 기준으로 정하고 구현합니다.

## 명령어

Vite + React + TypeScript, 패키지는 npm으로 관리합니다(`package-lock.json` 커밋). 아래 명령은 모두 `web/` 폴더에서 실행합니다.

### 처음 한 번

```bash
npm install                     # 의존성 설치
cp .env.example .env.local      # 백엔드 주소를 바꿀 때만. .env.local은 커밋하지 않는다
```

### 실행, 테스트, 빌드

```bash
npm run dev                     # 개발 서버. http://localhost:5173
npm test                        # 전체 테스트 (Vitest, jsdom). 지켜보며 돌리려면 npx vitest
npm run lint                    # ESLint
npm run build                   # 타입 검사(tsc -b) 후 dist/에 빌드
npm run gen:api                 # docs/api/openapi.yaml → src/api/schema.d.ts 타입 다시 생성
```

### 백엔드 주소

- `VITE_API_BASE_URL`(`.env.local`)에 적습니다. 비우면 `http://localhost:8000`입니다(`src/config.ts`).
- 다른 PC에서 개발할 때는 ngrok 고정 도메인을 적습니다. 백엔드가 `localhost`, `127.0.0.1`의 모든 포트에 CORS를 허용하므로(#56) Vite 프록시는 쓰지 않습니다.

### API 호출

- `src/api/client.ts`의 `createApiClient({ baseUrl, getAccessToken })`를 씁니다. `openapi-fetch` 클라이언트라서 경로, 요청, 응답 타입이 `docs/api/openapi.yaml`과 같습니다. 예: `client.GET('/api/v1/sessions')` → `{ data, error }`, `error`는 `{ error: { code, message } }` 모양입니다.
- 요청마다 `ngrok-skip-browser-warning: 1`을 붙이고, 토큰이 있으면 `Authorization: Bearer`를 붙입니다. 토큰 저장 방법은 로그인 화면(#18)에서 정합니다.
- 규격이 바뀌면 `npm run gen:api`로 `src/api/schema.d.ts`를 다시 만들어 함께 커밋합니다. 이 파일은 손으로 고치지 않습니다.
- SSE(질문 전송)는 `openapi-fetch`로 받지 않습니다. 처리 방법은 채팅 화면(#24)에서 만듭니다.

### 로그인 상태와 화면 전환 (#18)

- 로그인 상태는 `localStorage`의 `iris.auth`(`src/auth/storage.ts`)가 기준입니다: `accessToken`, `passwordChangeRequired`, `loginId`. 브라우저를 닫아도 유지되고 로그아웃 버튼은 없습니다.
- 화면 전환은 라우터 없이 `src/auth/useAuthFlow.ts`의 상태(`login`, `force-change`, `chat`, `settings`)로 합니다.
- 어느 API에서 받든 `UNAUTHORIZED`·`ACCOUNT_BLOCKED`면 토큰을 지우고 로그인 화면(안내 표시), `PASSWORD_CHANGE_REQUIRED`면 강제 변경 화면으로 갑니다. `createApiClient`의 `onAuthError`가 한 곳에서 처리하므로 화면마다 따로 처리하지 않습니다.
- 관리자 계정은 로그인 응답의 `role`로 막습니다(`../ssot/GLOSSARY.md` "사용자 앱").
- 화면 문구는 `src/auth/messages.ts`에 모읍니다. 오류는 규격의 `message`를 그대로 쓰고, 연결 실패(응답 없음)는 "서버 오류가 발생했습니다."입니다.
- 폼은 응답을 기다리는 동안 다시 제출되지 않게 막습니다. Primer `Button`의 `loading`은 `aria-disabled`만 붙이고 제출을 막지 않습니다.
- 테스트는 `src/test/fakeApi.ts`(경로별 응답을 정하는 가짜 fetch)를 씁니다.

### Primer와 테마

- `@primer/react` 38.46.0, `@primer/primitives` 11.10.0을 정확한 버전으로 고정합니다. 버전을 올릴 때는 `../ssot/PRIMER.md`를 따릅니다(관리자 웹, 모바일과 함께).
- 토큰 CSS(`primitives.css`, `light.css`, `dark.css`)는 `src/main.tsx`에서 불러옵니다. 직접 쓰는 CSS도 색, 간격, 글자는 토큰만 씁니다.
- 테마는 기기 설정을 따릅니다. `index.html`의 `<html>`에 `data-color-mode="auto"`, `data-light-theme="light"`, `data-dark-theme="dark"`가 있어서 `body` 배경까지 테마를 따릅니다. 화면에 테마 전환 버튼은 없습니다.
- `ThemeProvider`는 `@primer/react/next`의 것을 씁니다(루트의 것은 deprecated). 속성은 `<html>`에 있으므로 `contextOnly`로 씁니다.
- 테스트에서 `@primer/react`가 CSS를 import하므로 `vite.config.ts`의 `test.server.deps.inline`에 넣어 두었습니다. jsdom에 없는 `matchMedia`는 `src/test/setup.ts`가 채웁니다.
