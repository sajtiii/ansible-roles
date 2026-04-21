#!/bin/bash
#
# Ansible managed
#

# This script updates resources defined in the gitops repository.
# Should be scheduled using cron.

starting_dir=$(pwd)
trap 'cd "$starting_dir"' EXIT

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')][${DESTINATION:-GEN}] - $1"
}

notify_discord() {
  local message="$1"
  if [ -z "${DISCORD_WEBHOOK_URL:-}" ]; then
    return 0
  fi

  local hostname
  hostname=$(hostname)
  local timestamp
  timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

  local payload
  payload=$(jq -n \
    --arg title ":x: GitOps failure on \`${hostname}\`" \
    --arg host "\`${hostname}\`" \
    --arg dest "\`${DESTINATION:-unknown}\`" \
    --arg error "\`\`\`${message}\`\`\`" \
    --arg ts "$timestamp" \
    '{embeds: [{title: $title, color: 15158332, fields: [
      {name: "Host", value: $host, inline: true},
      {name: "Destination", value: $dest, inline: true},
      {name: "Error", value: $error}
    ], timestamp: $ts}]}')

  curl -s -o /dev/null -X POST "$DISCORD_WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -d "$payload"
}

fail() {
  log "Error: $1"
  notify_discord "$1"
  exit 1
}

# Updates or creates a cron job to run this script periodically.
cronjob() {
  if [ $# -ne 2 ]; then
    fail "Two arguments required for this call: $1 <name> <cron_definition>"
  fi

  local name="$1"
  local cron_definition="$2"
  local cron_entry="$cron_definition #//$name//"

  if ! crontab -l | grep -q "$name"; then
    (crontab -l 2>/dev/null; echo "$cron_entry") | crontab -
    log "Added cron job: $name"
  else
    log "Cron job $name already exists. Updating it if changed."
    if ! crontab -l | grep -qF "$cron_entry"; then
      (crontab -l | grep -v "$name"; echo "$cron_entry") | crontab -
      log "Updated cron job: $name"
    else
      log "Cron job $name is already up to date."
      return
    fi
  fi
}

hook() {
  if [ -f "$DESTINATION/repository/hooks/$1.sh" ]; then
    log "Running git hook: $1"
    source "$DESTINATION/repository/hooks/$1.sh" || fail "Git hook $1 failed."
  fi
}

export -f log fail notify_discord cronjob

DESTINATION="$(cd "$(dirname "$0")" && pwd)"
FORCE_UPDATE=0
while [ $# -gt 0 ] && [[ "$1" == --* ]]; do
  case "$1" in
    --force-update)
      FORCE_UPDATE=1
      shift
      ;;
    --help|-h)
      log "Usage: $0 [--force-update] [path in repository]"
      exit 0
      ;;
    *)
      fail "Unknown option: $1"
      ;;
  esac
done

REPOSITORY_PATH="${1:-/}"

if [ ! -d "$DESTINATION/repository/.git" ]; then
  fail "Destination directory $DESTINATION/repository is not a git repository."
fi

if [ -f "$DESTINATION/gitops.conf" ]; then
  # shellcheck source=/dev/null
  . "$DESTINATION/gitops.conf"
fi

has_env_changes=0
envs_hash=""
if [ -f "$DESTINATION/envs.sh" ]; then
  log "Sourcing environment from $DESTINATION/envs.sh"
  _env_before=$(env | sort)
  # shellcheck source=/dev/null
  . "$DESTINATION/envs.sh" || fail "${ENVS_ERROR:-Failed to source environment file: $DESTINATION/envs.sh}"
  envs_hash=$(comm -13 <(echo "$_env_before") <(env | sort) | sha256sum | cut -d' ' -f1)
  unset _env_before
  stored_envs_hash=$(cat "$DESTINATION/last-envs-hash" 2>/dev/null || echo "")
  if [ "$envs_hash" != "$stored_envs_hash" ]; then
    has_env_changes=1
    log "Environment change detected."
  fi
fi

cd "$DESTINATION/repository" || fail "Failed to change directory to $DESTINATION"

hook "before"

git fetch --all --prune --tags || fail "Failed to fetch from remote repository."
echo $(date +%s) > "$DESTINATION/last-fetch"

# Determine current branch and remote ref to compare
current_branch=$(git rev-parse --abbrev-ref HEAD) || fail "Failed to determine current branch."
remote_ref="origin/$current_branch"
if ! git show-ref --verify --quiet "refs/remotes/$remote_ref"; then
  # Fallback to origin/main if branch remote not found
  remote_ref="origin/main"
fi

local_rev=$(git rev-parse --verify HEAD) || fail "Failed to get local revision."
remote_rev=$(git rev-parse --verify "$remote_ref" 2>/dev/null) || true
has_git_changes=0
if [ -z "$remote_rev" ] || [ "$local_rev" != "$remote_rev" ]; then
  has_git_changes=1
fi

if [ "$has_git_changes" -eq 1 ] || [ "$has_env_changes" -eq 1 ] || [ "$FORCE_UPDATE" -eq 1 ]; then
  hook "pre-pull"
  if [ "$has_git_changes" -eq 1 ]; then
    log "Git changes detected, pulling (local: $local_rev remote: $remote_rev)"
    # Reset local branch to remote, remove any local modifications/untracked files,
    # and ensure submodules follow the repository state.
    git reset --hard "$remote_ref" || fail "Failed to reset to $remote_ref."
    git clean -fdx || fail "Failed to remove untracked files."
    git pull --rebase --recurse-submodules || fail "Failed to pull latest changes."
    git submodule sync --recursive || fail "Failed to sync submodules."
    git submodule update --init --recursive --force || fail "Failed to update submodules."
  fi
  hook "post-pull"

  if [ ! -d "$DESTINATION/repository/$REPOSITORY_PATH" ]; then
    fail "Path $DESTINATION/$REPOSITORY_PATH does not exist in the repository."
  fi

  cd "$DESTINATION/repository/$REPOSITORY_PATH" || fail "Failed to change directory to $DESTINATION/$REPOSITORY_PATH"

  hook "pre-update"
  if [ -f "update.sh" ]; then
    log "Running update.sh in ${DESTINATION}${REPOSITORY_PATH}"
    ./update.sh || fail "Failed to run update.sh."
  else
    log "No update.sh found in ${DESTINATION}${REPOSITORY_PATH}, nothing to run."
  fi
  hook "post-update"

  [ -n "${envs_hash:-}" ] && echo "$envs_hash" > "$DESTINATION/last-envs-hash"
  echo $(date +%s) > "$DESTINATION/last-update"
  log "Update complete."
else
  log "No changes detected in $DESTINATION. Skipping update."
  hook "no-update"
fi

hook "after"

