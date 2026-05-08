# lab-temancoding

Personal lab/playground app — served at <https://lab.temancoding.my.id> via Cloudflare Tunnel.

Also serves as a **starter template** for any tiny self-hosted project: clone it,
run `bootstrap.sh`, and you have a project with CI, CD, public HTTPS URL, and
auto-deploy in about 5 minutes.

## Stack

- **App**: Node.js + Express (Node 22, ESM) + pino structured logs
- **Container**: Docker compose (app + cloudflared)
- **CI**: GitHub Actions — single `ci.yml` runs `test` then `build` (build is gated on test passing)
- **CD**: systemd timer on host runs `git pull && docker compose pull && up -d` every 30s
- **Edge**: Cloudflare Tunnel — no public IP needed, SSL terminated at CF edge
- **Image registry**: GHCR (free for public repos)
- **Hygiene**: prettier, dependabot, PR/issue templates, MIT license, pinned action SHAs

## Endpoints

| Path       | Purpose                                                   |
| ---------- | --------------------------------------------------------- |
| `/`        | HTML status page (commit, build time, uptime)             |
| `/healthz` | Liveness probe — `{ "ok": true }`                         |
| `/version` | Build metadata as JSON (commit, build time, node, uptime) |

## Layout

```
.
├── src/server.js              # Express app (createApp() exported for tests)
├── test/server.test.js        # node:test smoke tests
├── package.json
├── Dockerfile                 # multi-stage, runs as non-root
├── compose.yaml               # app + cloudflared
├── .env.example               # TUNNEL_TOKEN
├── bootstrap.sh               # one-shot template provisioning script
├── deploy/                    # systemd timer + auto-pull (server-side CD)
│   ├── auto-pull.sh
│   ├── lab-deploy.service
│   ├── lab-deploy.timer
│   └── install.sh             # run once on host
├── .github/
│   ├── workflows/
│   │   ├── ci.yml             # test → build → push image to GHCR
│   │   └── dependabot-auto-merge.yml  # auto-merge patch/minor dep bumps
│   ├── dependabot.yml
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── ISSUE_TEMPLATE/
└── README.md
```

## Local dev

```sh
npm install
npm run dev          # auto-restart on changes, http://localhost:3000
npm test             # node:test runner, no extra deps
npm run format       # prettier write
npm run format:check # prettier check (also runs in CI)
```

## Use as a template (new project, ~5 minutes)

Prerequisites on your laptop:

- `gh` CLI authenticated: `gh auth login`
- Cloudflare Global API Key exported: `CF_EMAIL`, `CF_API_TOKEN`
- `python3`, `openssl`, `git`, `curl` (all standard on macOS/Linux)
- A target host with Docker (e.g. an SSH alias `omans` set up)

```sh
# 1. Fork or clone this repo, then enter it
gh repo clone rochmanramadhani/lab-temancoding my-cool-app
cd my-cool-app

# 2. Provision a tunnel + DNS + .env
bash bootstrap.sh my-cool-app myapp           # myapp.temancoding.my.id
bash bootstrap.sh my-cool-app myapp --push    # also creates GH repo + pushes

# 3. On the host, clone the new repo + start
ssh omans 'git clone https://github.com/rochmanramadhani/my-cool-app.git /root/my-cool-app'
scp .env omans:/root/my-cool-app/.env
ssh omans 'cd /root/my-cool-app && docker compose up -d && sudo bash deploy/install.sh'
```

After that, every `git push` to `main` deploys to <https://myapp.temancoding.my.id>
in about 60 seconds.

If you want a different base domain, edit `BASE_DOMAIN`/`ZONE_ID`/`ACCOUNT_ID`
defaults at the top of `bootstrap.sh`, or pass them as env vars when running it.

## How it deploys (architecture)

```
git push origin main
        │
        ▼
GitHub Actions (ci.yml)
  • test job:  npm ci → npm run format:check → npm test  (~25s)
  • build job: docker build → push to ghcr.io/<owner>/<repo>:latest  (~25s)
  •   build only runs after test passes (sequential, gated)
        │
        ▼
omans VM
  • systemd timer fires every 30s → deploy/auto-pull.sh
  • git pull origin main
  • docker compose pull --quiet
  • docker compose up -d --quiet-pull   (no-op if image digest unchanged)
        │
        ▼
cloudflared container
  • outbound persistent connection to CF edge (4 connections, region-spread)
  • routes  https://lab.temancoding.my.id  →  http://app:3000
```

End-to-end: ~60s from `git push` to live.

## Operational tips

```sh
# CD log on host (systemd timer):
journalctl -u lab-deploy.service -f

# App log (pino structured JSON):
docker logs -f lab-app

# Tunnel log:
docker logs -f lab-cloudflared

# Next CD tick:
systemctl list-timers lab-deploy.timer

# Force an immediate pull/redeploy (bypassing the 30s wait):
ssh omans 'systemctl start lab-deploy.service'
```

## Recommended additions when this becomes a real project

These are intentionally **not** in the template (would slow down playground vibes),
but flip them on for anything that matters:

- **Branch protection on `main`** — require PR before merge. One-off via gh CLI:
  ```sh
  gh api -X PUT repos/:owner/:repo/branches/main/protection \
    --input - <<<'{"required_status_checks":{"strict":true,"contexts":["test","build"]},"enforce_admins":false,"required_pull_request_reviews":null,"restrictions":null}'
  ```
  Note: enabling branch protection makes the dependabot auto-merge workflow
  actually queue (instead of merging immediately).
- **External uptime monitor** — point UptimeRobot or BetterStack at `/healthz`.
  Free tier covers 50 monitors at 5-minute intervals.
- **Error tracking** — Sentry SDK (`@sentry/node`) wired into pino.
- **Staging subdomain** — duplicate the compose stack on a `staging` branch
  with its own tunnel + DNS at `staging.<your-domain>`.
- **Off-server backups** — if you add a database, snapshot to R2/S3 nightly.

## License

MIT — see [LICENSE](./LICENSE).
