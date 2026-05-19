#!/bin/bash
# Build Keystone release APK with credentials from Doppler
# Usage: bash scripts/build_apk.sh
# Requires: Doppler CLI configured with keystone project (prd config)

doppler run -- flutter build apk --release \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
  --dart-define=CLOUDINARY_NAME=$CLOUDINARY_NAME \
  --dart-define=CLOUDINARY_API_KEY=$CLOUDINARY_API_KEY \
  --dart-define=CLOUDINARY_API_SECRET=$CLOUDINARY_API_SECRET

echo "APK built at build/app/outputs/flutter-apk/app-release.apk"
