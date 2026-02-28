# Changelog

All notable changes to this project are documented here. This project follows [Conventional Commits](https://www.conventionalcommits.org/).

## [Unreleased]

### Added
- **Multi-provider auto-registration** — detects all API keys in Railway env vars (`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `DEEPSEEK_API_KEY`, `GROK_API_KEY`, `KIMI_API_KEY`) and registers each as a provider, so OpenClaw can route to any of them
- **Provider-aware model routing** — primary, subagent, and heartbeat models are auto-selected to match the user's auth provider (MiniMax M2.5 for orchestration, Opus 4.6 for coding, free NVIDIA model for heartbeats via OpenRouter)
- **Heartbeat fallback chain** — 4 free-tier models (NVIDIA Nemotron, StepFun Flash, Upstage Solar, Arcee Trinity) with automatic failover so heartbeats never fail due to a single model going offline
- When `ANTHROPIC_API_KEY` is detected alongside OpenRouter primary auth, coding subagents route through Anthropic direct for prompt caching and Max subscription rate limits

### Fixed
- **Cost defaults now match user's auth provider** — previously hardcoded `openai-codex/gpt-5.3-codex` as subagent model and `openrouter/openai/gpt-5-nano` as heartbeat model regardless of auth choice, causing "No API key" / "Unknown model" errors for users who authenticated with Anthropic, Google, or other providers

### Changed
- Pinned OpenClaw to v2026.2.19 (was `main`). Notable upstream changes:
  - **Breaking:** Gateway auth defaults to token mode with auto-generation (set `gateway.auth.mode: "none"` for open loopback)
  - Apple Watch companion MVP (inbox UI, notification relay, command surfaces)
  - APNs push registration and iOS node wake before invocation
  - New device management CLI commands (`device.pair.remove`, `openclaw devices remove`)
  - Security hardening: path traversal prevention, SSRF protections for IPv6, prototype pollution blocking, command injection prevention

### Added
- Request flow diagrams in README and CONTRIBUTING explaining Express → Gateway proxy architecture
- Expanded troubleshooting section with gateway failure diagnostic table, debug steps, and n8n connectivity fixes
- Deployment checklists (pre-deploy, deploy, post-deploy, companion services, monitoring)
- Manual n8n webhook wiring guide for non-template deployments
- Local development troubleshooting in CONTRIBUTING (gateway, n8n DB errors, Tailscale auth)

## 2026-02-19

### Added
- Multi-service Railway template (`cDVYRI`) with all 7 services auto-wired via reference variables
- "Removing Optional Services" section in README with dependency impact table
- "How OpenClaw Connects to n8n" section with webhook examples in both directions
- Multi-Service Template Architecture section in CONTRIBUTING with dependency graph and reference variable wiring table
- Network architecture diagram showing all 7 services and external APIs

### Changed
- Restructured README for multi-service template (core vs companion services)
- Deploy button now points to multi-service template (`cDVYRI`) instead of single-service
- Updated npm to v11, removed deprecated Bird CLI
- Services table updated to reflect all 7 template services with roles and optionality

### Fixed
- Added python3-pip to Dockerfile for runtime script dependencies
- Documented n8n webhook wiring with correct variable names and internal URLs

## 2026-02-18

### Added
- 8 new workspace skills: SEO audit, video production, web performance, YouTube transcript extraction

### Fixed
- Docker cache bust mechanism with `CACHEBUST` ARG and `RUN echo` layer to ensure code changes are picked up

## 2026-02-17

### Added
- Hot-update mechanism for OpenClaw without Docker rebuild (boot-time, auto-detect, live update via debug console)
- Channel flags for update script: `--stable`, `--beta`, `--canary`, or any branch/tag/SHA
- OpenTelemetry observability with Langfuse (LLM evals) and PostHog (product analytics)
- OTLP trace exporter for generic APM backends (Grafana, Jaeger, etc.)
- OpenLLMetry auto-instrumentation for OpenAI, Anthropic, Google, Cohere SDKs
- Infrastructure routing layer in AGENTS.md (Railway, Modal, n8n, Composio decision tree)
- n8n-skills knowledge base with 545 node docs and 20 workflow templates
- 30 default skills covering Railway, n8n, development, communication, research, and creative work
- CLI tools: Rube MCP (Composio), yt-dlp, Modal CLI, Homebrew
- Multi-model routing prompt as default AGENTS.md
- Comprehensive README overhaul, developer guide, and `.env.example` template

### Changed
- Default coding subagent model set to GPT-5.3 Codex

## 2026-02-16

### Added
- Cost-optimized defaults applied automatically on first setup (90%+ API spend reduction)
- Heartbeat model set to `openrouter/openai/gpt-5-nano` ($0.005/day vs $0.24/day)
- Active hours (06:00-23:00 UTC), context pruning, memory compaction defaults
- Concurrency limits (4 agents, 8 subagents) to prevent runaway token consumption
- Auto-configure OpenClaw webhook hooks when `OPENCLAW_HOOKS_TOKEN` is set
- n8n integration docs, webhook bridge configuration, and service icons

### Changed
- Default Tailscale hostname changed from `openclaw-honey` to `openclaw-railway`

## 2026-02-13

### Added
- Initial open-source release: README, LICENSE (MIT), .gitignore
- Railway template with Tailscale Serve and GitHub integration
- Multi-stage Dockerfile: OpenClaw compiled from source with Tailscale and CLI tools
- Express wrapper (`server.js`): setup wizard, health checks, gateway proxy, debug console
- OpenTelemetry instrumentation module (`instrumentation.mjs`)
- Container entrypoint (`start.sh`): Tailscale, GitHub creds, hot update, exec server

### Fixed
- Merged Tailscale install into apt layer to bust Docker cache correctly
- Added `CACHEBUST` ARG for forcing fresh Docker builds
