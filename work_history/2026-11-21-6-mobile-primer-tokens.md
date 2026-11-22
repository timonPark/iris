# [mobile] Primer 토큰의 Flutter 적용 방식 결정

| 항목 | 내용 |
|---|---|
| 이슈 | #6 (https://github.com/timonPark/iris/issues/6) |
| 브랜치 | 2026-11-21-6-mobile-primer-tokens |
| 상태 | 완료 |
| 시작일자 | 2026-11-21 |
| 종료일자 | 2026-11-22 |

## 작업 내용

Primer는 React용이라 Flutter용 출력(Dart)이 없다. 웹과 앱의 값이 어긋나지 않게 Primer 패키지의 CSS 변수 값을 읽어 Dart 토큰 파일을 만든다.

### 범위
- 포함
  - [x] Primer 패키지의 CSS 변수 값을 읽어 Dart 토큰 파일을 생성하는 스크립트
  - [x] 색, 간격, 모서리, 글자 크기
  - [x] 라이트와 다크
  - [x] Primer 버전을 올리면 스크립트를 다시 돌려 재생성
- 제외: 손으로 값을 복사하는 방식

### 완료 조건
- [x] 스크립트를 실행하면 Dart 토큰 파일이 생성된다.
- [x] 생성된 값이 웹의 CSS 변수 값과 같다.
- [x] 라이트와 다크 값이 모두 있다.

### 선행 이슈와 결정 필요
- [x] 선행 #2 닫힘 확인 (2026-11-21)
- [x] 결정 필요: 없음 (방식은 확정)

### 이번에 정한 것 (Claude가 정함)
- 스크립트는 Node(이 PC에 Flutter·Dart가 없고, 웹과 같은 npm 패키지를 그대로 읽을 수 있다). 위치는 `mobile/tool/primer_tokens/`, `@primer/primitives`를 `11.10.0`으로 정확히 고정한 자체 `package.json`을 둔다(`ssot/PRIMER.md`).
- 원본은 패키지의 CSS 파일(웹이 쓰는 것과 같은 파일). 색은 `functional/themes/light.css`, `dark.css`의 첫 블록(테마 선택자)만 읽고, `var(--…)` 참조는 끝까지 따라가 실제 값으로 바꾼다. 한 가지 색으로 끝나지 않는 값(그림자 등 여러 값)은 넣지 않는다.
- 크기: `rem`은 16을 곱한 논리 픽셀(Flutter의 크기 단위), `px`는 그대로. `em`처럼 상대 단위는 넣지 않는다. 모바일 앱은 늘 터치 화면이므로 터치 화면용 파일(`size-coarse.css`)을 넣고 마우스용(`size-fine.css`)은 뺀다. 파일은 웹의 `primitives.css`가 불러오는 순서대로 읽어, 뒤 파일이 덮는 값(`size.css`의 `controlStack-*-auto` 8px)도 웹과 같게 한다. 그래서 터치 값은 `control-minTarget-auto`(44)만 남는다.
- 이름: CSS 변수 이름을 lowerCamelCase로(`--bgColor-default` → `bgColorDefault`). Primer에 옛 이름과 새 이름이 함께 있어(예: `--focus-outline-color`, `--focus-outlineColor`) Dart 이름이 겹치면, 값이 같을 때 하나만 넣고 다르면 스크립트가 멈춘다.
- 확인 스크립트(`npm run verify`): 생성한 Dart 값을 같은 Primer CSS를 불러온 Chrome의 계산값과 비교한다. Primer를 올릴 때도 다시 돌린다. `playwright-core`만 쓰고 브라우저는 설치된 Chrome을 쓴다.
- 출력: `mobile/lib/theme/primer_tokens.dart`(생성 파일, 커밋한다). Flutter 프로젝트는 #13에서 만든다.

