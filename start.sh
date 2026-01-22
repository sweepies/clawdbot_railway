#!/bin/bash
set -euo pipefail

# Ensure directories exist (volume may be empty on first deploy)
mkdir -p /data/.clawdbot /data/clawd

# Decrypt config using AGE_KEY environment variable
if [ -z "${AGE_KEY:-}" ]; then
    echo "Error: AGE_KEY environment variable not set"
    exit 1
fi

echo "$AGE_KEY" | age --decrypt --identity - --output clawdbot.json clawdbot.json.enc
mv clawdbot.json /data/.clawdbot/clawdbot.json

# Install mise tools in each directory under /data
for dir in /data/*/; do
    [ -d "$dir" ] || continue
    (cd "$dir" && mise install)
done

# Start the gateway daemon (--allow-unconfigured for non-interactive deployment)
exec clawdbot gateway-daemon --bind lan --port 18789 --allow-unconfigured
