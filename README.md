# OpenClaw + n8n + Tailscale on Railway

Deploy [OpenClaw](https://github.com/openclaw/openclaw) and [n8n](https://n8n.io) to Railway with secure Tailscale mesh networking. One click to deploy, zero SSH required.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.app/template/TEMPLATE_ID?referralCode=YOUR_CODE)

## What This Does

- Builds OpenClaw from source and runs the gateway on Railway
- Deploys n8n with PostgreSQL and Redis for workflow automation
- Connects OpenClaw to n8n via webhooks for AI-triggered workflows
- Wraps everything in a Tailscale encrypted mesh network
- Provides a browser-based setup wizard at `/setup` for onboarding
- Your local OpenClaw CLI discovers the remote instance over Tailscale

## Prerequisites

1. **Railway account** - [railway.app](https://railway.app)
2. **Tailscale account** - [tailscale.com](https://tailscale.com) (free for personal use)
3. **Tailscale auth key** - Generate one at [Tailscale Admin > Keys](https://login.tailscale.com/admin/settings/keys)
   - Enable **Reusable** and **Ephemeral** (recommended)
   - Pre-approve the key to skip manual device approval
4. **LLM API key** - Anthropic, OpenAI, Google, OpenRouter, or another supported provider

## Quick Start

### 1. Deploy to Railway

Click the deploy button above, or:

1. Fork this repo to your GitHub account
2. Create a new project in Railway
3. Select "Deploy from GitHub repo" and pick your fork
4. Add a **Volume** mounted at `/data` (persists config and workspace across deploys)

### 2. Set Environment Variables

In Railway's Variables tab, set:

| Variable | Required | Description |
|---|---|---|
| `SETUP_PASSWORD` | Yes | Password to access the `/setup` wizard |
| `TAILSCALE_AUTHKEY` | Yes | Tailscale auth key (reusable + ephemeral) |
| `TAILSCALE_HOSTNAME` | No | Tailnet hostname (default: `openclaw-railway`) |
| `TAILSCALE_SERVE` | No | Enable Tailscale Serve HTTPS proxy (default: `true`) |
| `ANTHROPIC_API_KEY` | No | Set here or enter during setup wizard |
| `OPENAI_API_KEY` | No | Alternative LLM provider |
| `GITHUB_TOKEN` | No | GitHub PAT for repo access from the instance |
| `OPENCLAW_GATEWAY_TOKEN` | No | Gateway auth token (auto-generated if not set) |
| `OPENCLAW_HOOKS_TOKEN` | No | Shared secret for webhook auth (OpenClaw <-> n8n) |
| `COMPOSIO_API_KEY` | No | Composio API key for Rube MCP (500+ SaaS integrations) |
| `MODAL_TOKEN_ID` | No | Modal token ID for serverless GPU/compute tasks |
| `MODAL_TOKEN_SECRET` | No | Modal token secret (pair with `MODAL_TOKEN_ID`) |
| `OPENCLAW_STATE_DIR` | No | State directory (default: `/data/.openclaw`) |
| `OPENCLAW_WORKSPACE_DIR` | No | Workspace directory (default: `/data/workspace`) |

### 3. Run Setup

Once deployed, open your Railway service URL and navigate to `/setup`. Enter the `SETUP_PASSWORD` you configured and follow the wizard:

1. Choose your model provider (Anthropic, OpenAI, Google, etc.)
2. Enter your API key
3. Optionally configure Telegram, Discord, or Slack channels
4. Click "Run setup"

The wizard runs `openclaw onboard` non-interactively and starts the gateway.

### 4. Connect from Your Local Machine

With Tailscale installed on your Mac/PC, the Railway instance appears on your tailnet:

```bash
# Verify the instance is visible
tailscale status | grep openclaw

# The OpenClaw gateway is accessible at:
# https://openclaw-railway.<your-tailnet>.ts.net
```

Your local OpenClaw CLI can now connect to the remote gateway over Tailscale.

## Architecture

```
                          Railway Private Network
  ┌─────────────────────────────────────────────────────────────┐
  │                                                             │
  │  ┌─────────────────┐     webhooks      ┌───────────────┐   │
  │  │  OpenClaw        │◄────────────────►│  n8n Primary   │   │
  │  │  Express :8080   │  /hooks/agent     │  :5678         │   │
  │  │  Gateway :18789  │  /hooks/wake      │                │   │
  │  │  Tailscale       │                   │  n8n Worker    │   │
  │  └────────┬─────────┘                   └───────┬────────┘   │
  │           │                                     │            │
  │           │                              ┌──────┴──────┐     │
  │      /data volume                        │  PostgreSQL  │     │
  │   (config + workspace)                   │  Redis       │     │
  │                                          └─────────────┘     │
  └─────────────────────────────────────────────────────────────┘
              │
              │ Tailscale (WireGuard)
              ▼
        Your Tailnet
    (encrypted mesh network)
```

### Services

| Service | Role |
|---|---|
| **OpenClaw** | AI assistant gateway with setup wizard, proxied through Express |
| **n8n Primary** | Workflow automation engine with AI agent nodes |
| **n8n Worker** | Queue-based execution for heavy workflows |
| **PostgreSQL** | Persistent storage for n8n workflows and credentials |
| **Redis** | Queue backend for distributed n8n execution |
| **Tailscale** | Encrypted mesh networking (userspace, no root required) |

### How OpenClaw connects to n8n

OpenClaw and n8n communicate via webhooks over Railway's private network:

**n8n triggering OpenClaw** (run AI from a workflow):
```bash
# n8n HTTP Request node calls OpenClaw's hooks API
POST http://openclaw-railway-template.railway.internal:8080/hooks/agent
Authorization: Bearer <OPENCLAW_HOOKS_TOKEN>
Content-Type: application/json

{"message": "Summarize today's sales data", "deliver": true, "channel": "slack"}
```

**OpenClaw triggering n8n** (AI kicks off a workflow):
```bash
# OpenClaw cron or tool calls n8n's webhook trigger
POST http://Primary.railway.internal:5678/webhook/my-workflow
Content-Type: application/json

{"data": "process this"}
```

Set `OPENCLAW_HOOKS_TOKEN` on the OpenClaw service to enable webhook auth.

## Pre-Installed Skills & Tools

This template ships with default skills and CLI tools so your OpenClaw instance is productive from the first boot.

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
| **Bird CLI** (`@steipete/bird`) | Fast X/Twitter search via GraphQL (cookie auth, no API key needed for reading) |
| **yt-dlp** | YouTube video metadata and transcript extraction |
| **gog** | Installable via Homebrew (`brew install steipete/tap/gogcli`) at runtime |

Skills are automatically copied to your workspace on first setup. You can add more skills by placing SKILL.md files in your workspace's `skills/` directory.

## Cost Optimization (Applied Automatically)

Running OpenClaw 24/7 on Railway can burn through API credits fast. This template applies cost-optimized defaults on first setup that can **reduce spend by 90%+**:

### What's auto-configured

| Setting | Value | Why |
|---|---|---|
| **Heartbeat model** | `openrouter/openai/gpt-5-nano` | Background checks run every 30min — use the cheapest model ($0.005/day vs $0.24/day with Opus) |
| **Active hours** | 06:00–23:00 UTC | Skip heartbeats while nobody's awake |
| **Context pruning** | `cache-ttl` with 6h TTL | Automatically prune old context, keep cache valid, reduce token bloat |
| **Memory compaction** | Flush at 40k tokens | Distill sessions into daily memory files instead of growing context forever |
| **Embeddings** | `text-embedding-3-small` | Cheapest OpenAI embedding model for memory search |
| **Coding subagents** | `openai-codex/gpt-5.3-codex` | GPT-5.3 Codex for coding tasks — purpose-built for agentic code work |
| **Concurrency limits** | 4 agents, 8 subagents max | Prevent cascading retries and runaway token consumption |

### Brain + Muscle pattern

For best results, use an expensive model as the "brain" (orchestrator) and cheaper models as "muscles" (workers):

| Role | Recommended Model | Cost |
|---|---|---|
| **Brain** (orchestration) | `anthropic/claude-opus-4-6` | $$$ |
| **Coding muscle** | `openai-codex/gpt-5.3-codex` (default) | $$ |
| **Heartbeat** | `openrouter/openai/gpt-5-nano` | Free-tier |
| **Subagents** | `deepseek/deepseek-reasoner` | $ |
| **Web search** | Brave API | $ |
| **Social/trending** | xAI Grok API | $ |

Configure via the `/setup` config editor or tell your OpenClaw directly: *"For coding, use DeepSeek. For heartbeats, use the cheapest model available."*

### Further savings

- Add `OPENROUTER_API_KEY` for access to dozens of cheap models via one API key
- Set model fallback chains in config so rate limits don't cascade to expensive retries
- Create a `HEARTBEAT.md` in your workspace — if it's empty, heartbeats are skipped entirely

## Managing Your Instance

### Setup Wizard

The `/setup` page provides:

- **Status** - Gateway health, version, links to the OpenClaw UI
- **Debug console** - Run safe diagnostic commands without SSH
- **Config editor** - Edit the full `openclaw.json` config with backup
- **Backup/restore** - Download and upload `.tar.gz` archives of `/data`
- **Device pairing** - Approve Telegram/Discord DM pairing requests

### Health Endpoints

| Endpoint | Auth | Purpose |
|---|---|---|
| `/setup/healthz` | None | Railway deployment probe |
| `/healthz` | None | Detailed health (gateway reachable, config status) |
| `/setup/api/debug` | Basic | Full diagnostics (versions, paths, gateway state) |

### Updating OpenClaw

Redeploy from Railway to pull the latest OpenClaw `main` branch. Your config and workspace persist on the `/data` volume.

To pin a specific version, set the build argument:
```
OPENCLAW_GIT_REF=v2026.2.12
```

## Troubleshooting

### Gateway not starting

1. Visit `/setup/api/debug` for diagnostics
2. Check the Debug console at `/setup` and run `openclaw doctor`
3. Verify your API key is valid
4. Check Railway deployment logs

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

## Security

- The `/setup` wizard is protected by `SETUP_PASSWORD` via HTTP Basic auth
- The OpenClaw gateway binds to `127.0.0.1` only (not exposed directly)
- All external access goes through the Express wrapper or Tailscale Serve
- Gateway tokens are auto-generated and persisted to the volume
- Secret values are redacted in debug console output
- Tar import validates paths to prevent directory traversal
- Tailscale provides end-to-end encrypted mesh networking (WireGuard)

## Files

| File | Purpose |
|---|---|
| `Dockerfile` | Multi-stage build: compiles OpenClaw from source, installs Tailscale + Bird + yt-dlp |
| `start.sh` | Entrypoint: starts Tailscale, configures GitHub creds, launches server |
| `src/server.js` | Express wrapper: setup wizard, health checks, gateway proxy |
| `src/setup-app.js` | Browser JS for the `/setup` wizard UI |
| `workspace/AGENTS.md` | Default multi-model routing system prompt |
| `workspace/skills/` | Default skills: coding-agent, pr-creator, gog, last30days |
| `railway.toml` | Railway deployment configuration |
| `.env.example` | Template for required environment variables |

## Contributing

Issues and PRs welcome. For questions about OpenClaw itself, visit the [OpenClaw Discord](https://discord.gg/clawd) (`#golden-path-deployments` channel).

## License

MIT
