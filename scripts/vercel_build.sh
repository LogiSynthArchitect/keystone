#!/bin/bash
set -e

echo "Building Keystone for web with HTML renderer..."
flutter build web --web-renderer html --release

echo "✓ Build complete. Service worker and fonts optimized."
