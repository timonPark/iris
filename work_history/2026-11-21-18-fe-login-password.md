# [fe] 로그인과 비밀번호 변경 화면

| 항목 | 내용 |
|---|---|
| 이슈 | #18 (https://github.com/timonPark/iris/issues/18) |
| 브랜치 | 2026-11-21-18-fe-login-password |
| 상태 | 검증 대기 |
| 시작일자 | 2026-11-21 |
| 종료일자 | |

## 작업 내용

사용자 웹의 로그인과 비밀번호 변경 화면.

### 범위
- 포함
  - [x] 로그인 화면
  - [x] 임시 비밀번호 로그인 직후 바로 뜨는 비밀번호 변경 화면
  - [x] 설정의 비밀번호 변경 화면
  - [x] "차단됨" 오류를 받으면 로그인 화면으로 보내고 안내 표시
  - [x] 토큰 저장
- 제외: 회원가입, 비밀번호 찾기

### 완료 조건
- [x] 샘플(#3)과 같은 화면이다.
- [x] 임시 비밀번호로 로그인하면 변경 화면이 뜬다.
- [x] 차단된 계정은 로그인 화면에서 안내를 본다.

### 선행 이슈와 결정 필요
- [x] 선행 #3, #11, #16, #17 닫힘 확인 (2026-11-21)
- [x] 이슈의 결정 필요: 없음
- [x] 작업 중 나온 결정 2건을 사용자에게 물어 확정(아래)

### 사용자와 정한 것 (2026-11-21)
- 토큰 저장: `localStorage`. 브라우저를 닫았다 열어도 로그인이 유지된다. 로그아웃 버튼은 #3에서 넣지 않기로 했다.
- 관리자 계정: 사용자 웹은 관리자 계정의 로그인을 막는다. 로그인 응답의 `role`이 `admin`이면 토큰을 저장하지 않고 "관리자 계정은 관리자 웹을 이용해 주세요."라고 안내한다. `ssot/GLOSSARY.md`의 "사용자 앱"에 반영했다(모바일 앱도 같다).

### 이번에 정한 것 (Claude가 정함)
- 새로 쓴 문구(샘플에 없던 것): "관리자 계정은 관리자 웹을 이용해 주세요.", "새 비밀번호가 서로 다릅니다.", "새 비밀번호는 8자 이상이어야 합니다.", "현재 비밀번호가 올바르지 않습니다."(설정에서 `INVALID_CREDENTIALS`일 때. 규격 문구 "아이디 또는 비밀번호가…"는 설정 화면에 맞지 않음), "비밀번호를 변경했습니다.", 채팅 자리의 "채팅 화면은 준비 중입니다.". 연결 실패는 새 문구 없이 "서버 오류가 발생했습니다."를 쓴다.
- 화면 전환은 라우터 없이 상태로 한다(로그인, 비밀번호 강제 변경, 채팅 자리, 설정). 채팅 화면과 사이드바는 #24에서 만든다. 그때까지는 로그인 뒤 빈 채팅 자리에 "설정" 버튼만 둔다.
- 저장하는 값: `accessToken`, `passwordChangeRequired`, 로그인한 아이디(샘플 사이드바 아래에 아이디가 보인다. #24에서 쓴다).
- 다른 API 응답에서도 `UNAUTHORIZED`, `ACCOUNT_BLOCKED`면 저장한 토큰을 지우고 로그인 화면으로 보낸다(차단이면 차단 안내). `PASSWORD_CHANGE_REQUIRED`면 비밀번호 강제 변경 화면으로 보낸다. API 클라이언트가 한 곳에서 처리한다.

## 진행 기록
- 2026-11-21 브랜치와 작업 파일 생성. 선행 이슈 닫힘 확인. GitHub Project 상태 `In Progress`, `Start date`·`Target date` 2026-11-21.
- 2026-11-21 `ssot/`에 정의가 없는 2건(토큰 저장 위치, 관리자 계정 로그인)을 사용자에게 물어 확정.

- 2026-11-21 테스트를 먼저 쓰고(저장, API 클라이언트의 인증 오류 알림, 세 화면, App 흐름) 실패를 확인한 뒤 구현. 함수 30줄 규칙에 맞추려고 로직을 훅(`useLogin`, `usePasswordChange`, `useAuthFlow`)으로 나눔.
- 2026-11-21 이 PC에는 `backend/.env`가 없어(다른 PC에서 웹을 개발하는 환경) 확인용 임시 백엔드를 띄움: 볼륨 없는 임시 PostgreSQL 컨테이너(`iris-e2e-pg`, 포트 5544, 끝나고 삭제)와 임시 설정의 백엔드(포트 8010). 실제 백엔드와 데이터는 건드리지 않음. Aside 브라우저로 확인(결과 참고).
- 2026-11-21 코드 리뷰(codex, agy) 반영. PR을 올리고 상태를 `검증 대기`로 변경.

## 결과

### 변경한 파일
- 코드: `web/src/App.tsx`, `web/src/auth/`(`storage.ts`, `messages.ts`, `useLogin.ts`, `usePasswordChange.ts`, `useAuthFlow.ts`), `web/src/api/client.ts`(`onAuthError`), `web/src/api/safely.ts`, `web/src/components/FormParts.tsx`, `web/src/screens/`(`LoginScreen`, `ForceChangeScreen`, `SettingsScreen`, `ChatPlaceholder`), `web/src/index.css`
- 테스트: `web/src/auth/storage.test.ts`, `web/src/api/client.test.ts`, `web/src/screens/*.test.tsx`, `web/src/App.test.tsx`, `web/src/test/fakeApi.ts`
- 패키지: `@primer/octicons-react` 19.42.0(정확히 고정. `@primer/react`가 쓰는 버전과 같음), `@testing-library/user-event`(개발)
- 문서: `ssot/GLOSSARY.md`("사용자 앱"에 관리자 계정 로그인 금지), `web/CLAUDE.md`(로그인 상태와 화면 전환)

### 확인 방법과 결과
- `npm test` 39개 통과, `npm run build`(tsc 포함), `npm run lint` 오류 없음.
- Aside 브라우저, 임시 백엔드(관리자 API로 `tempuser1`(임시 비밀번호), `blockuser1`(차단)을 만듦), `VITE_API_BASE_URL=http://localhost:8010`:
  - 완료 조건 1(샘플과 같은 화면): 로그인, 비밀번호 강제 변경, 설정 화면을 스크린샷으로 샘플과 비교. 배치, 문구, 버튼 색, 힌트 "8자 이상", 안내 상자가 같다. 입력칸 글자 16px, 좁은 화면(375px)에서 "Iris" 제목이 20px(title-medium)로 줄어듦. 다크 모드 설정 화면도 확인.
  - 완료 조건 2: `tempuser1`을 임시 비밀번호로 로그인 → "비밀번호 변경" 화면. 새로고침해도 다시 뜸. 확인 값이 다르면 보내지 않고 안내, 임시 비밀번호와 같은 값은 백엔드 문구("현재 비밀번호와 다른 비밀번호를 입력해 주세요.") 표시, 바꾸면 채팅 자리로 가고 저장된 토큰이 새 토큰으로 바뀌고 `passwordChangeRequired`가 false.
  - 완료 조건 3: `blockuser1` 로그인 → "차단된 계정입니다. 관리자에게 문의해 주세요.", 토큰 저장 안 됨. 로그인한 상태에서 관리자 API로 `tempuser1`을 차단한 뒤 설정에서 비밀번호 변경을 시도 → 로그인 화면으로 가서 같은 안내, 저장한 토큰 삭제.
  - 그 밖: 틀린 비밀번호 → 규격 문구, 관리자 계정(`e2eadmin`) → "관리자 계정은 관리자 웹을 이용해 주세요."(토큰 저장 안 됨), 설정에서 현재 비밀번호가 틀림 → "현재 비밀번호가 올바르지 않습니다.", 성공 → "비밀번호를 변경했습니다."와 칸 비움.
  - 확인 뒤 임시 컨테이너와 서버를 멈추고 브라우저 저장소를 비웠다.

### 코드 리뷰 반영 내역
- codex(`codex review --uncommitted`): 2건 모두 반영
  - 반영: 응답을 기다리는 동안 다시 제출하면 요청이 두 번 간다(Primer `loading`은 제출을 막지 않음). 비밀번호 변경이 두 번 가면 첫 요청이 토큰을 바꾼 뒤 두 번째가 `UNAUTHORIZED`를 받아 로그인이 풀린다. 재현 테스트 2개를 먼저 쓰고 훅에서 막음.
  - 반영: 화면이 카드보다 낮으면(가로 모드, 확대) `align-items: center` 때문에 카드 위쪽이 잘려 스크롤로도 못 본다 → `margin: auto`로 가운데 정렬.
- agy(`agy -p`, diff를 프롬프트에 넣음): 15건
  - 반영: `PasswordPanel` 31줄 → 30줄 이하로 줄임
  - 반영: 변수 타입 명시(`SettingsScreen`의 `set`, `storage.ts`의 `v`)
  - 이미 반영됨: 중복 제출(codex 지적과 같음)
  - 넘어감: 설정에서 채팅으로 돌아가는 버튼. 샘플은 사이드바로 오가며 사이드바는 #24에서 만든다. 지금 채팅 자리는 기능이 없다.
  - 넘어감: `readErrorCode`의 `body.error.code`. 모양이 다르면 `try/catch`가 잡아 null을 돌려준다.
  - 넘어감: 입력칸 16px 미적용 위험. Aside에서 입력칸 글자가 16px인 것을 쟀다(안쪽 input이 상속).
  - 넘어감: 1024자 상한, 현재 비밀번호 빈 값 검사. 백엔드가 `VALIDATION_FAILED`로 거부하고 그 문구를 보여준다.
  - 넘어감: 입력칸 `name` 속성. `autocomplete`(username, current-password, new-password)로 비밀번호 관리자가 인식한다.
  - 넘어감: 테스트의 `vi.fn` 변수 타입. 제네릭(`vi.fn<…>`)으로 타입이 정해진다.
  - 넘어감: 미디어 쿼리 `48rem`. 조건에는 CSS 변수를 쓸 수 없어 주석과 함께 직접 쓴다(#3과 같음).
  - 넘어감: 채팅 자리와 설정에 `h1`이 없음. 샘플의 `h1`은 사이드바의 "Iris"이고 #24에서 들어간다.
  - 넘어감: work_history 상태와 체크리스트. 리뷰 시점에 진행 중이었다.

### PR
- https://github.com/timonPark/iris/pull/60

### 남은 일
- 채팅 화면, 사이드바(아이디 표시, 설정 버튼), 설정에서 돌아가기는 #24.
- 모바일 앱(#19)도 관리자 계정 로그인을 막아야 한다(`ssot/GLOSSARY.md`에 반영함).
- 확인에 쓴 임시 백엔드 방식(볼륨 없는 컨테이너 + 임시 설정)은 이 PC에서 다시 쓸 수 있다. 필요하면 `web/CLAUDE.md`에 적는다.
