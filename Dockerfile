FROM node:22-bookworm-slim

# Install clawdbot globally
RUN npm install -g clawdbot@latest

# Create non-root user for security
RUN useradd -m -s /bin/bash -u 1000 clawdbot

# Create persistent data directories
RUN mkdir -p /data/.clawdbot /data/clawd && \
    chown -R clawdbot:clawdbot /data

USER clawdbot
WORKDIR /home/clawdbot

# Set environment for persistent storage
ENV CLAWDBOT_STATE_DIR=/data/.clawdbot
ENV HOME=/home/clawdbot

EXPOSE 18789

COPY --chown=clawdbot:clawdbot start.sh /home/clawdbot/start.sh
RUN chmod +x /home/clawdbot/start.sh

CMD ["/home/clawdbot/start.sh"]
