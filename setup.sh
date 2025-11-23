#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./setup.sh [remote-url]
#
# If a remote-url is passed, it sets/updates origin and syncs.
# If no remote-url is passed, it initializes a repo and exits cleanly.

REMOTE_URL="${1:-}"

########################################
# 0. Ensure repo exists
########################################

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "No git repo found. Initializing..."
  git init

  # Default new repo to 'main'
  git checkout -b main || git branch -M main

  # Commit initial content if needed
  if [[ -n "$(git status --porcelain)" ]]; then
    git add .
    git commit -m "Initial commit"
  fi
fi

########################################
# 1. If NO remote provided AND origin missing → exit cleanly
########################################

if [[ -z "$REMOTE_URL" ]] && ! git remote get-url origin >/dev/null 2>&1; then
  echo "No remote provided and no origin remote exists. Repo initialized locally."
  exit 0
fi

########################################
# 2. Configure origin remote
########################################

if [[ -n "$REMOTE_URL" ]]; then
  if git remote get-url origin >/dev/null 2>&1; then
    echo "Updating existing origin → $REMOTE_URL"
    git remote set-url origin "$REMOTE_URL"
  else
    echo "Setting origin → $REMOTE_URL"
    git remote add origin "$REMOTE_URL"
  fi
fi

echo "Using origin: $(git remote get-url origin)"

########################################
# 3. Detect remote default branch
########################################

DEFAULT_BRANCH=""

# Try origin/HEAD reference
if git rev-parse --abbrev-ref origin/HEAD >/dev/null 2>&1; then
  DEFAULT_BRANCH="$(git rev-parse --abbrev-ref origin/HEAD | sed 's#origin/##')"
fi

# Fall back to common branch names
if [[ -z "$DEFAULT_BRANCH" ]]; then
  for b in main master; do
    if git ls-remote --heads origin "$b" | grep -q "$b"; then
      DEFAULT_BRANCH="$b"
      break
    fi
  done
fi

# Final fallback if remote is empty
[[ -z "$DEFAULT_BRANCH" ]] && DEFAULT_BRANCH="main"

echo "Using branch: $DEFAULT_BRANCH"

########################################
# 4. Ensure the local branch exists
########################################

if git show-ref --verify --quiet "refs/heads/$DEFAULT_BRANCH"; then
  git checkout "$DEFAULT_BRANCH"
else
  git checkout -b "$DEFAULT_BRANCH"
fi

########################################
# 5. Sync with remote (if branch exists remotely)
########################################

git fetch origin || true

if git show-ref --verify --quiet "refs/remotes/origin/$DEFAULT_BRANCH"; then
  git pull --rebase origin "$DEFAULT_BRANCH"
fi

# Push (set upstream if new)
git push -u origin "$DEFAULT_BRANCH"

echo "Repo synced successfully!"

