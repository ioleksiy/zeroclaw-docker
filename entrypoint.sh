#!/bin/bash
set -e

log_identity_debug() {
  local exit_code="$?"
  local line_no="${1:-unknown}"

  echo "entrypoint error: failed at line ${line_no} (exit ${exit_code})" >&2
  echo "identity debug: available users (name uid gid home shell):" >&2
  getent passwd | awk -F: '{ printf "  %s uid=%s gid=%s home=%s shell=%s\n", $1, $3, $4, $6, $7 }' >&2 || true

  echo "identity debug: available groups (name gid):" >&2
  getent group | awk -F: '{ printf "  %s gid=%s\n", $1, $3 }' >&2 || true

  echo "hint: set ZEROCLAW_UID and ZEROCLAW_GID to a valid pair, for example:" >&2
  echo "  -e ZEROCLAW_UID=65534 -e ZEROCLAW_GID=65534" >&2
}

trap 'log_identity_debug ${LINENO}' ERR

TARGET_UID="${ZEROCLAW_UID:-65534}"
TARGET_GID="${ZEROCLAW_GID:-65534}"

mkdir -p /zeroclaw-data /repos

# Named volumes are created as root:root; fix ownership before dropping privileges.
chown -R "${TARGET_UID}:${TARGET_GID}" /zeroclaw-data 2>/dev/null || true
chown -R "${TARGET_UID}:${TARGET_GID}" /repos 2>/dev/null || true

PASSWD_HOME="$(getent passwd "${TARGET_UID}" | cut -d: -f6 || true)"
if [ -n "${PASSWD_HOME}" ] && [ "${PASSWD_HOME}" != "/nonexistent" ]; then
  HOME_DIR="${PASSWD_HOME}"
else
  HOME_DIR="/zeroclaw-data"
fi

mkdir -p "${HOME_DIR}"
chown -R "${TARGET_UID}:${TARGET_GID}" "${HOME_DIR}" 2>/dev/null || true

if [ -n "${GIT_USER_NAME:-}" ]; then
  env HOME="${HOME_DIR}" gosu "${TARGET_UID}:${TARGET_GID}" git config --global user.name "${GIT_USER_NAME}"
fi
if [ -n "${GIT_USER_EMAIL:-}" ]; then
  env HOME="${HOME_DIR}" gosu "${TARGET_UID}:${TARGET_GID}" git config --global user.email "${GIT_USER_EMAIL}"
fi

exec env HOME="${HOME_DIR}" gosu "${TARGET_UID}:${TARGET_GID}" "$@"