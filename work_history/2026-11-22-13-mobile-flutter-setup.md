# [mobile] 프로젝트 세팅 (Flutter)

| 항목 | 내용 |
|---|---|
| 이슈 | #13 (https://github.com/timonPark/iris/issues/13) |
| 브랜치 | 2026-11-22-13-mobile-flutter-setup |
| 상태 | 진행 중 |
| 시작일자 | 2026-11-22 |
| 종료일자 | |

## 작업 내용

모바일 앱 프로젝트를 만든다. iOS와 Android를 모두 지원한다.

### 범위
- 포함
  - [x] `mobile/` Flutter 프로젝트
  - [x] Primer 토큰 Dart 파일 적용(#6)
  - [x] 라이트·다크
  - [x] 서버 주소 설정
  - [x] `mobile/CLAUDE.md`에 실행·빌드 명령 채우기
- 제외: 화면 구현

### 완료 조건
- [x] iOS와 Android에서 앱이 실행된다.
- [x] 토큰이 적용된 테마가 보인다.
- [x] `mobile/CLAUDE.md`에 명령어가 적혀 있다.

### 선행 이슈와 결정 필요
- [x] 선행 #6 닫힘 확인 (2026-11-22)
- [x] 이슈의 결정 필요: 없음
- [x] 구현 전 점검에서 나온 확인 사항(아래, 사용자 확정)

### 사용자와 정한 것
- 실행 환경: Android SDK·에뮬레이터는 Claude가 설치하고, Xcode는 사용자가 App Store에서 설치한다. iOS 시뮬레이터 런타임은 Xcode 설치 후 Claude가 받는다.
- 앱 식별자: `com.timonpark.iris`(iOS 번들 ID, Android applicationId)
- 서버 주소: `--dart-define=API_BASE_URL=...`. 비우면 `http://localhost:8000`(웹과 같은 기본값). Android 에뮬레이터에서는 PC를 `10.0.2.2`로 부른다는 점을 `mobile/CLAUDE.md`에 적는다.
- 위젯 라이브러리: `package:material_ui`(Flutter 3.50에서 `package:flutter/material.dart`가 deprecated)

### 이번에 정한 것 (Claude가 정함)
- 테마 연결(`lib/theme/app_theme.dart`): ssot에 Material 테마 자리와 Primer 토큰의 짝이 없어서, PRIMER.md의 색 짝 규칙을 지키는 최소 연결로 정함. 배경 `bgColorDefault`·글자 `fgColorDefault`(surface/onSurface, scaffold), 보조 글자 `fgColorMuted`(onSurfaceVariant), 강조 `bgColorAccentEmphasis`·`fgColorOnEmphasis`(primary/onPrimary), 오류 `bgColorDangerEmphasis`·`fgColorOnEmphasis`(error/onError), 테두리 `borderColorDefault`·`borderColorMuted`(outline/outlineVariant). 글자는 Primer title·body 토큰의 크기·줄 간격·굵기를 titleLarge/Medium/Small, bodyLarge/Medium/Small에 넣음. 나머지 컴포넌트 테마는 화면 이슈에서 필요할 때 더한다.
- 테마는 기기 설정을 따른다(`ThemeMode.system`).
- 첫 화면은 테마 확인용 자리 표시 화면(앱 이름과 "준비 중입니다.")만 둔다. 실제 화면은 #19, #25.

## 진행 기록
- 2026-11-22 브랜치와 작업 파일 생성. 선행 #6 닫힘 확인. GitHub Project 상태 `In Progress`, `Start date`·`Target date` 2026-11-22.
- 2026-11-22 구현 전 점검: 이 PC에 Flutter 3.50.1은 있으나 Xcode(iOS)와 Android SDK·에뮬레이터가 없어 완료 조건 1을 확인할 수 없음. 앱 식별자, 서버 주소 설정 방식도 정해진 곳이 없어 사용자에게 확인(위 "사용자와 정한 것").
- 2026-11-23 Android 설치: brew로 `android-commandlinetools`, `openjdk@21`. sdkmanager로 platform-tools, emulator, platforms;android-36, build-tools;36.0.0, 시스템 이미지(android-36 google_apis arm64). 에뮬레이터 `iris_pixel`(Pixel 8) 생성. `flutter config`에 SDK와 JDK 21 지정.
- 2026-11-23 `flutter create --org com.timonpark --project-name iris --platforms=ios,android --empty`로 프로젝트 생성. 기존 파일(`README.md`, `CLAUDE.md`, `lib/theme/`, `tool/`)은 그대로. 생성 결과가 이미 `material_ui`를 씀.
- 2026-11-23 테스트(테마, 서버 주소, 앱) 먼저 쓰고 실패 확인 → 구현 → 12개 통과, `flutter analyze --fatal-infos` 문제 없음.
- 2026-11-23 Android 에뮬레이터에서 실행해 라이트·다크 화면 확인. 처음엔 `flutter emulators --launch`로 띄운 에뮬레이터가 빌드 중 꺼짐 → 에뮬레이터를 따로 띄워 해결.
- 2026-11-23 iOS: 사용자가 Xcode 27.2 설치와 `xcode-select`·`-runFirstLaunch`·라이선스 동의를 마침. iOS 27.2 시뮬레이터 런타임은 이미 있었음. CocoaPods 1.17 설치(이번엔 플러그인이 없어 안 쓰지만 #19, #32에서 필요). iPhone 17 시뮬레이터에서 실행해 라이트·다크 확인.
- 2026-11-23 Xcode 27에는 Simulator 앱이 기존 위치에 없어 `open -a Simulator`가 실패 → `mobile/CLAUDE.md`를 `xcrun simctl boot "iPhone 17"`로 고침(창 없이 켜지고 `flutter devices`에 잡힘).
- 2026-11-23 코드 리뷰(codex, agy) 반영(결과 참고).

## 결과

### 변경한 파일
- Flutter 프로젝트(`flutter create` 기본 생성물): `mobile/pubspec.yaml`·`pubspec.lock`, `analysis_options.yaml`, `.gitignore`, `.metadata`, `android/`, `ios/`
- `mobile/lib/main.dart`: `IrisApp`(라이트·다크 테마, 기기 설정 따름), 테마 확인용 자리 표시 화면
- `mobile/lib/theme/app_theme.dart`: `buildAppTheme(Brightness)` Primer 토큰 → ColorScheme, TextTheme
- `mobile/lib/config.dart`: `apiBaseUrl`, `resolveApiBaseUrl`(웹 `src/config.ts`와 같은 규칙)
- 테스트: `mobile/test/app_test.dart`, `test/theme/app_theme_test.dart`, `test/config_test.dart`
- 문서: `mobile/CLAUDE.md`(실행과 빌드), `mobile/README.md`(상태)

### 확인 방법과 결과
- `flutter test`: 9개 통과(라이트·다크 색 짝, 라이트·다크 글자 토큰, 서버 주소 기본값·공백·끝의 `/`, 기기 라이트·다크에 따른 앱 테마).
- `flutter analyze --fatal-infos`: "No issues found!"
- 함수 길이: lib·test의 모든 함수 30줄 이하(awk로 확인).
- 생성 파일 `lib/theme/primer_tokens.dart`: 바뀌지 않음(`npm run generate` 후 `git diff` 없음).
- 완료 조건 1, 2:
  - Android: Pixel 8 에뮬레이터(Android 16, API 36)에 `flutter build apk --debug` → `adb install` → 실행. `com.timonpark.iris/.MainActivity`가 맨 앞 화면. 기기 다크 모드(`cmd uimode night yes`)로 바꾸면 앱도 다크 토큰 배경으로 바뀜(캡처 확인).
  - iOS: iPhone 17 시뮬레이터(iOS 27.2)에 `flutter build ios --simulator --debug` → `simctl install` → 실행. `simctl ui appearance dark`로 바꾸면 다크로 바뀜(캡처 확인).
  - `flutter devices`가 두 기기를 모두 잡음.
- 완료 조건 3: `mobile/CLAUDE.md`의 "실행과 빌드 (#13)"에 명령어, 서버 주소, Android 에뮬레이터의 `10.0.2.2`, 위젯 라이브러리, 테마 위치를 적음.

### 코드 리뷰 반영 내역
- codex(`codex review --uncommitted`): 지적 없음.
- agy(`agy -p`, android·ios 기본 생성물을 뺀 diff): 3건
  - 반영: 서버 주소가 공백뿐이면 기본 주소를 써야 함 → 웹(`src/config.ts`)과 같게 앞뒤 공백을 자르고 끝의 `/`도 뺌(테스트 추가)
  - 반영: 테마 테스트의 `main`이 30줄을 넘음 → 검사 함수로 나눔. `dart format` 뒤 `_textTheme`(40줄)도 넘어서 글자 토큰 묶음을 상수로 뺌
  - 반영: 테스트에 `titleMedium`, `bodyMedium`, `secondary`, `onSecondary` 검증이 빠짐 → 추가

### PR

### 남은 일
- 화면 이슈(#19, #25, #32)에서 필요한 컴포넌트 테마(버튼, 입력칸 등)를 Primer 토큰으로 더한다.
- `ssot/PRIMER.md`에 Material 테마 자리와 Primer 토큰의 연결(이번에 Claude가 정한 것)을 올릴지 사용자 확인이 필요하다.

