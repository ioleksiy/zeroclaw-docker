#!/usr/bin/env bash
set -euo pipefail

ensure_writable_dir() {
  local dir="$1"

  if [[ ! -d "${dir}" ]]; then
    return 0
  fi

  if [[ -w "${dir}" ]]; then
    return 0
  fi

  # In Swarm/Portainer, fresh named volumes are often root-owned.
  # If we are root, relax ownership/permissions so the app can write.
  if [[ "$(id -u)" -eq 0 ]]; then
    chmod -R a+rwX "${dir}" 2>/dev/null || true
  fi
}

require_writable_dir() {
  local dir="$1"

  ensure_writable_dir "${dir}"

  if [[ ! -w "${dir}" ]]; then
    echo "error: ${dir} is not writable; waiting for volume permissions init" >&2
    exit 1
  fi
}

require_writable_dir "/zeroclaw-data"
require_writable_dir "/repos"

if [[ -n "${GIT_USER_NAME:-}" || -n "${GIT_USER_EMAIL:-}" ]]; then
  if [[ -n "${GIT_USER_NAME:-}" ]]; then
    git config --global user.name "${GIT_USER_NAME}"
  fi

  if [[ -n "${GIT_USER_EMAIL:-}" ]]; then
    git config --global user.email "${GIT_USER_EMAIL}"
  fi
fi

exec "$@"