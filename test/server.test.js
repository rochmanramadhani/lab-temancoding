import { test } from "node:test";
import assert from "node:assert/strict";
import { createApp } from "../src/server.js";

function listen(app) {
  return new Promise((resolve) => {
    const server = app.listen(0, () => {
      const { port } = server.address();
      resolve({ server, baseUrl: `http://127.0.0.1:${port}` });
    });
  });
}

test("GET /healthz returns ok", async () => {
  const { server, baseUrl } = await listen(createApp());
  try {
    const res = await fetch(`${baseUrl}/healthz`);
    assert.equal(res.status, 200);
    assert.deepEqual(await res.json(), { ok: true });
  } finally {
    server.close();
  }
});

test("GET /version returns build metadata", async () => {
  const { server, baseUrl } = await listen(createApp());
  try {
    const res = await fetch(`${baseUrl}/version`);
    assert.equal(res.status, 200);
    const body = await res.json();
    for (const key of ["version", "commit", "buildTime", "node", "uptimeSeconds"]) {
      assert.ok(key in body, `missing key: ${key}`);
    }
  } finally {
    server.close();
  }
});

test("GET / returns HTML page", async () => {
  const { server, baseUrl } = await listen(createApp());
  try {
    const res = await fetch(baseUrl);
    assert.equal(res.status, 200);
    assert.match(res.headers.get("content-type"), /text\/html/);
    const body = await res.text();
    assert.match(body, /halo dari/);
  } finally {
    server.close();
  }
});
