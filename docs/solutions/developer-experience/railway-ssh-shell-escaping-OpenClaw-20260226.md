---
module: OpenClaw Gateway
date: 2026-02-26
problem_type: developer_experience
component: tooling
symptoms:
  - "Railway SSH commands with parentheses fail: sh: 1: Syntax error: ( unexpected"
  - "Python -c and node -e one-liners broken through railway ssh"
  - "f-strings, function calls, and subshells mangled by intermediate shell"
root_cause: missing_tooling
resolution_type: workflow_improvement
severity: medium
tags: [railway, ssh, shell-escaping, debugging, workflow]
---

# Troubleshooting: Railway SSH Shell Escaping Breaks Complex Commands

## Problem
When executing commands via `railway ssh --service <id> --environment <id> -- <command>`, any command containing parentheses, curly braces, or complex quoting is mangled by the intermediate shell layer. This makes `python3 -c`, `node -e`, and many common one-liners fail with syntax errors.

## Environment
- Module: Railway CLI / SSH
- Platform: macOS → Railway container (Debian Bookworm)
- Affected Component: `railway ssh` command pipeline
- Date: 2026-02-26

## Symptoms
- `sh: 1: Syntax error: "(" unexpected` for any command with parentheses
- Python f-strings with `{` conflict with shell interpretation
- `node -e` commands with `.forEach()`, `.map()`, etc. fail
- Even `python3 -c 'print("hello")'` sometimes fails depending on quoting
- Piping via stdin (`printf '...' | railway ssh ... -- node`) also fails

## What Didn't Work

**Attempted Solution 1:** Various quoting strategies (single quotes, double quotes, escaping)
- **Why it failed:** The Railway SSH pipeline has multiple shell expansion layers. Quotes that protect against one layer get consumed by another.

**Attempted Solution 2:** Piping script via stdin
- **Why it failed:** `printf 'script' | railway ssh ... -- node` - the stdin pipe doesn't connect through Railway's SSH tunnel properly.

**Attempted Solution 3:** Using `--command` flag
- **Why it failed:** Railway CLI doesn't have a `--command` flag. The syntax is `railway ssh ... -- <command>`.

## Solution

**Use simple commands only through Railway SSH.** For anything complex, use one of these workarounds:

**Approach 1: grep/sed/awk for reading config (preferred for quick inspection)**
```bash
# Works - no parentheses:
railway ssh --service $SVC --environment $ENV -- grep skills /data/.openclaw/openclaw.json
railway ssh --service $SVC --environment $ENV -- cat /data/.openclaw/openclaw.json
railway ssh --service $SVC --environment $ENV -- ls -la /data/workspace/skills/
```

**Approach 2: Write a script file first, then execute it**
```bash
# Write script to container, then run it:
railway ssh --service $SVC --environment $ENV -- sh -c 'cat > /tmp/check.js << INNEREOF
const fs = require("fs");
const cfg = JSON.parse(fs.readFileSync("/data/.openclaw/openclaw.json", "utf8"));
console.log(JSON.stringify(cfg.workspace, null, 2));
INNEREOF'
railway ssh --service $SVC --environment $ENV -- node /tmp/check.js
```

**Approach 3: For config modifications, use node with string concatenation (no template literals)**
```bash
# Avoid: node -e 'console.log(`${var}`)'  — backticks get eaten
# Use:   node -e 'console.log(var)'       — simple expressions only
railway ssh --service $SVC --environment $ENV -- node -e 'var j=require("/data/.openclaw/openclaw.json");console.log(j.workspace)'
```
Note: Even `require()` with parentheses sometimes fails. Test each command.

**Approach 4: For bulk config changes, use the OpenClaw Control UI or API**
The Control UI at the gateway URL provides a JSON editor that avoids SSH escaping entirely.

## Why This Works

1. **Root cause:** `railway ssh` pipes commands through multiple shell layers (local zsh → Railway CLI → container sh). Each layer performs its own expansion. Parentheses, braces, backticks, and dollar signs are all shell metacharacters that get interpreted before reaching the target command.

2. **Simple commands work** because they don't contain metacharacters. `grep`, `cat`, `ls`, `sed` with basic patterns all survive the multi-layer expansion.

3. **The script-file approach** separates "getting the script onto the container" from "executing it", bypassing the escaping problem entirely.

## Prevention

- Default to simple commands (`grep`, `cat`, `ls`, `sed`) when inspecting remote state via Railway SSH
- For complex operations, prefer the Control UI or write a helper script in the repo's `scripts/` directory that gets copied into the container at build time
- Consider adding a `/app/scripts/inspect-config.sh` helper that prints common config values without needing complex one-liners
- When debugging SSH escaping issues, don't spend more than 2 attempts — switch to the script-file approach immediately

## Related Issues
No related issues documented yet.
