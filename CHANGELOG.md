# Changelog

All notable changes to this project are documented here. Format loosely
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and
[SemVer](https://semver.org/).

## [0.2.0] — 2026-05-09

The "real template" cut. Repo is now usable as a starting point for any
small self-hosted project, not just this playground.

### Added

- **`bootstrap.sh`** — one-shot script to provision a new project from this template:
  creates a Cloudflare Tunnel, DNS CNAME, `.env`, and (optionally) the GitHub repo.
- `/version` JSON endpoint exposing build metadata (commit, build time, Node version, uptime).
- Smoke tests with `node:test` (zero deps) covering `/`, `/healthz`, `/version`.
- Pino structured logging with `pino-http` middleware.
- Combined `ci.yml` workflow with sequential `test → build` jobs (build is gated on test).
- `dependabot-auto-merge.yml` — auto-merges patch/minor Dependabot bumps after CI green.
- Dependabot config covering npm, Docker base image, and GitHub Actions, with
  ignore rules for non-LTS Node majors (23/25/26/27).
- Repo hygiene: `LICENSE` (MIT), `.editorconfig`, `.prettierrc`, PR/issue templates.
- README: badges, architecture diagram, "Use as a template" walkthrough, ops cheat sheet.

### Changed

- Base image: Node **22** → Node **24** alpine (LTS until April 2027).
- Replaced **Watchtower** with a **systemd timer + bash auto-pull script**.
  Watchtower was archived in Dec 2025 and broke against Docker 29's API.
- All GitHub Actions pinned to commit SHA (security best practice for templates).
- `auto-pull.sh` made path-agnostic so the repo works from any clone path.

### Removed

- Watchtower service from `compose.yaml` and all references.
- Separate `test.yml` / `build.yml` workflows (folded into `ci.yml`).

## [0.1.0] — 2026-05-09

Initial cut. Express + Docker compose + Cloudflare Tunnel + Watchtower CD.
Live at <https://lab.temancoding.my.id>.

[0.2.0]: https://github.com/rochmanramadhani/lab-temancoding/releases/tag/v0.2.0
[0.1.0]: https://github.com/rochmanramadhani/lab-temancoding/commits/79ffeb8
