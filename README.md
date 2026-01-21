# Clawdbot Railway Template

One-click deployment template for [Clawdbot](https://github.com/clawdbot/clawdbot) on Railway. Clawdbot is an AI assistant platform supporting WhatsApp, Telegram, Discord, and other messaging channels.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/mpxXJp?referralCode=igaHaH&utm_medium=integration&utm_source=template&utm_campaign=generic)

## Quick Start

### 1. Deploy the Template

1. Click the **Deploy on Railway** button above
2. Fill in the environment variables:
   - **AI Provider** (at least one required):
     - `ANTHROPIC_API_KEY` - for Claude models
     - `OPENAI_API_KEY` - for OpenAI models
     - `OPENROUTER_API_KEY` - for OpenRouter models
   - **Channels** (optional - add the ones you want):
     - `TELEGRAM_BOT_TOKEN` - from [@BotFather](https://t.me/BotFather)
     - `DISCORD_BOT_TOKEN` - from [Discord Developer Portal](https://discord.com/developers/applications)
   - `CLAWDBOT_GATEWAY_PASSWORD` is auto-generated for you
3. Click **Deploy**

### 2. Add a Volume (Required)

Railway containers lose their filesystem on each deploy. You must attach a volume:

1. After deployment, go to your service in the Railway dashboard
2. Right-click the service → **Attach Volume**
3. Set **Mount Path** to `/data`
4. Click **Add** then **Redeploy** the service

### 3. Enable Public Networking

1. Go to **Settings** → **Networking**
2. Click **Generate Domain**
3. Your gateway will be available at `https://your-app.railway.app`

### 4. Access the Web UI

Open your gateway URL with your password to access the Control UI:

```
https://your-app.railway.app?token=YOUR_GATEWAY_PASSWORD
```

The Control UI provides:
- Chat interface
- Configuration management
- Session monitoring
- Channel status

### 5. Test Your Bot

If you configured Telegram or Discord tokens, your bot is already live. Send it a message to test.

**First-time Telegram DM:** You'll receive a pairing code. Approve it via SSH:
```bash
railway ssh
clawdbot pairing approve telegram <CODE>
```

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `CLAWDBOT_GATEWAY_PASSWORD` | Auto | *(generated)* | Gateway authentication (auto-generated) |
| `ANTHROPIC_API_KEY` | No* | - | API key for Claude models |
| `OPENAI_API_KEY` | No* | - | API key for OpenAI models |
| `OPENROUTER_API_KEY` | No* | - | API key for OpenRouter models |
| `TELEGRAM_BOT_TOKEN` | No | - | Telegram bot token from @BotFather |
| `DISCORD_BOT_TOKEN` | No | - | Discord bot token |
| `CLAWDBOT_STATE_DIR` | Auto | `/data/.clawdbot` | Config storage (set by Dockerfile) |

> *At least one AI provider API key is required

## Volume Storage

The volume at `/data` persists across deploys:

```
/data/
├── .clawdbot/          # Clawdbot configuration
│   ├── clawdbot.json   # Main config file
│   ├── credentials/    # Channel credentials (Telegram tokens, etc.)
│   └── agents/         # Agent state and auth profiles
└── clawd/              # Workspace
    ├── skills/         # Custom skills
    └── memory/         # Conversation memory
```

## Common Tasks

### Adding a New Channel

**Telegram/Discord:** Add via environment variables in Railway dashboard, then redeploy:
- `TELEGRAM_BOT_TOKEN`
- `DISCORD_BOT_TOKEN`

**WhatsApp** (requires SSH for QR scan):
```bash
railway ssh
clawdbot channels add whatsapp
# Scan the QR code with your phone
```

**Other channels** (Slack, Signal, Teams, etc.):
```bash
railway ssh
clawdbot onboard
```

### Checking Channel Status

```bash
railway ssh

# Inside container:
clawdbot channels status
clawdbot channels logs telegram
```

### Creating/Managing Agents

```bash
railway ssh

# Inside container:
clawdbot agents list
clawdbot agents create my-agent
clawdbot agents config my-agent --provider anthropic --model claude-sonnet-4-20250514
```

### Viewing Logs

From Railway dashboard:
- Click **Deployments** → select deployment → **View Logs**

Or via CLI:
```bash
railway logs
```

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Railway Container                     │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────────┐    ┌────────────────────────────┐  │
│  │  Clawdbot CLI   │───▶│     Gateway (port 18789)   │  │
│  └─────────────────┘    └────────────────────────────┘  │
│           │                          │                   │
│           ▼                          ▼                   │
│  ┌─────────────────────────────────────────────────────┐│
│  │              Volume mounted at /data                ││
│  │  ┌──────────────────┐  ┌────────────────────────┐  ││
│  │  │  /data/.clawdbot │  │     /data/clawd        │  ││
│  │  │  (config/state)  │  │     (workspace)        │  ││
│  │  └──────────────────┘  └────────────────────────┘  ││
│  └─────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────┘
```

## Troubleshooting

### Gateway won't start

**Check logs for errors:**
- Railway dashboard → **Deployments** → **View Logs**

**Common causes:**
- Missing volume mount at `/data`
- No AI provider API key configured

### State not persisting between deploys

1. Verify volume exists: **Settings** → **Volumes**
2. Confirm mount path is exactly `/data`
3. Check volume has available space

### SSH connection fails

1. Ensure the service is running (not crashed)
2. Verify you're logged in: `railway login`
3. Link your project: `railway link`

### Channel not responding

```bash
railway ssh

# Check status
clawdbot channels status

# View channel logs
clawdbot channels logs telegram
```

### Health check failing

1. Check deployment logs for startup errors
2. Verify port 18789 is exposed
3. Increase `healthcheckTimeout` in `railway.toml` if needed

## Updating Clawdbot

To update to the latest version:

1. Dependabot will open a PR updating `package.json` and `pnpm-lock.yaml`
2. Merge the PR
3. Railway dashboard → **Deployments** → **Redeploy** (or rely on your CI/CD)

The Dockerfile installs Clawdbot from the pinned version in `package.json`.

## Resources

- [Clawdbot Documentation](https://docs.clawd.bot)
- [Clawdbot GitHub](https://github.com/clawdbot/clawdbot)
- [Railway Documentation](https://docs.railway.app)
- [Railway CLI Guide](https://docs.railway.com/guides/cli)

## License

Apache License 2.0 - see [LICENSE](LICENSE) file for details.
