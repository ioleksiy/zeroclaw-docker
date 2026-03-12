#!/bin/bash
set -e

wait_for_manual_fix() {
  echo "startup blocked: this container is running as non-root and needs writable mounts." >&2
  echo "required writable paths: /zeroclaw-data and /repos" >&2
  echo "fix volume ownership/permissions, then restart the container." >&2
  echo "container will stay running for troubleshooting (attach with docker exec)." >&2
  while true; do
    sleep 3600
  done
}

is_writable_dir() {
  local dir="$1"
  local probe="${dir}/.write-probe-$$"

  if [ ! -d "${dir}" ]; then
    return 1
  fi

  if [ ! -w "${dir}" ]; then
    return 1
  fi

  : > "${probe}" 2>/dev/null || return 1
  rm -f "${probe}" 2>/dev/null || true
  return 0
}

if ! is_writable_dir "/zeroclaw-data" || ! is_writable_dir "/repos"; then
  echo "permission error: unable to write to one or more required mount points." >&2
  id >&2 || true
  ls -ld /zeroclaw-data /repos >&2 || true
  wait_for_manual_fix
fi

if [ "${HOME:-}" = "" ] || [ "${HOME}" = "/nonexistent" ]; then
  export HOME="/zeroclaw-data"
fi

if [ -n "${GIT_USER_NAME:-}" ]; then
  git config --global user.name "${GIT_USER_NAME}" || true
fi
if [ -n "${GIT_USER_EMAIL:-}" ]; then
  git config --global user.email "${GIT_USER_EMAIL}" || true
fi

if [ "$#" -eq 0 ]; then
  set -- gateway
fi

if command -v "$1" >/dev/null 2>&1; then
  exec "$@"
fi

if command -v zeroclaw >/dev/null 2>&1; then
  exec zeroclaw "$@"
fi

echo "startup error: cannot resolve command '$1' and zeroclaw is unavailable in PATH" >&2
wait_for_manual_fix