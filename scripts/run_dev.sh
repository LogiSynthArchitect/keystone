#!/bin/bash
# Run Keystone in debug mode with credentials from .env
# Usage: bash scripts/run_dev.sh

set -a
source .env
set +a

flutter run \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
