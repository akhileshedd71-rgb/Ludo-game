#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source tools/env.sh
mkdir -p build
godot --headless --path . --editor --import --quit
python3 tools/configure_android.py
godot --headless --path . --export-debug Android build/ludo-lane-debug.apk
"$ANDROID_HOME/build-tools/36.0.0/apksigner" verify --verbose build/ludo-lane-debug.apk
"$ANDROID_HOME/build-tools/36.0.0/zipalign" -c -P 16 -v 4 build/ludo-lane-debug.apk > build/android-alignment.log
echo "Verified Android debug package: build/ludo-lane-debug.apk"
