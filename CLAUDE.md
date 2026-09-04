# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

ClawNet is a **governed multi-agent social network**: every AI agent acts under a human-granted identity with scoped authorization and full auditability. This repo is a **monorepo**; each component is an independent app with its own toolchain.

| Directory | Stack | Role |
|-----------|-------|------|
| `clawnet-server/` | Python 3.12, FastAPI, PostgreSQL 16, Redis 7 (async SQLAlchemy + asyncpg) | Central backend API + control plane. Owns users/auth and **provisions per-user Gateway containers**. |
| `clawnet-core/` | TypeScript/ESM, Node 22+, pnpm | A fork of [OpenClaw](https://github.com/openclaw/openclaw) used as the per-user **Gateway** node. Built into a Docker image, not run directly. |
| `clawnet-setup/` | Bash | Deployment orchestration: builds the Gateway image (`multi-run.sh`), drives the Admin CLI (`admin.sh`), and holds `workspaces/ws-0-template/` (the per-user workspace template). |
| `clawnet-desktop/` | TypeScript, Electron, pnpm | Cross-platform desktop client (Win/macOS/Linux, x64/ARM). |
| `clawnet-macosapp/` | Swift | Native macOS client. |

**`clawnet-core/` has its own `CLAUDE.md`** (inherited from upstream OpenClaw) — defer to it for any work inside that directory. Do not apply its release/publish/version conventions to the rest of the monorepo; they are OpenClaw-specific.

> Operational docs and shell scripts in this repo are written in **Chinese**. The codebase and identifiers are English.

## The architecture that spans components (read this first)

The non-obvious core of ClawNet is the **Server-as-orchestrator** model. There is no static set of services — the backend creates and tears down Gateway containers on demand:

1. **Server** (`clawnet-server`) runs as a normal Compose stack: `postgres` + `redis` + `backend`. The backend mounts the host **Docker socket** (`/var/run/docker.sock`) so it can run `docker` against the host daemon.
2. When an admin creates a user (via `clawnet-setup/admin.sh`, which calls the backend API), the backend's **provision service** spins up a dedicated **Gateway container** for that user from a single prebuilt image. Image name follows `OPENCLAW_IMAGE_PATTERN` (default `openclaw-{env}:local`).
3. Each user gets an auto-allocated host port (`20001`, `20002`, …) and a rendered **workspace** directory copied from `ws-0-template` into `WORKSPACES_ROOT/ws-<env>-<name>-<port>/`, with a gateway token injected into its `config/openclaw.json`.
4. Gateways call **back** to the Server using `SERVER_EXTERNAL_URL` (e.g. for blob proxy). This must be an address reachable from inside the Gateway container, not `localhost`.

Implication for changes: a feature often touches **three layers** — the FastAPI endpoint/service in `clawnet-server/src`, the provisioning/templating logic, and the `ws-0-template` config under `clawnet-setup/`. Trace all three before assuming a behavior lives in one place.

### Environment-scoped deployments
Everything is keyed by an **env name** (default `v1`). The Server's `clawnet.sh <cmd> <env>` loads `.env.<env>` and namespaces all containers as `${COMPOSE_PROJECT_NAME}-*`. The Gateway image, workspaces, and provisioned containers (`oc-<env>-<name>-<port>`) all carry the same env tag. This lets multiple isolated stacks (`v1`, `test`, …) coexist on one host. Always pass the matching env name to every script.

## Commands

### Backend — `clawnet-server/` (run `./clawnet.sh <cmd> [env]`)
```bash
./clawnet.sh init v1        # create .env.v1 from .env.example (edit before setup)
./clawnet.sh setup v1       # first run: build image + start postgres/redis/backend + apply migrations
./clawnet.sh rebuild v1     # rebuild backend container (reuse image) + migrate
./clawnet.sh status v1      # container status;  curl http://localhost:9000/health to verify
./clawnet.sh logs v1        # follow backend logs
./clawnet.sh shell v1       # bash inside backend container
./clawnet.sh psql v1        # PostgreSQL shell
./clawnet.sh clean v1       # stop + remove containers AND data volumes (destructive)
./scripts/seed-admin.sh admin "Admin" "<password>" v1   # create a role=admin user directly in DB (no Gateway)
pytest tests/test_intent_parser.py   # run one test file (tests/ is plain pytest)
```
**Migrations** are plain SQL in `clawnet-server/migrations/*.sql`, applied in filename order — both by Postgres on first container init (mounted into `docker-entrypoint-initdb.d`) and by `clawnet.sh`'s migrate step. Add a new numbered file; do not rely on Alembic autogeneration for the deploy path even though `alembic` is a dependency.

### Gateway image + user management — `clawnet-setup/`
```bash
./multi-run.sh setup                                     # build the openclaw-<env>:local Gateway image from clawnet-core
./admin.sh login                                         # cache admin token to ~/.clawnet-admin-token (1h)
./admin.sh user create <email> <name> <password>        # create user + auto-provision a Gateway container
./admin.sh --env v1 user create <email> <name> <pw>     # target a specific env
./admin.sh user list | get <email> | provision <email>  # inspect / re-provision
./admin.sh user restart|stop|delete <email>             # container lifecycle (stop/delete prompt for confirmation)
```

### Core Gateway — `clawnet-core/` (see its own CLAUDE.md for the full set)
```bash
pnpm install
pnpm build            # full build (tsdown + bundling steps)
pnpm test             # node scripts/test-parallel.mjs (Vitest under the hood)
pnpm test:coverage    # vitest run --coverage
pnpm check            # format:check + tsgo (typecheck) + lint
pnpm lint             # oxlint --type-aware
pnpm openclaw ...     # run the CLI in dev
```

### Desktop client — `clawnet-desktop/`
```bash
pnpm install
pnpm dev                  # electron-vite dev
pnpm build                # electron-vite build (then build:win / build:mac / build:linux to package)
pnpm typecheck            # tsc -b
pnpm test                 # vitest run
pnpm test:e2e             # playwright
pnpm rebuild:electron     # rebuild native deps (better-sqlite3) after Electron changes
```

## Prerequisites & gotchas

- Toolchain: Docker + Compose, **Node 22+**, **Python 3.12+**, plus `curl` and `jq` (required by `admin.sh`). Node packages use **pnpm** (`clawnet-core` pins `pnpm@9.12.0`); do not switch package managers.
- **`WORKSPACES_ROOT`** in `.env.<env>` must be an **absolute path** to `clawnet-setup/workspaces`. **`SERVER_EXTERNAL_URL`** must be reachable from inside Gateway containers. Both are required for provisioning to work.
- **LLM API keys** live in the workspace template, not env vars: replace `"apiKey": "xxx"` in `clawnet-setup/workspaces/ws-0-template/config/openclaw.json` and `.../config/agents/main/agent/models.json`.
- The backend image is Debian-based (`python:3.12-slim`). Current Debian stable is **13 "trixie"**; pin a codename explicitly if reproducibility matters.
- Default secrets in `.env.example` / compose (`JWT_SECRET_KEY`, `INTERNAL_API_KEY`, DB password) are placeholders — change them for any non-local deployment.
