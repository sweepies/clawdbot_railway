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

RUN apt update && apt install -y curl git age
RUN install -dm 755 /etc/apt/keyrings && \
    curl -fSs https://mise.jdx.dev/gpg-key.pub | tee /etc/apt/keyrings/mise-archive-keyring.asc 1> /dev/null && \
    echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.asc] https://mise.jdx.dev/deb stable main" | tee /etc/apt/sources.list.d/mise.list && \
    apt update && apt install -y mise
RUN mise use -g fnox && mise plugin install fnox-env https://github.com/jdx/mise-env-fnox

COPY --from=deps /root/node_modules node_modules
COPY .bashrc .bashrc
COPY clawdbot.json.enc clawdbot.json.enc
COPY start.sh start.sh

RUN chmod +x /root/start.sh

EXPOSE 18789

# Health check for Railway
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD clawdbot health || exit 1

CMD ["/bin/bash", "/root/start.sh"]
