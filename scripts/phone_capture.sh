#!/bin/bash
# Continuously capture phone screenshots
SCREEN_DIR="/home/cybocrime/workspace/phone-view"
mkdir -p "$SCREEN_DIR"
while true; do
  adb exec-out screencap -p > "$SCREEN_DIR/screen.png" 2>/dev/null
  sleep 1
done