# Roadmap

Current status of the OpenClaw + n8n + Tailscale Railway template.

## In Progress: Railway Template Cleanup

The multi-service template (`cDVYRI`) has been generated from the live project with all 7 services but needs cleanup before publishing to the Railway marketplace.

**Template guidelines score: 2/5**

### Phase 1: Variable Descriptions File

Create `template-vars.json` with canonical variable descriptions for all 7 services. This file serves as both documentation and input for the automation script.

**Problem:** Railway's "Generate from Project" copied all shared/project-level variables to every service. Redis has `KIMI_API_KEY`, Postgres has `ANTHROPIC_API_KEY`, etc. These need to be removed.

| Service | Current Vars | Expected Vars | Leaked Vars to Remove |
|---|---|---|---|
| OpenClaw | 36 | ~20 | ~16 (duplicates of shared vars) |
| Redis | 18 | ~4 | ~14 (LLM keys, Modal tokens, etc.) |
| Postgres | 23 | ~5 | ~18 |
| n8n Primary | 33 | ~15 | ~18 |
| n8n Worker | 31 | ~12 | ~19 |
| Postiz | 22 | ~8 | ~14 |
| Temporal | 17 | ~5 | ~12 |

### Phase 2: Playwright Automation

Railway has no public API for updating template variable descriptions (confirmed via GraphQL schema introspection). Two approaches:

**Option A — Browser automation (reliable):**
Write a script using Playwright MCP to open the Railway template editor and batch-enter descriptions. Slower but guaranteed to work.

**Option B — Internal API interception (faster):**
Use Playwright to intercept the dashboard's XHR when saving, discover the internal mutation, then call it directly via curl. Faster for bulk updates but may break if Railway changes their internal API.

### Phase 3: Template Guidelines Fixes

| Guideline | Status | Action |
|---|---|---|
| Template description | Missing | Add via template editor header |
| Service icons | 4 missing (Template, OpenClaw, Temporal, Postiz) | Upload icons from `assets/` |
| Healthcheck paths | 3 missing (Redis, OpenClaw, Postiz) | Set healthcheck paths in template |
| Variable descriptions | 100+ missing | Phases 1-2 |
| Private networking | Not configured | Mark internal-only services (Postgres, Redis, Temporal, n8n Worker) |

### Phase 4: Publish Template

1. Set template category (AI / Developer Tools)
2. Write template README (shown on Railway marketplace)
3. Publish via dashboard or `templatePublish` GraphQL mutation
4. Verify deploy button works end-to-end

### Phase 5: Delete Old Template

Delete the old single-service template (`W28_9m`) after the new multi-service template is published and verified.

---

## Future: Feature Ideas

### Template Improvements
- [ ] Add Railway cron job service for scheduled OpenClaw tasks
- [ ] Pre-configure n8n workflow templates (imported on first boot)
- [ ] Add Grafana service for self-hosted observability dashboards
- [ ] Add Minio service for self-hosted S3-compatible object storage

### OpenClaw Wrapper Enhancements
- [ ] WebSocket support in gateway proxy for real-time streaming
- [ ] Multi-tenant support (multiple OpenClaw instances behind one Express wrapper)
- [ ] OAuth2 authentication option (in addition to HTTP Basic)
- [ ] Automatic SSL certificate management via Tailscale HTTPS
- [ ] Backup scheduling (automatic daily backups to S3/R2)

### Skills & Integrations
- [ ] n8n workflow import/export from debug console
- [ ] One-click Modal function deployment from OpenClaw
- [ ] Composio OAuth flow integrated into setup wizard
- [ ] GitHub Actions integration for CI/CD from OpenClaw

### Developer Experience
- [ ] `railway.json` support for multi-service template definition (if Railway adds this)
- [ ] Terraform/Pulumi provider for Railway template management
- [ ] E2E test suite using Playwright against a deployed template instance
- [ ] Local development with Docker Compose mirroring the full 7-service stack

---

## Key References

| Resource | URL |
|---|---|
| Live template | `https://railway.com/deploy/cDVYRI` |
| Railway GraphQL API | `https://backboard.railway.com/graphql/v2` |
| Template JSON Schema | `https://backboard.railway.com/schema/template.schema.json` |
| Template config snapshot | `/tmp/railway-template-config.json` (local) |