## 진행 기록
- 2026-11-21 브랜치와 작업 파일 생성. 선행 #2 닫힘, 결정 필요 없음 확인. GitHub Project 상태 `In Progress`, `Start date`·`Target date` 2026-11-21.
- 2026-11-21 이 PC에 Flutter와 Dart가 설치되어 있지 않음을 확인.
- 2026-11-21 테스트를 먼저 쓰고(값 읽기·변환 함수, 실제 패키지로 만든 결과) 실패를 확인한 뒤 구현. 처음 실행에서 Dart 이름이 겹침(옛 이름·새 이름 별칭) → 값이 같으면 하나만 넣도록 고침(테스트 추가).
- 2026-11-21 브라우저 확인에서 3개(`controlStack-*-auto`)가 웹과 다름 → 웹은 `size.css`가 터치용 파일 뒤에서 다시 정해 8px. 파일을 웹과 같은 순서로 읽도록 고침(테스트 추가). 이후 1,973개 모두 같음.
- 2026-11-21 이 PC에 Dart가 없어 Docker의 공식 Dart 이미지(`dart:3.5`, 3.5.4)로 `dart analyze`. Flutter의 `dart:ui`는 순수 Dart SDK에 없어 `Color`, `FontWeight` 모양만 같은 대역으로 바꿔 확인.
- 2026-11-21 문서 반영(`ssot/PRIMER.md`, `mobile/CLAUDE.md`, `mobile/README.md`).
- 2026-11-21 코드 리뷰(codex, agy) 반영(결과 참고). PR을 올리고 상태를 `검증 대기`로 변경.
- 2026-11-22 검증: Homebrew로 Flutter 3.50.1(Dart 3.14.0) 설치. 저장소 밖 임시 Flutter 프로젝트에서 생성 파일을 불러와 analyze·위젯 테스트·화면 확인(결과 참고). Xcode가 없어 iOS·macOS 앱 대신 Flutter 웹으로 띄움.
- 2026-11-22 사용자 검증 후 머지 지시. 상태 `완료`.

## 결과

### 변경한 파일
- 스크립트: `mobile/tool/primer_tokens/`(`package.json`·`package-lock.json`, `tokens.mjs` 값 읽기·변환, `generate.mjs` 생성, `verify.mjs` 브라우저 비교, `tokens.test.mjs`, `generate.test.mjs`, `.gitignore`)
- 생성 파일: `mobile/lib/theme/primer_tokens.dart`(3,813줄)
- 문서: `ssot/PRIMER.md`(모바일 토큰 파일과 재생성·확인 방법), `mobile/CLAUDE.md`(명령어), `mobile/README.md`

### 확인 방법과 결과
- `npm test`: 21개 통과(hex 3·4·6·8자리·rgb()·rgba()·transparent, rem·px, 이름 변환, var() 참조 따라가기, 테마 파일의 첫 블록만 읽기, 실제 패키지로 만든 결과의 라이트·다크 값, 별칭, 파일 순서, 그림자·em 제외).
- 완료 조건 1: `npm run generate` → `mobile/lib/theme/primer_tokens.dart` 생성. 색 905개(라이트·다크), 크기·모서리·글자 163개. 두 번 만들어도 같은 파일(해시 같음).
- 완료 조건 2: `npm run verify` → 1,973개(색 라이트 905, 다크 905, 크기·줄 간격 150, 굵기 13)를 Chrome이 같은 Primer CSS로 계산한 값과 비교해 다른 값 0개. 일부러 값 2개를 바꾸면 두 개를 찾아 실패(exit 1)하는 것도 확인.
- 완료 조건 3: `PrimerColors.light`, `PrimerColors.dark`가 같은 이름의 색 905개를 모두 갖는다(예: `bgColorDefault` 라이트 `0xFFFFFFFF`, 다크 `0xFF0D1117`).
- Dart 문법: `dart:3.5` 이미지에서 `dart analyze --fatal-infos` "No issues found!"(생성 파일과, 그것을 쓰는 예시 코드).
- 2026-11-22 다시 실행: `npm test` 21개 통과, `npm run generate` 결과가 커밋한 파일과 같음(`git status` 변경 없음), `npm run verify` 1,973개 다른 값 0개.
- 2026-11-22 Flutter 3.50.1 확인(저장소 밖 임시 프로젝트, 생성 파일을 그대로 복사):
  - `flutter analyze --fatal-infos`: "No issues found!"(실제 `dart:ui`의 `Color`, `FontWeight`로 컴파일)
  - `flutter test` 3개 통과: 라이트·다크 `bgColorDefault`가 웹 값과 같음, 라이트·다크 토큰으로 그린 위젯의 크기 44×44(`PrimerSize.controlMinTargetAuto`), 모서리 6(`PrimerRadius.borderRadiusMedium`), 배경색
  - 화면: 라이트·다크 토큰(배경·글자·테두리·강조색 5가지, 간격, 모서리, 글자 크기·굵기)으로 그린 화면을 Flutter 웹으로 빌드해 Chrome에서 캡처, 사용자 확인
