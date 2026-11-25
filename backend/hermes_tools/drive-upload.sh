#!/bin/bash
# Hermes가 부르는 고정 진입점: 구글 라이브러리가 있는 Hermes의 파이썬을 찾아 drive_upload.py를 실행한다.
# (Hermes가 업데이트되면 파이썬 환경 경로가 바뀌므로 매번 찾는다.)
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
for py in "$HOME"/.hermes/installs/*/environments/*/venv/bin/python; do
  if [ -x "$py" ] && "$py" -c "import googleapiclient, google.oauth2" >/dev/null 2>&1; then
    exec "$py" "$HERE/drive_upload.py" "$@"
  fi
done
echo '{"error": "구글 라이브러리가 있는 Hermes 파이썬을 찾지 못했습니다."}'
exit 1
