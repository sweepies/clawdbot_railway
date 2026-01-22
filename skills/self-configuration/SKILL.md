---
name: self-configuration
description: Auto-save when modifying my own configuration. Copies config to repo, encrypts it, and commits with [skip ci] so human can review and trigger deploy manually.
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
3. **Commit changes** with `[skip ci]` prefix (prevents auto-redeploy)
4. **Push** changes to repository
5. **Inform user** that manual redeploy is needed

### Important: `[skip ci]` Commits

All commits made by this skill include `[skip ci]` to prevent automatic Railway redeployment. After the skill commits and pushes:

- **Tell the user**: "Config saved! Review the changes and run `git push` or trigger redeploy manually."
- The human must decide when to redeploy (prevents unintended deploys)

This ensures the human stays in control of deployment timing.

## Manual Trigger

If automatic detection misses changes, run the deployment script directly from the repo root:

```bash
cd /path/to/clawdbot_railway
./skills/self-configuration/scripts/deploy-config.sh "Your commit message here"
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
