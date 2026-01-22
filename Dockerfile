# syntax=docker/dockerfile:1.5
FROM node:lts-slim AS base

RUN corepack enable
WORKDIR /root

FROM base AS deps

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --prod --frozen-lockfile

FROM base AS runtime

WORKDIR /root

ENV CLAWDBOT_STATE_DIR=/data/.clawdbot
ENV HOME=/root
ENV PATH="/root/node_modules/.bin:$PATH"
ENV SHELL=/bin/bash
ENV MISE_TRUSTED_CONFIG_PATHS=/root

RUN apt update && apt install -y apt-transport-https ca-certificates curl git

COPY --from=deps /root/node_modules node_modules
COPY .bashrc .bashrc
COPY clawdbot.json.enc clawdbot.json.enc
COPY mise.toml mise.toml
COPY start.sh start.sh

RUN curl https://mise.run | sh
RUN chmod +x /root/start.sh

EXPOSE 18789

# Health check for Railway
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD clawdbot health || exit 1

CMD ["/bin/bash", "/root/start.sh"]
