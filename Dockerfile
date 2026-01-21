FROM node:lts-alpine

RUN apk add --no-cache git

# Install clawdbot globally
RUN pnpm install -g clawdbot@latest

# Set environment for persistent storage
ENV CLAWDBOT_STATE_DIR=/data/.clawdbot
ENV HOME=/root

WORKDIR /root

EXPOSE 18789

# Health check for Railway
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD clawdbot health || exit 1

# Copy default config and startup script
COPY clawdbot.json /root/clawdbot.json
COPY start.sh /root/start.sh
RUN chmod +x /root/start.sh

CMD ["/root/start.sh"]
