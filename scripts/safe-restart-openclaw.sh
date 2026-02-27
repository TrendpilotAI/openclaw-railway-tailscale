#!/usr/bin/env bash
set -euo pipefail

SERVICE="openclaw-railway-template"
EXPECTED_PROJECT="OpenClaw AI + n8n + Tailscale"
EXPECTED_ENVIRONMENT="production"
CONFIRM=0

usage() {
  cat <<'EOF'
Safe restart helper for OpenClaw Railway service.

Usage:
  scripts/safe-restart-openclaw.sh [options]

Options:
  --service <name>        Railway service name (default: openclaw-railway-template)
  --project <name>        Expected Railway project name
  --environment <name>    Expected Railway environment name (default: production)
  --yes                   Execute restart after safety checks
  -h, --help              Show this help

Behavior:
  - Verifies Railway CLI is installed and authenticated
  - Verifies linked project + environment match expected values
  - Restarts only the targeted service via: railway restart -s <service> -y
  - Never performs project-wide restart or destructive actions
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --service)
      SERVICE="${2:-}"
      shift 2
      ;;
    --project)
      EXPECTED_PROJECT="${2:-}"
      shift 2
      ;;
    --environment)
      EXPECTED_ENVIRONMENT="${2:-}"
      shift 2
      ;;
    --yes)
      CONFIRM=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if ! command -v railway >/dev/null 2>&1; then
  echo "railway CLI not found. Install it first: npm i -g @railway/cli" >&2
  exit 1
fi

if ! railway whoami >/dev/null 2>&1; then
  echo "Railway CLI is not authenticated. Run: railway login" >&2
  exit 1
fi

STATUS="$(railway status 2>/dev/null || true)"
PROJECT="$(printf '%s\n' "$STATUS" | sed -n 's/^Project: //p' | head -n1)"
ENVIRONMENT="$(printf '%s\n' "$STATUS" | sed -n 's/^Environment: //p' | head -n1)"
LINKED_SERVICE="$(printf '%s\n' "$STATUS" | sed -n 's/^Service: //p' | head -n1)"

if [[ -z "$PROJECT" || -z "$ENVIRONMENT" ]]; then
  echo "Could not parse Railway status. Run 'railway status' and verify link/context." >&2
  exit 1
fi

if [[ "$PROJECT" != "$EXPECTED_PROJECT" ]]; then
  echo "Project mismatch." >&2
  echo "Expected: $EXPECTED_PROJECT" >&2
  echo "Actual:   $PROJECT" >&2
  exit 1
fi

if [[ "$ENVIRONMENT" != "$EXPECTED_ENVIRONMENT" ]]; then
  echo "Environment mismatch." >&2
  echo "Expected: $EXPECTED_ENVIRONMENT" >&2
  echo "Actual:   $ENVIRONMENT" >&2
  exit 1
fi

echo "Safety checks passed."
echo "Project:           $PROJECT"
echo "Environment:       $ENVIRONMENT"
echo "Linked service:    ${LINKED_SERVICE:-"(none)"}"
echo "Target service:    $SERVICE"
echo "Restart command:   railway restart -s $SERVICE -y"
echo "Blast radius:      only service '$SERVICE'"

if [[ "$CONFIRM" -ne 1 ]]; then
  echo
  echo "Dry-run only. Re-run with --yes to execute."
  exit 0
fi

railway restart -s "$SERVICE" -y
echo "Restart requested for service '$SERVICE'."
