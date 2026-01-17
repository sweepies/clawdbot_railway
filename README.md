# Clawdbot Railway Template

One-click deployment template for [Clawdbot](https://github.com/clawdbot/clawdbot) on Railway. Clawdbot is an AI assistant platform supporting WhatsApp, Telegram, Discord, and other messaging channels.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/template/clawdbot)

## Quick Start

1. Click the "Deploy on Railway" button above
2. Set required environment variables (see below)
3. **Add a volume** mounted at `/data` (see Volume Setup)
4. Deploy and wait for the service to start
5. Configure your messaging channels via CLI

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `CLAWDBOT_STATE_DIR` | Auto | `/data/.clawdbot` | Config storage (set by Dockerfile) |
| `CLAWDBOT_GATEWAY_TOKEN` | Yes | - | Gateway authentication token |
| `ANTHROPIC_API_KEY` | No* | - | API key for Claude models |
| `OPENAI_API_KEY` | No* | - | API key for OpenAI models |
| `OPENROUTER_API_KEY` | No* | - | API key for OpenRouter models |

> *At least one AI provider API key is required

### Generating a Gateway Token

Use Railway's secret generator or create a secure random token:

```bash
openssl rand -hex 32
```

## Volume Setup

**Important**: Railway containers lose their filesystem on each deploy. You must attach a volume for persistent storage.

### Adding a Volume in Railway

1. Go to your service in the Railway dashboard
2. Click **Settings** → **Volumes**
3. Click **Add Volume**
4. Set **Mount Path** to `/data`
5. Recommended size: **1GB minimum**

### What's Stored in the Volume

```
/data/
├── .clawdbot/          # Clawdbot configuration
│   ├── clawdbot.json   # Main config file
│   ├── credentials/    # Channel credentials
│   └── agents/         # Agent state
└── clawd/              # Workspace
    ├── skills/         # Custom skills
    └── memory/         # Conversation memory
```

## Network Configuration

- **Internal port**: 18789
- **Protocol**: HTTP/WebSocket
- **Public networking**: Enable in Railway settings to access the gateway dashboard

### Enabling Public Access

1. Go to **Settings** → **Networking**
2. Click **Generate Domain** or add a custom domain
3. Access your gateway at `https://your-domain.railway.app`

## Post-Deployment Setup

### Connecting via CLI

You can manage your Clawdbot instance using the CLI from your local machine:

```bash
# Install clawdbot locally
npm install -g clawdbot

# Connect to your Railway gateway
clawdbot gateway connect https://your-domain.railway.app --token YOUR_GATEWAY_TOKEN
```

### Configuring Channels

#### Telegram

```bash
# Get a bot token from @BotFather on Telegram
clawdbot channels add telegram --token YOUR_BOT_TOKEN
```

#### Discord

```bash
# Create a bot at discord.com/developers/applications
clawdbot channels add discord --token YOUR_BOT_TOKEN
```

#### WhatsApp

```bash
# Requires WhatsApp Business API credentials
clawdbot channels add whatsapp --setup
```

### Creating Agents

```bash
# Create a new agent
clawdbot agents create my-agent

# Configure the agent's AI provider
clawdbot agents config my-agent --provider anthropic --model claude-3-5-sonnet-20241022
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
- Go to your service in Railway dashboard
- Click **Deployments** → select latest deployment → **View Logs**

**Common causes:**
- Missing volume mount at `/data`
- Missing `CLAWDBOT_GATEWAY_TOKEN` environment variable
- No AI provider API key configured

### State not persisting between deploys

**Ensure volume is properly mounted:**
1. Check that a volume exists in **Settings** → **Volumes**
2. Verify mount path is exactly `/data`
3. Check that the volume has available space

### Cannot connect from local CLI

**Verify network configuration:**
1. Ensure public networking is enabled
2. Check that you're using the correct gateway URL
3. Verify your `CLAWDBOT_GATEWAY_TOKEN` matches

### Channel not responding

**Debug channel connection:**
```bash
clawdbot channels status
clawdbot channels logs <channel-name>
```

### Health check failing

The gateway exposes a health endpoint at `/`. If health checks fail:
1. Increase `healthcheckTimeout` in `railway.toml`
2. Check that port 18789 is being used correctly
3. Review deployment logs for startup errors

## Updating Clawdbot

To update to the latest version of Clawdbot:

1. Go to your service in Railway dashboard
2. Click **Deployments** → **Redeploy**

The Dockerfile uses `clawdbot@latest`, so each rebuild fetches the newest version.

## Resources

- [Clawdbot Documentation](https://github.com/clawdbot/clawdbot)
- [Railway Documentation](https://docs.railway.app)
- [Railway Templates Guide](https://docs.railway.app/guides/templates)

## License

Apache License 2.0 - see [LICENSE](LICENSE) file for details.
