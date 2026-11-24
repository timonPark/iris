# admin

## 기준 문서

- 용어와 개념은 `../ssot/`를 기준으로 작업합니다. admin의 코드, 변수명, 화면 문구도 `../ssot/`의 용어를 따릅니다.
- `../ssot/`에 정의가 없거나 모호하면 임의로 정하지 말고 먼저 묻습니다.

## 행동 지침

루트 CLAUDE.md의 행동 지침을 따르며, admin에서는 이렇게 적용합니다.

- **먼저 묻기**: 임시 비밀번호 변경 절차는 미결정이므로 임의로 정하지 않고 묻습니다.
- **단순하게**: 기능은 사용자 등록, 차단, 비밀번호 초기화 세 가지뿐입니다. 대화 열람은 만들지 않습니다.
- **필요한 곳만**: 사용자 API와 분리된 관리자 API만 호출합니다. 권한 검사는 백엔드 몫이므로 화면 숨김으로 대신하지 않습니다.
- **검증 먼저**: 등록한 계정으로 로그인 가능, 차단하면 로그인 거부, 초기화 후 새 비밀번호로 로그인처럼 기능별 성공 기준을 정하고 구현합니다.

## 명령어

사용자 웹(`../web/`)과 같은 스택입니다(#12에서 정함): Vite + React + TypeScript, 패키지는 npm으로 관리합니다(`package-lock.json` 커밋). 아래 명령은 모두 `admin/` 폴더에서 실행합니다.

### 처음 한 번

```bash
npm install                     # 의존성 설치
cp .env.example .env.local      # 백엔드 주소를 바꿀 때만. .env.local은 커밋하지 않는다
```

### 실행, 테스트, 빌드

```bash
npm run dev                     # 개발 서버. http://localhost:5174 (사용자 웹 5173과 함께 띄울 수 있다)
npm test                        # 전체 테스트 (Vitest, jsdom). 지켜보며 돌리려면 npx vitest
npm run lint                    # ESLint
npm run build                   # 타입 검사(tsc -b) 후 dist/에 빌드
npm run gen:api                 # docs/api/openapi.yaml → src/api/schema.d.ts 타입 다시 생성
```

### 백엔드 주소

- `VITE_API_BASE_URL`(`.env.local`)에 적습니다. 비우면 `http://localhost:8000`입니다(`src/config.ts`).
- 다른 PC에서 개발할 때는 ngrok 고정 도메인을 적습니다. 백엔드가 `localhost`, `127.0.0.1`의 모든 포트에 CORS를 허용하므로(#56) Vite 프록시는 쓰지 않습니다.

### API 호출

- `src/api/client.ts`의 `createApiClient({ baseUrl, getAccessToken })`를 씁니다. `openapi-fetch` 클라이언트라서 경로, 요청, 응답 타입이 `docs/api/openapi.yaml`과 같습니다. 예: `client.GET('/api/v1/admin/users')` → `{ data, error }`, `error`는 `{ error: { code, message } }` 모양입니다.
- 관리자 웹은 로그인(`/api/v1/auth/login`)과 관리자 API(`/api/v1/admin/...`)만 부릅니다.
- 요청마다 `ngrok-skip-browser-warning: 1`을 붙이고, 토큰이 있으면 `Authorization: Bearer`를 붙입니다.
- 관리자 API의 인증 오류(`UNAUTHORIZED`, `FORBIDDEN`) 처리는 처음 관리자 API를 부르는 계정 관리 화면(#28)에서 만듭니다.
- 규격이 바뀌면 `npm run gen:api`로 `src/api/schema.d.ts`를 다시 만들어 함께 커밋합니다. 이 파일은 손으로 고치지 않습니다.

### 로그인 (#20)

- 로그인 상태는 `sessionStorage`의 `iris.admin.auth`(`src/auth/storage.ts`)가 기준입니다: `accessToken`, `loginId`. 새로고침해도 유지되지만 탭이나 브라우저를 닫으면 로그아웃됩니다. 새 탭은 로그인 화면부터입니다. 로그아웃 버튼은 없습니다(`../ssot/GLOSSARY.md` "관리자 웹").
- 로그인 응답의 `role`이 `admin`이 아니면 저장하지 않고 "관리자 계정만 로그인할 수 있습니다."라고 안내합니다. 차단된 사용자 계정(`ACCOUNT_BLOCKED`)도 같은 문구입니다. 그 밖의 오류는 규격의 `message`, 연결 실패(응답 없음)는 "서버 오류가 발생했습니다."입니다(`src/auth/messages.ts`).
- 화면 전환은 라우터 없이 상태로 합니다(`src/auth/useAuthFlow.ts`): 로그인 전이면 `LoginScreen`, 뒤면 `AdminScreen`(머리글과 본문 틀. 계정 목록은 #28).
- 폼은 응답을 기다리는 동안 다시 제출되지 않게 막습니다. Primer `Button`의 `loading`은 `aria-disabled`만 붙이고 제출을 막지 않습니다.
- 테스트는 `src/test/fakeApi.ts`(경로별 응답을 정하는 가짜 fetch, `loginOk`, `apiError`)를 씁니다.
- 확인용 임시 환경: 볼륨 없는 PostgreSQL 컨테이너와 임시 설정(`ADMIN_LOGIN_ID`, `ADMIN_PASSWORD`)의 백엔드를 띄우고 `VITE_API_BASE_URL=http://127.0.0.1:<포트> npm run dev`로 붙입니다(#20 work_history 참고).

### Primer와 테마

- `@primer/react` 38.46.0, `@primer/primitives` 11.10.0을 정확한 버전으로 고정합니다(사용자 웹과 같은 버전). 버전을 올릴 때는 `../ssot/PRIMER.md`를 따릅니다(사용자 웹, 모바일과 함께).
- 토큰 CSS(`primitives.css`, `light.css`, `dark.css`)는 `src/main.tsx`에서 불러옵니다. 직접 쓰는 CSS도 색, 간격, 글자는 토큰만 씁니다.
- 테마는 기기 설정을 따릅니다. `index.html`의 `<html>`에 `data-color-mode="auto"`, `data-light-theme="light"`, `data-dark-theme="dark"`가 있어서 `body` 배경까지 테마를 따릅니다. 화면에 테마 전환 버튼은 없습니다.
- `ThemeProvider`는 `@primer/react/next`의 것을 씁니다(루트의 것은 deprecated). 속성은 `<html>`에 있으므로 `contextOnly`로 씁니다.
- 테스트에서 `@primer/react`가 CSS를 import하므로 `vite.config.ts`의 `test.server.deps.inline`에 넣어 두었습니다. jsdom에 없는 `matchMedia`는 `src/test/setup.ts`가 채웁니다.
