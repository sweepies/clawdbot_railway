# Clawdbot Railway Deployment

A git-managed deployment template for [Clawdbot](https://github.com/clawdbot/clawdbot) on Railway. Clawdbot is an AI assistant platform supporting WhatsApp, Telegram, Discord, and other messaging channels.

## Prerequisites
> [!IMPORTANT]
> This deployment method is intended for **advanced users** who are comfortable with:
> - Command-line tools and Git workflows
> - Managing encryption keys
> - Railway deployment configuration

### Required Tools

Install these tools before proceeding:

| Tool | Purpose | Installation |
|------|---------|--------------|
| [mise](https://mise.jdx.dev) | Task runner and tool manager | `curl https://mise.run \| sh` |
| [age](https://github.com/FiloSottile/age) | Config file encryption | `mise use -g age` |
| [fnox](https://fnox.jdx.dev) | Secrets management | `mise use -g fnox` |
| [Railway CLI](https://docs.railway.com/guides/cli) | Deployment and SSH access | `mise use -g railway` |

## How It Works

This repository serves as the **source of truth** for your Clawdbot configuration. Your configuration is stored **encrypted** in the repository and decrypted at runtime.

**Deployment flow:**

1. You edit `clawdbot.json` locally and encrypt it
2. You commit `clawdbot.json.enc` to your repository
3. Railway builds and deploys the Docker image
4. At startup, the config is decrypted using the secret key stored in Railway
5. On each redeploy, the Clawdbot configuration is overwritten to match your repository

> [!WARNING]
> Any changes made to the running `clawdbot.json` (via the web UI, SSH, or other means) will be **overwritten on the next deploy**. To persist configuration changes, you must commit them to your forked repository.

### Automatic Updates

This repository includes Dependabot and a GitHub Actions workflow that automatically keeps Clawdbot up to date:

1. Dependabot opens PRs when new Clawdbot versions are released
2. The auto-merge workflow (`.github/workflows/dependabot-auto-merge.yml`) merges these PRs after CI passes
3. Railway automatically redeploys when the PR is merged (if auto-deploy is enabled)

To disable automatic updates and review them manually, delete or disable the auto-merge workflow in your fork.

## Quick Start

### 1. Fork This Repository

1. Click **Fork** on GitHub to create your own copy
2. Clone your fork locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/clawdbot_railway.git
   cd clawdbot_railway
   ```

### 2. Set Up Age Keys

You need two age identities:

1. **Your personal identity** — used to decrypt fnox secrets locally
2. **Railway's identity** — used by Railway to decrypt the config at runtime

#### Personal Identity

If you don't already have an age identity, generate one:

```bash
age-keygen -o ~/.config/age/keys.txt
```

Add your public key (the `age1...` line) to the `recipients` list in `fnox.toml`.

Alternatively, you can use your existing SSH key. Add your SSH public key directly to `fnox.toml`:

```toml
recipients = [
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA...",  # from ~/.ssh/id_ed25519.pub
]
```

Then tell fnox where to find your private key:

```bash
export FNOX_AGE_KEY_FILE=~/.ssh/id_ed25519
```

> [!NOTE]
> Password-protected SSH keys are not supported. If your key has a passphrase, create a copy without one for use with fnox.

#### Railway Identity

Generate a separate key for Railway:

```bash
age-keygen -o age-key.txt
```

This creates a file containing both the secret and public key:

```
# created: 2024-01-01T00:00:00Z
# public key: age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
AGE-SECRET-KEY-1XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

**Keep `age-key.txt` secure and never commit it to git.** The secret key goes in Railway's `AGE_KEY` environment variable.

### 3. Configure Encryption

Store your age key in fnox so authorized users can update the config:

```bash
# Install the mise-env-fnox plugin
mise plugins install fnox-env https://github.com/jdx/mise-env-fnox

# Store your age key in fnox
fnox set CONFIG_KEY < age-key.txt
```

This stores your Railway decryption key (`CONFIG_KEY`) in `fnox.toml`, encrypted to the recipients listed there. Anyone whose age identity is in the recipients list can then run `mise run encrypt-config` to update the encrypted config—without needing direct access to the Railway key.

### 4. Initial Deploy

Commit your fnox configuration and deploy:

```bash
git add fnox.toml
git commit -m "Configure encryption"
git push
```

Now deploy to Railway:

1. Go to [Railway](https://railway.app) and create a new project
2. Select **Deploy from GitHub repo**
3. Connect your forked repository
4. Add your environment variables (see [Environment Variables](#environment-variables))
5. Click **Deploy**
6. Link the project locally for CLI access:
   ```bash
   railway link
   ```

### 5. Add a Volume (Required)

Railway containers lose their filesystem on each deploy. Attach a volume for persistent data:

1. In Railway dashboard, right-click your service → **Attach Volume**
2. Set **Mount Path** to `/data`
3. Click **Add** then **Redeploy**

### 6. Enable Public Networking

1. Go to **Settings** → **Networking**
2. Click **Generate Domain**
3. Your gateway will be available at `https://your-app.railway.app`

### 7. Configure Your Bot

Run the interactive configurator via SSH:

```bash
railway ssh -- clawdbot configure
```

This walks you through setting up agents, channels, and other options interactively.

### 8. Save Your Configuration

After configuring, copy the config back to your local machine:

```bash
railway ssh -- cat /data/.clawdbot/clawdbot.json > clawdbot.json
```

Then encrypt and commit to persist it:

```bash
mise run encrypt-config
git add clawdbot.json.enc
git commit -m "Configure my bot"
git push
```

The plaintext `clawdbot.json` is gitignored and will not be committed.

### 9. Access the Web UI

1. Connect to your instance via SSH and run the dashboard command:
   ```bash
   railway ssh -- clawdbot dashboard
   ```

2. Copy the token from the URL it displays (the value after `?token=`)

3. Open your Railway deployment's public URL in your browser

4. Go to **Overview** → **Gateway Access** and enter the token

5. Click **Connect**

The token will be saved in your browser storage, allowing continued access to the web UI.

## Configuration

### The `clawdbot.json` File

Your `clawdbot.json` is the heart of your bot's configuration. This file defines:

- Agent settings and personalities
- Model preferences
- Channel configurations
- Custom behaviors

**Example:**
```json
{
  "agents": {
    "defaults": {
      "workspace": "/data/clawd",
      "provider": "anthropic",
      "model": "claude-sonnet-4-20250514"
    }
  }
}
```

### Encryption Workflow

Your configuration contains sensitive data and is stored encrypted in git:

| File | Purpose | Committed to Git |
|------|---------|------------------|
| `clawdbot.json` | Plaintext config (your working copy) | No (gitignored) |
| `clawdbot.json.enc` | Encrypted config | Yes |
| `clawdbot.example.json` | Example/template config | Yes |
| `fnox.toml` | Encryption key (encrypted to authorized users) | Yes |
| `age-key.txt` | Your local age identity | No (gitignored) |

**Local workflow:**
```bash
# Edit your config
nano clawdbot.json

# Encrypt before committing (uses fnox to get the encryption key)
mise run encrypt-config

# Commit the encrypted version
git add clawdbot.json.enc
git commit -m "Update bot configuration"
git push
```

**Decryption at runtime:**
The `start.sh` script automatically decrypts the config using the `AGE_KEY` environment variable before starting Clawdbot.

### Persisting Configuration Changes

Since configuration is overwritten on every deploy, you have two options for persisting changes:

#### Option 1: Manual Updates

1. Make changes via web UI or SSH
2. Export or copy the updated configuration
3. Encrypt and commit to your repository:
   ```bash
   mise run encrypt-config
   git add clawdbot.json.enc
   git commit -m "Update bot configuration"
   git push
   ```

#### Option 2: Agent-Managed Updates

Configure your Clawdbot agent with permissions to commit configuration changes back to your repository. This allows the bot to persist its own configuration updates automatically.

### Self-Configuration Skill

This repository includes a **self-configuration skill** (`skills/self-configuration/`) that enables the agent to save its configuration back to the repository:

1. **Copy config**: The agent copies its current config to the repo root
2. **Encrypt**: Config is encrypted using `mise run encrypt-config`
3. **Commit**: Changes are committed with `[skip ci]` prefix
4. **Push**: Changes are pushed to the repository

The `[skip ci]` prefix prevents automatic Railway redeployment, ensuring the human stays in control of deployment timing. After the agent saves config, it will inform you to review changes and trigger deploy manually.

To enable this skill, install it in your agent's workspace:
```bash
cp -r skills/self-configuration /path/to/your/agent/workspace/skills/
```

When the agent detects configuration changes, it will automatically run the self-configuration workflow and prompt you to deploy when ready.

## Environment Variables

Configure these in your Railway dashboard under **Variables**:

| Variable | Required | Description |
|----------|----------|-------------|
| `AGE_KEY` | **Yes** | Your age secret key (the full `AGE-SECRET-KEY-...` string) for decrypting config |
| `ANTHROPIC_API_KEY` | No* | API key for Claude models |
| `OPENAI_API_KEY` | No* | API key for OpenAI models |
| `OPENROUTER_API_KEY` | No* | API key for OpenRouter models |
| `TELEGRAM_BOT_TOKEN` | No | Telegram bot token from [@BotFather](https://t.me/BotFather) |
| `DISCORD_BOT_TOKEN` | No | Discord bot token |

> [!NOTE]
> *At least one AI provider API key is required, unless configured in `clawdbot.json`

### Configuring AGE_KEY

The `AGE_KEY` environment variable must contain your age secret key. This cannot be set via the Railway CLI—you must configure it in the Railway dashboard:

1. Go to your service in the Railway dashboard
2. Click **Variables**
3. Add a new variable:
   - **Name:** `AGE_KEY`
   - **Value:** Your full secret key (e.g., `AGE-SECRET-KEY-1XXXXXX...`)
4. Click **Add** then **Redeploy**

## Volume Storage

The volume at `/data` persists across deploys and stores runtime data:

```
/data/
├── .clawdbot/
│   ├── clawdbot.json   # Decrypted config (restored on each deploy)
│   ├── credentials/    # Channel credentials (Telegram sessions, etc.)
│   └── agents/         # Agent state and auth profiles
└── clawd/              # Workspace
    ├── skills/         # Custom skills
    └── memory/         # Conversation memory
```

### Workspace Tooling

This deployment comes with mise configured to trust all agent workspace directories. This means users or agents can add a `mise.toml` file to any workspace to manage tools and environment variables available in that workspace.
> [!WARNING]
> Trusting workspace directories means an agent with filesystem write access can create mise configs with hooks that execute arbitrary shell commands. If your security model relies on granting filesystem access while denying shell execution, be aware that mise hooks can bypass this restriction. Consider removing `MISE_TRUSTED_CONFIG_PATHS` from the Dockerfile if this is a concern.

## Common Tasks

### Adding a New Channel

**Telegram/Discord:** Add tokens via Railway environment variables, then redeploy.

**WhatsApp** (requires SSH for QR scan):
```bash
railway ssh
clawdbot channels add whatsapp
# Scan the QR code with your phone
```

### Checking Channel Status

```bash
railway ssh
clawdbot channels status
clawdbot channels logs telegram
```

### Updating Your Bot Configuration

1. Edit `clawdbot.json` locally
2. Encrypt: `mise run encrypt-config`
3. Commit and push: `git add clawdbot.json.enc && git commit -m "Update config" && git push`
4. Railway will automatically redeploy (if auto-deploy is enabled)

### Updating Clawdbot Version

See [Automatic Updates](#automatic-updates) for details on how Clawdbot stays up to date.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Your GitHub Repo                          │
│  ┌───────────────────┐  ┌────────────┐                      │
│  │ clawdbot.json.enc │  │ fnox.toml  │                      │
│  │ (encrypted config)│  │ (key mgmt) │                      │
│  └───────────────────┘  └────────────┘                      │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼ (deploy)
┌─────────────────────────────────────────────────────────────┐
│                    Railway Container                         │
├─────────────────────────────────────────────────────────────┤
│  start.sh: age --decrypt (using AGE_KEY env var)            │
│                              │                               │
│                              ▼                               │
│  ┌─────────────────┐    ┌────────────────────────────────┐  │
│  │  Clawdbot CLI   │───▶│     Gateway (port 18789)       │  │
│  └─────────────────┘    └────────────────────────────────┘  │
│           │                          │                       │
│           ▼                          ▼                       │
│  ┌─────────────────────────────────────────────────────────┐│
│  │              Volume mounted at /data                    ││
│  │         (credentials, agent state, workspace)           ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

## Troubleshooting

### Decryption fails at startup

- Verify `AGE_KEY` is set correctly in Railway Variables
- Ensure the key is the full secret key string starting with `AGE-SECRET-KEY-`
- Check that `clawdbot.json.enc` was encrypted with the key stored in `fnox.toml` (`CONFIG_KEY`)

### Local encryption/decryption fails

- Ensure fnox is configured: `fnox get CONFIG_KEY` should return the Railway age identity
- If CONFIG_KEY is not set, run: `fnox set CONFIG_KEY < age-key.txt`
- Verify your personal age identity is listed in the `recipients` in `fnox.toml`
- Check that your identity exists at `~/.config/age/keys.txt`, or if using SSH keys, set `FNOX_AGE_KEY_FILE=~/.ssh/id_ed25519`

### Configuration changes not persisting

This is expected behavior. Changes made at runtime are overwritten on redeploy. Encrypt and commit your changes to your repository to persist them.

### Gateway won't start

- Check logs in Railway dashboard → **Deployments** → **View Logs**
- Verify volume is mounted at `/data`
- Ensure at least one AI provider API key is configured
- Verify `AGE_KEY` is configured correctly

### Channel not responding

```bash
railway ssh
clawdbot channels status
clawdbot channels logs telegram
```

### SSH connection fails

1. Ensure the service is running
2. Verify you're logged in: `railway login`
3. Link your project: `railway link`

## Resources

- [Clawdbot Documentation](https://docs.clawd.bot)
- [Clawdbot GitHub](https://github.com/clawdbot/clawdbot)
- [age Encryption](https://github.com/FiloSottile/age)
- [fnox Documentation](https://fnox.jdx.dev)
- [mise Documentation](https://mise.jdx.dev)
- [Railway Documentation](https://docs.railway.app)
- [Railway CLI Guide](https://docs.railway.com/guides/cli)

## License

Apache License 2.0 - see [LICENSE](LICENSE) file for details.
