#!/bin/bash
set -e

# Ensure directories exist (volume may be empty on first deploy)
mkdir -p /data/.clawdbot /data/clawd

# Check if first-time setup is needed
if [ ! -f /data/.clawdbot/clawdbot.json ]; then
    echo "First-time setup: initializing Clawdbot..."

    # Run non-interactive setup with workspace pointing to persistent volume
    clawdbot agents setup --workspace /data/clawd --non-interactive || true
fi

# Start the gateway
exec clawdbot gateway --port 18789 --bind 0.0.0.0
