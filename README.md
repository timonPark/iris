# Iris

웹과 모바일 앱의 채팅 화면에서 질문을 입력하면 백엔드가 이 PC에서 실행 중인 Hermes(Nous Research 에이전트)에 전달하고, Hermes의 답변을 스트리밍으로 화면에 표시하는 서비스입니다.

## 이름의 유래

Hermes와 연관성이 높은 캐릭터로 정한 이름입니다. Iris는 그리스 신화의 전령 여신으로, 사용자의 질문을 Hermes에 전달하고 답을 돌려주는 이 서비스의 역할과 맞닿아 있습니다.

```text
[사용자 웹 / 모바일 앱 / 관리자 웹] → [백엔드 (FastAPI)] → [Hermes API 서버]
                                          ↓
                                    [PostgreSQL]
```

- 백엔드가 모든 클라이언트의 유일한 입구입니다.
- 질문은 클라이언트 → 백엔드 → Hermes 순서로 가고, 답변은 같은 경로로 SSE 스트리밍으로 돌아옵니다.
- Hermes의 동작(옵시디언 저장과 조회, 기억 등)은 Iris의 구현 대상이 아닙니다.

## 저장소 구조

| 폴더 | 역할 | 기술 |
|---|---|---|
| [`backend/`](backend/README.md) | 백엔드 | Python, FastAPI |
| [`web/`](web/README.md) | 사용자 웹 | Vite, React, Primer |
| [`admin/`](admin/README.md) | 관리자 웹 | Primer |
| [`mobile/`](mobile/README.md) | 모바일 앱 | Flutter (iOS, Android) |
| [`ssot/`](ssot/README.md) | 용어와 개념의 단일 기준 | 문서 |
| `docs/` | 기획 문서, API 규격 | 문서 |
| `docker-compose.yml` | PostgreSQL | Docker |

백엔드, 사용자 웹, 관리자 웹은 whisper, Claude, Hermes 접근을 그대로 쓰기 위해 이 PC에서 직접 실행하고, PostgreSQL만 컨테이너로 실행합니다.

## 이번 스프린트 (Sprint 1)

1. 텍스트 채팅: 질문 입력, 답변 스트리밍, 답변 중지, 세션 목록과 삭제
2. 모바일 음성 입력: 녹음 → 변환 → 음성 인식 → 맞춤법 보정 → 질문 전송
3. 관리자 웹: 사용자 계정 등록, 차단과 해제, 비밀번호 초기화
4. 인증: 아이디/비밀번호와 accessToken

다음 스프린트(Sprint 2)는 구글 문서, 시트, 슬라이드 링크 처리입니다.

## 문서

- [`docs/PROJECT_SPEC.md`](docs/PROJECT_SPEC.md): 프로젝트 기획 정리
- [`ssot/GLOSSARY.md`](ssot/GLOSSARY.md): 용어집. 모든 프로젝트가 이 용어를 씁니다.
- [`ssot/adr/`](ssot/adr/): 결정 기록
- `docs/api/openapi.yaml`: API 규격 (작성 예정, 이슈 #8)
- [`CLAUDE.md`](CLAUDE.md): 작업 절차와 규칙

## 작업 관리

- 이슈와 일정: [GitHub Project](https://github.com/users/timonPark/projects/14)와 마일스톤(Sprint 1, Sprint 2)
- 이슈 제목은 `[be]`, `[fe]`, `[admin]`, `[mobile]`, `[common]` 접두어로 대상 프로젝트를 표시하고, 에픽과 하위 이슈로 나눕니다.
- 작업은 이슈마다 브랜치를 만들어 진행하고, 작업 기록은 `work_history/`에 남깁니다. 자세한 순서는 [`CLAUDE.md`](CLAUDE.md)의 작업 절차를 따릅니다.

## 상태

구현 전입니다. 현재는 기획, 용어 정리, 이슈 등록까지 끝났습니다.
