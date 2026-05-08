# lab-temancoding

Personal lab/playground app — served at https://lab.temancoding.my.id via Cloudflare Tunnel.

## Stack

- **App**: Node.js + Express (Node 22, ESM)
- **Container**: Docker compose (app + cloudflared)
- **CI**: GitHub Actions builds image, pushes to GHCR on push to `main`
- **CD**: systemd timer on host runs `git pull && docker compose pull && up -d` every 30s
- **Edge**: Cloudflare Tunnel (no public IP needed on host)

## Layout

```
.
├── src/server.js         # Express app
├── package.json
├── Dockerfile
├── compose.yaml          # app + cloudflared
├── .env.example          # TUNNEL_TOKEN
├── deploy/               # systemd timer + auto-pull script for CD
│   ├── auto-pull.sh
│   ├── lab-deploy.service
│   ├── lab-deploy.timer
│   └── install.sh        # bootstrap (run once on host)
├── .github/workflows/    # CI build + push to GHCR
└── README.md
```

## Local dev

```sh
npm install
npm run dev
# open http://localhost:3000
```

## Server deploy (one-time)

On omans VM:

```sh
git clone https://github.com/rochmanramadhani/lab-temancoding.git /root/lab
cd /root/lab
cp .env.example .env
# edit .env, paste Cloudflare Tunnel token
docker compose up -d
sudo bash deploy/install.sh   # installs the systemd timer
```

After this, every `git push` to `main` triggers:
1. GitHub Actions build → push image to `ghcr.io/rochmanramadhani/lab-temancoding:latest`
2. systemd timer on omans (runs every 30s) does `git pull && docker compose pull && up -d`
3. Container is recreated only if image digest changed — no manual deploy

## Logs

```sh
journalctl -u lab-deploy.service -f    # CD log on host
docker logs -f lab-app                  # app log
docker logs -f lab-cloudflared          # tunnel log
```
