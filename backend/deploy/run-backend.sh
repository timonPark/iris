#!/bin/bash
# 백엔드를 띄운다(launchd가 로그인 때 실행하고, 죽으면 다시 실행한다).
# Docker Desktop이 꺼져 있으면 켜고, PostgreSQL 포트가 열릴 때까지 기다린 뒤 uvicorn을 띄운다.
# 기다려도 열리지 않으면 실패로 끝나서 launchd가 다시 시도한다.
set -euo pipefail

DOCKER="${IRIS_DOCKER:-docker}"
OPEN_DOCKER="${IRIS_OPEN_DOCKER:-open}"
UVICORN="${IRIS_UVICORN:-.venv/bin/uvicorn}"
DB_PORT="${IRIS_DB_PORT:-5433}"
WAIT_SECONDS="${IRIS_WAIT_SECONDS:-300}"
POLL_SECONDS="${IRIS_POLL_SECONDS:-2}"
PROBE_SECONDS="${IRIS_PROBE_SECONDS:-10}"

cd "$(dirname "$0")/.."  # backend/

deadline=$((SECONDS + WAIT_SECONDS))

# Docker Desktop이 시작하는 도중에는 `docker info`가 응답 없이 멈출 수 있어서 제한 시간을 둔다.
docker_up() { perl -e 'alarm shift; exec @ARGV' "$PROBE_SECONDS" "$DOCKER" info >/dev/null 2>&1; }

if ! docker_up; then
  echo "Docker가 꺼져 있어서 켭니다"
  "$OPEN_DOCKER" -ga Docker
  until docker_up; do
    if ((SECONDS >= deadline)); then echo "Docker가 ${WAIT_SECONDS}초 안에 켜지지 않았습니다" >&2; exit 1; fi
    sleep "$POLL_SECONDS"
  done
fi

"$DOCKER" start iris-postgres >/dev/null 2>&1 || true  # 멈춰 있으면 시작한다(재시작 정책이 이미 켜 두었으면 그대로 통과)

until nc -z 127.0.0.1 "$DB_PORT" >/dev/null 2>&1; do
  if ((SECONDS >= deadline)); then echo "PostgreSQL(포트 $DB_PORT)이 ${WAIT_SECONDS}초 안에 열리지 않았습니다" >&2; exit 1; fi
  sleep "$POLL_SECONDS"
done

exec "$UVICORN" app.main:app --host 127.0.0.1 --port 8000
