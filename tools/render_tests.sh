#!/usr/bin/env bash
# Render UI test screenshots using an existing display, or a private dummy Xorg.
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ -n "${DISPLAY:-}" ]]; then exec tools/test.sh --screenshots; fi
if [[ ! -x /usr/lib/xorg/Xorg || ! -f /usr/lib/xorg/modules/drivers/dummy_drv.so ]]; then
  echo 'A display or Xorg with its dummy driver is required. Use tools/test.sh for headless tests.' >&2
  exit 1
fi
render_dir="$(mktemp -d "${TMPDIR:-/tmp}/ludo-display.XXXXXX")"
display_number=98
while [[ -e "/tmp/.X${display_number}-lock" || -S "/tmp/.X11-unix/X${display_number}" ]]; do
  display_number=$((display_number+1))
done
cat > "$render_dir/xorg.conf" <<'CONF'
Section "ServerFlags"
 Option "AutoAddDevices" "false"
 Option "AutoEnableDevices" "false"
EndSection
Section "Device"
 Identifier "Dummy"
 Driver "dummy"
 VideoRam 256000
EndSection
Section "Monitor"
 Identifier "Monitor"
 HorizSync 5.0-1000.0
 VertRefresh 5.0-200.0
 Modeline "1280x1600" 170.00 1280 1360 1496 1712 1600 1603 1609 1650
EndSection
Section "Screen"
 Identifier "Screen"
 Device "Dummy"
 Monitor "Monitor"
 DefaultDepth 24
 SubSection "Display"
  Depth 24
  Modes "1280x1600"
 EndSubSection
EndSection
CONF
/usr/lib/xorg/Xorg ":$display_number" -noreset -nolisten tcp -config "$render_dir/xorg.conf" -logfile "$render_dir/Xorg.log" > "$render_dir/stdout.log" 2>&1 &
display_pid=$!
trap 'kill "$display_pid" 2>/dev/null || true; rm -rf "$render_dir"' EXIT
export DISPLAY=":$display_number"
for attempt in {1..30}; do
  if xdpyinfo >/dev/null 2>&1; then break; fi
  if ! kill -0 "$display_pid" 2>/dev/null; then cat "$render_dir/stdout.log" >&2; exit 1; fi
  sleep 0.2
done
xdpyinfo >/dev/null
tools/test.sh --screenshots
