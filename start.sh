#!/bin/bash
set -e

# --- Tailscale Setup ---
if [ -n "$TAILSCALE_AUTHKEY" ]; then
  echo "[tailscale] Starting daemon..."
  tailscaled --tun=userspace-networking --socks5-server=localhost:1055 \
    --state=/data/tailscale/tailscaled.state &
  TAILSCALED_PID=$!

  # Wait for tailscaled to be ready
  for i in $(seq 1 30); do
    if tailscale status >/dev/null 2>&1; then
      break
    fi
    sleep 1
  done

  tailscale up \
    --authkey="$TAILSCALE_AUTHKEY" \
    --hostname="${TAILSCALE_HOSTNAME:-openclaw-railway}" \
    --accept-routes
  echo "[tailscale] Connected to tailnet"

  # Enable Tailscale Serve in the background once the gateway is up
  if [ "$TAILSCALE_SERVE" = "true" ]; then
    (
      echo "[tailscale] Waiting for gateway before enabling serve..."
      for i in $(seq 1 120); do
        if curl -sf http://127.0.0.1:18789/health > /dev/null 2>&1; then
          sleep 2
          tailscale serve --bg --https=443 http://127.0.0.1:18789 2>&1 && \
            echo "[tailscale] Serve enabled on tailnet" || \
            echo "[tailscale] Serve setup failed (check ACLs)"
          break
        fi
        sleep 2
      done
    ) &
  fi
else
  echo "[tailscale] No TAILSCALE_AUTHKEY set, skipping"
fi

# --- GitHub CLI Setup ---
if [ -n "$GITHUB_TOKEN" ]; then
  git config --global credential.helper store
  echo "https://oauth2:${GITHUB_TOKEN}@github.com" > ~/.git-credentials
  echo "[github] Credentials configured"
fi

# --- Start OpenClaw ---
exec node /app/src/server.js
