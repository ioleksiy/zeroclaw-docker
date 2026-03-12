#!/bin/bash
set -e

TARGET_UID="${ZEROCLAW_UID:-65534}"
TARGET_GID="${ZEROCLAW_GID:-65534}"

mkdir -p /zeroclaw-data /repos

# Named volumes are created as root:root; fix ownership before dropping privileges.
chown -R "${TARGET_UID}:${TARGET_GID}" /zeroclaw-data 2>/dev/null || true
chown -R "${TARGET_UID}:${TARGET_GID}" /repos 2>/dev/null || true

HOME_DIR="$(getent passwd "${TARGET_UID}" | cut -d: -f6 || true)"
if [ -n "${HOME_DIR}" ] && [ -d "${HOME_DIR}" ]; then
  chown -R "${TARGET_UID}:${TARGET_GID}" "${HOME_DIR}" 2>/dev/null || true
fi

if [ -n "${GIT_USER_NAME:-}" ]; then
  gosu "${TARGET_UID}:${TARGET_GID}" git config --global user.name "${GIT_USER_NAME}"
fi
if [ -n "${GIT_USER_EMAIL:-}" ]; then
  gosu "${TARGET_UID}:${TARGET_GID}" git config --global user.email "${GIT_USER_EMAIL}"
fi

exec gosu "${TARGET_UID}:${TARGET_GID}" "$@"