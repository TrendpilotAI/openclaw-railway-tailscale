# OpenClaw + n8n + Tailscale on Railway

Deploy [OpenClaw](https://github.com/openclaw/openclaw) and [n8n](https://n8n.io) to Railway with secure Tailscale mesh networking, built-in observability, and 4-platform compute routing. One click to deploy, zero SSH required.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.app/template/TEMPLATE_ID?referralCode=YOUR_CODE)

## What This Deploys

One click deploys the full stack. All companion services are pre-wired with Railway reference variables — no manual secret sharing or internal URLs to configure.

### Core (always deployed)

| Service | Source | Purpose |
|---|---|---|
| **OpenClaw** | This repo (Dockerfile) | AI gateway with setup wizard, Tailscale mesh, and 4-platform compute routing |

### Companion Services (optional — delete any you don't need)

| Service | Image | Purpose | Depends On |
|---|---|---|---|
| **n8n Primary** | `n8nio/n8n` | Workflow automation engine with AI agent nodes | Postgres, Redis |
| **n8n Worker** | `n8nio/n8n` | Background workflow execution (queue mode) | n8n Primary, Postgres, Redis |
| **Postgres** | `postgres-ssl:17` | Persistent storage for n8n, Postiz, and Temporal | -- |
| **Redis** | `redis:8.2.1` | Queue/cache backend for n8n and Postiz | -- |
| **Postiz** | `postiz-app` | Social media scheduling and automation | Postgres, Redis |
| **Temporal** | `temporalio/auto-setup` | Distributed workflow orchestration | Postgres |

### Also included

- Tailscale encrypted mesh networking (embedded in OpenClaw container)
- 39 skills, 3 CLI tools, and 500+ SaaS integrations (via Composio) out of the box
- OpenTelemetry tracing with Langfuse (LLM evals) and PostHog (product analytics)
- Cost-optimized defaults that reduce API spend by 90%+
- Browser-based setup wizard at `/setup` for onboarding

## Prerequisites

1. **Railway account** — [railway.app](https://railway.app)
2. **Tailscale account** — [tailscale.com](https://tailscale.com) (free for personal use)
3. **Tailscale auth key** — Generate at [Tailscale Admin > Keys](https://login.tailscale.com/admin/settings/keys)
   - Enable **Reusable** and **Ephemeral** (recommended)
   - Pre-approve the key to skip manual device approval
4. **LLM API key** — Anthropic, OpenAI, Google, OpenRouter, or another supported provider

## Quick Start

### 1. Deploy to Railway

Click the deploy button above, or:

1. Fork this repo to your GitHub account
2. Create a new project in Railway
3. Select "Deploy from GitHub repo" and pick your fork
4. Add a **Volume** mounted at `/data` (persists config and workspace across deploys)

### 2. Set Environment Variables

The template auto-generates secrets and wires all cross-service connections via Railway reference variables. You only need to fill in:

| Variable | Required | Description |
|---|---|---|
| `SETUP_PASSWORD` | Yes | Password to access the `/setup` wizard |
| `TAILSCALE_AUTHKEY` | Yes | Tailscale auth key (reusable + ephemeral) |
| `ANTHROPIC_API_KEY` | Recommended | Set here or enter during setup wizard |

Everything else is optional and pre-configured with sensible defaults. For the full list of OpenClaw environment variables, see [`.env.example`](.env.example).

### 3. Run Setup

Once deployed, open your Railway service URL and navigate to `/setup`. Enter the `SETUP_PASSWORD` you configured and follow the wizard:

1. Choose your model provider (Anthropic, OpenAI, Google, etc.)
2. Enter your API key
3. Optionally configure Telegram, Discord, or Slack channels
4. Click "Run setup"

The wizard runs `openclaw onboard` non-interactively, applies cost-optimized defaults, copies 39 skills to your workspace, and starts the gateway.

### 4. Connect from Your Local Machine

With Tailscale installed on your Mac/PC, the Railway instance appears on your tailnet:

```bash
# Verify the instance is visible
tailscale status | grep openclaw

# The OpenClaw gateway is accessible at:
# https://openclaw-railway.<your-tailnet>.ts.net
```

Your local OpenClaw CLI can now connect to the remote gateway over Tailscale.

## Removing Optional Services

After deploying, you can delete any companion services you don't need from the Railway dashboard. This reduces cost and simplifies your project.

| Service | Safe to Delete? | Impact if Deleted |
|---|---|---|
| **OpenClaw** | No | Core service — everything depends on it |
| **n8n Primary** | Yes | No workflow automation. Also delete Worker. |
| **n8n Worker** | Yes | Primary handles all execution (slower but functional) |
| **Postgres** | Only if n8n, Postiz, and Temporal are also deleted | Required by n8n, Postiz, and Temporal |
| **Redis** | Only if n8n and Postiz are also deleted | Required by n8n queue mode and Postiz |
| **Postiz** | Yes | No social media scheduling |
| **Temporal** | Yes | No distributed workflow orchestration. Postiz v2.12+ falls back to BullMQ. |

**Common configurations:**

- **OpenClaw only** — Delete n8n Primary, n8n Worker, Postgres, Redis, Postiz, Temporal
- **OpenClaw + n8n** — Delete Postiz, Temporal
- **Full stack** — Keep everything

## Architecture

```
                              Railway Private Network
  ┌───────────────────────────────────────────────────────────────────────┐
  │                                                                       │
  │  ┌──────────────────┐     webhooks      ┌────────────────────────┐   │
  │  │  OpenClaw          │◄───────────────►│  n8n Primary :5678      │   │
  │  │  Express :8080     │  /hooks/agent    │  n8n Worker             │   │
  │  │  Gateway :18789    │  /hooks/wake     └───────────┬────────────┘   │
  │  │  Tailscale         │                              │                │
  │  │  OTel + PostHog    │                       ┌──────┴──────┐         │
  │  └────────┬───────────┘                       │  PostgreSQL  │         │
  │           │                                   │  Redis       │         │
  │      /data volume                             └──────┬──────┘         │
  │   (config + workspace)                     ┌─────────┼─────────┐      │
  │                                            │                   │      │
  │                                    ┌───────┴──────┐  ┌─────────┴───┐  │
  │                                    │  Postiz       │  │  Temporal    │  │
  │                                    │  :5000        │  │  gRPC :7233  │  │
  │                                    └──────────────┘  └─────────────┘  │
  └───────────────────────────────────────────────────────────────────────┘
              │                         │                    │
              │ Tailscale (WireGuard)   │ HTTPS API          │ OAuth
              ▼                         ▼                    ▼
        Your Tailnet              Modal (GPU)          Composio (SaaS)
    (encrypted mesh)          (serverless compute)    (500+ integrations)
```

### Services

All Railway services below are deployed by the template and wired together automatically via [reference variables](https://docs.railway.com/variables#reference-variables). The multi-service template is defined in the Railway dashboard (not in `railway.toml`, which only configures the OpenClaw service's build/deploy settings).

| Service | Type | Role | Optional? |
|---|---|---|---|
| **OpenClaw** | GitHub repo (this repo) | AI assistant gateway with setup wizard, proxied through Express | No |
| **n8n Primary** | Docker image | Workflow automation engine with AI agent nodes | Yes |
| **n8n Worker** | Docker image | Background workflow execution in queue mode | Yes |
| **Postgres** | Docker image | Persistent storage for n8n, Postiz, and Temporal | If n8n/Postiz deleted |
| **Redis** | Docker image | Queue/cache backend for n8n and Postiz | If n8n/Postiz deleted |
| **Postiz** | Docker image | Social media scheduling ([postiz.com](https://postiz.com)) | Yes |
| **Temporal** | Docker image | Distributed workflow orchestration | Yes |
| **Tailscale** | Embedded | Encrypted mesh networking (runs inside OpenClaw container) | -- |
| **Modal** | External API | Serverless GPU/compute for ML inference, batch processing | -- |
| **Composio** | External API | Universal MCP server for 500+ SaaS integrations | -- |

### How OpenClaw Connects to n8n

The template auto-wires OpenClaw and n8n via Railway reference variables:

- `OPENCLAW_HOOKS_TOKEN` — auto-generated shared secret, injected into both services
- `N8N_WEBHOOK_URL` — set to `http://${{n8n Primary.RAILWAY_PRIVATE_DOMAIN}}:5678` on OpenClaw

**n8n triggering OpenClaw** (run AI from a workflow):
```bash
# n8n HTTP Request node calls OpenClaw's hooks API
POST http://OpenClaw.railway.internal:8080/hooks/agent
Authorization: Bearer <OPENCLAW_HOOKS_TOKEN>
Content-Type: application/json

{"message": "Summarize today's sales data", "deliver": true, "channel": "slack"}
```

**OpenClaw triggering n8n** (AI kicks off a workflow):
```bash
# OpenClaw cron or tool calls n8n's webhook trigger
POST http://n8n-Primary.railway.internal:5678/webhook/my-workflow
Content-Type: application/json

{"data": "process this"}
```

No manual setup required — the template handles all secret sharing and internal URL wiring.

## Infrastructure Routing

The template routes workloads across 4 compute platforms automatically. See `workspace/AGENTS.md` for the full decision tree.

| Platform | Best For | Cost |
|---|---|---|
| **Railway** (this container) | Gateway, web server, cron, lightweight CLI tasks | ~$5-20/mo fixed |
| **Modal** (serverless) | ML inference, batch processing, image/video gen, data pipelines | Pay-per-second |
| **n8n** (orchestration) | Multi-step workflows, scheduled jobs, webhook chains | Included in Railway plan |
| **Composio** (SaaS bridge) | Direct SaaS actions (send email, create issue, update CRM) | Free tier available |

### Routing Examples

```
"Fix the auth bug in middleware.ts"   → Railway local + Claude Opus 4.6
"Generate 100 product thumbnails"     → Modal A10G GPU + Qwen 3.5 VL
"Every morning, email a sales report" → n8n scheduled workflow
"Post a message to Slack"             → Composio Rube MCP
```

## Pre-Installed Skills & Tools

This template ships with 39 skills and 3 CLI tools so your OpenClaw instance is productive from the first boot. Skills are automatically copied to your workspace on first setup.

### Skills (copied to workspace on first setup)

**Railway (platform management):**

| Skill | What it does |
|---|---|
| **railway-deploy** | Deploy code with `railway up` — detach and CI modes, service targeting |
| **railway-status** | Check project status, services, deployments, and domains |
| **railway-environment** | Query and apply config changes — variables, build/deploy settings, replicas |
| **railway-service** | Service management — status, rename, Docker image deploys |
| **railway-database** | Add Postgres, Redis, MySQL, MongoDB with connection wiring |
| **railway-domain** | Add/remove Railway and custom domains, DNS configuration |
| **railway-projects** | List, switch, and configure Railway projects and workspaces |

**n8n (workflow automation):**

| Skill | What it does |
|---|---|
| **n8n-workflow-patterns** | 5 core patterns: webhook, HTTP API, database, AI agent, scheduled tasks |
| **n8n-code-javascript** | Write JavaScript in n8n Code nodes — `$input`/`$json` syntax, modes, patterns |
| **n8n-code-python** | Write Python in n8n Code nodes — `_input`/`_json` syntax, stdlib-only |
| **n8n-node-configuration** | Operation-aware node config — property dependencies, progressive discovery |
| **n8n-expression-syntax** | Expression syntax (`{{$json.field}}`), variable access, webhook data structure |
| **n8n-mcp-tools** | MCP tool selection guide — node search, validation, workflow management |
| **n8n-validation** | Interpret and fix validation errors — severity levels, the validate-fix loop |
| **n8n-skills** | Complete n8n knowledge base — 545 node docs, 20 templates, community packages, compatibility matrix |

**Development & DevOps:**

| Skill | What it does |
|---|---|
| **coding-agent** | Run Codex CLI, Claude Code, OpenCode, or Pi in background processes with PTY support |
| **pr-creator** | Create pull requests following repo templates and Conventional Commits |
| **test-driven-development** | TDD workflow: red-green-refactor cycle for all features and bugfixes |
| **writing-plans** | Write comprehensive implementation plans with bite-sized TDD tasks |

**Communication & Productivity:**

| Skill | What it does |
|---|---|
| **gog** | Google Workspace CLI — Gmail, Calendar, Drive, Contacts, Sheets, Docs |
| **himalaya** | CLI email client via IMAP/SMTP — read, write, reply, search, organize |
| **wacli** | WhatsApp CLI — send messages, search history, sync conversations |
| **jira** | Jira issue management — view, create, transition, comment via CLI or MCP |

**Research & Analytics:**

| Skill | What it does |
|---|---|
| **last30days** | Research any topic across Reddit, X, YouTube, and the web from the last 30 days |
| **data-storytelling** | Transform data into compelling narratives for executive presentations |
| **visualization-expert** | Chart selection and data visualization guidance |
| **project-planner** | Break down projects into tasks with timelines, dependencies, milestones |
| **strategy-advisor** | High-level strategic thinking and business decision guidance |

**Content & Creative:**

| Skill | What it does |
|---|---|
| **changelog-social** | Generate Discord, Twitter, LinkedIn announcements from changelogs |
| **scientific-slides** | Build slide decks for conferences, seminars, thesis defenses |
| **viral-generator-builder** | Build shareable quiz makers, name generators, personality tests |

### CLI Tools (pre-installed in Docker image)

| Tool | Purpose |
|---|---|
| **Rube MCP** (`@composio/rube-mcp`) | Composio universal MCP server — 500+ SaaS integrations (Gmail, Slack, Notion, GitHub, etc.) |
| **yt-dlp** | YouTube video metadata and transcript extraction |
| **Modal** (`modal`) | Serverless GPU/compute CLI — deploy functions, run batch jobs on A10G/A100/H100 |
| **Homebrew** | Available at runtime for installing additional CLI tools (e.g. `brew install gogcli`) |

You can add more skills by placing `SKILL.md` files in your workspace's `skills/` directory.

## Observability

The template ships with built-in OpenTelemetry instrumentation. All tracing is opt-in and gracefully degrades — no keys means no overhead.

### What Gets Traced

| Layer | Auto-instrumented |
|---|---|
| **Express routes** | All `/setup/*`, `/healthz`, proxy requests |
| **HTTP client** | Gateway proxy calls, n8n webhook calls |
| **LLM providers** | OpenAI, Anthropic, Google, Cohere SDK calls (via OpenLLMetry) |

### Trace Backends

| Backend | Purpose | Required Vars |
|---|---|---|
| **Langfuse** | LLM tracing, evals, cost tracking | `LANGFUSE_PUBLIC_KEY` + `LANGFUSE_SECRET_KEY` |
| **PostHog** | Product analytics (setup, gateway events) | `POSTHOG_API_KEY` |
| **OTLP** (Grafana, Jaeger, etc.) | Generic APM traces | `OTEL_EXPORTER_OTLP_ENDPOINT` |

PostHog events include OTel trace IDs for cross-system correlation. See `workspace/AGENTS.md` for the full observability architecture.

## Cost Optimization (Applied Automatically)

Running OpenClaw 24/7 on Railway can burn through API credits fast. This template applies cost-optimized defaults on first setup that can **reduce spend by 90%+**:

### What's Auto-Configured

| Setting | Value | Why |
|---|---|---|
| **Heartbeat model** | `openrouter/openai/gpt-5-nano` | Background checks run every 30min — use the cheapest model ($0.005/day vs $0.24/day with Opus) |
| **Active hours** | 06:00-23:00 UTC | Skip heartbeats while nobody's awake |
| **Context pruning** | `cache-ttl` with 6h TTL | Automatically prune old context, keep cache valid, reduce token bloat |
| **Memory compaction** | Flush at 40k tokens | Distill sessions into daily memory files instead of growing context forever |
| **Embeddings** | `text-embedding-3-small` | Cheapest OpenAI embedding model for memory search |
| **Coding subagents** | `openai-codex/gpt-5.3-codex` | GPT-5.3 Codex for coding tasks — purpose-built for agentic code work |
| **Concurrency limits** | 4 agents, 8 subagents max | Prevent cascading retries and runaway token consumption |

### Brain + Muscle Pattern

Use an expensive model as the "brain" (orchestrator) and cheaper models as "muscles" (workers):

| Role | Recommended Model | Cost |
|---|---|---|
| **Brain** (orchestration) | `anthropic/claude-opus-4-6` | $$$ |
| **Coding muscle** | `openai-codex/gpt-5.3-codex` (default) | $$ |
| **Heartbeat** | `openrouter/openai/gpt-5-nano` | Free-tier |
| **Subagents** | `deepseek/deepseek-reasoner` | $ |
| **Web search** | Brave API | $ |
| **Social/trending** | xAI Grok API | $ |

Configure via the `/setup` config editor or tell your OpenClaw directly: *"For coding, use DeepSeek. For heartbeats, use the cheapest model available."*

### Further Savings

- Add `OPENROUTER_API_KEY` for access to dozens of cheap models via one API key
- Set model fallback chains in config so rate limits don't cascade to expensive retries
- Create a `HEARTBEAT.md` in your workspace — if it's empty, heartbeats are skipped entirely

## Managing Your Instance

### Setup Wizard

The `/setup` page provides:

- **Status** — Gateway health, version, links to the OpenClaw UI
- **Debug console** — Run safe diagnostic commands without SSH
- **Config editor** — Edit the full `openclaw.json` config with backup
- **Backup/restore** — Download and upload `.tar.gz` archives of `/data`
- **Device pairing** — Approve Telegram/Discord DM pairing requests

### Health Endpoints

| Endpoint | Auth | Purpose |
|---|---|---|
| `/setup/healthz` | None | Railway deployment probe |
| `/healthz` | None | Detailed health (gateway reachable, config status) |
| `/setup/api/debug` | Basic | Full diagnostics (versions, paths, gateway state) |

### Updating OpenClaw

There are three ways to update OpenClaw, from heaviest to lightest:

**1. Docker rebuild** (full rebuild, ~10 min)

Redeploy from Railway to pull the latest OpenClaw `main` branch. Pin a specific version with the build arg:
```
OPENCLAW_GIT_REF=v2026.2.12
```

**2. Boot-time update** (no rebuild, updates on container start)

Set the `OPENCLAW_UPDATE_REF` environment variable in Railway. The container clones, builds, and starts the updated version automatically:

```bash
# Channel flags
OPENCLAW_UPDATE_REF=--stable    # Latest release tag (v*)
OPENCLAW_UPDATE_REF=--beta      # Latest pre-release tag (v*-beta*, v*-rc*)
OPENCLAW_UPDATE_REF=--canary    # Latest main branch commit

# Or pin to a specific ref
OPENCLAW_UPDATE_REF=v2026.3.1   # Specific tag
OPENCLAW_UPDATE_REF=main        # Branch
OPENCLAW_UPDATE_REF=fix/auth    # Feature branch
```

The update is stored on the `/data` volume. On subsequent restarts, the updated version is used automatically even without the env var set. Remove the env var after the first update to avoid re-building every boot.

**3. Live update from debug console** (no restart needed)

Open `/setup`, go to the Debug console, select `openclaw.update`, and enter a ref (`--stable`, `--beta`, `--canary`, or any branch/tag/SHA). The gateway restarts automatically with the new version — zero downtime.

Your config and workspace always persist on the `/data` volume. The original OpenClaw in the Docker image is never modified and serves as a fallback if an update fails.

## Troubleshooting

### Gateway not starting

1. Visit `/setup/api/debug` for diagnostics
2. Check the Debug console at `/setup` and run `openclaw doctor`
3. Verify your API key is valid
4. Check Railway deployment logs

### n8n "relation does not exist" errors

If you see `relation "public.execution_entity" does not exist` or similar errors in n8n logs, the database tables were never created. Common causes:

1. **`DB_POSTGRESDB_HOST` is misspelled** — double-check the variable name (not `HOSE`)
2. **`DB_POSTGRESDB_USER` is missing** — set it to `postgres` (Railway's default)
3. **n8n started before PostgreSQL was ready** — redeploy the n8n service

After fixing, redeploy n8n. It runs migrations automatically on startup.

### Gateway token missing (Control UI)

If the browser shows `unauthorized: gateway token missing`, you need to paste the gateway token into the Control UI settings. Find it at `/setup` on the Railway public URL (`https://<your-service>.up.railway.app/setup`).

### Tailscale not connecting

1. Verify `TAILSCALE_AUTHKEY` is set and not expired
2. Check if the key is pre-approved in Tailscale Admin
3. Look for `[tailscale] Connected to tailnet` in Railway logs
4. Ensure the auth key has not hit its usage limit

### 502 errors from Railway

This usually means the gateway hasn't started yet. The Express wrapper returns a `503` with troubleshooting hints. Common causes:
- Missing or invalid config (visit `/setup` to run onboarding)
- Gateway crash on startup (check `/setup/api/debug`)
- Volume not mounted (config lost between deploys)

### Telegram/Discord "pairing required"

1. Visit `/setup` and expand the "Pairing helper" section
2. Click "Refresh pending devices" to see requests
3. Approve the device ID for your chat

### No traces appearing in Langfuse

1. Verify both `LANGFUSE_PUBLIC_KEY` and `LANGFUSE_SECRET_KEY` are set
2. Check Railway logs for `[otel] Langfuse span processor enabled`
3. If you see `[otel] No trace backends configured`, the keys are missing or empty
4. Verify `LANGFUSE_BASEURL` if using a self-hosted Langfuse instance

## Security

- The `/setup` wizard is protected by `SETUP_PASSWORD` via HTTP Basic auth
- The OpenClaw gateway binds to `127.0.0.1` only (not exposed directly)
- All external access goes through the Express wrapper or Tailscale Serve
- Gateway tokens are auto-generated and persisted to the volume
- Secret values are redacted in debug console output
- Tar import validates paths to prevent directory traversal
- Tailscale provides end-to-end encrypted mesh networking (WireGuard)
- Observability data is sent only to backends you explicitly configure

## Project Structure

```
.
├── Dockerfile                  # Multi-stage build: OpenClaw from source + Tailscale + tools
├── scripts/
│   └── update-openclaw.sh      # Hot-update script: clone/build OpenClaw to /data without Docker rebuild
├── start.sh                    # Entrypoint: Tailscale → GitHub creds → hot update → OTel → server
├── railway.toml                # Railway config for OpenClaw service only (the multi-service template is dashboard-defined)
├── package.json                # Node.js dependencies (Express, OTel, PostHog, Langfuse)
├── .env.example                # Template for all environment variables
├── .gitignore
├── LICENSE                     # MIT
│
├── src/
│   ├── server.js               # Express wrapper: setup wizard, health, gateway proxy, PostHog
│   ├── instrumentation.mjs     # OpenTelemetry SDK: Langfuse + OTLP exporters, auto-instrumentation
│   └── setup-app.js            # Browser JS for the /setup wizard UI
│
├── workspace/
│   ├── AGENTS.md               # Multi-model routing prompt + infra routing + observability docs
│   └── skills/                 # 30+ default skills (copied to user workspace on first setup)
│       ├── railway-deploy/     # Railway platform management (7 skills)
│       ├── railway-status/
│       ├── railway-environment/
│       ├── railway-service/
│       ├── railway-database/
│       ├── railway-domain/
│       ├── railway-projects/
│       ├── n8n-skills/         # Comprehensive n8n knowledge base (545 node docs, 20 templates)
│       ├── n8n-workflow-patterns/  # n8n workflow automation (7 skills)
│       ├── n8n-code-javascript/
│       ├── n8n-code-python/
│       ├── n8n-node-configuration/
│       ├── n8n-expression-syntax/
│       ├── n8n-mcp-tools/
│       ├── n8n-validation/
│       ├── coding-agent/       # Development & DevOps (4 skills)
│       ├── pr-creator/
│       ├── test-driven-development/
│       ├── writing-plans/
│       ├── gog/                # Communication & Productivity (4 skills)
│       ├── himalaya/
│       ├── wacli/
│       ├── jira/
│       ├── last30days/         # Research & Analytics (5 skills)
│       ├── data-storytelling/
│       ├── visualization-expert/
│       ├── project-planner/
│       ├── strategy-advisor/
│       ├── changelog-social/   # Content & Creative (3 skills)
│       ├── scientific-slides/
│       └── viral-generator-builder/
│
└── assets/
    ├── openclaw-icon.png
    ├── n8n-icon.png
    └── tailscale-icon.png
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, architecture details, and contribution guidelines.

Issues and PRs welcome. For questions about OpenClaw itself, visit the [OpenClaw Discord](https://discord.gg/clawd) (`#golden-path-deployments` channel).

## License

MIT
