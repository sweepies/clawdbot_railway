---
name: self-deploy
description: Auto-deploy when modifying my own configuration. Copies current config to repo, encrypts it, and pushes to trigger Railway redeployment.
---

# Self-Deploy Skill

This skill enables self-managed deployment by automatically persisting configuration changes back to the git repository, which triggers Railway redeployment.

## When to Use

Trigger this skill when:
- Your configuration has been modified (via web UI, SSH, or any means)
- The user asks you to "save config", "persist changes", or "deploy my changes"
- Configuration updates need to survive redeploys

## Workflow

1. **Copy config** from the agent's config location to the repo root as `clawdbot.json`
2. **Encrypt config** using `mise run encrypt-config`
3. **Commit changes** with descriptive message
4. **Push** to trigger Railway auto-deploy

## Manual Trigger

If automatic detection misses changes, run the deployment script directly from the repo root:

```bash
cd /path/to/clawdbot_railway
./skills/self-deploy/scripts/deploy-config.sh "Your commit message here"
```

## Requirements

- Git repository must be cloned and configured
- Age encryption tools available via mise
- Git remote must be set (origin)
- Git credentials configured (HTTPS with token, or SSH)

## Environment Variables

| Variable | Description |
|----------|-------------|
| `SOURCE_CONFIG` | Path to source config (defaults to `./clawdbot.json`) |
