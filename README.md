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
| `Dockerfile` | Multi-stage build: compiles OpenClaw from source, installs Tailscale |
| `start.sh` | Entrypoint: starts Tailscale, configures GitHub creds, launches server |
| `src/server.js` | Express wrapper: setup wizard, health checks, gateway proxy |
| `src/setup-app.js` | Browser JS for the `/setup` wizard UI |
| `railway.toml` | Railway deployment configuration |
| `.env.example` | Template for required environment variables |

## Contributing

Issues and PRs welcome. For questions about OpenClaw itself, visit the [OpenClaw Discord](https://discord.gg/clawd) (`#golden-path-deployments` channel).

## License

MIT
