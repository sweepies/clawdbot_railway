FROM node:22-bookworm-slim

# Install git (required for some npm dependencies)
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

# Install clawdbot globally
RUN npm install -g clawdbot@latest

# Set environment for persistent storage
ENV CLAWDBOT_STATE_DIR=/data/.clawdbot
ENV HOME=/root

WORKDIR /root

EXPOSE 18789

COPY start.sh /root/start.sh
RUN chmod +x /root/start.sh

CMD ["/root/start.sh"]