- 한계: 저장소 안 Flutter 프로젝트에서 테마로 연결하는 것은 #13에서 한다.

### 코드 리뷰 반영 내역
- codex(`codex review --uncommitted`): 지적 없음(테스트 19개 통과, 다시 만든 내용이 커밋할 파일과 같음을 확인).
- agy(`agy -p`, 생성 파일 일부와 diff를 프롬프트에 넣음): 16건
  - 반영: `verify.mjs`에서 브라우저가 값을 못 읽으면(`NaN`) 크기 비교가 통과로 처리됨 → 다른 값으로 봄
  - 반영: `var( --x )`처럼 괄호 안 공백이나 `var(--x, 대체값)`이면 참조를 못 따라감 → 이름만 보고 따라감(테스트 추가)
  - 반영: 상수 이름을 공백으로 잘라 꺼내던 것(형식이 바뀌면 깨짐) → 이름을 따로 들고 다님
  - 반영: 라이트와 다크 한쪽에만 있는 색이 조용히 빠짐 → 멈춤(테스트 추가)
  - 반영: JSDoc 타입이 빠진 함수(`parseHex`, `verify.mjs`의 함수들)
  - 넘어감: `PrimerSize`에 글자 토큰이 섞였다. 생성 파일에서 `PrimerSize`의 글자 토큰은 0개, `PrimerText`에 44개(프롬프트에 붙인 일부를 잘못 읽음).
  - 넘어감: 색 값 0~255 범위 제한. 원본은 Primer CSS라 범위를 넘는 값이 없다.
  - 넘어감: 첫 블록 안의 중첩 블록. Primer 테마 파일에는 중첩이 없다.
  - 넘어감: 크기·글자의 별칭 합치기. 겹치면 `assertUnique`가 멈추므로 조용히 틀리지 않는다(지금은 겹치는 이름 없음).
  - 넘어감: `verify.mjs`의 이름 찾기에 `dark.css`가 없다. 라이트와 다크의 이름이 같다(이제 생성 스크립트가 다르면 멈춘다).
  - 넘어감: `light.css`와 `dark.css`를 함께 불러오면 다크가 라이트를 덮는다. 두 파일은 `data-color-mode` 속성 선택자로 나뉘어 있고, 다크로 바꿔 비교한 값도 모두 맞았다.

### PR
- https://github.com/timonPark/iris/pull/63

### 남은 일
- Flutter 프로젝트를 만드는 #13에서 `lib/theme/primer_tokens.dart`를 실제로 불러 써 본다(테마 연결).
- 모바일 앱 샘플(#5)도 이제 시작할 수 있다.
- #13 참고: Flutter 3.50에서 `package:flutter/material.dart`가 deprecated(`package:material_ui/material_ui.dart`로 안내). 토큰 파일은 `dart:ui`만 써서 영향 없음.
