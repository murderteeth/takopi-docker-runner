FROM node:24-bookworm

ENV DEBIAN_FRONTEND=noninteractive
ENV UV_PYTHON_INSTALL_DIR=/opt/uv/python
ENV UV_TOOL_DIR=/opt/uv/tools
ENV UV_TOOL_BIN_DIR=/usr/local/bin
ENV PATH="/home/takopi/.local/bin:/usr/local/bin:${PATH}"

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        curl \
        gh \
        git \
        nano \
        openssh-client \
        ripgrep \
        tini \
    && rm -rf /var/lib/apt/lists/*

RUN corepack enable \
    && corepack prepare pnpm@11.3.0 --activate

RUN groupmod --new-name takopi node \
    && usermod --login takopi --home /home/takopi --move-home --shell /bin/bash node \
    && mkdir -p /workspace /opt/uv/python /opt/uv/tools \
    && chown -R takopi:takopi /workspace /opt/uv

RUN uv python install 3.14 \
    && uv tool install --python 3.14 takopi \
    && npm install -g \
        @openai/codex \
        @anthropic-ai/claude-code \
        opencode-ai@latest \
        @mariozechner/pi-coding-agent \
    && npm cache clean --force

USER takopi
WORKDIR /workspace

ENTRYPOINT ["tini", "--"]
CMD ["takopi"]
