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

ensure_writable_dir "/zeroclaw-data"
ensure_writable_dir "/repos"

if [[ ! -w "/zeroclaw-data" ]]; then
  export HOME="/tmp/zeroclaw-home"
  mkdir -p "${HOME}"
  echo "warning: /zeroclaw-data is not writable; using ${HOME} for git global config" >&2
fi

if [[ -n "${GIT_USER_NAME:-}" || -n "${GIT_USER_EMAIL:-}" ]]; then
  if [[ -n "${GIT_USER_NAME:-}" ]]; then
    git config --global user.name "${GIT_USER_NAME}"
  fi

  if [[ -n "${GIT_USER_EMAIL:-}" ]]; then
    git config --global user.email "${GIT_USER_EMAIL}"
  fi
fi

exec "$@"