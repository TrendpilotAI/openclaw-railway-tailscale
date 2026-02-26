# fix: Make OpenClaw Gateway Super Robust and Reliable

## Overview

The OpenClaw gateway on Railway keeps crash-looping. The root cause is a cascading failure pattern: OpenClaw's strict config schema validator rejects any unrecognized key (e.g. `channels.discord.allowedChannels`, `commands.ownerDisplay`, `channels.slack.streaming`) and exits with code 1. The wrapper's auto-restart has no backoff, creating an infinite 5-second crash loop that fills logs and blocks all functionality.

This plan addresses 10 distinct failure modes across 4 phases, ordered by blast radius and ROI.

## Problem Statement

**Immediate**: The gateway is actively crash-looping right now due to `channels.discord.allowedChannels` being an unrecognized config key. This is the 5th time a stale config key has caused a crash loop in the last week.

**Systemic**: The wrapper (`src/server.js`) has several architectural gaps that make it fragile:

1. Config cleanup only removes `gateway.bind` -- all other stale keys crash the gateway
2. Fixed 5s restart delay with no backoff or retry limit
3. No safe mode -- crashes repeat forever
4. Node.js runs as PID 1 without tini (zombie processes, missed signals)
5. SIGTERM handler doesn't drain connections or wait for child
6. Health check always returns 200 even during crash loops (lies to Railway)
7. Hot update bug: `OPENCLAW_ENTRY` const captured at module load, never updated
8. No config backup/recovery mechanism
9. Dockerfile pins v2026.2.19 but latest stable is v2026.2.25
10. `runCmd()` has no timeout -- hung CLI commands block Express forever

## Proposed Solution

### Phase 1: Stop the Crash Loop (Critical, Do First)

**Goal**: Gateway stops crash-looping within minutes of any config schema change.

#### 1a. Expand `cleanupStaleConfigKeys()` to run `openclaw doctor --fix`

**File**: `src/server.js:185-215`

Before starting the gateway, run `openclaw doctor --fix` with a 30s timeout. This is OpenClaw's built-in tool for removing unrecognized config keys. If it fails (because the config is too broken), fall back to deleting the config and entering setup mode.

```javascript
async function cleanupStaleConfigKeys() {
  try {
    const p = configPath();
    if (!fs.existsSync(p)) return;
    const raw = fs.readFileSync(p, "utf8");
    if (!raw.trim()) {
      console.warn("[wrapper] config file is empty; removing to allow re-setup");
      fs.unlinkSync(p);
      return;
    }
    try {
      JSON.parse(raw);
    } catch (parseErr) {
      console.warn(`[wrapper] config file is corrupt; removing: ${parseErr.message}`);
      fs.unlinkSync(p);
      return;
    }

    // Run openclaw doctor --fix to remove any unrecognized keys
    console.log("[wrapper] running openclaw doctor --fix to clean config...");
    const result = await runCmdWithTimeout(
      OPENCLAW_NODE, clawArgs(["doctor", "--fix"]), 30_000
    );
    if (result.code === 0) {
      console.log("[wrapper] doctor --fix completed successfully");
    } else {
      console.warn(`[wrapper] doctor --fix exited ${result.code}: ${result.output}`);
    }
  } catch (err) {
    console.warn(`[wrapper] config cleanup failed (non-fatal): ${String(err)}`);
  }
}
```

**Decision**: Run `doctor --fix` at boot AND before each auto-restart attempt. If it removes user-set keys that are valid in a newer version but not the running version, that's acceptable -- the alternative is an infinite crash loop.

#### 1b. Add exponential backoff with crash counting

**File**: `src/server.js:287-306` (replace gateway exit handler)

