import express from "express";
import pino from "pino";
import pinoHttp from "pino-http";
import os from "node:os";

const log = pino({ level: process.env.LOG_LEVEL ?? "info" });

const port = Number(process.env.PORT ?? 3000);
const commit = process.env.GIT_COMMIT ?? "dev";
const buildTime = process.env.BUILD_TIME ?? new Date().toISOString();
const version = process.env.npm_package_version ?? "0.0.0";

export function createApp() {
  const app = express();

  app.disable("x-powered-by");
  app.use(pinoHttp({ logger: log }));

  app.get("/healthz", (_req, res) => res.json({ ok: true }));

  app.get("/version", (_req, res) =>
    res.json({
      version,
      commit,
      buildTime,
      node: process.version,
      uptimeSeconds: Math.round(process.uptime()),
    })
  );

  app.get("/", (_req, res) => {
    res.set("content-type", "text/html; charset=utf-8");
    res.send(html({ hostname: os.hostname() }));
  });

  return app;
}

function html({ hostname }) {
  return `<!doctype html>
<html lang="id">
<head>
  <meta charset="utf-8">
  <title>lab-temancoding</title>
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <style>
    body { font: 14px/1.6 ui-monospace, "JetBrains Mono", Menlo, monospace;
           max-width: 640px; margin: 6vh auto; padding: 0 1rem; color: #e5e5e5; background: #0a0a0a; }
    h1 { font-size: 1.4rem; margin: 0 0 1.2rem; }
    .row { display: grid; grid-template-columns: 130px 1fr; gap: .5rem 1rem; }
    .k { color: #888; }
    code { background: #1a1a1a; padding: .15rem .35rem; border-radius: 3px; }
    a { color: #7dd3fc; }
  </style>
</head>
<body>
  <h1>halo dari ${hostname} 👋</h1>
  <div class="row">
    <div class="k">version</div><div><code>${version}</code></div>
    <div class="k">commit</div><div><code>${commit}</code></div>
    <div class="k">build time</div><div>${buildTime}</div>
    <div class="k">server time</div><div>${new Date().toISOString()}</div>
    <div class="k">uptime</div><div>${Math.round(process.uptime())}s</div>
    <div class="k">node</div><div>${process.version}</div>
    <div class="k">deployed by</div><div>systemd timer (auto-pull every 30s)</div>
  </div>
  <p style="color:#666;margin-top:2rem">
    served via <a href="https://www.cloudflare.com/products/tunnel/">cloudflare tunnel</a>
    → docker compose → omans VM (tailnet).
    auto-deployed by github actions + systemd timer on push to <code>main</code>.
  </p>
  <p style="color:#666">
    machine-readable status: <a href="/version"><code>/version</code></a> &middot;
    health: <a href="/healthz"><code>/healthz</code></a>
  </p>
</body>
</html>`;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const app = createApp();
  app.listen(port, () => {
    log.info({ port, commit, buildTime, version }, "listening");
  });
}
