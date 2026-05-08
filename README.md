# lab-temancoding

Personal lab/playground app — served at https://lab.temancoding.my.id via Cloudflare Tunnel.

## Stack

- **App**: Node.js + Express (Node 22, ESM)
- **Container**: Docker compose (app + cloudflared + watchtower)
- **CI**: GitHub Actions builds image, pushes to GHCR on push to `main`
- **CD**: Watchtower polls GHCR every 30s, auto-pulls + restarts on new image
- **Edge**: Cloudflare Tunnel (no public IP needed on host)

## Layout

```
.
├── src/server.js         # Express app
├── package.json
├── Dockerfile
├── compose.yaml          # app + cloudflared + watchtower
├── .env.example          # TUNNEL_TOKEN
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
git clone git@github.com:rochmanramadhani/lab-temancoding.git ~/lab
cd ~/lab
cp .env.example .env
# edit .env, paste Cloudflare Tunnel token
docker compose up -d
```

After this, every `git push` to `main` triggers:
1. GitHub Actions build → push image to `ghcr.io/rochmanramadhani/lab-temancoding:latest`
2. Watchtower (running on omans) detects new image within 30s
3. Container restarts with new code, no manual deploy
