#!/usr/bin/env bash
# Reproduce the Godot + Android toolchain without changing project dependencies.
set -euo pipefail
cd "$(dirname "$0")/.."
source tools/env.sh
tools_dir=/workspace/.ludo-tools
templates_dir="$XDG_DATA_HOME/godot/export_templates/4.6.3.stable"
mkdir -p "$tools_dir" "$templates_dir"

command -v python3 >/dev/null
command -v curl >/dev/null
command -v unzip >/dev/null
test -x "$JAVA_HOME/bin/java"
if ! command -v godot >/dev/null || [[ "$(godot --version)" != 4.6.3.* ]]; then
  echo 'This workspace requires Godot 4.6.3 and Java 21. Install the pinned Godot release before continuing.' >&2
  exit 1
fi

# Godot's official release digest, verified against its published SHA512-SUMS.txt.
template_sha=da606b61c10157844f8300172df374472665f95015495cb1a7cd132c40ede404faa96cc1016a4b9662db9909ddea69632c4948b2cd11163438dad4808881fb68
if [[ ! -s "$templates_dir/android_debug.apk" || ! -s "$templates_dir/android_release.apk" || ! -s "$templates_dir/linux_release.x86_64" || ! -s "$templates_dir/linux_debug.x86_64" ]]; then
  archive="$tools_dir/templates.tpz"
  if [[ ! -s "$archive" ]]; then
    curl -fL --retry 3 https://github.com/godotengine/godot-builds/releases/download/4.6.3-stable/Godot_v4.6.3-stable_export_templates.tpz -o "$archive"
  fi
  printf '%s  %s\n' "$template_sha" "$archive" | sha512sum -c -
  python3 - "$archive" "$templates_dir" <<'PY'
import sys, zipfile
from pathlib import Path
with zipfile.ZipFile(sys.argv[1]) as archive:
    for name in ['android_debug.apk', 'android_release.apk', 'linux_debug.x86_64', 'linux_release.x86_64']:
        dest = Path(sys.argv[2]) / name
        dest.write_bytes(archive.read('templates/' + name))
PY
fi

if [[ ! -x "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" ]]; then
  archive="$tools_dir/android-tools.zip"
  if [[ ! -s "$archive" ]]; then
    curl -fL --retry 3 https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip -o "$archive"
  fi
  # Official repository2-1.xml SHA1 for Google's command line tools 19.0.
  printf '%s  %s\n' 5fdcc763663eefb86a5b8879697aa6088b041e70 "$archive" | sha1sum -c -
  mkdir -p "$ANDROID_HOME/cmdline-tools"
  unzip -q "$archive" -d "$ANDROID_HOME/cmdline-tools"
  mv "$ANDROID_HOME/cmdline-tools/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
fi
if [[ ! -x "$ANDROID_HOME/build-tools/36.0.0/apksigner" || ! -f "$ANDROID_HOME/platforms/android-36/android.jar" || ! -x "$ANDROID_HOME/platform-tools/adb" ]]; then
  "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" --sdk_root="$ANDROID_HOME" 'platform-tools' 'platforms;android-36' 'build-tools;36.0.0' <<'ANSWERS'
y
y
y
y
y
y
y
y
ANSWERS
fi

# ADB's default key directory is under the account's home. This snapshot retains
# a symlink to the workspace's android-user directory. The SDK itself uses
# ANDROID_USER_HOME above; no HOME or TLS overrides are needed.
godot --headless --path . --editor --import --quit
python3 tools/configure_android.py
tools/test.sh
echo 'Godot project and Android export toolchain are prepared.'
