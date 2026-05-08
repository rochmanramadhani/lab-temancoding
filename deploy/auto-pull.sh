#!/usr/bin/env bash
# Pull latest images for the stack and recreate any container whose
# image digest changed. Designed to be invoked by a systemd timer.
# Logs to journald via the unit.
set -euo pipefail

# Resolve repo root from the script location so this works no matter
# where the repo is cloned (default is /root/lab).
cd "$(dirname "$0")/.."

git fetch -q origin main
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/main)
if [ "$LOCAL" != "$REMOTE" ]; then
  echo "[auto-pull] git: $LOCAL -> $REMOTE"
  git reset -q --hard origin/main
fi

# `docker compose pull` is quiet when nothing to update; `up -d` is a no-op
# if image digests didn't change, otherwise it recreates the affected container.
docker compose pull --quiet
docker compose up -d --quiet-pull
