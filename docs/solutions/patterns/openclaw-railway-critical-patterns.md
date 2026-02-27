# OpenClaw Railway — Critical Patterns

Patterns learned from production incidents. Review before making config changes.

---

## Pattern 1: Config Validation Must Check Content, Not Just Existence

**Common symptom:** Gateway crash loop with "JSON5 parse failed at 1:1"
**Root cause:** `fs.existsSync()` returns true for 0-byte files
**Solution pattern:** Always read + parse config files; treat empty/corrupt as "not configured"

```javascript
// WRONG: File exists but may be empty/corrupt
if (fs.existsSync(configPath)) { /* assume configured */ }

// CORRECT: Validate content is parseable
const raw = fs.readFileSync(configPath, "utf8").trim();
if (raw && JSON.parse(raw)) { /* actually configured */ }
```

**Examples:**
- [gateway-crash-loop-empty-config-OpenClaw-20260226.md](../runtime-errors/gateway-crash-loop-empty-config-OpenClaw-20260226.md)

---

## Pattern 2: Never Enable gateway.tls Behind a TLS-Terminating Proxy

**Common symptom:** Gateway hangs silently on startup — no crash, no error
**Root cause:** TLS auto-generation conflicts with Railway/Render/Fly edge TLS
**Solution pattern:** Remove `gateway.tls` entirely; let the platform handle TLS

```json
// WRONG (behind Railway/Render/Fly):
{ "gateway": { "tls": { "autoGenerate": true } } }

// CORRECT (behind any edge proxy):
{ "gateway": { /* no tls key at all */ } }
```

**Examples:**
- [gateway-tls-blocks-behind-proxy-OpenClaw-20260226.md](../runtime-errors/gateway-tls-blocks-behind-proxy-OpenClaw-20260226.md)

---

## Pattern 3: gateway.mode Must Be "local" on the Server

**Common symptom:** Gateway crashes immediately after config change
**Root cause:** Setting `gateway.mode: "remote"` on the actual gateway server makes it try to connect to itself as a remote
**Solution pattern:** The server running the gateway MUST use `gateway.mode: "local"`. Only CLI clients use "remote".

---

## Pattern 4: maxHistoryShare Minimum is 0.1

**Common symptom:** Gateway rejects config with validation error
**Root cause:** Schema enforces minimum 0.1 for `maxHistoryShare`
**Solution pattern:** Use 0.1 (not 0) to minimize history share; 0 is invalid.

---

## Pattern 5: Apply Bulk Config Changes in Small Groups

**Common symptom:** Gateway won't start after applying many config changes at once
**Root cause:** One bad setting in a batch is hard to identify
**Solution pattern:** Apply 3-5 settings at a time, verify gateway comes back, then add the next group. Use config bisection if the gateway breaks.
