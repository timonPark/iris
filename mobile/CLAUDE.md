# mobile

## 기준 문서

- 용어와 개념은 `../ssot/`를 기준으로 작업합니다. mobile의 코드, 변수명, 화면 문구도 `../ssot/`의 용어를 따릅니다.
- `../ssot/`에 정의가 없거나 모호하면 임의로 정하지 말고 먼저 묻습니다.

## 행동 지침

루트 CLAUDE.md의 행동 지침을 따르며, mobile에서는 이렇게 적용합니다.

- **먼저 묻기**: 녹음 버튼 동작과 최대 녹음 길이는 `../ssot/GLOSSARY.md`의 "음성 입력"을 따릅니다(#5에서 정함). 정의에 없는 동작은 임의로 정하지 않고 묻습니다. API 규격이 모호할 때도 추측하지 않습니다.
- **단순하게**: 보정된 텍스트를 화면에 표시하고 바로 Hermes로 전송합니다. 수정 단계는 만들지 않습니다.
- **필요한 곳만**: 음성 업로드는 모바일 전용 엔드포인트를 씁니다. 웹과 공유하는 API 규격은 임의로 바꾸지 않고, iOS와 Android 양쪽 영향을 확인합니다.
- **검증 먼저**: 녹음 → 업로드 → 보정 텍스트 표시 → 답변 스트리밍 흐름을 단계별 검증 기준으로 정하고 구현합니다.

## 실행과 빌드 (#13)

Flutter 3.50 이상(Dart 3.14). 앱 식별자는 iOS·Android 모두 `com.timonpark.iris`입니다.

```bash
flutter pub get
flutter analyze --fatal-infos   # 정적 분석. info도 실패로 본다
flutter test                    # 테스트
flutter devices                 # 실행할 기기 확인
flutter emulators --launch iris_pixel   # Android 에뮬레이터 켜기
xcrun simctl boot "iPhone 17"           # iOS 시뮬레이터 켜기(Xcode 27은 창 없이 켜진다)
flutter run -d <기기 id>                 # 실행
flutter build apk --debug               # Android 빌드
flutter build ios --simulator           # iOS 시뮬레이터용 빌드
```

- 서버 주소는 `--dart-define=API_BASE_URL=...`로 넣습니다. 비우면 `http://localhost:8000`입니다(`lib/config.dart`).
- Android 에뮬레이터 안에서 `localhost`는 에뮬레이터 자신입니다. PC의 백엔드는 `--dart-define=API_BASE_URL=http://10.0.2.2:8000`으로 부릅니다. iOS 시뮬레이터는 `localhost` 그대로 됩니다.
- 위젯은 `package:material_ui/material_ui.dart`를 씁니다. Flutter 3.50에서 `package:flutter/material.dart`는 deprecated입니다.
- 테마는 `lib/theme/app_theme.dart`의 `buildAppTheme`이 Primer 토큰으로 만들고, 기기의 라이트·다크 설정을 따릅니다.

## 로그인 상태와 화면 전환 (#19)

- 로그인 상태는 기기 보안 저장소(`flutter_secure_storage`, iOS Keychain·Android Keystore)의 `iris.auth`(`lib/auth/auth_storage.dart`)가 기준입니다: `accessToken`, `passwordChangeRequired`, `loginId`. 모바일 앱을 껐다 켜도 유지되고 로그아웃 버튼은 없습니다.
- 화면 전환은 `AuthController`(`lib/auth/auth_controller.dart`)의 `screen`(`loading`, `login`, `forceChange`, `home`)을 `IrisApp`이 따릅니다. `home`은 채팅 화면(`lib/screens/chat_screen.dart`)입니다.
- 어느 API에서 받든 `UNAUTHORIZED`·`ACCOUNT_BLOCKED`면 토큰을 지우고 로그인 화면(안내 표시), `PASSWORD_CHANGE_REQUIRED`면 강제 변경 화면으로 갑니다. `ApiClient`의 `onAuthError`가 한 곳에서 처리하고, 위에 연 화면(설정 등)은 `IrisApp`이 닫습니다. 화면마다 따로 처리하지 않습니다.
- 관리자 계정은 로그인 응답의 `role`로 막습니다(`../ssot/GLOSSARY.md` "사용자 앱").
- 화면 문구는 `lib/auth/messages.dart`에 모읍니다(사용자 웹 `web/src/auth/messages.ts`와 같은 문구). 오류는 규격의 `message`를 그대로 쓰고, 연결 실패(응답 없음)는 "서버 오류가 발생했습니다."입니다.
- 요청·응답 모양은 `lib/api/api_models.dart`에 `docs/api/openapi.yaml`과 같게 손으로 둡니다. 결과는 `ApiOk`/`ApiFailure`(`error`가 null이면 연결 실패)입니다.
- 폼 버튼은 응답을 기다리는 동안 누를 수 없게 합니다(`PrimaryButton`의 `busy`). 위쪽 막대는 테마의 `appBarTheme`(샘플의 topbar)를 씁니다.
- 테스트는 `test/support/fake_api.dart`(경로별 응답을 정하는 가짜 `http.Client`)와 `FlutterSecureStorage.setMockInitialValues`를 씁니다. 입력칸은 `test/support/finders.dart`의 `fieldFor('라벨')`로 찾습니다.

## 채팅 (#25)

- 구조: `lib/chat/`(상태와 API: `ChatController` 지금 세션, `SessionsController` 목록, `sse.dart`, `chat_item.dart`), `lib/widgets/`(`SessionDrawer`, `ThreadView`, `Composer`, `DeleteDialog`), 틀은 `lib/screens/chat_screen.dart`. 설정은 서랍 아래의 "설정"으로 본문 자리에 열고, 세션을 누르면 채팅으로 돌아옵니다.
- 질문 전송 SSE는 `ApiClient.sendQuestion`이 돌려주는 바이트 스트림을 `parseSse`로 읽습니다. 시작 전 실패는 일반 JSON 오류라서 차단·토큰 무효 처리를 그대로 탑니다.
- **새 세션은 답변이 끝날 때 저장됩니다.** 목록에 올리고 지금 세션 ID로 정하는 것은 `done`, `stopped`, 조각을 받은 뒤의 `error`를 받았을 때입니다. 중지 API에는 `session` 이벤트의 ID를 씁니다(사용자 웹 #24와 같음).
- 다른 세션을 열어도 받던 답변은 끝까지 읽어, 저장되면 목록에 올립니다. 화면 갱신은 generation이 같을 때만 합니다.
- **연결이 끊기면**(끝 이벤트 없이 스트림이 끝남) 받은 부분까지 두고 안내합니다(`AnswerState.disconnected`, `../ssot/GLOSSARY.md` "답변"). 모바일 앱이 앞에 있으면 바로, 아니면 다시 앞으로 왔을 때(`AppLifecycleListener.onResume` → `ChatController.resumed`) 그 세션을 다시 불러와, 저장이 끝났으면 전체 답변으로 바꿉니다.
- 답변은 일반 텍스트(줄바꿈 유지)로 보여줍니다. 마크다운과 링크 처리는 하지 않습니다(링크는 #39). 입력이 비었을 때의 녹음 버튼은 #32에서 붙입니다.
- 테스트 도구(`test/support/fake_api.dart`): `sseReply`(한 번에 끝나는 SSE), `ControlledSse`(이벤트를 하나씩 흘리고 `cut`/`fail`로 끊음), `sessionPage`, `questionPage`, `requestsTo(path)`.
- 기기 확인(Hermes 없는 PC): 볼륨 없는 PostgreSQL 컨테이너 + 임시 설정의 백엔드 + OpenAI 호환 가짜 Hermes + 임시 통합 테스트(`flutter drive`, 커밋하지 않음). 연결 끊김은 앱과 백엔드 사이에 TCP 중계를 두고 끊어서 확인합니다(#25 work_history 참고). Android는 `flutter drive`가 앱을 다시 설치해 로그인 상태가 지워지고, 스크린샷 전에 `convertFlutterSurfaceToImage()`가 필요합니다. iOS 시뮬레이터 앱의 `debugPrint`는 `flutter drive` 출력에 나오지 않습니다.

## Primer 토큰 (#6)

Flutter용 Primer 출력이 없어서 `@primer/primitives`의 CSS 변수 값을 읽어 Dart 파일을 만듭니다(`../ssot/PRIMER.md`).

```bash
cd tool/primer_tokens
npm install          # 처음 한 번(@primer/primitives 11.10.0, 웹과 같은 버전)
npm test             # 생성 스크립트 테스트
npm run generate     # lib/theme/primer_tokens.dart 다시 만들기
npm run verify       # 생성한 값이 웹의 CSS 변수 값(Chrome에서 계산)과 같은지 확인. CHROME_PATH로 Chrome 위치를 바꿀 수 있다
```

- `lib/theme/primer_tokens.dart`는 생성 파일이라 손으로 고치지 않고, 다시 만든 결과를 커밋합니다.
- 화면 코드는 색을 `PrimerColors.light`/`dark`로, 간격·크기는 `PrimerSize`, 모서리는 `PrimerRadius`, 글자는 `PrimerText`로 씁니다. 값을 직접 쓰지 않습니다.
- Primer 버전을 올릴 때는 웹 두 곳과 함께 `tool/primer_tokens/package.json`의 버전을 바꾸고 generate → verify 순서로 돌립니다.
