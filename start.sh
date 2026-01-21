#!/bin/bash
set -euo pipefail

# Ensure directories exist (volume may be empty on first deploy)
mkdir -p /data/.clawdbot /data/clawd

mise run decrypt-config
mv clawdbot.json /data/.clawdbot/clawdbot.json

# Start the gateway daemon (--allow-unconfigured for non-interactive deployment)
exec clawdbot gateway-daemon --bind lan --port 18789 --allow-unconfigured
