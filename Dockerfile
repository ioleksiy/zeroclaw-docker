FROM debian:bookworm-slim AS tools

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
        gnupg \
        gh; \
    rm -rf /var/lib/apt/lists/*; \
    npm install -g @anthropic-ai/claude-code

FROM ghcr.io/zeroclaw-labs/zeroclaw:latest

# The base image has no /bin/sh, so tools are installed in a builder stage and
# copied in directly.
COPY --from=tools /usr/bin/ /usr/bin/
COPY --from=tools /usr/lib/ /usr/lib/
COPY --from=tools /usr/local/ /usr/local/
COPY --from=tools /usr/share/ /usr/share/
COPY --from=tools /lib/ /lib/
COPY --from=tools /lib64/ /lib64/
COPY --from=tools /etc/ssl/ /etc/ssl/
COPY --from=tools /etc/ssh/ /etc/ssh/
COPY --from=tools /etc/bash.bashrc /etc/bash.bashrc
COPY --from=tools /bin/bash /bin/bash

COPY --chmod=755 entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]