import express from "express";
import os from "node:os";

const app = express();
const port = process.env.PORT || 3000;
const commit = process.env.GIT_COMMIT || "dev";
const buildTime = process.env.BUILD_TIME || new Date().toISOString();

app.get("/healthz", (_req, res) => res.json({ ok: true }));

app.get("/", (_req, res) => {
  const payload = {
    message: "halo dari lab.temancoding.my.id",
    hostname: os.hostname(),
    commit,
    buildTime,
    serverTime: new Date().toISOString(),
    uptimeSeconds: Math.round(process.uptime()),
    nodeVersion: process.version,
  };

  res.set("content-type", "text/html; charset=utf-8");
  res.send(`<!doctype html>
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
  <h1>halo dari ${payload.hostname} 👋</h1>
  <div class="row">
    <div class="k">commit</div><div><code>${payload.commit}</code></div>
    <div class="k">build time</div><div>${payload.buildTime}</div>
    <div class="k">server time</div><div>${payload.serverTime}</div>
    <div class="k">uptime</div><div>${payload.uptimeSeconds}s</div>
    <div class="k">node</div><div>${payload.nodeVersion}</div>
  </div>
  <p style="color:#666;margin-top:2rem">
    served via <a href="https://www.cloudflare.com/products/tunnel/">cloudflare tunnel</a>
    → docker compose → omans VM (tailnet).
    auto-deployed by github actions + watchtower on push to <code>main</code>.
  </p>
</body>
</html>`);
});

app.listen(port, () => {
  console.log(`listening :${port} commit=${commit} build=${buildTime}`);
});
