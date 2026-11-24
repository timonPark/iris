# [admin] 사용자 계정 관리 화면

| 항목 | 내용 |
|---|---|
| 이슈 | #28 (https://github.com/timonPark/iris/issues/28) |
| 브랜치 | 2026-11-24-28-admin-user-management |
| 상태 | 검증 대기 |
| 시작일자 | 2026-11-24 |
| 종료일자 | |

## 작업 내용

범위: 계정 목록(페이징, 상태 표시), 계정 등록, 차단과 해제, 비밀번호 초기화, 임시 비밀번호를 한 번만 보여주는 화면(복사 버튼, 닫으면 다시 볼 수 없다는 안내). 계정 검색, 관리자 계정 관리, 대화 열람은 제외.

완료 조건
- [x] 샘플(#4)과 같은 화면이다.
- [x] 등록과 초기화 후 임시 비밀번호가 한 번 표시된다.
- [x] 차단과 해제가 목록에 반영된다.

할 일(샘플 #4 화면 기준)
- [x] 계정 목록(`users`): 아이디, 상태(활성/차단 중), 비밀번호(임시 비밀번호/설정함), 등록일, 작업. 20개씩, "더 보기"
- [x] 빈 목록(`users-empty`), 목록 오류(`users-error`, 다시 시도)
- [x] 계정 등록(`create`, `create-taken`): 아이디만, 오류는 규격 문구
- [x] 임시 비밀번호(`create-done`, `reset-done`): 한 번만, 복사, "전달했습니다"
- [x] 차단 확인(`block`), 해제는 확인 없이 바로, 초기화 확인(`reset`)
- [x] 관리자 API가 `UNAUTHORIZED`·`FORBIDDEN`이면 로그인 상태를 지우고 로그인 화면(#20에서 미룸)
- [x] `admin/CLAUDE.md` 갱신

## 진행 기록

- 2026-11-24 브랜치와 작업 파일 생성. 선행 이슈 #4, #12, #27 닫힘 확인. 결정 필요 없음.

- 2026-11-24 샘플의 화면 상태를 테스트로 먼저 쓰고(목록, 더 보기, 빈 목록, 목록 오류, 등록, 중복, 복사, 차단, 해제, 초기화, 인증 오류) 실패를 확인한 뒤 구현. 30줄이 넘는 함수는 나눔(`useFirstPage`, `LoginIdField`, `CopyButton`, `ListError`, `EmptyList`, `Dialogs`).
- 2026-11-24 이 PC의 임시 백엔드(8010)에 붙인 확인용 관리자 웹(5175)으로 headless Chrome과 Aside에서 확인. 사용자가 쓰는 5174(원격 서버 연결)는 건드리지 않음.
- 2026-11-24 코드 리뷰 반영(테스트 먼저) 후 다시 확인하고 PR을 올려 상태를 `검증 대기`로 변경.

## 결과

### 변경한 파일
- 코드: `admin/src/users/`(`types.ts`, `useUsers.ts`, `useCreateUser.ts`, `useUserActions.ts`), `admin/src/components/`(`UserList.tsx`, `UserTable.tsx`, `CreateDialog.tsx`, `ConfirmDialog.tsx`, `SecretDialog.tsx`, `TitleOnly.tsx`), `admin/src/screens/AdminScreen.tsx`, `admin/src/api/client.ts`(`onAuthError`), `admin/src/auth/`(`useAuthFlow.ts` 인증 오류, `messages.ts` `errorText`, `useLogin.ts`), `admin/src/screens/LoginScreen.tsx`(들어올 때의 안내), `admin/src/App.tsx`, `admin/src/index.css`(샘플의 표, 빈 목록, 대화상자, 임시 비밀번호, 좁은 화면)
- 테스트: `admin/src/screens/AdminScreen.test.tsx`(새), `admin/src/components/SecretDialog.test.tsx`(새), `admin/src/App.test.tsx`, `admin/src/api/client.test.ts`, `admin/src/test/fakeApi.ts`(`query`, `userOf`, `userPage`), `admin/src/test/setup.ts`(`ResizeObserver`)
- 문서: `admin/CLAUDE.md`(API 호출의 인증 오류, 사용자 계정 관리)

### 확인 방법과 결과
- `npm test` 50개 통과, `npm run lint`·`npm run build` 오류 없음, 30줄 넘는 함수 없음.
- 실제 백엔드: 이 PC에 임시 백엔드(볼륨 없는 PostgreSQL, 임시 관리자)를 띄우고 `VITE_API_BASE_URL=http://127.0.0.1:8010 npx vite --port 5175`로 붙여 Chrome headless(playwright-core)로 확인. 로그인 결과는 백엔드 로그인 API로 확인(`admin/CLAUDE.md` "검증 먼저").
  - 빈 목록 → 샘플의 안내 문구
  - 등록(`kimdh`) → "계정을 등록했습니다", 임시 비밀번호 12자, 복사하면 클립보드 값이 같고 버튼이 "복사함", "전달했습니다"로 닫으면 화면에서 사라지고 목록 맨 위에 "활성 / 임시 비밀번호 / 2026-11-24". 그 비밀번호로 로그인 200
  - 같은 아이디 다시 등록 → "이미 사용 중인 아이디입니다."(409), 입력칸 `aria-invalid`. `AB` → "아이디는 영문 소문자와 숫자 4~20자여야 합니다."(422)
  - 차단(확인) → 행이 "차단 중"과 [차단 해제], 로그인 403. 해제(확인 없음) → "활성", 로그인 200
  - 초기화(확인) → "비밀번호를 초기화했습니다", 새 비밀번호가 다름. 이전 비밀번호 로그인 401, 새 비밀번호 200
  - 계정 22개(API로 추가) → 처음 20개, "더 보기" → 22개, 중복 없음, 버튼 사라짐
  - 무효 토큰으로 새로고침 → 로그인 화면 "다시 로그인해 주세요.", 로그인 상태 지움
  - 콘솔 오류는 파비콘 404와 일부러 만든 409, 422 응답뿐
- Aside 브라우저: 확인용 탭을 따로 열어(5175) 같은 흐름을 다시 함. 목록 20개 + "더 보기", 등록(`asidecheck`) → 임시 비밀번호 창, 복사 → "복사함", 닫으면 사라지고 맨 위에 올라옴, 차단 → "차단 중", 해제 → "활성", 초기화 → "비밀번호를 초기화했습니다". 초기화 뒤 이전 비밀번호 401, 새 비밀번호 200(백엔드 로그인 API). "더 보기" 21 → 23. 스크린샷을 눈으로 확인하고 탭을 닫음.
- 완료 조건 1(샘플과 같은 화면): 샘플의 `users`, `create-taken`, `create-done`, `block`과 스크린샷 비교. 표의 칸, 상태·비밀번호 라벨 색, 버튼, 임시 비밀번호 상자(고정폭 큰 글자, 복사 버튼), 안내 문구가 같다. 다른 점: 대화상자 머리가 Primer 기본(작은 제목과 구분선)이다. 사용자 웹 대화상자(#24)와 같은 방식이라 그대로 둠. 라이트·다크·375px(표가 계정마다 한 장씩 쌓임) 확인.
  - 확인 중 본 것: 테마를 바꾼 직후 스크린샷의 버튼이 이전 색이었으나, Primer 버튼의 색 전환(80ms) 중이었고 1초 뒤 다크 색(`#212830`)이었다. 다크로 시작해도 같다. 고칠 것 없음(`admin/CLAUDE.md`에 적음).
- 완료 조건 2, 3: 위의 등록·초기화(임시 비밀번호 한 번 표시), 차단·해제(목록 반영).
- 한계: 원격 서버(ngrok)에서의 계정 관리는 실제 계정을 만들게 되어 하지 않았다. 사용자가 확인한다.

### 코드 리뷰 반영 내역
- codex(`codex review --uncommitted`): 2건 모두 반영
  - 목록을 받는 중에 등록하면 늦게 온 목록이 새 계정을 덮음 → 목록을 받는 동안 [계정 등록]을 막음
  - 차단·초기화를 기다리는 동안 대화상자를 닫고 다른 확인 창을 열면 늦게 온 응답이 그 창을 닫거나 엉뚱한 오류를 보임 → 기다리는 동안 취소와 Esc로 닫지 않음(등록 창도 같게)
- agy(`agy -p`, diff를 프롬프트에 넣음): 17건
  - 반영: 클립보드를 쓸 수 없는 환경(HTTP 주소)에서 복사 버튼 오류 → 그대로 둠(값을 직접 선택)
  - 반영: [차단 해제] 연타로 중복 요청 → 기다리는 동안 한 번만, 버튼에 기다림 표시
  - 반영: 기다리는 동안 대화상자 닫힘(codex와 같음)
  - 반영: 아이디를 고쳐도 이전 오류가 남음 → 고치면 지움
  - 반영: 임시 비밀번호 창이 Esc로 닫혀 비밀번호를 잃음 → "전달했습니다"로만 닫음
  - 반영: 타입 명시(`UserWithTemporaryPassword`, `fetchPage` 반환 타입, 테스트의 `AuthErrorCode`)
  - 반영: 테스트 보강("더 보기" 실패 후 다시, 초기화 취소, 등록 취소 후 입력칸 비움, 403 `FORBIDDEN`)
  - 넘어감: `new URL(request.url)` 상대 경로. `Request.url`은 항상 절대 주소이고 서버 주소에 하위 경로를 쓰지 않는다.
  - 넘어감: `letter-spacing: var(--base-size-2)`. 샘플(#4)에서 정한 그대로다.

### PR
- https://github.com/timonPark/iris/pull/71

### 남은 일
- 원격 서버에서의 계정 관리 확인(사용자).
