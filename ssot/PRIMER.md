# Primer 적용 방침

사용자 웹, 관리자 웹, 모바일 앱이 같은 디자인 언어를 쓰도록 Primer를 기준으로 삼는다. 이 문서는 3개 클라이언트가 함께 따르는 기준이다. 문서와 화면이 다르면 이 문서가 맞다.

용어: 이 문서의 "디자인 토큰"은 색, 간격, 모서리, 글자 같은 디자인 값의 이름이다. 로그인에서 쓰는 accessToken과 무관하다.

## 패키지와 버전

| 패키지 | 버전 | 쓰는 곳 |
|---|---|---|
| `@primer/primitives` | `11.10.0` (정확히 고정) | 사용자 웹, 관리자 웹, 모바일(#6에서 값만 읽어 Dart로 생성) |
| `@primer/react` | `38.46.0` (정확히 고정) | 사용자 웹, 관리자 웹 |

- 두 패키지의 버전은 사용자 웹과 관리자 웹이 같게 쓴다. 설치할 때 `--save-exact`로 고정하고 lock 파일을 커밋한다.
- `@primer/react` 38.46.0은 `@primer/primitives` `10.x || 11.x`와 `react` `18.x || 19.x`를 요구한다. 11.10.0은 이 범위 안이다.
- 버전을 올릴 때는 웹 두 곳과 모바일(#6의 생성 스크립트 재실행)을 함께 올린다. 한 쪽만 올리지 않는다.
- 모바일의 Dart 토큰 파일은 생성 결과를 커밋하고, 버전을 올리는 PR에 다시 생성한 파일을 함께 넣는다. 웹의 CSS 변수 값과 같은지 확인하는 방법은 #6의 완료 조건이다.
- 이슈와 일부 문서에 `primer/react`로 적힌 곳이 있지만, 실제 패키지 이름은 `@primer/react`, `@primer/primitives`다.

## 테마 (라이트와 다크)

- 라이트와 다크를 모두 지원한다. 색은 테마별 파일(`light.css`, `dark.css`)에 있고, 간격·모서리·글자는 테마와 무관한 `primitives.css`에 있다. 둘 다 불러와야 한다.
- 테마는 루트 요소의 `data-color-mode`(`light`, `dark`, `auto`)로 고른다. 색 토큰의 선택자는 `data-light-theme`, `data-dark-theme`도 함께 요구하므로, 세 속성이 모두 있어야 색이 적용된다.
- 이 속성들을 어떻게 설정하는지(`@primer/react`의 `ThemeProvider` 사용 여부)와 `auto`가 기기 설정에 맞춰 바뀌는 동작은 프로젝트 세팅(#11)에서 확인한다.
- 색 토큰은 라이트와 다크에서 이름이 같고 값만 다르다. 그래서 코드는 테마를 구분하지 않고 토큰 이름만 쓴다.
- 접근성 변형 테마(색약, 고대비 등)는 이번 범위에 넣지 않는다.

## 디자인 토큰 사용 규칙

1. **색, 간격, 모서리, 글자는 토큰만 쓴다.** `#fff`, `16px` 같은 값을 직접 쓰지 않는다. 토큰이 없으면 임의로 만들지 말고 먼저 묻는다.
2. **색은 짝을 맞춘다.**
   - `bgColor-default`와 `fgColor-default`가 기본 짝이다.
   - `bgColor-*-emphasis` 위의 글자는 `fgColor-onEmphasis`를 쓴다.
   - `bgColor-muted` 위에는 `fgColor-default`를 쓰고 `fgColor-muted`를 쓰지 않는다.
   - 글자 대비는 일반 글자 4.5:1, 큰 글자와 컨트롤 3:1 이상이다.
3. **글자는 shorthand 토큰을 쓴다.** `font: var(--text-body-shorthand-medium)`처럼 글자 크기와 줄 간격, 굵기를 한 번에 정한다. 역할에 맞는 토큰을 쓴다(제목은 `title`, 본문은 `body`). 여러 줄 본문에 `caption`을 쓰지 않는다.
   - 질문, 답변, 입력칸처럼 사용자가 쓰거나 읽는 내용은 `--text-body-shorthand-large`(16px)를 쓴다. 16px 미만이면 iOS Safari가 입력칸을 누를 때 화면을 확대한다.
   - 좁은 화면(`--breakpoint-medium` 미만)에서는 `--text-title-shorthand-large`를 `--text-title-shorthand-medium`으로 한 단계 줄이고, 본문은 그대로 둔다(Primer 토큰 설명의 규칙). 사용자 웹 샘플(#3) 검토에서 정했다.
4. **간격은 토큰을 쓴다.** 레이아웃 간격은 `--stack-gap-*`, `--stack-padding-*`(`condensed`, `normal`, `spacious`), 버튼 같은 컨트롤은 `--control-*` 토큰을 쓴다. 기본은 `medium`과 `normal`이다.
5. **모서리는 `--borderRadius-*`를 쓴다.** `small`, `medium`, `large`, `full`이 있고 기본은 `medium`이다.
6. **겹치는 층은 `--zIndex-*`를 쓴다.** 숫자를 직접 쓰지 않는다.
7. **움직임은 `--motion-*` 토큰을 쓴다.** 300ms를 넘기지 않고, `prefers-reduced-motion`이면 움직임을 끈다.
8. **상호작용 요소는 다섯 상태(기본, hover, `:focus-visible`, active, disabled)를 모두 정한다.** 비활성은 투명도가 아니라 `bgColor-disabled`, `fgColor-disabled`로 표현한다.

모바일 앱은 CSS 변수를 쓸 수 없으므로 같은 규칙을 Dart 토큰 파일로 따른다. 생성 방식은 이슈 #6에서 정한다.

## 글꼴

- **한글 글꼴을 따로 지정하지 않는다.** Primer 기본 글꼴 스택(`--fontStack-sansSerif`)을 그대로 쓰고, 글꼴 파일이나 웹폰트를 따로 불러오지 않는다.
- 기본 스택에는 한글 글꼴이 없어서 한글은 기기의 시스템 글꼴로 표시된다. 기기마다 한글 모양이 조금씩 다른 것은 감수한다.
- 스택 맨 앞의 `Mona Sans VF`는 우리가 넣어 주지 않으므로 대부분 기기에서 다음 글꼴로 넘어간다.
- 모바일 앱은 글꼴 파일을 넣지 않고 기기 기본 글꼴을 쓴다. 글자 크기, 줄 간격, 굵기는 위 토큰 값을 따른다.
- 한글 글꼴을 지정해야 할 일이 생기면 이 문서를 먼저 고치고 3개 클라이언트에 알린다.

## 확인한 사실

2026-11-17에 `@primer/primitives@11.10.0` 패키지를 받아 직접 확인했다.

- 색 토큰 파일은 테마마다 하나씩 있다(`light.css`, `dark.css` 등). `light.css`와 `dark.css`의 변수 이름 959개가 서로 완전히 같고 값만 다르다.
- 테마 선택자는 `[data-color-mode="light"][data-light-theme="light"]`, `[data-color-mode="dark"][data-dark-theme="dark"]`, `auto` 형태다.
- 글자, 간격, 모서리 토큰은 `:root`에 정의되어 있다.
- 규칙에서 이름을 든 토큰 계열이 모두 있다: `--zIndex-*`(behind, default, sticky, dropdown, overlay, modal, popover, skipLink), `--motion-duration-*`, `--motion-easing-*`, `--motion-transition-*`, `--control-medium-*`, `--stack-gap-*`, `--stack-padding-*`, `--focus-outline`, `--outline-focus-offset`, `fgColor-onEmphasis`, `bgColor-disabled`, `fgColor-disabled`.
- `--fontStack-sansSerif`는 `"Mona Sans VF"`, `-apple-system`, `BlinkMacSystemFont`, `"Segoe UI"`, `"Noto Sans Backtick Fix"`, `"Noto Sans"`, `Helvetica`, `Arial`, `sans-serif`, 이모지 글꼴 순서이고 한글 전용 글꼴은 없다.
