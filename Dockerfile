FROM node:lts-alpine

RUN apk add --no-cache git
RUN corepack enable

WORKDIR /root

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --prod --frozen-lockfile

# Set environment for persistent storage
ENV CLAWDBOT_STATE_DIR=/data/.clawdbot
ENV HOME=/root
ENV PATH="/root/node_modules/.bin:$PATH"

EXPOSE 18789

# Health check for Railway
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD clawdbot health || exit 1

# Copy default config and startup script
COPY clawdbot.json /root/clawdbot.json
COPY start.sh /root/start.sh
RUN chmod +x /root/start.sh

CMD ["/root/start.sh"]
