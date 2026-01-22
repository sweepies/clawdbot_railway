# Self-Configuration Skill Reference

This document describes the self-configuration skill that enables clawdbot to manage its own configuration.

## Overview

The self-configuration skill allows clawdbot to:
1. Detect when its configuration has been modified
2. Automatically persist changes back to the git repository
3. Trigger Railway redeployment via git push

## Skill Location

The skill should be installed in:
- **Repository**: `<repo>/skills/self-configuration/` (for version control)
- **Active**: `<agent-workspace>/skills/self-configuration/` (for clawdbot to use)

## Files

```
self-configuration/
├── SKILL.md                 # Skill definition and usage instructions
├── references/
│   └── SETUP.md            # This file - detailed setup and troubleshooting
└── scripts/
    └── deploy-config.sh    # Main deployment script
```

## How It Works

### 1. Trigger
The skill triggers when:
- Config modifications are detected
- User explicitly requests deployment ("save config", "deploy", etc.)
- Called via the skill system

### 2. Deployment Process
1. Copy current config from agent's config location to repo root
2. Encrypt config using `mise run encrypt-config` (age encryption)
3. Stage and commit changes with descriptive message
4. Push to `origin main` to trigger Railway webhook

### 3. Railway Redeploy
Railway automatically deploys when:
- New commits are pushed to the main branch
- The `clawdbot.json.enc` file contains the encrypted config
- Railway decrypts config at startup using `AGE_KEY` environment variable

## Usage

### Automatic
The skill monitors for config changes and auto-deploys when detected.

### Manual
```bash
cd /path/to/repo
./skills/self-configuration/scripts/deploy-config.sh "Your commit message"
```

### Via Clawdbot
When clawdbot detects config changes, it will:
1. Load the self-configuration skill
2. Execute the deployment workflow
3. Report status back

## Requirements

### Git Configuration
```bash
git config user.name "Clawdbot"
git config user.email "clawdbot@localhost"
```

### SSH Access (for git push)
- SSH key must be configured for GitHub
- Or use HTTPS with credentials in git credential store

### Age Encryption
- `age` tool available via `mise use -g age`
- `CONFIG_KEY` stored in `fnox.toml` (run `fnox set CONFIG_KEY < age-key.txt` to configure)
- `AGE_KEY` set in Railway environment variables

## Troubleshooting

### "Source config not found"
- Check that your config file exists
- Ensure clawdbot is running and has created the config
- Set `SOURCE_CONFIG` environment variable if using non-default location

### "Repository not found"
- Verify repo is cloned and you're running from its root
- Check that `.git` directory exists

### "Encryption failed"
- Verify `mise` and `age` are installed
- Check `fnox.toml` is configured with `CONFIG_KEY` (`fnox get CONFIG_KEY` should return the age identity)
- Run `mise run encrypt-config` manually to test

### Push fails
- Verify git remote is configured: `git remote -v`
- Check SSH keys or HTTPS credentials
- Ensure branch name matches (main vs master)

### Railway doesn't redeploy
- Verify Railway project is linked to the GitHub repo
- Check that auto-deploy is enabled in Railway settings
- Check Railway dashboard for deployment history

## Security Notes

- The deployment script runs with clawdbot's filesystem access
- Config is encrypted before commit (safe for git)
- `AGE_KEY` should never be committed (stored in Railway only)
- Review commit messages before pushing

## Integration with Clawdbot

To enable automatic deployment:

1. Install the skill in `<agent-workspace>/skills/self-configuration/`
2. Clawdbot will automatically load skills from this directory
3. When config modifications are detected, the skill triggers
4. Deployment happens automatically without user intervention

## Maintenance

### Updating the Skill
1. Edit files in `<repo>/skills/self-configuration/`
2. Copy changes to `<agent-workspace>/skills/self-configuration/`
3. Test deployment workflow
4. Commit to git for version control

### Skill Structure
- **SKILL.md**: When to use, workflow overview
- **scripts/deploy-config.sh**: Actual deployment logic
- **references/**: Detailed documentation

## Future Enhancements

Potential improvements:
- Dry-run mode for testing
- Rollback capability
- Deployment status notifications
- Config diff before deployment
- Multiple environment support
