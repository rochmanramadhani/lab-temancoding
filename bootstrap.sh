#!/usr/bin/env bash
# bootstrap.sh — turn a fresh clone of this template into a real project:
#   1. rename project (package.json + compose.yaml image name)
#   2. create a Cloudflare Tunnel + DNS CNAME for <subdomain>.<base-domain>
#   3. write .env with the tunnel token
#   4. (optionally) create the GitHub repo + push
#
# Usage:
#   CF_EMAIL=... CF_API_TOKEN=... \
#   bash bootstrap.sh <project-name> <subdomain> [--push]
#
# Examples:
#   bash bootstrap.sh my-cool-app myapp           # myapp.temancoding.my.id
#   bash bootstrap.sh my-cool-app myapp --push    # also create+push GH repo
#
# Configurable via env (defaults are mine — change for your setup):
#   GH_OWNER         GitHub user/org for the new repo (default: rochmanramadhani)
#   BASE_DOMAIN      apex domain on Cloudflare         (default: temancoding.my.id)
#   ZONE_ID          CF zone id for $BASE_DOMAIN
#   ACCOUNT_ID       CF account id that owns the zone

set -euo pipefail

if [ $# -lt 2 ]; then
  cat <<USAGE >&2
Usage: $0 <project-name> <subdomain> [--push]
  <project-name>  e.g. my-cool-app — used for repo name + GHCR image
  <subdomain>     e.g. myapp -> myapp.\$BASE_DOMAIN
  --push          also create the GitHub repo and push initial commit
USAGE
  exit 2
fi

PROJECT="$1"
SUB="$2"
PUSH="${3:-}"

GH_OWNER="${GH_OWNER:-rochmanramadhani}"
BASE_DOMAIN="${BASE_DOMAIN:-temancoding.my.id}"
ZONE_ID="${ZONE_ID:-347bfa5a279b0782fc6dcb81a98445cc}"
ACCOUNT_ID="${ACCOUNT_ID:-4ab8537135f8d0edf826345ccac3e90f}"
DOMAIN="${SUB}.${BASE_DOMAIN}"

: "${CF_EMAIL:?CF_EMAIL must be exported (Cloudflare Global API Key auth)}"
: "${CF_API_TOKEN:?CF_API_TOKEN must be exported (Cloudflare Global API Key)}"
command -v gh       >/dev/null || { echo "missing: gh CLI" >&2; exit 1; }
command -v python3  >/dev/null || { echo "missing: python3" >&2; exit 1; }
command -v openssl  >/dev/null || { echo "missing: openssl" >&2; exit 1; }
gh auth status      >/dev/null 2>&1 || { echo "gh not authed: run 'gh auth login'" >&2; exit 1; }

# Validate project name (lowercase, dashes only — Docker/GHCR friendly)
if ! [[ "$PROJECT" =~ ^[a-z][a-z0-9-]{1,38}$ ]]; then
  echo "project-name must be lowercase alphanumeric+dashes, 2-39 chars" >&2
  exit 2
fi

cf() {
  local method="$1" path="$2" data="${3:-}"
  if [ -n "$data" ]; then
    curl -sf -X "$method" \
      -H "X-Auth-Email: $CF_EMAIL" -H "X-Auth-Key: $CF_API_TOKEN" \
      -H "Content-Type: application/json" \
      "https://api.cloudflare.com/client/v4$path" --data "$data"
  else
    curl -sf -X "$method" \
      -H "X-Auth-Email: $CF_EMAIL" -H "X-Auth-Key: $CF_API_TOKEN" \
      "https://api.cloudflare.com/client/v4$path"
  fi
}

jget() { python3 -c "import json,sys; d=json.load(sys.stdin); print($1)"; }

echo "==> [1/5] Rename project to '$PROJECT'"
# Replace template name with new name in package.json + compose.yaml.
# We anchor on the literal template strings so re-running on an already-bootstrapped
# project is a no-op rather than a mistaken double-rename.
sed -i.bak "s|\"name\": \"lab-temancoding\"|\"name\": \"$PROJECT\"|" package.json
sed -i.bak "s|ghcr.io/rochmanramadhani/lab-temancoding|ghcr.io/$GH_OWNER/$PROJECT|g" compose.yaml
rm -f package.json.bak compose.yaml.bak

echo "==> [2/5] Create Cloudflare Tunnel '$PROJECT'"
TUNNEL_SECRET=$(openssl rand -base64 32)
TUNNEL_ID=$(cf POST "/accounts/$ACCOUNT_ID/cfd_tunnel" \
  "{\"name\":\"$PROJECT\",\"tunnel_secret\":\"$TUNNEL_SECRET\",\"config_src\":\"cloudflare\"}" \
  | jget "d['result']['id']")
echo "    tunnel_id = $TUNNEL_ID"

echo "==> [3/5] Set tunnel ingress: $DOMAIN -> http://app:3000"
cf PUT "/accounts/$ACCOUNT_ID/cfd_tunnel/$TUNNEL_ID/configurations" \
  "{\"config\":{\"ingress\":[{\"hostname\":\"$DOMAIN\",\"service\":\"http://app:3000\"},{\"service\":\"http_status:404\"}]}}" \
  >/dev/null

echo "==> [4/5] Create DNS CNAME $DOMAIN -> $TUNNEL_ID.cfargotunnel.com"
cf POST "/zones/$ZONE_ID/dns_records" \
  "{\"type\":\"CNAME\",\"name\":\"$SUB\",\"content\":\"$TUNNEL_ID.cfargotunnel.com\",\"proxied\":true,\"comment\":\"$DOMAIN -> CF tunnel ($PROJECT)\"}" \
  >/dev/null

echo "==> [5/5] Fetch tunnel token + write .env"
TUNNEL_TOKEN=$(cf GET "/accounts/$ACCOUNT_ID/cfd_tunnel/$TUNNEL_ID/token" | jget "d['result']")
umask 077
printf "TUNNEL_TOKEN=%s\n" "$TUNNEL_TOKEN" > .env

if [ "$PUSH" = "--push" ]; then
  echo "==> [+] Create GitHub repo + push"
  if [ ! -d .git ] || ! git rev-parse HEAD >/dev/null 2>&1; then
    git init -q -b main
    git add -A
    git commit -q -m "init: bootstrap from lab-temancoding template"
  fi
  gh repo create "$GH_OWNER/$PROJECT" --public --source=. --remote=origin \
    --description "Auto-deployed at $DOMAIN" >/dev/null
  git push -u origin main
fi

cat <<DONE

✅ bootstrap done.
   project    $PROJECT
   url        https://$DOMAIN  (DNS proxied via Cloudflare)
   tunnel     $TUNNEL_ID
   image      ghcr.io/$GH_OWNER/$PROJECT:latest
   .env       written (mode 600)

next steps on the host (e.g. omans VM):
   git clone https://github.com/$GH_OWNER/$PROJECT.git /root/$PROJECT
   cd /root/$PROJECT
   # copy the .env from your laptop (or paste TUNNEL_TOKEN manually):
   scp .env omans:/root/$PROJECT/.env
   docker compose up -d
   sudo bash deploy/install.sh

after that, every push to main auto-deploys within ~60 seconds.
DONE