```javascript
// Crash recovery state
let crashCount = 0;
let lastCrashTime = 0;
const CRASH_RESET_WINDOW = 5 * 60 * 1000; // 5min stability resets counter
const BASE_DELAY = 2000;
const MAX_DELAY = 60_000;
const MAX_CRASHES = 10;

function calculateRestartDelay() {
  const now = Date.now();
  if (now - lastCrashTime > CRASH_RESET_WINDOW) {
    crashCount = 0;
  }
  crashCount++;
  lastCrashTime = now;

  if (crashCount > MAX_CRASHES) return null; // safe mode

  const delay = Math.min(BASE_DELAY * Math.pow(2, crashCount - 1), MAX_DELAY);
  const jitter = Math.random() * 1000;
  return Math.round(delay + jitter);
}
```

Restart delays: 2s, 4s, 8s, 16s, 32s, 60s, 60s, 60s, 60s, 60s, then safe mode.

#### 1c. Add safe mode

After 10 crashes, stop restarting the gateway. Keep the Express wrapper alive so:
- Railway health check still passes (returns 200)
- `/setup` UI is accessible for diagnosis
- Debug console works for manual restart
- `/healthz` includes `{ safeMode: true, crashCount: N }` for monitoring

**Decision**: Crash counter is in-memory only. Container restart resets it, giving a fresh set of 10 attempts. This prevents permanent lockout from transient issues.

User exits safe mode by:
- Manually restarting via `/setup` debug console (resets crash counter)
- Saving a fixed config via config editor (auto-restarts gateway, resets counter)
- Redeploying the service on Railway

---

### Phase 2: Infrastructure Hardening

**Goal**: Proper process management, signal handling, and honest health reporting.

#### 2a. Add tini as init process

**File**: `Dockerfile:31-32` (runtime stage)

```dockerfile
RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    tini ca-certificates curl ... \
  && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/app/start.sh"]
```

Benefits:
- Proper signal forwarding to all child processes (tailscaled, node)
- Zombie process reaping (critical for the many `runCmd` spawns)
- No code changes needed in server.js or start.sh

`start.sh` keeps `exec node ...` -- this is fine because tini is already the parent.

#### 2b. Implement graceful shutdown

**File**: `src/server.js:1565-1578` (replace SIGTERM handler)

```javascript
let shuttingDown = false;

async function gracefulShutdown(signal) {
  if (shuttingDown) return;
  shuttingDown = true;
  console.log(`[wrapper] received ${signal}, shutting down...`);

  // 1. Stop accepting new connections
  const serverClosePromise = new Promise((resolve) => {
    server.close(resolve);
    if (server.closeIdleConnections) server.closeIdleConnections();
  });

  // 2. Stop gateway child
  if (gatewayProc) {
    gatewayProc.kill("SIGTERM");
    await Promise.race([
      new Promise((resolve) => gatewayProc?.on("exit", resolve)),
      sleep(5000),
    ]);
    if (gatewayProc) gatewayProc.kill("SIGKILL");
  }

  // 3. Flush analytics
  try { if (posthog) await posthog.shutdown(); } catch {}

  // 4. Drain HTTP (max 3s)
  await Promise.race([serverClosePromise, sleep(3000)]);

  console.log("[wrapper] shutdown complete");
  process.exit(0);
}

process.on("SIGTERM", () => gracefulShutdown("SIGTERM"));
process.on("SIGINT", () => gracefulShutdown("SIGINT"));
```

Total shutdown budget: ~8s (Railway gives ~10s grace).

#### 2c. Fix health check honesty

**File**: `src/server.js:398-429`

Railway only supports one `healthcheckPath`. Keep `/setup/healthz` returning 200 always (Railway needs this for deployment success). Add status fields:

```javascript
app.get("/setup/healthz", (_req, res) => {
  res.json({
    ok: true,
    gateway: {
      configured: isConfigured(),
      running: Boolean(gatewayProc),
      safeMode: crashCount > MAX_CRASHES,
      crashCount,
    },
  });
});
```

**Decision**: Health check always returns 200. Reasoning: If it returns 503 during safe mode, Railway kills the container, defeating safe mode. Monitoring systems can key on the `safeMode` field.

