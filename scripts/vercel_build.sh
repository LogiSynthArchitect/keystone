#!/bin/bash
set -e

echo "→ Installing Flutter (stable)..."
git clone https://github.com/flutter/flutter.git --depth 1 -b stable /tmp/flutter
export PATH="$PATH:/tmp/flutter/bin"

echo "→ Pre-caching web tools..."
flutter precache --web

echo "→ Installing dependencies..."
flutter pub get

echo "→ Building for web (HTML renderer)..."
flutter build web --web-renderer html --release

echo "✓ Build complete."
