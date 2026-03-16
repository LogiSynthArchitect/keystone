#!/bin/bash
# Build Keystone release APK with credentials from .env
# Usage: bash scripts/build_apk.sh

set -a
source .env
set +a

flutter build apk --release \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY

echo "APK built at build/app/outputs/flutter-apk/app-release.apk"
