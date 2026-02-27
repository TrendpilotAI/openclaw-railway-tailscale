---
module: OpenClaw Gateway
date: 2026-02-26
problem_type: runtime_error
component: service_object
symptoms:
  - "Gateway crash loop - JSON5 parse failed at 1:1"
  - "Config file exists but is 0 bytes"
  - "isConfigured() returns true for empty file, gateway tries to parse it and crashes"
  - "/healthz reports gateway unreachable"
root_cause: config_error
resolution_type: code_fix
severity: critical
tags: [openclaw, gateway, crash-loop, config, zero-byte, validation]
---

# Troubleshooting: Gateway Crash Loop from Empty/Corrupt Config File

## Problem
The OpenClaw gateway entered an infinite crash loop because the config file (`/data/.openclaw/openclaw.json`) existed but was 0 bytes. The `isConfigured()` function only checked `fs.existsSync()`, treating the empty file as a valid config, causing the gateway to attempt JSON parsing and crash repeatedly.

## Environment
- Module: OpenClaw Gateway (Express wrapper + internal gateway on :18789)
- Platform: Railway (Docker, Node 22 Bookworm)
- Affected Component: `src/server.js` - config validation and lifecycle management
- Date: 2026-02-26

## Symptoms
- Gateway crash loop visible in Railway logs: "JSON5 parse failed at 1:1"
- `/healthz` endpoint shows `gateway.reachable: false`
- `lastExit` populated with recent timestamps, gateway keeps restarting
- SSH inspection reveals config file is exactly 0 bytes
- Backup files (`.bak.2`) contain valid config (7,020 bytes)

## What Didn't Work

**Attempted Solution 1:** Simply restarting the Railway service
- **Why it failed:** The corrupt config persists on the volume. Each restart re-reads the same empty file and crashes again.

**Attempted Solution 2:** Deleting the config file via SSH without code fix
- **Why it failed:** Removes immediate crash but doesn't prevent recurrence. Any future config corruption would cause the same crash loop.

## Solution

Two-part fix in `src/server.js`:

**Fix 1: `isConfigured()` now validates JSON parseability (not just existence)**

```javascript
// Before (broken):
function isConfigured() {
  try {
    return resolveConfigCandidates().some((candidate) => {
      return fs.existsSync(candidate);
    });
  } catch { return false; }
}

// After (fixed):
function isConfigured() {
  try {
    return resolveConfigCandidates().some((candidate) => {
      if (!fs.existsSync(candidate)) return false;
      try {
        const raw = fs.readFileSync(candidate, "utf8").trim();
        if (!raw) return false;
        JSON.parse(raw);
        return true;
      } catch { return false; }
    });
  } catch { return false; }
}
```

**Fix 2: `cleanupStaleConfigKeys()` auto-recovers from corrupt configs**

```javascript
function cleanupStaleConfigKeys() {
  try {
    const p = configPath();
    if (!fs.existsSync(p)) return;
    const raw = fs.readFileSync(p, "utf8");

    // Empty file — remove so setup wizard re-triggers
    if (!raw.trim()) {
      console.warn("[wrapper] config file is empty; removing to allow re-setup");
      fs.unlinkSync(p);
      return;
    }

    // Corrupt JSON — remove so setup wizard re-triggers
    let cfg;
    try { cfg = JSON.parse(raw); }
    catch (parseErr) {
      console.warn(`[wrapper] config file is corrupt; removing: ${parseErr.message}`);
      fs.unlinkSync(p);
      return;
    }
    // ... rest of cleanup for valid config
  } catch { /* ignore */ }
}
```

**Recovery step:** Restored config from backup via SSH:
```bash
cp /data/.openclaw/openclaw.json.bak.2 /data/.openclaw/openclaw.json
```

## Why This Works

1. **Root cause:** `fs.existsSync()` returns `true` for any file, regardless of content. A 0-byte file passes the existence check but fails JSON parsing, causing an unhandled crash in the gateway startup.
2. **The fix adds content validation:** Reading the file, checking for non-empty content, and attempting `JSON.parse()` catches all corruption states (empty, truncated, invalid JSON).
3. **Auto-recovery ensures self-healing:** If a corrupt config is detected, the wrapper removes it, allowing the setup wizard to re-trigger on the next request — converting a permanent crash loop into a graceful degradation.

## Prevention

- **Always validate file content, not just existence**, when checking config files that will be parsed
- Config file writes should be atomic (write to temp file, then rename) to prevent partial writes
- Keep automated backups of config files (OpenClaw already creates `.bak` files)
- The `cleanupStaleConfigKeys()` function should run early in the startup sequence, before any code attempts to parse the config
- Monitor for crash loops via `/healthz` endpoint — if `lastExit` has recent timestamps and `reachable: false`, suspect config corruption

## Related Issues
No related issues documented yet.
