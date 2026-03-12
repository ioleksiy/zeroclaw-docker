FROM ubuntu:24.04 AS tools

ENV DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        nodejs \
        npm \
        git \
        curl \
        bash \
        openssh-client \
        ca-certificates \
        gh; \
    rm -rf /var/lib/apt/lists/*; \
    npm install -g @anthropic-ai/claude-code; \
    npm cache clean --force

RUN set -eux; \
    mkdir -p /opt/runtime; \
    copy_path() { \
        local src="$1"; \
        local rel; \
        local dst; \
        if [ -e "${src}" ]; then \
            rel="${src#/}"; \
            case "${rel}" in \
                lib/*) rel="usr/${rel}" ;; \
                lib64/*) rel="usr/${rel}" ;; \
            esac; \
            dst="/opt/runtime/${rel}"; \
            mkdir -p "$(dirname "${dst}")"; \
            cp -a "${src}" "${dst}"; \
        fi; \
    }; \
    copy_bin_with_libs() { \
        local bin="$1"; \
        copy_path "${bin}"; \
        ldd "${bin}" | awk '/=> \/|^\// { if ($3 ~ /^\//) print $3; else if ($1 ~ /^\//) print $1 }' | sort -u | while read -r lib; do \
            copy_path "${lib}"; \
        done; \
    }; \
    for bin in \
        /usr/bin/bash \
        /usr/bin/git \
        /usr/bin/gh \
        /usr/bin/curl \
        /usr/bin/ssh \
        /usr/bin/scp \
        /usr/bin/sftp \
        /usr/bin/node \
        /usr/bin/npm \
        /usr/bin/npx; do \
        copy_bin_with_libs "${bin}"; \
    done; \
    copy_path /usr/local/bin/claude; \
    copy_path /usr/local/lib/node_modules; \
    copy_path /usr/lib/node_modules; \
    copy_path /etc/ssl/certs; \
    copy_path /etc/ssh

FROM ghcr.io/zeroclaw-labs/zeroclaw:latest

# Upstream runtime is distroless/non-root. Copy a minimal runtime payload
# containing only selected tools and their shared libraries.
COPY --from=tools /opt/runtime/ /

COPY --chmod=755 entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]