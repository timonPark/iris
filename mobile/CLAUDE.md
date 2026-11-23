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
