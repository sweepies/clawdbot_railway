#!/bin/bash
set -e

# Self-deploy script: copies config, encrypts, commits and pushes

REPO_DIR="/data/miku-private/clawdbot_railway"
SOURCE_CONFIG="/data/.clawdbot/clawdbot.json"
TARGET_CONFIG="$REPO_DIR/clawdbot.json"

# Get commit message from args or use default
COMMIT_MSG="${1:-Update bot configuration}"

echo "🔄 Starting self-deploy..."

# Check if source config exists
if [ ! -f "$SOURCE_CONFIG" ]; then
    echo "❌ Error: Source config not found at $SOURCE_CONFIG"
    exit 1
fi

# Check if repo is set up
if [ ! -d "$REPO_DIR/.git" ]; then
    echo "❌ Error: Repository not found at $REPO_DIR"
    exit 1
fi

cd "$REPO_DIR"

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

# Stage and commit
echo "📝 Committing changes..."
git add clawdbot.json.enc
git add clawdbot.json  # tracked in gitignore but we stage explicitly
git commit -m "$COMMIT_MSG"

# Push to trigger redeploy
echo "🚀 Pushing to trigger Railway redeploy..."
git push origin main

echo "✅ Done! Railway should auto-redeploy shortly."
