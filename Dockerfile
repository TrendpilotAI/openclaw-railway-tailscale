# Build openclaw from source to avoid npm packaging gaps (some dist files are not shipped).
FROM node:22-bookworm AS openclaw-build

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    git ca-certificates curl python3 make g++ \
  && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

RUN corepack enable

WORKDIR /openclaw

ARG OPENCLAW_GIT_REF=v2026.2.19
RUN git clone --depth 1 --branch "${OPENCLAW_GIT_REF}" https://github.com/openclaw/openclaw.git .

RUN set -eux; \
  find ./extensions -name 'package.json' -type f | while read -r f; do \
    sed -i -E 's/"openclaw"[[:space:]]*:[[:space:]]*">=[^"]+"/"openclaw": "*"/g' "$f"; \
    sed -i -E 's/"openclaw"[[:space:]]*:[[:space:]]*"workspace:[^"]+"/"openclaw": "*"/g' "$f"; \
  done

RUN pnpm install --no-frozen-lockfile
RUN pnpm build
ENV OPENCLAW_PREFER_PNPM=1
RUN pnpm ui:install && pnpm ui:build


# Runtime image
FROM node:22-bookworm
ENV NODE_ENV=production

# Install system deps + Tailscale in a single layer for reliability
RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates curl build-essential gcc g++ make procps file git \
    python3 python3-pip pkg-config sudo iptables iproute2 dnsutils \
  && curl -fsSL https://tailscale.com/install.sh | sh \
  && rm -rf /var/lib/apt/lists/*

# Install Homebrew
RUN useradd -m -s /bin/bash linuxbrew \
  && echo 'linuxbrew ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER linuxbrew
RUN NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
USER root
RUN chown -R root:root /home/linuxbrew/.linuxbrew
ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"

WORKDIR /app

RUN corepack enable
COPY package.json pnpm-lock.yaml* ./
RUN pnpm install --prod || npm install --omit=dev

# Copy built openclaw
COPY --from=openclaw-build /openclaw /openclaw

RUN printf '%s\n' '#!/usr/bin/env bash' 'exec node /openclaw/dist/entry.js "$@"' > /usr/local/bin/openclaw \
  && chmod +x /usr/local/bin/openclaw

# Update npm, install CLI tools: yt-dlp (YouTube transcripts),
# Composio Rube MCP server (500+ SaaS integrations), Modal (serverless GPU)
RUN npm install -g npm@11 @composio/rube-mcp \
  && curl -fsSL https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp \
  && chmod +x /usr/local/bin/yt-dlp \
  && pip3 install --break-system-packages modal

# Clone /last30days research skill
RUN git clone --depth 1 https://github.com/mvanhorn/last30days-skill.git /root/.claude/skills/last30days

# Force fresh build — v2026.02.19
RUN echo "build-v3"
COPY src ./src
COPY workspace ./workspace
COPY scripts ./scripts
COPY start.sh ./start.sh
RUN chmod +x /app/start.sh /app/scripts/*.sh

# Create tailscale state directory
RUN mkdir -p /data/tailscale

ENV PORT=8080
EXPOSE 8080
CMD ["/app/start.sh"]
