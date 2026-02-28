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

---

## Pattern 6: Never Hardcode Provider-Specific Models in Defaults

**Common symptom:** "All models failed" / "No API key found for provider" despite having API keys set
**Root cause:** Onboard only configures ONE provider. Hardcoded model IDs like `openai-codex/gpt-5.3-codex` fail when the user authenticated with a different provider. Other API keys in env vars are not auto-discovered.
**Solution pattern:** Always select models based on the user's auth choice and detected providers. Register all available API keys as providers using `models.mode: merge`.

```javascript
// WRONG: Assumes a specific provider is configured
subagents: { model: "openai-codex/gpt-5.3-codex" }

// CORRECT: Select based on what's actually available
const subagentModel = pickSubagentModel(authChoice, registeredProviders);
subagents: { ...(subagentModel ? { model: subagentModel } : {}) }
```

**Examples:**
- [multi-provider-model-routing-OpenClaw-20260227.md](../integration-issues/multi-provider-model-routing-OpenClaw-20260227.md)

---

## Pattern 7: Always Provide Fallbacks for Background/Automated Models

**Common symptom:** Heartbeats or cron jobs silently stop working
**Root cause:** Free-tier models on OpenRouter can go offline without notice
**Solution pattern:** Use an array of fallback models for any automated task. Order by reliability (major providers first).

```javascript
// WRONG: Single model, no fallback
heartbeat: { model: "openrouter/openai/gpt-5-nano" }

// CORRECT: Fallback chain
heartbeat: {
  model: "openrouter/nvidia/nemotron-3-nano-30b-a3b:free",
  fallbacks: [
    "openrouter/stepfun/step-3.5-flash:free",
    "openrouter/upstage/solar-pro-3:free",
    "openrouter/arcee-ai/trinity-mini:free",
  ]
}
```

**Examples:**
- [multi-provider-model-routing-OpenClaw-20260227.md](../integration-issues/multi-provider-model-routing-OpenClaw-20260227.md)
