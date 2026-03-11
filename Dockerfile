FROM ghcr.io/zeroclaw-labs/zeroclaw:latest

RUN set -eux; \
    . /etc/os-release; \
    if [ "${ID}" = "alpine" ] || echo "${ID_LIKE:-}" | grep -qi alpine; then \
        apk add --no-cache \
            nodejs \
            npm \
            git \
            curl \
            bash \
            openssh-client \
            github-cli; \
    else \
        apt-get update; \
        apt-get install -y --no-install-recommends \
            nodejs \
            npm \
            git \
            curl \
            bash \
            openssh-client \
            ca-certificates \
            gnupg; \
        if ! apt-get install -y --no-install-recommends github-cli; then \
            apt-get install -y --no-install-recommends gh; \
        fi; \
        rm -rf /var/lib/apt/lists/*; \
    fi; \
    npm install -g @anthropic-ai/claude-code

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]