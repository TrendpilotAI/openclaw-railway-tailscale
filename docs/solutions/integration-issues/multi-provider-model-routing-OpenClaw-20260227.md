---
module: OpenClaw
date: 2026-02-27
problem_type: integration_issue
component: tooling
symptoms:
  - "All models failed (2): deepseek/deepseek-coder: Unknown model (model_not_found)"
  - "openai-codex/gpt-5.3-codex: No API key found for provider openai-codex (auth)"
  - "Agent failed before reply despite multiple API keys set in Railway env vars"
root_cause: config_error
resolution_type: code_fix
severity: critical
tags: [multi-provider, model-routing, api-keys, openrouter, anthropic, cost-optimization, heartbeat-fallback]
---

# Troubleshooting: Multi-Provider Model Routing — API Keys Not Picked Up by OpenClaw

## Problem

OpenClaw agents fail with "All models failed" errors despite having 6+ API keys (`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `DEEPSEEK_API_KEY`, `GROK_API_KEY`, `KIMI_API_KEY`, `OPENROUTER_API_KEY`) set in Railway service variables. The setup wizard only configures one auth provider, leaving all other API keys invisible to OpenClaw's model router.

## Environment

- Module: OpenClaw Railway Template (server.js Express wrapper)
- Platform: Railway (Docker, Node.js)
- Affected Component: Setup wizard post-onboarding cost defaults
- Date: 2026-02-27

## Symptoms

- Discord error: `Agent failed before reply: All models failed (2)`
- First model `deepseek/deepseek-coder` fails with `model_not_found` — invalid model identifier
- Fallback model `openai-codex/gpt-5.3-codex` fails with `auth` — no API key for the `openai-codex` provider
- All other API keys in Railway env vars are ignored
- Heartbeat model hardcoded to `openrouter/openai/gpt-5-nano` regardless of auth provider

## What Didn't Work

**Attempted Solution 1:** Hardcoded `openai-codex/gpt-5.3-codex` as the universal subagent model
- **Why it failed:** Requires ChatGPT OAuth (`openai-codex` provider). Users who authenticate via OpenRouter, Anthropic, or Google don't have this provider configured.

**Attempted Solution 2:** Hardcoded `openrouter/openai/gpt-5-nano` as the universal heartbeat model
- **Why it failed:** Requires an OpenRouter API key. Users who authenticate directly with Anthropic or OpenAI don't have OpenRouter access. Also, `gpt-5-nano` was a placeholder model ID.

## Solution

Three-part fix in `src/server.js`:

### 1. Provider Auto-Registration (`PROVIDER_REGISTRY` + `registerDetectedProviders()`)

A declarative registry maps every supported env var to its OpenClaw provider config. After onboarding, the system scans the environment and registers all detected providers using `models.mode: merge`.

```javascript
// Before (broken): only one provider configured during onboard
// After (fixed): auto-detect and register ALL available API keys
const PROVIDER_REGISTRY = {
  ANTHROPIC_API_KEY: {
    providerId: "anthropic",
    apiKeyRef: "${ANTHROPIC_API_KEY}",
    models: [
      { id: "claude-opus-4-6", name: "Claude Opus 4.6" },
      { id: "claude-sonnet-4-6", name: "Claude Sonnet 4.6" },
      { id: "claude-haiku-4-5", name: "Claude Haiku 4.5" },
    ],
  },
  OPENAI_API_KEY: { /* ... */ },
  DEEPSEEK_API_KEY: { /* ... */ },
  GROK_API_KEY: { /* ... */ },
  KIMI_API_KEY: { /* ... */ },
};
```

### 2. Provider-Aware Model Selection

Three helper functions pick models compatible with the user's auth:

- `pickPrimaryModel(authChoice)` — orchestration brain (MiniMax M2.5 for OpenRouter)
- `pickSubagentModel(authChoice, registeredProviders)` — coding muscle (prefers Anthropic direct when detected)
- `pickHeartbeatModels(authChoice)` — returns array with fallback chain (4 free models for OpenRouter)

### 3. Heartbeat Fallback Chain

```javascript
// Before: single hardcoded model, no fallback
model: "openrouter/openai/gpt-5-nano"

// After: 4-model fallback chain, all free-tier
[
  "openrouter/nvidia/nemotron-3-nano-30b-a3b:free",   // primary
  "openrouter/stepfun/step-3.5-flash:free",            // fallback 1
  "openrouter/upstage/solar-pro-3:free",               // fallback 2
  "openrouter/arcee-ai/trinity-mini:free",             // fallback 3
]
```

## Why This Works

1. **Root cause: OpenClaw's `onboard` command only configures ONE provider.** Env vars like `ANTHROPIC_API_KEY` are passed through to the OpenClaw process (via `...process.env` in the spawn options), but OpenClaw doesn't auto-discover them — each provider must be explicitly registered in the config's `models.providers.*` section.

2. **The `${VAR}` syntax in `apiKeyRef`** means secrets are resolved at runtime by OpenClaw, never baked into the JSON config file on disk.

3. **`models.mode: merge`** ensures each provider registration adds to the existing config rather than replacing the primary provider that `onboard` already set up.

4. **Anthropic direct routing for coding** bypasses OpenRouter when `ANTHROPIC_API_KEY` is detected, giving access to prompt caching (90% input cost reduction), batch API (50% off), and Max subscription rate limits.

5. **Heartbeat fallback chain** ensures background health checks never fail due to a single free model going offline. All four models are free-tier on OpenRouter from different providers (NVIDIA, StepFun, Upstage, Arcee).

## Prevention

- **Never hardcode provider-specific model IDs in cost defaults.** Always select models based on the user's configured auth provider.
- **Use the `PROVIDER_REGISTRY` pattern** when adding support for new providers — add the env var mapping and it will be auto-detected.
- **Always provide fallbacks** for models used in background/automated tasks (heartbeats, cron). Free models can go offline without notice.
- **Test the setup wizard with each auth provider** to verify model routing works end-to-end.

### Critical Pattern: Provider-Model Compatibility

```javascript
// WRONG — assumes a specific provider is configured
model: "openai-codex/gpt-5.3-codex"  // fails if user auth'd with Anthropic

// CORRECT — select based on what's actually available
const model = pickSubagentModel(authChoice, registeredProviders);
```

## Related Issues

- See also: [gateway-crash-loop-empty-config-OpenClaw-20260226.md](../runtime-errors/gateway-crash-loop-empty-config-OpenClaw-20260226.md)
- See also: [openclaw-railway-critical-patterns.md](../patterns/openclaw-railway-critical-patterns.md) (Pattern 5: Apply Bulk Config Changes in Small Groups)
