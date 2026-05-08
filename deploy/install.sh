#!/usr/bin/env bash
# One-time install of the systemd timer that runs auto-pull every 30s.
# Idempotent — safe to re-run after editing the unit/timer files in this folder.
set -euo pipefail

cd "$(dirname "$0")"
chmod +x auto-pull.sh
install -m 0644 lab-deploy.service /etc/systemd/system/lab-deploy.service
install -m 0644 lab-deploy.timer   /etc/systemd/system/lab-deploy.timer

systemctl daemon-reload
systemctl enable --now lab-deploy.timer

echo
echo "[install] timer enabled. status:"
systemctl --no-pager status lab-deploy.timer | head -10