#### 2d. Fix hot update bug

**File**: `src/server.js:103,132-134`

Change `clawArgs()` to read `process.env.OPENCLAW_ENTRY` at call time:

```javascript
// Before (line 103):
const OPENCLAW_ENTRY = process.env.OPENCLAW_ENTRY?.trim() || "/openclaw/dist/entry.js";

// After:
function getOpenClawEntry() {
  return process.env.OPENCLAW_ENTRY?.trim() || "/openclaw/dist/entry.js";
}

// Before (line 132-134):
function clawArgs(args) {
  return [OPENCLAW_ENTRY, ...args];
}

// After:
function clawArgs(args) {
  return [getOpenClawEntry(), ...args];
}
```

Also update the `OPENCLAW_NODE` pattern for consistency.

#### 2e. Add timeout to `runCmd()`

**File**: `src/server.js:735-757`

Add an `AbortController`-based timeout:

```javascript
function runCmd(cmd, args, opts = {}) {
  const timeoutMs = opts.timeout ?? 30_000;
  return new Promise((resolve) => {
    const ac = new AbortController();
    const timer = setTimeout(() => ac.abort(), timeoutMs);

    const proc = childProcess.spawn(cmd, args, {
      ...opts,
      signal: ac.signal,
      env: { ...process.env, OPENCLAW_STATE_DIR: STATE_DIR, OPENCLAW_WORKSPACE_DIR: WORKSPACE_DIR },
    });

    let out = "";
    proc.stdout?.on("data", (d) => (out += d.toString("utf8")));
    proc.stderr?.on("data", (d) => (out += d.toString("utf8")));
    proc.on("error", (err) => {
      clearTimeout(timer);
      out += `\n[spawn error] ${String(err)}\n`;
      resolve({ code: 127, output: out });
    });
    proc.on("close", (code) => {
      clearTimeout(timer);
      resolve({ code: code ?? 0, output: out });
    });
  });
}
```

Default 30s for diagnostic commands. `openclaw.update` gets 600s via `{ timeout: 600_000 }`.

---

### Phase 3: Config Resilience

**Goal**: Never lose a working config. Auto-recover from corruption.

#### 3a. Auto-backup config before gateway start

**File**: `src/server.js` (new function, called in `ensureGatewayRunning`)

```javascript
function backupConfigIfExists() {
  try {
    const p = configPath();
    if (!fs.existsSync(p)) return;
    const raw = fs.readFileSync(p, "utf8").trim();
    if (!raw) return;

    // Only backup valid JSON
    try { JSON.parse(raw); } catch { return; }

    const backupPath = `${p}.auto-bak-${Date.now()}`;
    fs.copyFileSync(p, backupPath);

    // Prune: keep last 5 auto-backups
    const dir = path.dirname(p);
    const base = path.basename(p);
    const backups = fs.readdirSync(dir)
      .filter((f) => f.startsWith(`${base}.auto-bak-`))
      .sort()
      .reverse();
    for (const old of backups.slice(5)) {
      try { fs.unlinkSync(path.join(dir, old)); } catch {}
    }
  } catch (err) {
    console.warn(`[wrapper] config backup failed: ${String(err)}`);
  }
}
```

Called at the start of `ensureGatewayRunning()`, before `startGateway()`.

#### 3b. Recover from last-known-good backup after 3 crashes

In the crash recovery logic (Phase 1b), after 3 consecutive crashes:

```javascript
if (crashCount >= 3) {
  console.warn("[wrapper] 3+ crashes, attempting config recovery from backup");
  recoverFromBackup();
}
```

