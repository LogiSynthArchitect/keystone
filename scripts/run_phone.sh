#!/bin/bash
# Run Keystone on connected phone via wireless ADB with production credentials
# Usage: bash scripts/run_phone.sh
# Requires: ADB connected, Doppler CLI configured with keystone project (prd config)
#
# IMPORTANT: Uses bash -c pattern so $SUPABASE_URL et al expand INSIDE doppler's
# injected environment. Without bash -c, variables expand in the OUTER shell
# before doppler injects real values — causing Blind Bridge masked placeholders
# (mask_keystone_supabase_url) to leak through instead of real URLs.

set -e
export ANDROID_HOME=/home/cybocrime/Tools/android-sdk
export FLUTTER_ROOT=/home/cybocrime/Tools/flutter

# Auto-detect connected Android device (prefer wireless, fallback to USB)
DEVICE_ID=$(adb devices | awk 'NR>1 && $2=="device" {print $1; exit}')
if [ -z "$DEVICE_ID" ]; then
  echo "ERROR: No Android device connected via ADB"
  exit 1
fi
echo "→ Using device: $DEVICE_ID"
export DEVICE_ID

doppler run --project keystone --config prd -- bash -c '
  export ANDROID_HOME=/home/cybocrime/Tools/android-sdk
  /home/cybocrime/Tools/flutter/bin/flutter run -d $DEVICE_ID \
    --dart-define=SUPABASE_URL=$SUPABASE_URL \
    --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
    --dart-define=CLOUDINARY_NAME=$CLOUDINARY_NAME \
    --dart-define=CLOUDINARY_API_KEY=$CLOUDINARY_API_KEY \
    --dart-define=CLOUDINARY_API_SECRET=$CLOUDINARY_API_SECRET
'
