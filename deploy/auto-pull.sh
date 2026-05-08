#!/usr/bin/env bash
# Pull latest images for the lab stack and restart any container whose
# image digest changed. Logs to journald via systemd unit.
set -euo pipefail

cd /root/lab

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