```javascript
function recoverFromBackup() {
  const p = configPath();
  const dir = path.dirname(p);
  const base = path.basename(p);
  const backups = fs.readdirSync(dir)
    .filter((f) => f.startsWith(`${base}.auto-bak-`) || f.startsWith(`${base}.bak-`))
    .sort()
    .reverse();

  for (const backup of backups) {
    try {
      const raw = fs.readFileSync(path.join(dir, backup), "utf8");
      JSON.parse(raw); // validate
      fs.copyFileSync(path.join(dir, backup), p);
      console.log(`[wrapper] recovered config from backup: ${backup}`);
      return true;
    } catch { continue; }
  }
  console.error("[wrapper] no valid backup found for recovery");
  return false;
}
```

After recovery, `doctor --fix` runs on the restored config before starting the gateway.

#### 3c. Make config writes atomic

**File**: `src/server.js:1249` and `cleanupStaleConfigKeys`

Replace `fs.writeFileSync(p, content)` with write-to-temp-then-rename:

```javascript
function atomicWriteFile(filePath, content) {
  const tmpPath = `${filePath}.tmp-${process.pid}`;
  fs.writeFileSync(tmpPath, content, { encoding: "utf8", mode: 0o600 });
  fs.renameSync(tmpPath, filePath); // atomic on POSIX
}
```

---

### Phase 4: Version Management

**Goal**: Run latest stable, prevent version/config mismatches.

#### 4a. Update Dockerfile pin to v2026.2.25

**File**: `Dockerfile:16`

```dockerfile
# Before:
ARG OPENCLAW_GIT_REF=v2026.2.19

# After:
ARG OPENCLAW_GIT_REF=v2026.2.25
```

v2026.2.25 is the current latest stable. It includes security hardening and the config schema that matches what the running instance's config was written with.

#### 4b. Switch update channel preference

The runtime config at `/data/.openclaw/openclaw.json` has `"update": { "channel": "beta" }`. Change to `"stable"`:

```json
{
  "update": {
    "channel": "stable",
    "checkOnStart": true
  }
}
```

This is a runtime config change, not a code change. Apply via `railway ssh` or the config editor.

#### 4c. Add version info to startup logs

```javascript
// In server.listen callback, after startup info:
const versionResult = await runCmd(OPENCLAW_NODE, clawArgs(["--version"]), { timeout: 10_000 });
console.log(`[wrapper] openclaw version: ${versionResult.output.trim()}`);
console.log(`[wrapper] entry point: ${getOpenClawEntry()}`);
```

This helps diagnose version mismatch issues from logs.

---

## Acceptance Criteria

### Functional Requirements

- [ ] Gateway survives any unknown config key without crash-looping (`cleanupStaleConfigKeys` runs `doctor --fix`)
- [ ] Auto-restart uses exponential backoff: 2s, 4s, 8s, 16s, 32s, 60s (capped)
- [ ] After 10 consecutive crashes, gateway enters safe mode (no more auto-restarts)
- [ ] Safe mode is visible in `/setup/healthz` JSON response
- [ ] Manual restart from `/setup` debug console resets crash counter and exits safe mode
- [ ] Config editor save resets crash counter and exits safe mode
- [ ] `SIGTERM` gracefully shuts down: stops accepting connections, waits for gateway child (up to 5s), flushes analytics
- [ ] Hot update via debug console immediately uses the new entry point without container restart
- [ ] Config backup created before every gateway start (max 5 auto-backups retained)
- [ ] After 3 crashes, config recovery from last-known-good backup is attempted
- [ ] `runCmd()` has 30s default timeout (600s for `openclaw.update`)
- [ ] Config writes use atomic write (write-to-temp, rename)
- [ ] Dockerfile pins v2026.2.25

### Non-Functional Requirements

