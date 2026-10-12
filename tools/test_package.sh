#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd "$(dirname "$0")/.." && pwd)"
source "$project_dir/tools/env.sh"
package_dir="$(mktemp -d "${TMPDIR:-/tmp}/ludo-package.XXXXXX")"
trap 'rm -rf "$package_dir"' EXIT
cd "$package_dir"
# An empty working directory prevents missing packaged files from being
# accidentally supplied by the development checkout.
export XDG_DATA_HOME="$package_dir/data"
export XDG_CACHE_HOME="$package_dir/cache"
mkdir -p "$XDG_DATA_HOME" "$XDG_CACHE_HOME"
result=0
godot --headless --main-pack "$project_dir/build/ludo-lane.x86_64" --script "$project_dir/tests/test_package.gd" > "$package_dir/result.log" 2>&1 || result=$?
cat "$package_dir/result.log"
if (( result != 0 )); then exit "$result"; fi
if grep -Eq 'SCRIPT ERROR:|ERROR:|[1-9][0-9]* failures' "$package_dir/result.log"; then exit 1; fi
"$project_dir/build/ludo-lane.x86_64" --headless --quit-after 5
