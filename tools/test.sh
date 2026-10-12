#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT_BIN="${GODOT_BIN:-godot}"
test_data="$(mktemp -d "${TMPDIR:-/tmp}/ludo-tests.XXXXXX")"
trap 'rm -rf "$test_data"' EXIT
export XDG_DATA_HOME="$test_data/data"
export XDG_CONFIG_HOME="$test_data/config"
export XDG_CACHE_HOME="$test_data/cache"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"

# Godot may return zero on a script error; inspect its diagnostics as well.
run_checked() {
  local result=0
  "$@" > "$test_data/run.log" 2>&1 || result=$?
  cat "$test_data/run.log"
  if (( result != 0 )); then return "$result"; fi
  if grep -Eq 'SCRIPT ERROR:|ERROR:|[1-9][0-9]* failures' "$test_data/run.log"; then return 1; fi
}
run_checked "$GODOT_BIN" --headless --path . --editor --import --quit
run_checked "$GODOT_BIN" --headless --path . --script res://tests/test_rules.gd
if [[ "${1:-}" == "--screenshots" ]]; then
  run_checked "$GODOT_BIN" --path . --resolution 720x1280 --audio-driver Dummy --script res://tests/test_ui.gd -- --screenshots
else
  run_checked "$GODOT_BIN" --headless --path . --script res://tests/test_ui.gd
fi
