#!/bin/bash
# push-private.sh — Backup EVERYTHING to private repo (keystone-internal)
# Usage: bash scripts/push-private.sh
# Run after every session to back up all internal files.

set -e

echo "→ Preparing full backup to private repo..."

CURRENT_BRANCH=$(git branch --show-current)

# Create/reset the internal-backup branch from current main
git checkout -B internal-backup

# Force-add all internal files that are excluded from public .gitignore
git add -f docs/v1/tracking/      2>/dev/null || true
git add -f docs/v1/dirc/          2>/dev/null || true
git add -f docs/dirc_log.md       2>/dev/null || true
git add -f AGENTS.md              2>/dev/null || true
git add -f GEMINI.md              2>/dev/null || true
git add -f CONTENT_CALENDAR.md    2>/dev/null || true
git add -f supabase/.temp/        2>/dev/null || true
git add -f query_db.sh            2>/dev/null || true

# Stage all regular tracked changes too
git add -A 2>/dev/null || true

# Commit only if there are staged changes
if ! git diff --staged --quiet; then
  git commit -m "backup: $(date '+%Y-%m-%d %H:%M') — internal sync"
  echo "✓ Changes committed to internal-backup branch."
else
  echo "  No new changes to commit."
fi

# Push internal-backup branch to private repo as main
git push internal internal-backup:main

echo "✓ Private backup complete → github.com/LogiSynthArchitect/keystone-internal"

# Return to original branch
git checkout "$CURRENT_BRANCH"

echo "✓ Back on branch: $CURRENT_BRANCH"
