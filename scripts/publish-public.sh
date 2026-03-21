#!/bin/bash
# publish-public.sh — Publish clean portfolio version to public repo (keystone)
# Usage: bash scripts/publish-public.sh
# Only run when work is ready to be seen publicly.

set -e

echo "→ Running pre-publish checks..."

# 1. Verify no sensitive files are staged
SENSITIVE=$(git ls-files | grep -E "(AGENTS|GEMINI|tracking/|dirc_log|CONTENT_CALENDAR|query_db|\.temp)" || true)
if [ -n "$SENSITIVE" ]; then
  echo ""
  echo "❌ STOP — Sensitive files are tracked in git:"
  echo "$SENSITIVE"
  echo ""
  echo "Run: git rm --cached <file> for each, then retry."
  exit 1
fi

# 2. Check flutter analyze
echo "→ Running flutter analyze..."
if ! flutter analyze --no-fatal-infos > /dev/null 2>&1; then
  echo "❌ flutter analyze failed. Fix issues before publishing."
  flutter analyze --no-fatal-infos
  exit 1
fi

# 3. Check flutter test
echo "→ Running flutter test..."
if ! flutter test > /dev/null 2>&1; then
  echo "❌ flutter test failed. Fix failing tests before publishing."
  flutter test
  exit 1
fi

# 4. Push to public repo
echo "→ Publishing to public repo..."
git push origin main

echo ""
echo "✓ Public portfolio updated → https://github.com/LogiSynthArchitect/keystone"
echo "  Check: https://github.com/LogiSynthArchitect/keystone"
