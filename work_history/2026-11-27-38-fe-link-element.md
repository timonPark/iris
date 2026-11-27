# [fe] 링크를 화면 요소로 표시

| 항목 | 내용 |
|---|---|
| 이슈 | #38 (https://github.com/timonPark/iris/issues/38) |
| 브랜치 | 2026-11-27-38-fe-link-element |
| 상태 | 완료 |
| 시작일자 | 2026-11-27 |
| 종료일자 | 2026-11-27 |

## 작업 내용

구글 링크를 사용자 웹에서 화면 요소로 표시한다. 기준: `ssot/GLOSSARY.md` "자료 링크", `docs/PROJECT_SPEC.md`.

### 범위
- 포함: 링크를 화면 요소로 표시, 구글 앱으로 연결
- 제외: 링크 목록 관리

### 완료 조건
- [x] 링크를 누르면 구글 앱으로 열린다.

### 선행 이슈
- [x] #37 닫힘
- [x] #75 닫힘
- [x] #24 닫힘

### 결정 필요 (구현 전에 확정)
- [x] 화면 요소의 모양 → **답변 아래 카드**. 링크마다 카드 하나(종류 아이콘, 종류 이름, 도메인), 본문의 주소는 짧은 링크 글자(종류 이름)로 바꾼다. 누르면 새 탭에서 연다.
- [x] 어떤 주소를 링크로 볼지 → 구글 문서(`docs.google.com/document/`), 시트(`/spreadsheets/`), 슬라이드(`/presentation/`), 드라이브 파일(`drive.google.com/file/`). 그 밖의 주소는 일반 글자.
- 2026-11-27 사용자 결정. `ssot/GLOSSARY.md` "자료 링크"와 이슈 본문에 반영.
- [x] 표시 시점 → 답변이 끝난 뒤(완료·중지·오류). 받는 중에는 글자 그대로(잘린 링크 방지). 2026-11-27 사용자 결정.
- [x] 테스트 경계 → `findGoogleLinks(text)`(경계 상황)와 채팅 화면(사용자가 보는 동작) 둘 다. 2026-11-27 사용자 결정.

### 할 일
- [x] 답변 글에서 구글 링크를 찾아 종류를 판별하는 함수(테스트 먼저)
- [x] 본문의 주소를 짧은 링크 글자로 바꿔 표시
- [x] 답변 아래 링크 카드(종류 아이콘, 종류 이름, 도메인, 새 탭으로 열기)
- [x] 구글이 아닌 주소는 일반 글자 그대로
- [x] 완료 조건 확인: 실제 화면에서 카드를 눌러 구글 앱이 열리는지(headless + Aside 브라우저)
- [x] `web/CLAUDE.md` 채팅 절의 "링크는 #38" 문구 갱신

