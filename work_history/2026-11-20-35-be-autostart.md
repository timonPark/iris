# [be] 터널과 백엔드 부팅 시 자동 실행

| 항목 | 내용 |
|---|---|
| 이슈 | #35 (https://github.com/timonPark/iris/issues/35) |
| 브랜치 | 2026-11-20-35-be-autostart |
| 상태 | 완료 |
| 시작일자 | 2026-11-20 |
| 종료일자 | 2026-11-20 |

## 작업 내용

PC를 켜면 백엔드와 ngrok 터널(#34)이 자동으로 실행되고, 죽으면 다시 시작되게 한다.

### 범위
- [x] PC 부팅(로그인) 시 백엔드와 터널이 자동 실행
- [x] 실패하면(프로세스가 죽으면) 다시 시작

제외: PC가 꺼져 있는 동안의 접속(불가)

### 완료 조건
- [ ] PC를 재부팅하면 터널과 백엔드가 자동으로 실행된다. (**미확인**: 사용자가 재부팅을 보류. 로그인 흉내(서비스 내렸다 올리기)와 강제 종료 재시작만 확인)
- [x] 재부팅 후에도 접속 주소가 같다(고정 도메인이라 주소는 그대로, 내렸다 올려서 확인. 실제 재부팅은 사용자 확인).

### 결정 필요 (Claude가 정함)
- **자동 실행 방식**: launchd **LaunchAgent**(사용자 로그인 때 시작, `RunAtLoad` + `KeepAlive`). 이 PC의 Hermes(`ai.hermes.gateway`)도 같은 방식이다. LaunchDaemon(부팅 즉시, root)은 쓰지 않는다: 백엔드가 쓰는 `claude`(보정)가 사용자의 키체인 로그인을 쓰고, `~/.hermes`, whisper 모델 등 사용자 환경이 필요하다. 그래서 **재부팅 뒤 이 계정으로 로그인이 되어야** 시작된다(자동 로그인을 켜 두면 완전히 자동. Hermes도 같은 조건).
- **Docker Desktop**: 설정이 로그인 때 자동 시작이 꺼져 있다(`AutoStart: false`). 사용자의 Docker 설정은 바꾸지 않고, 백엔드 시작 스크립트가 Docker가 꺼져 있으면 켜고(`open -ga Docker`) PostgreSQL 포트가 열릴 때까지 기다린 뒤 백엔드를 띄운다. 기다려도 안 열리면 실패로 끝나 launchd가 다시 시도한다.

## 설계
- 파일: `backend/deploy/run-backend.sh`(시작 스크립트), `backend/deploy/launchd/com.iris.backend.plist.template`, `com.iris.tunnel.plist.template`, `backend/deploy/install-launchd.sh`(경로를 채워 `~/Library/LaunchAgents`에 설치·제거).
- plist에는 이 PC의 경로가 들어가므로 저장소에는 템플릿만 두고, 설치할 때 만든다. 고정 도메인은 설치할 때 인자로 받는다(저장소에 넣지 않는다).
- 로그: `~/Library/Logs/iris/{backend,tunnel}.log`.

## 진행 기록
- 2026-11-20 브랜치와 작업 파일 생성. 선행 #34 닫힘 확인. 지금 떠 있는 수동 실행(백엔드, 터널)은 설치 전에 내린다.

## 결과

### 변경한 파일
- `backend/deploy/run-backend.sh`(시작 스크립트), `backend/deploy/install-launchd.sh`(설치/제거), `backend/deploy/launchd/com.iris.{backend,tunnel}.plist.template`
- `backend/tests/test_deploy.py`(19개), `backend/CLAUDE.md`(자동 실행 절)
- 이 PC: `~/Library/LaunchAgents/com.iris.backend.plist`, `com.iris.tunnel.plist` 설치됨(지금 launchd가 실행 중, 로그는 `~/Library/Logs/iris/`). 저장소에는 고정 도메인과 토큰이 없다.

### 확인 방법과 결과
- 전체 테스트 364개 통과(`test_deploy.py` 19개: plist 형식, 로그인 때 시작·죽으면 재시작 설정, 비밀 값 없음, 시작 스크립트의 Docker·DB 대기와 포기, Docker 멈춤 제한 시간, 설치 스크립트의 잘못된 입력 거절).
- 실제 PC에서 설치 후: 백엔드와 터널이 `running`, 로컬과 외부(고정 도메인) `/docs` 200.
- 두 프로세스를 `kill -9`로 종료 → 모두 자동으로 다시 시작되어 외부 주소 200.
- 서비스를 내렸다 다시 올리기(로그아웃→로그인 흉내): 내린 동안 외부 404, 올린 뒤 **같은 주소**로 200.
- 설치 스크립트를 연속 두 번 실행해도 성공(재실행 안전), 생성된 plist는 `plutil -lint` 통과, 채워지지 않은 자리 없음.
- launchd 환경(PATH, 키체인)에서 음성 질문 실제 3건(ffmpeg, whisper, claude 보정, Hermes) 모두 200, 임시 폴더 잔여 0, 개발 DB에는 `admin`만 남음.
- 확인하지 못한 것: **실제 재부팅**(사용자 PC를 제가 재부팅할 수 없음), Docker Desktop이 꺼진 상태에서의 실제 시작(이 PC의 n8n이 같은 Docker에 있어 끄지 않았고 가짜 docker로 테스트).

### 결정한 것 (이슈의 "결정 필요")
- launchd LaunchAgent(로그인 때 시작, `RunAtLoad`+`KeepAlive`). LaunchDaemon은 쓰지 않음(`claude` 키체인 로그인과 사용자 환경이 필요). 재부팅 뒤 이 계정으로 로그인이 되어야 시작되며, 자동 로그인을 켜 두면 완전 자동(Hermes와 같은 조건).
- Docker Desktop 설정(로그인 때 자동 시작 꺼짐)은 바꾸지 않고 시작 스크립트가 Docker를 켜고 DB를 기다린다.

### 코드 리뷰 반영 내역 (`/code-review medium`)
- 반영: Docker 시작 도중 `docker info`가 멈추면 영원히 기다리던 문제(10초 제한) / 설치 스크립트 재실행 때 `bootout`이 끝나기 전에 `bootstrap`하던 경쟁(내려갈 때까지 기다림) / 경로에 `&` 등이 있을 때 plist가 깨지는 문제(perl로 치환, 위험한 경로는 거절) / 도메인 형식 검증(`https://`, 옵션처럼 보이는 값 등 거절, launchd를 건드리기 전에) / 테스트의 약한 검사(채워지지 않은 자리, 줄 단위 비교)와 빠진 경로(Docker가 안 켜질 때, 설치 스크립트의 입력 거절).
- 설치 스크립트 테스트를 처음 구현 없이 돌리려다 자동 모드가 막았다: 검증이 없으면 실제 launchd 서비스를 잘못된 값으로 바꿀 수 있어서, 검증을 먼저 구현하고 테스트는 launchd를 건드리기 전에 끝나는 경로만 실행하게 했다.
- 넘어감: `.venv`가 없을 때 10초마다 재시도(문서화), 포트만 열린 시점의 DB 미준비(실패하면 launchd가 다시 시작해 스스로 회복), 터널 재시도 간격 조정(10초로 충분).

### 남은 일
- **실제 재부팅 확인은 사용자가 보류**했다(2026-11-20, 지금은 재부팅하기 어려움). 완료 조건 "PC를 재부팅하면 터널과 백엔드가 자동으로 실행된다"는 **미확인 상태로 머지**한다. 다음에 PC를 재부팅하고 로그인한 뒤 1~2분 뒤에 `https://<고정 도메인>/docs`가 열리는지 확인한다. 안 열리면 `~/Library/Logs/iris/backend.log`, `tunnel.log`를 보고(Docker가 늦게 켜지는 경우가 가장 흔함) 새 이슈로 고친다.
- PR #55, 2026-11-20 사용자 지시("머지해주세요")로 머지.
