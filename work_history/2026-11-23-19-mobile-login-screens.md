# [mobile] 로그인과 비밀번호 변경 화면

| 항목 | 내용 |
|---|---|
| 이슈 | #19 (https://github.com/timonPark/iris/issues/19) |
| 브랜치 | 2026-11-23-19-mobile-login-screens |
| 상태 | 진행 중 |
| 시작일자 | 2026-11-23 |
| 종료일자 | |

## 작업 내용

모바일 앱의 로그인과 비밀번호 변경 화면.

### 범위
- 포함
  - [x] 로그인 화면
  - [x] 임시 비밀번호 로그인 직후의 비밀번호 변경 화면
  - [x] 설정의 비밀번호 변경 화면
  - [x] "차단됨" 안내
  - [x] 토큰 저장
- 제외: 회원가입, 비밀번호 찾기

### 완료 조건
- [x] 샘플(#5)과 같은 화면이다.
- [x] 임시 비밀번호로 로그인하면 변경 화면이 뜬다.
- [x] iOS와 Android에서 동작한다.

### 선행 이슈와 결정 필요
- [x] 선행 #5, #13, #16, #17 닫힘 확인 (2026-11-23)
- [x] 이슈의 결정 필요: 토큰 저장 방식 → 사용자 확정(아래)

### 사용자와 정한 것 (2026-11-23)
- 토큰 저장: 기기 보안 저장소(`flutter_secure_storage`. iOS Keychain, Android Keystore). 모바일 앱을 껐다 켜도 로그인이 유지된다.

### 이번에 정한 것 (Claude가 정함, 사용자 웹 #18을 따름)
- 관리자 계정은 막는다(`ssot/GLOSSARY.md` "사용자 앱"). 문구와 오류 처리는 사용자 웹(#18)과 같다: "관리자 계정은 관리자 웹을 이용해 주세요.", "새 비밀번호가 서로 다릅니다.", "새 비밀번호는 8자 이상이어야 합니다.", 설정에서 `INVALID_CREDENTIALS`면 "현재 비밀번호가 올바르지 않습니다.", "비밀번호를 변경했습니다.", 연결 실패는 "서버 오류가 발생했습니다.".
- 채팅 화면은 #25에서 만든다. 그때까지 로그인 뒤에는 "채팅 화면은 준비 중입니다."와 "설정" 버튼만 있는 자리를 두고, 설정은 그 위에 연다(뒤로 가기). #25에서 세션 목록 아래의 "설정"으로 옮긴다.
- 어느 API에서 받든 `UNAUTHORIZED`·`ACCOUNT_BLOCKED`면 토큰을 지우고 로그인 화면(안내), `PASSWORD_CHANGE_REQUIRED`면 강제 변경 화면. API 클라이언트가 한 곳에서 처리한다.
- HTTP는 `http` 패키지, 요청·응답 모양은 `lib/api/api_models.dart`에 규격과 같게 손으로 둔다(Dart용 생성기는 들이지 않음).
- 주 버튼 높이는 터치 최소 크기 44(샘플 #5의 버튼 규칙). 위쪽 막대는 샘플 topbar처럼 왼쪽 정렬 title-small과 아래 테두리(테마 `appBarTheme`).

## 진행 기록
- 2026-11-23 브랜치와 작업 파일 생성. 선행 #5, #13, #16, #17 닫힘 확인. GitHub Project 상태 `In Progress`, `Start date`·`Target date` 2026-11-23.
- 2026-11-23 토큰 저장 방식을 사용자와 정함(보안 저장소).
- 2026-11-23 테스트를 먼저 쓰고(저장, API 클라이언트, 로그인 상태, 세 화면) 컴파일 실패를 확인한 뒤 구현. `http`, `flutter_secure_storage` 추가.
- 2026-11-23 실제 백엔드로 확인: 이 PC에는 `backend/.env`가 없고 포트 8000은 다른 프로젝트라, #18처럼 볼륨 없는 임시 PostgreSQL 컨테이너(`iris-e2e-pg`, 포트 5544)와 임시 설정의 백엔드(포트 8010)를 띄움. 관리자 API로 `tempios1`, `tempand1`(임시 비밀번호), `blockuser1`(차단)을 만듦. 임시 통합 테스트(`integration_test`, 커밋하지 않음)로 iOS 시뮬레이터와 Android 에뮬레이터에서 화면을 조작하고 캡처.
- 2026-11-23 처음 캡처에서 위쪽 막대 제목이 기본 titleLarge(32)로 커서 샘플과 다름 → 테마에 `appBarTheme`을 넣음(테스트 먼저). 비밀번호를 초기화하고 다시 확인(iOS는 다크 모드).
- 2026-11-23 확인 뒤 임시 테스트와 `integration_test` 의존성을 되돌리고, 백엔드와 컨테이너를 멈춤(컨테이너는 `--rm`으로 삭제됨). 시뮬레이터는 라이트로 되돌림.
- 2026-11-23 코드 리뷰(codex, agy) 반영(결과 참고). 반영한 것은 테스트를 먼저 써서 실패를 확인한 뒤 고침.
- 2026-11-23 리뷰 반영 뒤 같은 방식(임시 DB·백엔드, 새 계정)으로 iOS·Android 통합 테스트를 다시 돌려 모두 통과. 다시 정리(임시 파일 삭제, 백엔드와 컨테이너 중지).

## 결과

### 변경한 파일
- 코드: `mobile/lib/main.dart`, `lib/api/`(`api_client.dart`, `api_models.dart`), `lib/auth/`(`auth_storage.dart`, `auth_controller.dart`, `messages.dart`, `password_change.dart`), `lib/screens/`(`auth_layout.dart`, `login_screen.dart`, `force_change_screen.dart`, `settings_screen.dart`, `home_placeholder_screen.dart`), `lib/widgets/form_parts.dart`, `lib/theme/app_theme.dart`(`appBarTheme`, `primerColorsOf`)
- 테스트: `test/api/api_client_test.dart`, `test/auth/`(`auth_storage_test.dart`, `auth_controller_test.dart`), `test/screens/`(`auth_screens_test.dart`, `password_screens_test.dart`), `test/support/`(`fake_api.dart`, `finders.dart`), `test/app_test.dart`, `test/theme/app_theme_test.dart`
- 패키지: `http` ^1.6.0, `flutter_secure_storage` ^11.2.0
- 문서: `mobile/CLAUDE.md`(로그인 상태와 화면 전환)
- 설정: `mobile/android/app/src/main/AndroidManifest.xml`(인터넷 권한)

### 확인 방법과 결과
- `flutter test` 44개 통과(리뷰 반영 뒤), `flutter analyze --fatal-infos` 문제 없음. 함수 30줄 초과 없음(스크립트로 확인).
- 실제 백엔드(임시) + 임시 통합 테스트(`flutter drive`), iOS 시뮬레이터 iPhone 17(다크)과 Android 에뮬레이터 Pixel 8(라이트) 모두 통과:
  - 완료 조건 1(샘플과 같은 화면): 로그인, 차단 안내, 비밀번호 강제 변경, 설정 화면을 캡처해 샘플과 비교. 배치, 문구, 버튼 색, 힌트 "8자 이상", 안내 상자, 위쪽 막대가 같다.
  - 완료 조건 2: 임시 비밀번호로 로그인 → "비밀번호 변경" 화면. 임시 비밀번호와 같은 값은 백엔드 문구("현재 비밀번호와 다른 비밀번호를 입력해 주세요."), 바꾸면 채팅 자리로 감.
  - 완료 조건 3: 위 흐름이 iOS와 Android에서 모두 통과.
  - 그 밖: 차단 계정 로그인 → "차단된 계정입니다. 관리자에게 문의해 주세요.", 설정에서 현재 비밀번호가 틀림 → "현재 비밀번호가 올바르지 않습니다.", 성공 → "비밀번호를 변경했습니다."와 칸 비움, 앱을 새로 띄워도 로그인 유지(보안 저장소).
  - iOS는 비밀번호 칸에 입력하면 시스템의 "암호를 저장하겠습니까?" 창이 뜬다(iOS 자동 완성의 정상 동작).

### 코드 리뷰
- codex(`codex review --uncommitted`): 1건 반영
  - 반영: 인터넷 권한이 Android debug·profile 매니페스트에만 있어 릴리스 빌드에서 로그인이 안 됨 → main 매니페스트에 추가. debug 빌드는 다시 통과. 릴리스 빌드는 이 PC의 네트워크에서 `storage.googleapis.com`(Flutter 릴리스 라이브러리)에 TLS로 접속하지 못해(`curl` 35) 돌리지 못함. main 매니페스트는 모든 빌드에 합쳐진다.
- agy(`agy -p`, 전체 diff): 8건
  - 반영: 성공 응답의 모양이 규격과 다르면 `TypeError`가 잡히지 않음 → `ApiFailure(null)`(테스트 추가)
  - 반영: 키체인·키스토어 읽기의 `PlatformException`이 잡히지 않아 빈 화면(loading)에 멈출 수 있음 → 로그인 전으로 봄(테스트 추가)
  - 반영: 로그인 요청에도 남은 토큰을 붙일 수 있음(규격 `security: []`) → 로그인은 토큰 없이 보냄(테스트 추가). 지금 흐름에서는 로그인 화면일 때 토큰이 없지만 규격대로 막음
  - 반영: 인증 오류를 받으면 저장소를 지운 뒤에야 화면이 바뀜 → 화면을 먼저 바꾸고 저장
  - 반영: 테스트 보강 — 설정에서 `UNAUTHORIZED`면 로그인 화면과 "다시 로그인해 주세요.", 비밀번호 변경의 연결 실패는 서버 오류(둘 다 처음부터 통과)
  - 넘어감: `required this._storage`가 컴파일 오류라는 지적 → Dart 3.14의 private named parameter로 밖에서는 `storage:`로 부른다. 분석과 테스트가 통과한다
  - 넘어감: 설정 화면의 8자·확인 불일치 테스트 → 강제 변경과 같은 함수(`changePassword`)를 써서 강제 변경 테스트로 확인됨
  - 넘어감: `login()`의 403 처리 테스트 → 클라이언트의 인증 오류 처리는 경로와 상관없는 같은 코드이고, 로그인 화면의 차단 안내는 위젯 테스트로 확인함
