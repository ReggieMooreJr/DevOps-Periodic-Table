#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./setup_git_repo.sh [remote-url]
#
# If a remote-url is passed, it will set or update the 'origin' remote.
# If no remote-url is passed, it will use the existing 'origin' (if present).

REMOTE_URL="${1:-}"

########################################
# 0. Ensure we are in (or create) a git repo
########################################

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "No git repo found. Initializing..."
  git init

  # Use 'main' as the default local branch when creating a new repo
  git checkout -b main || git branch -M main

  # Add all files and make an initial commit (if there is anything to commit)
  if [[ -n "$(git status --porcelain)" ]]; then
    git add .
    git commit -m "Initial commit"
  fi
fi

########################################
# 1. Configure origin remote
########################################

HAS_ORIGIN=true
if ! git remote get-url origin >/dev/null 2>&1; then
  HAS_ORIGIN=false
fi

if [[ -n "$REMOTE_URL" ]]; then
  if [[ "$HAS_ORIGIN" == "true" ]]; then
    echo "Updating existing 'origin' to: $REMOTE_URL"
    git remote set-url origin "$REMOTE_URL"
  else
    echo "Adding 'origin' remote: $REMOTE_URL"
    git remote add origin "$REMOTE_URL"
  fi
else
  if [[ "$HAS_ORIGIN" != "true" ]]; then
    echo "Error: no 'origin' remote configured and no remote-url provided."
    echo "Usage: $0 <remote-url>"
    exit 1
  fi
fi

ORIGIN_URL="$(git remote get-url origin)"
echo "Using remote origin: $ORIGIN_URL"

########################################
# 2. Figure out the default branch on origin
########################################

DEFAULT_BRANCH=""

# Try to read origin/HEAD (this usually points to the default branch)
if git rev-parse --abbrev-ref origin/HEAD >/dev/null 2>&1; then
  DEFAULT_BRANCH="$(git rev-parse --abbrev-ref origin/HEAD | sed 's#origin/##')"
fi

# If that didn't work, try common names (main, master)
if [[ -z "$DEFAULT_BRANCH" ]]; then
  for candidate in main master; do
    if git ls-remote --heads origin "$candidate" >/dev/null 2>&1; then
      if [[ -n "$(git ls-remote --heads origin "$candidate")" ]]; then
        DEFAULT_BRANCH="$candidate"
        break
      fi
    fi
  done
fi

# If still unknown (e.g. empty remote), default to 'main'
if [[ -z "$DEFAULT_BRANCH" ]]; then
  DEFAULT_BRANCH="main"
fi

echo "Using default branch: $DEFAULT_BRANCH"

########################################
# 3. Ensure local branch exists and track origin
########################################

# If local branch doesn't exist yet, create it
if ! git show-ref --verify --quiet "refs/heads/$DEFAULT_BRANCH"; then
  echo "Creating local branch '$DEFAULT_BRANCH'"
  git checkout -b "$DEFAULT_BRANCH"
else
  git checkout "$DEFAULT_BRANCH"
fi

########################################
# 4. Sync with origin
########################################

# Fetch latest from origin
git fetch origin

# If the branch exists on origin, rebase on it
if git show-ref --verify --quiet "refs/remotes/origin/$DEFAULT_BRANCH"; then
  git pull --rebase origin "$DEFAULT_BRANCH"
fi

# Push local branch to origin (set upstream if needed)
if ! git rev-parse --abbrev-ref --symbolic-full-name "@{u}" >/dev/null 2>&1; then
  git push -u origin "$DEFAULT_BRANCH"
else
  git push origin "$DEFAULT_BRANCH"
fi

echo "Done: directory is a git repo and '$DEFAULT_BRANCH' is synced with origin/$DEFAULT_BRANCH."

