# Contributing

## Development Setup

### Prerequisites

- Node.js 22+
- pnpm (enabled via `corepack enable`)
- Docker (for full builds)

### Local Development

```bash
# Clone the repo
git clone https://github.com/TrendpilotAI/openclaw-railway-tailscale.git
cd openclaw-railway-tailscale

# Install dependencies
pnpm install

# Start the dev server
pnpm dev
```

The dev server starts the Express wrapper on port 8080. Without a configured OpenClaw gateway, it redirects all traffic to `/setup`.

### Environment Variables

Copy `.env.example` to `.env` and fill in the values you need:

```bash
cp .env.example .env
```

Only `SETUP_PASSWORD` is required for local development. The server gracefully degrades without optional services (Tailscale, Modal, Composio, Langfuse, PostHog).

### n8n Webhook Wiring

When deploying via the multi-service Railway template, all cross-service variables are auto-wired via [reference variables](https://docs.railway.com/variables#reference-variables). No manual setup is needed.

For **manual deployments** (not using the template), OpenClaw and n8n need a shared secret and internal URLs:

1. Generate a shared secret: `openssl rand -hex 32`
2. On the **OpenClaw** service, set:
   - `N8N_WEBHOOK_URL=http://n8n-Primary.railway.internal:5678`
   - `OPENCLAW_HOOKS_TOKEN=<the generated secret>`
3. On the **n8n (Primary)** service, set:
   - `OPENCLAW_HOOKS_TOKEN=<same secret>`
   - `DB_POSTGRESDB_HOST=Postgres.railway.internal` (not `HOSE` — a common typo)
   - `DB_POSTGRESDB_USER=postgres`
   - `DB_POSTGRESDB_DATABASE=railway`
   - `DB_POSTGRESDB_PORT=5432`
   - `DB_TYPE=postgresdb`

n8n auto-creates all database tables (`execution_entity`, `workflow_entity`, etc.) on first successful PostgreSQL connection. If you see "relation does not exist" errors, check the database variables and redeploy n8n.

### Running the Docker Build

```bash
docker build -t openclaw-railway .
docker run -p 8080:8080 -v openclaw-data:/data \
  -e SETUP_PASSWORD=dev \
  -e TAILSCALE_AUTHKEY=tskey-... \
  openclaw-railway
```

The build takes a while since it compiles OpenClaw from source. For faster iteration on the wrapper/instrumentation, use `pnpm dev` instead.

## Architecture

### Boot Sequence

```
start.sh
  ├── Start Tailscale daemon (if TAILSCALE_AUTHKEY set)
  ├── Join tailnet with --authkey
  ├── Configure GitHub credentials (if GITHUB_TOKEN set)
  ├── Hot-update OpenClaw (if OPENCLAW_UPDATE_REF set)
  │     └── scripts/update-openclaw.sh → clone/build to /data/openclaw
  ├── Auto-detect previous update (if /data/openclaw/dist/entry.js exists)
  └── exec node --import instrumentation.mjs server.js
         ├── instrumentation.mjs runs first (OTel SDK, OpenLLMetry)
         └── server.js starts Express on :8080
              ├── Setup wizard routes (/setup/*)
              ├── Health endpoints (/healthz, /setup/healthz)
              ├── Gateway proxy (everything else → :18789)
              └── Auto-start gateway if configured
```

### Request Flow

```
Internet → Railway :8080 → Express (server.js)
                              │
                    ┌─────────┴─────────┐
                    │                   │
              /setup/* routes      All other routes
              (setup wizard)       (proxy to gateway)
                    │                   │
                    ▼                   ▼
               Setup UI           Gateway :18789
              (browser)          (OpenClaw core)
                                       │
                              ┌────────┼────────┐
                              │        │        │
                            LLM     Skills    n8n
                           (API)   (tools)  (webhooks)
```

**Key details:**
- Express listens on `:8080` (Railway's public port)
- `/setup/*` routes serve the setup wizard UI and API, protected by `SETUP_PASSWORD` via HTTP Basic auth
- `/healthz` and `/setup/healthz` are unauthenticated for Railway health probes
- All other routes are proxied via `http-proxy` to `127.0.0.1:18789` (the OpenClaw gateway)
- The gateway is a child process spawned after setup completes — it only binds to loopback
- If the gateway is not running, Express returns a 503 with troubleshooting hints
- The gateway communicates with LLM APIs, executes skills/tools, and triggers n8n webhooks

### Key Source Files

| File | Lines | Purpose |
|---|---|---|
| `src/server.js` | ~1400 | Express wrapper: setup wizard, health checks, config editor, debug console, backup/restore, gateway proxy, PostHog analytics |
| `src/instrumentation.mjs` | ~95 | OpenTelemetry SDK: registers Langfuse + OTLP span processors, OpenLLMetry for LLM SDK auto-instrumentation |
| `src/setup-app.js` | ~350 | Browser-side JS for the `/setup` wizard UI (vanilla JS, no framework) |
| `start.sh` | ~70 | Container entrypoint: Tailscale, GitHub creds, hot update, exec server |
| `scripts/update-openclaw.sh` | ~160 | Hot-update script: resolve channel flags, clone/build to /data/openclaw |
| `Dockerfile` | ~86 | Multi-stage build: OpenClaw from source, runtime with Tailscale + tools |
| `workspace/AGENTS.md` | ~260 | Default system prompt: multi-model routing, infra routing, observability |

### server.js Structure

The server has these major sections:

1. **Environment & config** (lines 1-140) — Env var resolution with deprecation shims, gateway token persistence, config path resolution
2. **Gateway lifecycle** (lines 140-275) — Start/stop/restart gateway, health probing, crash diagnostics
3. **Auth middleware** (lines 277-300) — HTTP Basic auth for `/setup` routes
4. **Setup wizard routes** (lines 300-510) — HTML page, status API, auth groups for onboarding
5. **Onboarding** (lines 570-900) — `POST /setup/api/run`: runs `openclaw onboard`, configures gateway, copies skills, applies cost defaults, sets up channels
6. **Debug console** (lines 930-1070) — Allowlisted CLI commands, config editor, device management
7. **Config editor** (lines 1068-1110) — Raw config read/write with backup
8. **Backup/restore** (lines 1150-1285) — Tar export/import with path traversal protection
9. **Gateway proxy** (lines 1287-1320) — http-proxy to the internal gateway
10. **Boot** (lines 1322-1395) — Listen, auto-configure hooks, auto-start gateway

### Instrumentation Architecture

```
instrumentation.mjs (loaded via --import, runs before server.js)
  │
  ├── OpenLLMetry (@traceloop/node-server-sdk)
  │     Auto-patches: OpenAI, Anthropic, Google, Cohere SDKs
  │
  ├── NodeSDK with SpanProcessors:
  │     ├── LangfuseSpanProcessor → Langfuse (LLM eval + traces)
  │     └── BatchSpanProcessor + OTLPTraceExporter → Generic OTLP
  │
  └── Auto-instrumentations:
        Express routes, HTTP client (fs and DNS disabled)
```

PostHog is initialized separately in `server.js` because it tracks product events (not spans). PostHog events include the OTel `traceId` for correlation.

### Workspace & Skills

Skills are `SKILL.md` files with YAML frontmatter in `workspace/skills/<name>/`. On first setup, `server.js` recursively copies `workspace/` into the user's workspace directory (default: `/data/workspace`). Existing files are never overwritten.

To add a new default skill:

1. Create `workspace/skills/<skill-name>/SKILL.md`
2. Add YAML frontmatter with `name`, `description`, and optional `metadata`
3. Add any supporting files in the same directory
4. Update the skills table in `README.md`

### Infrastructure Routing

The `AGENTS.md` system prompt defines a decision tree that routes workloads to the cheapest capable platform:

| Workload | Platform |
|---|---|
| SaaS actions (email, Slack, CRM) | Composio Rube MCP |
| Multi-step orchestration | n8n workflows |
| GPU/heavy compute | Modal serverless |
| Lightweight/realtime | Railway local |
| Hybrid pipelines | Railway brain + Modal muscle + n8n glue + Composio delivery |

### Hot-Update Mechanism

OpenClaw can be updated at runtime without rebuilding the Docker image. The mechanism has three layers:

**Boot-time update** (`start.sh`):
When `OPENCLAW_UPDATE_REF` is set, `start.sh` calls `scripts/update-openclaw.sh` before starting the server. If the build succeeds, `OPENCLAW_ENTRY` is set to `/data/openclaw/dist/entry.js`. If it fails, the baked-in `/openclaw` is used as a fallback.

**Auto-detect previous update** (`start.sh`):
If `/data/openclaw/dist/entry.js` exists from a previous update (and `OPENCLAW_UPDATE_REF` is not set), the server automatically uses it. This means updates persist across container restarts.

**Live update** (`server.js` debug console):
The `openclaw.update` console command runs the same update script on-demand. After a successful build, it sets `process.env.OPENCLAW_ENTRY` and calls `restartGateway()` for zero-downtime swaps.

**Channel flags** (`scripts/update-openclaw.sh`):
The update script accepts `--stable` (latest `v*` release tag), `--beta` (latest `v*-beta*` or `v*-rc*` tag), `--canary` (latest `main` commit), or any branch/tag/SHA. It resolves channel flags via `git ls-remote --tags` to avoid cloning the entire repo just to find a tag.

**Key invariant**: The original `/openclaw` directory in the Docker image is never modified. It always serves as a fallback.

## Multi-Service Template Architecture

The Railway template deploys 7 services. The template is defined **in the Railway dashboard** (not in config files). The `railway.toml` in this repo only configures the OpenClaw service's build and deploy settings.

### How It Works

1. The template is created via Railway's dashboard using "Generate from existing project"
2. Each service has its own Docker image or GitHub repo source
3. Services are wired together using [reference variables](https://docs.railway.com/variables#reference-variables) (`${{ServiceName.VAR}}`)
4. Secrets are auto-generated using `${{secret(32, "hex")}}` syntax

### Dependency Graph

```
OpenClaw ←(optional webhook)→ n8n Primary
                                   ↓ (required)
                              Postgres ← Redis
                                   ↑
n8n Worker ───────────────────────┘

Postiz → Postgres, Redis (standalone — no OpenClaw dependency)
Temporal → Postgres (standalone — no OpenClaw dependency)
```

### Reference Variable Wiring

These are the cross-service references configured in the Railway dashboard template:

| Consumer | Variable | Value (Reference Expression) |
|---|---|---|
| OpenClaw | `OPENCLAW_HOOKS_TOKEN` | `${{secret(32, "hex")}}` |
| OpenClaw | `N8N_WEBHOOK_URL` | `http://${{n8n Primary.RAILWAY_PRIVATE_DOMAIN}}:5678` |
| n8n Primary | `DB_POSTGRESDB_HOST` | `${{Postgres.RAILWAY_PRIVATE_DOMAIN}}` |
| n8n Primary | `DB_POSTGRESDB_PASSWORD` | `${{Postgres.PGPASSWORD}}` |
| n8n Primary | `DB_POSTGRESDB_DATABASE` | `${{Postgres.POSTGRES_DB}}` |
| n8n Primary | `DB_POSTGRESDB_USER` | `${{Postgres.POSTGRES_USER}}` |
| n8n Primary | `QUEUE_BULL_REDIS_HOST` | `${{Redis.RAILWAY_PRIVATE_DOMAIN}}` |
| n8n Primary | `QUEUE_BULL_REDIS_PASSWORD` | `${{Redis.REDIS_PASSWORD}}` |
| n8n Primary | `N8N_ENCRYPTION_KEY` | `${{secret(32)}}` |
| n8n Primary | `OPENCLAW_HOOKS_TOKEN` | `${{OpenClaw.OPENCLAW_HOOKS_TOKEN}}` |
| n8n Worker | `N8N_ENCRYPTION_KEY` | `${{n8n Primary.N8N_ENCRYPTION_KEY}}` |
| n8n Worker | `DB_POSTGRESDB_HOST` | `${{Postgres.RAILWAY_PRIVATE_DOMAIN}}` |
| n8n Worker | `QUEUE_BULL_REDIS_HOST` | `${{Redis.RAILWAY_PRIVATE_DOMAIN}}` |
| Postiz | `DATABASE_URL` | `postgresql://${{Postgres.POSTGRES_USER}}:${{Postgres.PGPASSWORD}}@${{Postgres.RAILWAY_PRIVATE_DOMAIN}}:5432/${{Postgres.POSTGRES_DB}}` |
| Postiz | `REDIS_URL` | `redis://default:${{Redis.REDIS_PASSWORD}}@${{Redis.RAILWAY_PRIVATE_DOMAIN}}:6379` |
| Temporal | `POSTGRES_SEEDS` | `${{Postgres.RAILWAY_PRIVATE_DOMAIN}}` |
| Temporal | `POSTGRES_PWD` | `${{Postgres.PGPASSWORD}}` |

### Updating the Template

To modify the template (add/remove services, change variables):

1. Go to the Railway dashboard > **Settings > Templates**
2. Edit the template for "OpenClaw AI + n8n + Tailscale"
3. Add or modify services and their variables
4. Service names in `${{ServiceName.VAR}}` must exactly match — do not rename services after wiring

### Service Images

| Service | Docker Image |
|---|---|
| OpenClaw | Built from `Dockerfile` in this repo |
| n8n Primary | `n8nio/n8n:latest` |
| n8n Worker | `n8nio/n8n:latest` |
| Postgres | `ghcr.io/railwayapp-templates/postgres-ssl:17` |
| Redis | `redis:8.2.1` |
| Postiz | `ghcr.io/gitroomhq/postiz-app:latest` |
| Temporal | `temporalio/auto-setup:latest` |

## Troubleshooting Development Issues

### Gateway Won't Start Locally

If `pnpm dev` starts Express but the gateway doesn't connect:

1. **Check OpenClaw is available:** The gateway binary must exist at the path specified by `OPENCLAW_ENTRY` (or the default `/openclaw/dist/entry.js` in Docker)
2. **Verify environment variables:** `.env` must have at least `SETUP_PASSWORD` and an LLM API key
3. **Check port 18789 is free:** `lsof -i :18789` — kill any existing process
4. **Run with debug logging:** `DEBUG=* pnpm dev`

### n8n Database Errors

If n8n shows "relation does not exist" errors:

1. Verify Postgres is running and accessible
2. Check `DB_POSTGRESDB_*` variables match your Postgres service
3. Redeploy n8n — it runs migrations automatically on startup
4. If tables are corrupted, drop and let n8n recreate: `psql -h localhost -U postgres -d railway -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"`

### Tailscale Auth Key Expired

1. Generate a new key at [Tailscale Admin > Keys](https://login.tailscale.com/admin/settings/keys)
2. Enable **Reusable** and **Ephemeral**
3. Update `TAILSCALE_AUTHKEY` in `.env` (local) or Railway Variables (production)
4. Restart the server

## Deployment Checklist

### Before Deploying

- [ ] All tests pass: `pnpm test`
- [ ] No lint errors: `pnpm lint`
- [ ] Docker builds locally: `docker build -t openclaw-railway .`
- [ ] Commit message follows [Conventional Commits](https://www.conventionalcommits.org/)

### Deployment Configuration

- [ ] Volume mounted at `/data` (persistent state)
- [ ] `SETUP_PASSWORD` set (required)
- [ ] `TAILSCALE_AUTHKEY` set (required)
- [ ] LLM API key set (`ANTHROPIC_API_KEY` or equivalent)
- [ ] `healthcheckPath=/setup/healthz` configured in `railway.toml`
- [ ] `healthcheckTimeout=300` (or higher for slow first boots)

### Post-Deployment Verification

- [ ] Service shows "Online" in Railway dashboard
- [ ] Logs show `[wrapper] listening on :8080`
- [ ] No `[proxy] Error: connect ECONNREFUSED` errors
- [ ] `/setup/healthz` returns 200 OK
- [ ] Setup wizard loads at `/setup`
- [ ] Gateway starts after completing setup

### If Deploying with n8n

- [ ] n8n Primary deployed and shows "Online"
- [ ] Postgres and Redis deployed and healthy
- [ ] `N8N_WEBHOOK_URL` set on OpenClaw service
- [ ] `OPENCLAW_HOOKS_TOKEN` matches on both OpenClaw and n8n Primary
- [ ] n8n database variables set correctly (`DB_POSTGRESDB_*`)
- [ ] Both services redeployed after variable changes
- [ ] Tested webhook connectivity (n8n HTTP Request → OpenClaw `/hooks/agent`)

## Adding Features

### Adding a New Health Check

Add the endpoint in `server.js` near the existing `/healthz` route. Keep it free of secrets and authentication for Railway probes.

### Adding a New Debug Command

1. Add the command name to `ALLOWED_CONSOLE_COMMANDS` set
2. Add the handler in the `POST /setup/api/console/run` chain
3. Always wrap output in `redactSecrets()`

### Adding a New Trace Backend

1. Import the exporter in `src/instrumentation.mjs`
2. Create a span processor, guarded by an env var check
3. Push it to the `spanProcessors` array
4. The NodeSDK automatically fans spans to all registered processors

### Adding a New PostHog Event

Call `trackEvent("event_name", { key: "value" })` anywhere in `server.js`. It's a no-op if `POSTHOG_API_KEY` is not set.

### Adding a New CLI Tool to the Docker Image

Add the install command to the appropriate `RUN` layer in `Dockerfile`. Group with related tools to minimize layers:

```dockerfile
# In the tools installation RUN block
RUN npm install -g npm@11 @composio/rube-mcp your-new-tool \
  && ...
```

Update the CLI Tools table in `README.md`.

## Code Style

- ES modules (`import`/`export`), no CommonJS
- No TypeScript — the wrapper is intentionally plain JS for minimal build complexity
- No framework for the setup wizard UI — vanilla JS in `setup-app.js`
- Use `?.` optional chaining and `??` nullish coalescing
- Guard all optional features (Tailscale, PostHog, Langfuse, Modal) so they degrade gracefully
- Redact secrets in any user-facing output with `redactSecrets()`

## Testing

```bash
# Syntax check
pnpm lint

# Run tests (Node.js built-in test runner)
pnpm test

# Verify server starts without errors (will fail to connect gateway locally, but Express should start)
PORT=9999 node --import ./src/instrumentation.mjs src/server.js
# Look for: [wrapper] listening on :9999
```

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: Add new skill for X
fix: Resolve gateway probe bug in /healthz
docs: Update environment variables table
chore: Bump OpenTelemetry dependencies
```

## Pull Requests

1. Create a feature branch from `main`
2. Make your changes
3. Verify the server starts locally (`pnpm dev`)
4. Update README.md if you added env vars, skills, or tools
5. Open a PR with a description of what changed and why
