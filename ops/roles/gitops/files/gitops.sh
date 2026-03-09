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

fail() {
  log "Error: $1"
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

export -f log fail cronjob

FORCE_UPDATE=0
while [ $# -gt 0 ] && [[ "$1" == --* ]]; do
  case "$1" in
    --force-update)
      FORCE_UPDATE=1
      shift
      ;;
    --help|-h)
      log "Usage: $0 [--force-update] <destination> <path in repository>"
      exit 0
      ;;
    *)
      fail "Unknown option: $1"
      ;;
  esac
done

DESTINATION="${1}"
REPOSITORY_PATH="${2}"

if [ -z "$DESTINATION" ] || [ -z "$REPOSITORY_PATH" ]; then
  fail "Usage: $0 <destination> <path in repository>"
fi

if [ ! -d "$DESTINATION" ]; then
  fail "Destination directory $DESTINATION does not exist."
fi
if [ ! -d "$DESTINATION/repository/.git" ]; then
  fail "Destination directory $DESTINATION/repository is not a git repository."
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

if [ "$has_git_changes" -eq 1 ] || [ "$FORCE_UPDATE" -eq 1 ]; then
  hook "pre-pull"
  if [ "$has_git_changes" -eq 1 ]; then
    log "Updating resources in $DESTINATION (local: $local_rev remote: $remote_rev)"
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
  fi
  hook "post-update"

  echo $(date +%s) > "$DESTINATION/last-update"
else
  log "No changes detected in $DESTINATION. Skipping update."
  hook "no-update"
fi

hook "after"

