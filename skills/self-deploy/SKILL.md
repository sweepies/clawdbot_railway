---
name: self-deploy
description: Auto-deploy when modifying my own configuration. Triggers when config changes are detected, copies current config from /data/.clawdbot/clawdbot.json to the repo, encrypts it, and pushes to trigger Railway redeployment.
---

# Self-Deploy Skill

This skill enables self-managed deployment by automatically persisting configuration changes back to the git repository, which triggers Railway redeployment.

## When to Use

Trigger this skill when:
- You modify `/data/.clawdbot/clawdbot.json` via any means (web UI, SSH, direct edit)
- The user asks you to "save config", "persist changes", or "deploy my changes"
- Configuration updates need to survive redeploys

## Workflow

1. **Copy config** from `/data/.clawdbot/clawdbot.json` to repo root as `clawdbot.json`
2. **Encrypt config** using `mise run encrypt-config`
3. **Commit changes** with descriptive message
4. **Push** to trigger Railway auto-deploy

## Manual Trigger

If automatic detection misses changes, run the deployment script directly:

```bash
cd /data/miku-private/clawdbot_railway
./scripts/deploy-config.sh "Your commit message here"
```

## Requirements

- Git repository must be cloned and configured
- Age encryption tools available via mise
- Git remote must be set (origin)
- SSH access to git remote (for push) or HTTPS credentials configured
