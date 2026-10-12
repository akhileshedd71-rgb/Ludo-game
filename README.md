# Ludo Lane

An original, offline Android Ludo game built in **Godot 4.6.3**. Midnight colors, a warm ivory board, glossy pawns, generated hero artwork, and a little friendly rivalry.

## Play

- **Pass & play:** 2–4 people on one device, with editable player names.
- **Computer opponents:** switch any seat between human and computer.
- **Classic:** bring all four pawns home.
- **Quick:** two pawns per player; one starts on the track.
- Automatic save after every roll and move, including a pending die. Resume from the lounge.
- Animated dice and pawn movement, original sound cues, optional vibration, and reduced motion.
- Numbered pawn buttons provide an alternative to tapping the board. On desktop, Space rolls and 1–4 select pawns; Escape opens pause/back.
- Entirely local. No accounts, servers, ads, chat, or Internet permission.

This is an original game with familiar Ludo conventions; it does not use Ludo King's branding, artwork, code, or characters. Six-player boards, online modes, tournaments, theme unlocks and Snakes & Ladders are outside this first local version.

## Run the project

Open `project.godot` in **Godot 4.6.3 standard**, then press **F6** on the main scene or **F5** for the game. No plugins or package-manager dependencies are needed. The compatibility renderer supports modest mobile hardware.

```bash
godot --path .
```

The portrait canvas scales from 720 × 1280 and centers on taller/wider screens. Android uses immersive portrait mode. The default export supports **Android 7.0 / API 24 and later**, targets **API 36**, and contains ARMv7, ARM64, and x86_64 binaries.

## In this cloud workspace

```bash
cd /workspace/Ludo-game
source tools/env.sh
tools/setup_cloud.sh        # repeatable preparation + headless tests
godot --editor --path .     # requires a display
```

Godot 4.6.3 and Java 21 come from the base environment. Android SDK packages and verified Godot export templates are retained under `/workspace/.ludo-tools` and `/workspace/.ludo-data`. `tools/env.sh` activates the writable configuration and cache paths without changing `HOME`. The setup script verifies downloaded archive checksums and retains normal TLS verification.

This cloud task already has an isolated checkout. Use `/workspace/Ludo-game` directly; do not create a worktree unless requested.

## Tests and screenshots

```bash
tools/test.sh               # model simulations + headless UI integration
tools/render_tests.sh       # same tests, rendered UI + seven screenshots
```

The rule suite tests release on six, captures, safe squares, home lanes, exact finishes, extra turns, three sixes, turn order, save validation, and **64 complete seeded games** across both modes and 2–4 seats. The UI suite exercises setup, player names, rolling, pawn selection, actual CPU scheduling and animation, pause, save/resume, settings, rules, credits, and victory. Tests use isolated temporary save directories, not your player data. The runner checks Godot error output as well as the process exit code.

Rendered captures are written to `build/screenshots/`. A display is required; `render_tests.sh` can start a private dummy Xorg on this cloud image and stops only the server it starts. Generated screenshots and builds are ignored by Git and Godot's importer.

For the optional desktop package smoke check, export with `godot --headless --path . --export-release Linux build/ludo-lane.x86_64`, then run `tools/test_package.sh`. This validates the bundled assets and notices from an empty working directory and starts the standalone executable.

## Android APK

```bash
source tools/env.sh
tools/export_android.sh
# Optional: install on your connected phone with USB debugging enabled
adb install -r build/ludo-lane-debug.apk
```

The export script builds `build/ludo-lane-debug.apk`, verifies its signing, and checks 16 KB ZIP alignment. This is a **debug-signed development build**, not a Play Store release. The manifest requests only vibration. There is no Internet permission.

On another machine, install the matching official Godot export templates, JDK 17 or 21, Android platform-tools, Android platform 36, and build-tools 36.0.0. Set the Java SDK and Android SDK paths in Godot's Editor Settings → Export → Android, then use the included Android preset. The cloud helper paths are specific to this workspace; the Godot project itself is portable.

Before a store release, use your own release signing key, review the application ID, create an Android App Bundle using Godot's Gradle export, and run the device checks below. Never commit signing keys. No release credentials are required for local development.

## Rules used here

A six releases a pawn onto its starting star and earns another roll. Otherwise move clockwise by the rolled number. A pawn on a shared star is safe; landing on rivals on any other track square sends all of them to their yards. Pawns can share a square and do **not** form blockades. Captures and finished pawns grant another roll. Three consecutive sixes forfeit the third roll; previous moves remain. Your home lane is private and requires an exact roll to reach the center. No capture is required before entering it. First to finish all their pawns wins.

These choices are stated in the in-game rule sheet because household Ludo rules differ.

## Project map

| File | Purpose |
| --- | --- |
| `scripts/game_state.gd` | Pure rules, CPU move scoring, validated save format |
| `scripts/main.gd` | Screens, input, turn flow, settings, sound and lifecycle |
| `scripts/board.gd` | Vector board, pawns, legal highlights, hit testing and movement |
| `scripts/ui.gd`, `scripts/icon.gd` | Shared styling, typography and vector icons |
| `scripts/storage.gd` | Atomic local JSON persistence |
| `assets/art/hero.png` | Original artwork generated for this project |
| `tools/generate_audio.py` | Reproducible original PCM sound effects |
| `tests/` | Deterministic rule and UI integration tests |

The interface is built in GDScript from one root scene. Rules can be tested without rendering. CPU scoring prioritizes finishing, captures and deployment, favors safe squares, and discounts exposure to nearby rivals. Dice use Godot's random number generator; the deterministic roll argument is used by tests, not the player interface.

## Device validation still required

Cloud validation covers the rendered desktop game, headless simulations, packaged desktop startup, APK export, signature verification, manifest permissions and ZIP alignment. **A physical Android device has not been tested.** Check touch hit targets, portrait layout and system bars on several screen sizes; the software keyboard; sound/vibration; background/foreground and force-stop resume; and a complete multiplayer match on a phone before distribution.

## Assets and notices

The hero image was generated specifically for this project. The icon, board, pawns and sounds are original procedural assets. Open Sans is distributed under Apache 2.0; its copyright notice and the full license are included. Godot's MIT license is bundled. Settings → Credits exposes the notices in the game. Third-party licenses do not grant rights to unrelated game brands.
