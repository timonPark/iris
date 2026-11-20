#!/bin/bash
# 백엔드와 ngrok 터널을 로그인 때 자동 실행(launchd LaunchAgent)으로 설치하거나 제거한다.
#   설치: backend/deploy/install-launchd.sh <ngrok 고정 도메인>
#   제거: backend/deploy/install-launchd.sh --uninstall
set -euo pipefail

DEPLOY_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$DEPLOY_DIR/../.." && pwd)"
AGENTS_DIR="$HOME/Library/LaunchAgents"
LOG_DIR="$HOME/Library/Logs/iris"
DOMAIN_UID="gui/$(id -u)"
LABELS=(com.iris.backend com.iris.tunnel)

unload() {
  for label in "${LABELS[@]}"; do
    launchctl bootout "$DOMAIN_UID/$label" >/dev/null 2>&1 || true
    # bootout은 바로 끝나지 않으므로, 내려갈 때까지 기다려야 곧바로 다시 올릴 수 있다.
    for _ in $(seq 1 50); do
      launchctl print "$DOMAIN_UID/$label" >/dev/null 2>&1 || break
      sleep 0.2
    done
  done
}

if [ "${1:-}" = "--uninstall" ]; then
  unload
  for label in "${LABELS[@]}"; do rm -f "$AGENTS_DIR/$label.plist"; done
  echo "제거했습니다(로그는 $LOG_DIR 에 남아 있습니다)."
  exit 0
fi

DOMAIN="${1:-}"
if [ -z "$DOMAIN" ]; then echo "사용법: $0 <ngrok 고정 도메인>  또는  $0 --uninstall" >&2; exit 2; fi
if ! [[ "$DOMAIN" =~ ^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?(\.[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?)+$ ]]; then
  echo "고정 도메인은 https:// 없이 이름만 적습니다(예: example.ngrok-free.dev)." >&2; exit 2
fi
for value in "$REPO" "$HOME"; do
  if [[ "$value" == *[\&\<\>\"\'\|\\]* ]]; then
    echo "경로에 & < > \" ' | \\ 문자가 있으면 설치할 수 없습니다: $value" >&2; exit 3
  fi
done
NGROK="$(command -v ngrok || true)"
if [ -z "$NGROK" ]; then echo "ngrok이 설치되어 있지 않습니다(brew install --cask ngrok)." >&2; exit 1; fi
if [ ! -x "$REPO/backend/.venv/bin/uvicorn" ]; then echo "backend에서 uv sync를 먼저 실행하세요." >&2; exit 1; fi

mkdir -p "$AGENTS_DIR" "$LOG_DIR"
for label in "${LABELS[@]}"; do
  REPO="$REPO" NGROK="$NGROK" DOMAIN="$DOMAIN" LOG_DIR="$LOG_DIR" perl -pe \
    's/\@REPO\@/$ENV{REPO}/g; s/\@HOME\@/$ENV{HOME}/g; s/\@NGROK\@/$ENV{NGROK}/g; s/\@DOMAIN\@/$ENV{DOMAIN}/g; s/\@LOGDIR\@/$ENV{LOG_DIR}/g' \
    "$DEPLOY_DIR/launchd/$label.plist.template" > "$AGENTS_DIR/$label.plist"
  plutil -lint "$AGENTS_DIR/$label.plist" >/dev/null
done

unload
for label in "${LABELS[@]}"; do
  launchctl bootstrap "$DOMAIN_UID" "$AGENTS_DIR/$label.plist"
done
echo "설치했습니다. 로그인할 때마다 자동으로 실행되고, 죽으면 다시 시작합니다."
echo "로그: $LOG_DIR/backend.log, $LOG_DIR/tunnel.log"
