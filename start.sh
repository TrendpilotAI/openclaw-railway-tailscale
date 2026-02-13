#!/bin/bash
set -e

# Start Tailscale daemon in userspace networking mode (no TUN needed in containers)
tailscaled --tun=userspace-networking --socks5-server=localhost:1055 --state=/data/tailscale/tailscaled.state &
sleep 2

# Authenticate with Tailscale using auth key
if [ -n "$TAILSCALE_AUTHKEY" ]; then
  tailscale up --authkey="$TAILSCALE_AUTHKEY" --hostname="${TAILSCALE_HOSTNAME:-openclaw-honey}"
  echo "[tailscale] Connected to tailnet"

  # Enable Tailscale Serve to proxy the OpenClaw gateway
  if [ "$TAILSCALE_SERVE" = "true" ]; then
    # Wait for the OpenClaw gateway to start (server.js spawns it)
    echo "[tailscale] Waiting for gateway to start before enabling serve..."
    # Serve will be configured after the gateway is up
    (
      # Wait for gateway port to be available
      for i in $(seq 1 60); do
        if curl -sf http://127.0.0.1:18789/health > /dev/null 2>&1; then
          tailscale serve --bg --https=443 http://127.0.0.1:18789 2>/dev/null && \
            echo "[tailscale] Serve enabled: https://$(tailscale status --json | python3 -c 'import json,sys; print(json.load(sys.stdin)["Self"]["DNSName"].rstrip("."))')/" || \
            echo "[tailscale] Serve setup skipped (may need ACL)"
          break
        fi
        sleep 2
      done
    ) &
  fi
else
  echo "[tailscale] No TAILSCALE_AUTHKEY set, skipping Tailscale"
fi

# Start the OpenClaw wrapper server
exec node /app/src/server.js
