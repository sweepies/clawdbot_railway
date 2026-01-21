#!/bin/bash
set -e

# Self-deploy script: copies config, encrypts, commits and pushes
# Usage: ./deploy-config.sh [commit message]
# Expects: Current working directory is the git repo root
#          Source config at $SOURCE_CONFIG or ./clawdbot.json (copied from agent's config)

REPO_DIR="${PWD}"
SOURCE_CONFIG="${SOURCE_CONFIG:-$REPO_DIR/clawdbot.json}"
TARGET_CONFIG="$REPO_DIR/clawdbot.json"

# Get commit message from args or use default
# Prepend [skip ci] to prevent auto-redeploy - human must trigger redeploy
COMMIT_MSG="[skip ci] ${1:-Update bot configuration}"

echo "🔄 Starting self-deploy..."

# Check if source config exists
if [ ! -f "$SOURCE_CONFIG" ]; then
    echo "❌ Error: Source config not found at $SOURCE_CONFIG"
    echo "Make sure to copy your config to this location first"
    exit 1
fi

# Check if repo is set up
if [ ! -d "$REPO_DIR/.git" ]; then
    echo "❌ Error: Repository not found. Run from git repo root."
    exit 1
fi

# Copy config to repo
echo "📋 Copying config..."
cp "$SOURCE_CONFIG" "$TARGET_CONFIG"

# Encrypt config
echo "🔐 Encrypting config..."
mise run encrypt-config

# Check if encryption worked
if [ ! -f "clawdbot.json.enc" ]; then
    echo "❌ Error: Encryption failed - clawdbot.json.enc not created"
    exit 1
fi

# Stage and commit (only encrypted config - plaintext is gitignored)
echo "📝 Committing changes..."
git add clawdbot.json.enc
git commit -m "$COMMIT_MSG"

# Push changes (with [skip ci] - human must trigger redeploy)
echo "🚀 Pushing changes..."
git push origin main

echo ""
echo "✅ Config saved to repository!"
echo ""
echo "IMPORTANT: This commit has [skip ci] to prevent auto-redeploy."
echo "Review the changes and trigger redeploy manually when ready."
