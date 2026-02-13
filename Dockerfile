FROM node:22-bookworm

# Install Tailscale
RUN curl -fsSL https://tailscale.com/install.sh | sh

# Install app dependencies
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install --production

COPY src/ ./src/
COPY start.sh ./start.sh
RUN chmod +x /app/start.sh

ENV PORT=8080
ENV OPENCLAW_STATE_DIR=/data/.openclaw
ENV OPENCLAW_WORKSPACE_DIR=/data/workspace

EXPOSE 8080

CMD ["/app/start.sh"]
