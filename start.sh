#!/bin/bash
set -e

# Ensure directories exist (volume may be empty on first deploy)
mkdir -p /data/.clawdbot /data/clawd

# Copy default config if not present
if [ ! -f /data/.clawdbot/clawdbot.json ]; then
    echo "First-time setup: copying default config..."
    cp /root/clawdbot.json /data/.clawdbot/clawdbot.json
fi

# Start the gateway daemon
exec clawdbot gateway-daemon --bind lan --port 18789
