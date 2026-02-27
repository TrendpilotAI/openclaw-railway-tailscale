---
module: OpenClaw Gateway
date: 2026-02-26
problem_type: runtime_error
component: service_object
symptoms:
  - "Gateway hangs on startup — never becomes reachable on :18789"
  - "/healthz reports gateway.reachable: false indefinitely"
  - "No crash, no error — just silent hang"
  - "Setting gateway.tls.autoGenerate: true causes the hang"
root_cause: config_error
resolution_type: config_change
severity: high
tags: [openclaw, gateway, tls, railway, proxy, hang, startup]
---

# Troubleshooting: gateway.tls.autoGenerate Blocks Startup Behind Railway Proxy

## Problem
Setting `gateway.tls.autoGenerate: true` in the OpenClaw config causes the gateway to hang indefinitely on startup when running behind Railway's edge TLS proxy. The gateway never becomes reachable on `:18789` and there are no errors — just a silent hang.

## Environment
- Module: OpenClaw Gateway
- Platform: Railway (Docker, behind Railway's edge TLS termination)
- Affected Component: OpenClaw gateway TLS configuration
- Date: 2026-02-26

## Symptoms
- Gateway process starts but never binds to `:18789`
- `/healthz` shows `gateway.reachable: false` with no `lastError`
- No crash, no exit code — the process just hangs
- Other config changes work fine; removing `gateway.tls` fixes the hang
- Identified through systematic config bisection (removing groups of settings until the hang stopped)

## What Didn't Work

**Attempted Solution 1:** Waiting longer for gateway startup
- **Why it failed:** The gateway is genuinely stuck, not just slow. It hangs indefinitely attempting TLS certificate generation.

**Attempted Solution 2:** Increasing readiness timeout
- **Why it failed:** Same root cause — the TLS auto-generation never completes behind the proxy.

**Attempted Solution 3:** Systematic config bisection
- **Why it worked:** Removed all new config changes, then re-added in groups. Identified `gateway.tls` as the sole blocking setting.

## Solution

Remove `gateway.tls` entirely from the config when running behind Railway (or any edge proxy that handles TLS):

```bash
# Via SSH on Railway:
node -e 'var fs=require("fs");var c=JSON.parse(fs.readFileSync("/data/.openclaw/openclaw.json","utf8"));delete c.gateway.tls;fs.writeFileSync("/data/.openclaw/openclaw.json",JSON.stringify(c,null,2))'
```

**Do NOT set any of these when behind a TLS-terminating proxy:**
```json
{
  "gateway": {
    "tls": {
      "autoGenerate": true
    }
  }
}
```

## Why This Works

1. **Root cause:** `gateway.tls.autoGenerate: true` tells the OpenClaw gateway to generate its own TLS certificates and bind HTTPS directly. Behind Railway's edge proxy, the gateway receives plain HTTP traffic (Railway terminates TLS at the edge and forwards HTTP internally). The TLS auto-generation process blocks startup because it can't properly bind or verify certificates in this environment.

2. **Railway's architecture:** Railway handles TLS at the edge. Internal services communicate via HTTP. The flow is: `Client → HTTPS → Railway Edge → HTTP → Container :8080 → HTTP → Gateway :18789`. Adding TLS at the gateway level creates a conflict — the gateway expects HTTPS clients, but Railway sends HTTP.

3. **Removing TLS** lets the gateway bind plain HTTP on `:18789`, which is correct for a proxy-terminated environment.

## Prevention

- **Never enable `gateway.tls.autoGenerate` on Railway** (or Render, Fly.io, Heroku, or any platform with edge TLS termination)
- TLS auto-generation is only appropriate for bare-metal or VM deployments where the gateway is directly exposed to the internet
- When applying bulk config changes, add them in small groups and verify the gateway comes back after each group — this makes it easy to identify which setting caused a problem
- Document which config keys are "safe behind proxy" vs "bare-metal only" in the template README

## Related Issues
- See also: [gateway-crash-loop-empty-config-OpenClaw-20260226.md](./gateway-crash-loop-empty-config-OpenClaw-20260226.md)
