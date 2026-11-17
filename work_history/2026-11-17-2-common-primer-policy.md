# [common] Primer 디자인 시스템 적용 방침 정리

| 항목 | 내용 |
|---|---|
| 이슈 | #2 (https://github.com/timonPark/iris/issues/2) |
| 브랜치 | 2026-11-17-2-common-primer-policy |
| 상태 | 검증 대기 |
| 시작일자 | 2026-11-17 |
| 종료일자 | |

## 작업 내용

웹(사용자 웹, 관리자 웹)과 모바일 앱이 같은 디자인 언어를 쓰도록 Primer(`@primer/react`, `@primer/primitives`)를 기준으로 삼는다. 정리 결과를 `ssot/`에 문서로 남긴다.

### 범위
- [x] 쓰는 패키지와 버전 고정 (`@primer/primitives` 11.10.0, `@primer/react` 38.46.0)
- [x] 라이트·다크 테마 지원
- [x] 색·간격·모서리·글자는 토큰만 쓰는 규칙
- [x] 한글 글꼴 처리
- [x] 정리 결과를 `ssot/`에 문서로 남기기 (`ssot/PRIMER.md`)

제외: 화면 구현, Flutter 적용(#6)
제외(이슈에 없던 결정, 검토 필요): 접근성 변형 테마(색약, 고대비 등). 이슈 범위가 "라이트·다크 지원"뿐이라 `ssot/PRIMER.md`에 범위 밖으로 적었다.

### 완료 조건
- [x] `ssot/`에 Primer 적용 방침 문서가 있다.
- [x] 웹과 앱이 따를 토큰 사용 규칙이 적혀 있다.

### 결정 필요
- [x] 한글 글꼴: 따로 지정하지 않고 시스템 글꼴 유지 (사용자 결정)

## 진행 기록
- 2026-11-17 브랜치와 작업 파일 생성. 선행 이슈 없음. "결정 필요"(한글 글꼴)가 남아 있어 구현 전에 사용자에게 확인함.
- 2026-11-17 결정: 한글 글꼴은 지정하지 않고 시스템 글꼴 유지.
- 2026-11-17 `ssot/PRIMER.md` 작성.
- 2026-11-17 코드 리뷰: `codex`, `agy`가 없어 `/code-review`(medium)로 대신함. 첫 실행은 작업 경로가 git 저장소가 아니어서 아무것도 검토하지 못했고(빈 결과를 통과로 보지 않음), 파일 경로를 지정해 다시 실행함.
- 2026-11-17 코드 리뷰 지적을 반영해 `ssot/PRIMER.md`와 이 파일을 고침.
- 2026-11-17 PR 생성, 상태를 `검증 대기`로 변경.

## 결과

### 변경한 파일
- `ssot/PRIMER.md` (신규)
- `work_history/2026-11-17-2-common-primer-policy.md` (신규)

### 확인 방법과 결과
확인에 쓴 명령(다시 하려면 아래를 그대로 실행하면 된다. 받은 파일은 임시 폴더에만 두고 프로젝트에는 설치하지 않았다).

- 버전과 호환 범위: `npm view @primer/primitives@11.10.0 version` → 11.10.0 존재. `npm view @primer/react version peerDependencies dependencies.@primer/primitives` → 38.46.0, `react 18.x || 19.x`, `@primer/primitives 10.x || 11.x`.
- 패키지 내용: `npm pack @primer/primitives@11.10.0`을 새 폴더에 받아 `dist/css/` 아래를 `grep`으로 확인.
  - 색 토큰: `functional/themes/light.css`, `dark.css`의 변수 이름 959개가 서로 같음(차이 0). 선택자는 `[data-color-mode="light"][data-light-theme="light"]`, `[data-color-mode="dark"][data-dark-theme="dark"]`와 `auto` 형태.
  - 글자, 간격, 모서리: `functional/typography/typography.css`, `functional/spacing/space.css`, `functional/size/radius.css`.
  - 규칙에서 이름을 든 계열: `zIndex`, `motion`, `control`, `focus`, `onEmphasis`, `disabled`가 모두 존재.
  - 글꼴 스택: `--fontStack-sansSerif`에 한글 전용 글꼴 없음.
- 확인하지 못한 것: `data-color-mode="auto"`가 기기 설정에 맞춰 바뀌는 실제 동작과, 세 속성을 `ThemeProvider`가 설정하는지. 문서에 그렇게 적었고 프로젝트 세팅(#11)에서 확인하기로 함.

### 코드 리뷰 반영 내역
- 반영: 테마 선택자가 `data-light-theme`, `data-dark-theme`도 요구한다는 점 추가
- 반영: 확인한 사실의 글꼴 스택에 `Mona Sans VF` 등 전체 스택 기재
- 반영: 규칙에 쓴 토큰 계열을 실제로 확인하고 확인한 사실에 기재
- 반영: "1,918줄"을 "변수 이름 959개가 라이트와 다크에서 같다"로 교체
- 반영: 좁은 화면 글자 크기 규칙은 매핑이 없어 샘플 화면(#3~#5) 검토에서 정하는 것으로 미룸
- 반영: Dart 토큰 파일은 생성 결과를 커밋하고 버전 올리는 PR에 함께 넣는다고 추가(검증 방법은 #6)
- 반영: 확인 방법에 명령과 경로 기재, 접근성 테마 제외를 이 파일에 기록, 코드 리뷰와 PR 칸 추가
- 넘어감: 없음

### PR
- (PR 생성 후 기입)

### GitHub Project
- 상태(`In Progress`, `검증 대기`)와 `Start date`, `Target date`는 갱신하지 못했다. 현재 `gh` 토큰에 `project` 권한이 없다.

### 남은 일
- 이슈 본문과 일부 README에 `primer/react`로 적힌 곳이 있어 `@primer/react`로 고칠지 정해야 함(이 이슈 범위 밖이라 건드리지 않음).
