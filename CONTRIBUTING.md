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
                                        │
                                        ▼
                                  Gateway :18789
                                  (OpenClaw core)
```

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
RUN npm install -g @steipete/bird @composio/rube-mcp your-new-tool \
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
