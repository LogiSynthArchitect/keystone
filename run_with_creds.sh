#!/bin/bash
# Keystone Flutter Run Script with Credentials
# This script uses cred_use to inject credentials safely

cd /home/cybocrime/workspace/projects/keystone

# Get credentials via blind bridge and run flutter
bash ~/.config/opencode/scripts/cred_use keystone.SUPABASE_URL \
  "bash ~/.config/opencode/scripts/cred_use keystone.SUPABASE_ANON_KEY \
    '/home/cybocrime/Tools/flutter/bin/flutter run \\
      --device-id 192.168.69.15:5555 \\
      --dart-define=DEV_MODE=true \\
      --dart-define=SUPABASE_URL=\\\$CRED \\
      --dart-define=SUPABASE_ANON_KEY=\\\$CRED \\
      -t lib/main.dart'"
