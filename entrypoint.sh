#!/usr/bin/bash
set -eu

wait_for_manual_fix() {
  echo "startup blocked: this container is running as non-root and needs writable mounts." >&2
  echo "required writable paths: /zeroclaw-data and /repos" >&2
  echo "fix volume ownership/permissions, then restart the container." >&2
  echo "container will stay running for troubleshooting (attach with docker exec)." >&2
  while :; do
    read -r -t 3600 _ || true
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

apply_git_config() {
  local key="$1"
  local value="$2"

  if [ -z "${value}" ]; then
    return 0
  fi

  git config --global "${key}" "${value}" || true
}

if ! is_writable_dir "/zeroclaw-data" || ! is_writable_dir "/repos"; then
  echo "permission error: unable to write to one or more required mount points." >&2
  wait_for_manual_fix
fi

if [ "${HOME:-}" = "" ] || [ "${HOME}" = "/nonexistent" ]; then
  export HOME="/zeroclaw-data"
fi

apply_git_config user.name "${GIT_USER_NAME:-}"
apply_git_config user.email "${GIT_USER_EMAIL:-}"
apply_git_config user.signingkey "${GIT_SIGNING_KEY:-}"
apply_git_config init.defaultBranch "${GIT_DEFAULT_BRANCH:-}"
apply_git_config pull.rebase "${GIT_PULL_REBASE:-}"
apply_git_config core.autocrlf "${GIT_AUTOCRLF:-}"
apply_git_config push.autoSetupRemote "${GIT_PUSH_AUTO_SETUP_REMOTE:-}"

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