## 진행 기록
- 2026-11-27 `main` 최신화(#75, #79 반영) 뒤 브랜치 생성. 구현 전 점검: 선행 이슈는 모두 닫힘, "결정 필요"가 남아 사용자에게 물음.
- 2026-11-27 사용자 결정(대상 주소, 카드 모양)을 `ssot/`, 이슈 본문에 반영. GitHub Project `In Progress`, Start/Target date 2026-11-27.
- 2026-11-27 TDD: `findGoogleLinks`(종류 판별, 끝에 붙은 문장부호·괄호·한글·마크다운 제외, 구글이 아닌 주소 제외) → 채팅 화면(끝난 뒤 카드·짧은 링크 글자·새 탭, 받는 중에는 글자 그대로, 지난 세션, 링크 없을 때). 전체 88개 통과, lint·build 통과.
- 카드 아이콘: 문서 `NoteIcon`(accent), 시트 `TableIcon`(success), 슬라이드 `BrowserIcon`(attention), 드라이브 `FileIcon`(muted), 오른쪽에 `LinkExternalIcon`. Primer 토큰만 사용.
- 2026-11-27 완료 조건 확인. 이 Mac에서 이번 브랜치 웹을 5178로 띄우고(`VITE_API_BASE_URL`=고정 백엔드 ngrok) Aside 브라우저에서 사용자가 로그인. 백엔드·Hermes·옵시디언은 이 Mac이 아니라 고정 서버 쪽에 있다(이 Mac에는 8000 포트·ngrok·옵시디언 폴더 없음).
  - 첫 시도(#75 시험 파일 `iris-upload-test.txt` 요청): "해당 자료를 찾지 못했습니다." 그 파일은 옵시디언이 아니라 Iris 보관함에서 올린 것이라 옵시디언만 찾는 규칙상 맞는 답으로 보인다. 링크가 없어 카드 없음(정상).
  - 사용자가 같은 탭에서 실제 노트(`2026-11-27-daily-scrum-박종훈.md`)를 요청 → 답변 끝난 뒤 본문 주소가 "구글 문서" 링크 글자로, 아래에 카드 1개(문서 아이콘, "구글 문서", `docs.google.com`, 새 탭 아이콘). 사용자가 눌러 열리는 것 확인("잘되요").
  - HTML 자료: 사용자가 `workflow.html`을 요청. 처음에는 "해당 자료를 찾지 못했습니다."였다가 사용자가 서버 쪽을 확인한 뒤 다시 요청해서 찾음. 드라이브 파일 주소(`drive.google.com/file/d/<ID>/view`)로 와서 "구글 드라이브" 카드 1개가 표시되었다(별도 이슈 없음).
- 2026-11-27 코드 리뷰: codex 끝남(지적 없음). agy는 약 5분 응답이 없어 사용자 지시로 중단.
- 2026-11-27 agy 재시도: 첫 번째는 옵션 순서 실수(`-p` 뒤에 `--print-timeout`)로 요청이 전달되지 않음. 고쳐서 돌리던 중 사용자 지시로 다시 중단. 세 번째(`agy --print-timeout 10m -p`)에 완료. 타당한 3건 반영, 4건 넘어감(결과 참고). 89개 통과.
- 2026-11-27 커밋, 푸시, PR #82(https://github.com/timonPark/iris/pull/82). 상태 `검증 대기`.
- 2026-11-27 사용자 지시로 머지. 상태 `완료`.

### 확인한 사실 (2026-11-27)
- 답변의 링크는 별도 이벤트 없이 답변 글 속의 맨 URL로 온다(#37, #75, `ssot/GLOSSARY.md` "자료 링크"). API 변경은 없다.
- #75의 업로드 도구는 파일을 **원본 형식 그대로** 올리고 `webViewLink`를 돌려준다. 그래서 실제로 오는 자료 링크는 구글 문서·시트·슬라이드(`docs.google.com/...`)가 아니라 드라이브 파일 주소(`drive.google.com/file/d/<ID>/view...`)다.
- #37에서 Hermes가 드라이브 검색으로 돌려준 시트 주소는 `https://docs.google.com/spreadsheets/d/<ID>/edit` 모양이었다. 문서와 슬라이드 주소는 직접 보지 못했다.
- 지금 웹은 답변을 일반 텍스트로만 보여 준다(`web/src/components/Thread.tsx`의 `Answer`).

## 결과

### 변경한 파일
- 새 파일: `web/src/chat/links.ts`(`findGoogleLinks`), `web/src/chat/links.test.ts`, `web/src/components/LinkCards.tsx`(`LinkedText`, `LinkCards`)
- 수정: `web/src/components/Thread.tsx`(`Answer`에서 끝난 답변만 링크 처리), `web/src/index.css`(카드 스타일, 토큰만), `web/src/screens/ChatScreen.test.tsx`("자료 링크" 3개), `web/CLAUDE.md`, `ssot/GLOSSARY.md`("자료 링크")

### 확인 방법과 결과
- `npm test` 89개 통과(리뷰 반영 후), `npm run lint`, `npm run build` 통과.
- Aside 브라우저 확인(고정 백엔드, 실제 Hermes): 카드 1개 `구글 문서 / docs.google.com`, `href`가 Hermes가 준 문서 주소, `target="_blank"`, `rel="noopener noreferrer"`. 본문 링크 글자 1개("구글 문서"). 스크린샷을 눈으로 확인. 사용자가 직접 눌러 구글 문서가 열리는 것을 확인.
- headless Chrome 확인은 하지 않았다(사용자 계정 로그인이 Aside 탭에만 있음).

### 코드 리뷰
- codex(`codex review --uncommitted`): 고칠 결함 없음, 테스트 88개 통과. 반영할 것 없음.
- agy(`agy --print-timeout 10m -p`): 반영 후 89개 통과, lint·build 통과.
  - 반영: deprecated 토큰 `--outline-focus-offset` → `--focus-outline-offset`(`index.css`)
  - 반영: 테스트 콜백 매개변수 타입 명시(`links.test.ts`, 루트 CLAUDE.md 코드 규칙)
  - 반영: 중지(`stopped`)로 끝난 답변의 카드 테스트 추가. 화면 테스트에 없던 구글 문서·슬라이드 카드도 같이 확인
  - 넘어감: 대문자 호스트(`Drive.google.com`) 인식. Hermes는 업로드 도구의 링크를 바꾸지 않고 그대로 넣으므로 일어나지 않는 경우
  - 넘어감: 같은 주소가 두 번 나오면 카드 중복. 드물고, 합칠지는 정하지 않은 화면 동작이라 임의로 바꾸지 않음
  - 넘어감: `new URL()` 파싱 비용과 예외. 정규식이 `https://docs|drive.google.com/...`만 통과시켜 실패할 수 없고 비용도 무시할 만함
  - 넘어감: `LinkedText` 단독 단위 테스트. 합의한 테스트 경계(링크 찾기 함수, 채팅 화면) 밖이고 화면 테스트가 치환 결과를 확인함

### 발견한 것 (이 이슈 범위 밖)
- 실제 노트(.md)의 자료 링크가 `drive.google.com/file`이 아니라 `docs.google.com/document`로 왔다. #75 기록("원본 형식 그대로")과 다르다. 서버의 업로드 도구가 바뀌었거나 Hermes가 다른 방법으로 올렸을 수 있다. 카드는 두 모양 모두 처리하므로 #38에는 영향 없음. 확인이 필요하면 새 이슈로 제안.

### PR
- https://github.com/timonPark/iris/pull/82

### 남은 일
- 2026-11-27 사용자 지시("머지하세요")로 PR #82 머지.
- headless Chrome 확인은 하지 않음(로그인이 Aside 탭에만 있었음).
