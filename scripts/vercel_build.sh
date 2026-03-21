#!/bin/bash
set -e

echo "→ Installing Flutter (stable)..."
git clone https://github.com/flutter/flutter.git --depth 1 -b stable /tmp/flutter
export PATH="$PATH:/tmp/flutter/bin"

echo "→ Pre-caching web tools..."
flutter precache --web

echo "→ Installing dependencies..."
flutter pub get

echo "→ Building for web..."
flutter build web --target lib/main_web.dart --release \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY

echo "✓ Build complete."
