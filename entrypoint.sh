#!/bin/bash
set -e

log_identity_debug() {
  local exit_code="$?"
  local line_no="${1:-unknown}"
  local name=""
  local _x=""
  local uid=""
  local gid=""
  local home=""
  local shell=""

  echo "entrypoint error: failed at line ${line_no} (exit ${exit_code})" >&2
  echo "identity debug: available users (name uid gid home shell):" >&2
  while IFS=: read -r name _x uid gid _x home shell; do
    echo "  ${name} uid=${uid} gid=${gid} home=${home} shell=${shell}" >&2
  done < <(getent passwd || true)

  echo "identity debug: available groups (name gid):" >&2
  while IFS=: read -r name _x gid _x; do
    echo "  ${name} gid=${gid}" >&2
  done < <(getent group || true)

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
GIT_CONFIG_GLOBAL_PATH="${HOME_DIR}/.gitconfig"

if [ -n "${GIT_USER_NAME:-}" ]; then
  HOME="${HOME_DIR}" GIT_CONFIG_GLOBAL="${GIT_CONFIG_GLOBAL_PATH}" gosu "${TARGET_UID}:${TARGET_GID}" git config --global user.name "${GIT_USER_NAME}"
fi
if [ -n "${GIT_USER_EMAIL:-}" ]; then
  HOME="${HOME_DIR}" GIT_CONFIG_GLOBAL="${GIT_CONFIG_GLOBAL_PATH}" gosu "${TARGET_UID}:${TARGET_GID}" git config --global user.email "${GIT_USER_EMAIL}"
fi

export HOME="${HOME_DIR}"
exec gosu "${TARGET_UID}:${TARGET_GID}" "$@"