- [ ] No zombie processes accumulate (tini handles reaping)
- [ ] Railway health check never returns non-200 (prevents Railway-level crash loops)
- [ ] Crash loop generates at most ~10 log entries before safe mode (not infinite)
- [ ] Graceful shutdown completes within 8s (Railway's ~10s grace period)

---

## Risk Analysis

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| `doctor --fix` removes valid user config | Medium | High | Log what was removed; config is backed up first |
| Safe mode entered on transient issue | Low | Medium | In-memory counter resets on container restart |
| tini breaks existing behavior | Low | Low | tini is a well-tested init; transparent to app |
| Atomic write leaves `.tmp` file on crash | Low | Low | `.tmp` files are harmless, cleaned on next write |
| v2026.2.25 introduces new breaking changes | Low | Medium | `doctor --fix` now runs automatically |

## Dependencies

- `tini` package available in Debian bookworm (it is -- `apt-get install -y tini`)
- `openclaw doctor --fix` CLI command exists (confirmed in OpenClaw v2026.2.19+)
- Railway supports `ENTRYPOINT` in Dockerfile (confirmed)

## Implementation Order

1. **Phase 1a+1b+1c** (stop crash loop) -- highest ROI, ~100 lines changed in `src/server.js`
2. **Phase 2d** (fix hot update bug) -- 5 lines changed, high value
3. **Phase 2e** (runCmd timeout) -- 15 lines changed, prevents hung handlers
4. **Phase 2a** (tini) -- 3 lines changed in Dockerfile
5. **Phase 2b** (graceful shutdown) -- 30 lines replacing existing handler
6. **Phase 2c** (health check) -- 10 lines
7. **Phase 3a+3b** (config backup/recovery) -- 60 lines
8. **Phase 3c** (atomic writes) -- 10 lines
9. **Phase 4a+4b+4c** (version update) -- Dockerfile + runtime config

## Files Changed

| File | Changes |
|------|---------|
| `src/server.js` | Phases 1-3: crash recovery, backoff, safe mode, shutdown, health, hot update fix, runCmd timeout, config backup, atomic writes |
| `Dockerfile` | Phase 2a: add tini, Phase 4a: pin v2026.2.25 |
| `railway.toml` | No changes needed (health check path stays `/setup/healthz`) |
| `start.sh` | No changes needed (`exec node` works correctly with tini as ENTRYPOINT) |

## Test Plan

- [ ] Manually add an unknown config key, verify `doctor --fix` removes it and gateway starts
- [ ] Kill gateway process repeatedly, verify exponential backoff in logs (2s, 4s, 8s...)
- [ ] Kill gateway 11 times rapidly, verify safe mode activates and auto-restart stops
- [ ] Check `/setup/healthz` returns `{ safeMode: true }` when in safe mode
- [ ] Use debug console "gateway.restart" to exit safe mode
- [ ] Run `openclaw.update --stable` from debug console, verify new version is used immediately
- [ ] Deploy to Railway, verify tini is PID 1 (`cat /proc/1/cmdline`)
- [ ] Trigger Railway redeploy, check logs for "shutdown complete" (graceful shutdown)
- [ ] Corrupt config file, restart, verify recovery from backup
- [ ] Run `openclaw --version` and confirm v2026.2.25

## References

### Internal
- `src/server.js:185-215` -- current `cleanupStaleConfigKeys()`
- `src/server.js:287-306` -- current crash restart handler (fixed 5s delay)
- `src/server.js:103` -- `OPENCLAW_ENTRY` const capture bug
- `src/server.js:1565-1578` -- current SIGTERM handler
- `src/server.js:735-757` -- `runCmd()` without timeout
- `Dockerfile:16` -- `OPENCLAW_GIT_REF=v2026.2.19` pin

### External
- [OpenClaw Issue #8641: Docker gateway.bind restart loop](https://github.com/openclaw/openclaw/issues/8641)
- [OpenClaw Issue #5435: Config validation unrecognized keys](https://github.com/openclaw/openclaw/issues/5435)
- [Railway Health Checks](https://docs.railway.com/reference/healthchecks)
- [Railway Restart Policy](https://docs.railway.com/deployments/restart-policy)
- [tini - A tiny init for containers](https://github.com/krallin/tini)
- [Node.js Best Practices: Graceful Shutdown](https://github.com/goldbergyoni/nodebestpractices/blob/master/sections/docker/graceful-shutdown.md)
