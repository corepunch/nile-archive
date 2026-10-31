# Clayfight port — completion record

The active resource source is now the arcade 2.3 ROM set, at **672×480**
(2×336×240). See [the arcade runtime and catalogue](primal-rage-arcade.md).
The verification record below describes the earlier DOS integration; its
pixel parity and converted-script counts are historical, not current claims.

The original C simulation runs as game-local modules on the shared engine.
Lua owns the app descriptor and fixed-tick scheduling. The shared engine owns
the window, event polling, texture presentation, indexed CPU rasterisation,
image decoding, photo processing and 16-channel stereo PCM mixing. Clayfight
keeps resource decoding, original font mappings, alternate fighter palettes,
sound selection and gameplay. Compatibility adapters translate its legacy
calls into the public engine API; they do not open a second audio device.
No SDL dependency remains in the active sources.

- [x] Preserve original sources, artwork, capture tools and tests in this repository.
- [x] Copy Primal Rage reference resources and derived definitions into ignored storage.
- [x] Integrate the original C game into the shared engine and Lua app lifecycle.
- [x] Preserve animation states, root motion, hit/hurt boxes, blocking, jumps, knockdowns, rounds, timers, hitstop, CPU and particles.
- [x] Preserve title/select/options, conquest, continues, final gauntlet, training, tug and endurance.
- [x] Preserve full stereo PCM sound effects and original fighter voices.
- [x] Preserve desktop companion capture, validated publication and roster refresh.
- [x] Integrate native iOS camera/photo/video capture, drafts and persistent creature storage.
- [x] Provide native multi-touch controls and two Apple GameController devices.
- [x] Generate macOS and universal iPhone/iPad landscape Xcode targets.
- [x] Remove the superseded toy Lua simulation and duplicate legacy tree from active project files.
- [x] Archive original sources and Git history under ignored reference storage.

## Verification completed

- `make all`: all native games built.
- `make test`: generated API/project freshness, shared engine/Lua game tests,
  Clayfight framebuffer/photo/JS processing tests passed.
- `make test-clayfight-retail CFLAGS='-O2 -g -Werror'`: original menu/campaign,
  retail rendering, airborne poses, navigation, multiplayer joining/reset,
  training/tug/endurance and capture publication tests passed.
- Original VM comparison: **266 animations and moves, zero differences**.
- Original executable comparison: **78 frames across 13 scenes, pixel-identical**.
- `python3 -B games/clayfight/tests/concepts.py`: four tests passed, including
  the exported concept poses.
- Xcode macOS and iOS Simulator builds succeeded, including native capture code.
- Retail resources and derived creature files are excluded by `.gitignore`.

## Validation limits

CoreSimulator and a graphical macOS window are unavailable in this execution
environment. Native iOS camera permissions, live capture, multi-touch and physical
controllers still require testing on a device. The software renderer, simulation,
server capture publication, native compilation and iOS linking were verified.
Emscripten is not installed here; the WebAssembly recipe is provided but untested.
The web preview requires a native/desktop companion for creature capture. The
non-Apple platform joystick API exposes one device; two-controller support is
provided through GameController on macOS/iOS.

## Parity audit (30 October 2026)

Baseline: original Clayfight commit `c0305d3a812e6797cee8d87ea28fbc86bd702e75`.
The original simulation and resource semantics are retained. Generic CPU drawing
and photo processing are extracted to `engine/raster.c` and `engine/photo.c`;
legacy game calls adapt to those APIs. The PCM mixer lives in `engine/audio.c`
and shares one device with engine feedback tones. Game-local differences also
include resource paths, the host entry point and an explicit integer cast in the
stage palette average. Platform window/input adapters replace SDL.

`python3 games/clayfight/tests/parity.py /path/to/original/clayfight` reproduces
78 pixel comparisons: six ticks per scene (0, 120, 240, 360, 480, 600), covering
title menus, start/options, selection, conquest, all seven retail fighters/stages,
and the custom boxer/lizard fight. Both executables receive the same resources,
creatures and CPU inputs and run in temporary working directories.

The audit fixed player-one touch movement, root-relative legacy CLI launch paths,
focus-loss queue/axis resets and macOS bundle workshop/storage paths. Clean CI
now exercises the actual input adapter, Lua 60 Hz scheduling and stall cap, and
Clayfight's setup screen on WebGL and iOS. Retail resources remain local and
ignored; CI does not claim retail gameplay coverage. Native camera processing
checks are retained behind `--native-checks` in Debug iOS builds with local data.

The macOS development bundle includes the Python capture companion and disables
App Sandbox for that subprocess workflow. Python 3 must be installed. Captured
fighters and options are stored in Application Support/Clayfight. App Store
sandbox packaging of the desktop Python companion is outside this port.

The original local repository is preserved as a reference. No active build,
runtime, test or capture path depends on that directory. Original sources and a Git history bundle are preserved under
`reference/clayfight/`.

## Shared subsystem extraction (30 October 2026)

Completed the separation of reusable subsystems from the imported game:

- `engine/audio.c`: one lazy stereo device for 16 PCM voices and feedback tones;
  Clayfight's `i_sound.c` only forwards playback and stop calls.
- `engine/raster.c`: indexed CPU drawing on caller-owned surfaces;
  Clayfight retains its framebuffer dimensions and original font mappings.
- `engine/photo.c`: background removal, common scale, quantisation and detail;
  Clayfight's `w_photo.c` constructs its GRA frames and alternate palettes.
- Make/Web recipes and generated Xcode projects use the shared modules;
  no active build refers to `source/engine`.

Validation after extraction: all four native games built with `-Werror`;
`make test`, `make test-clayfight-retail` and concept tests passed. The shared
mixer has hardware-free callback tests for stereo pan, resampling, clipping,
mute, shared tone playback and device shutdown/reopen. Original executable
comparison still produces 78 pixel-identical frames across 13 scenes, and all
266 animation comparisons match. The shared unity unit and game adapters also
pass arm64 iOS Simulator syntax checks. Full iOS linking and live audio playback
were not repeated for this extraction; WebAssembly remains untested locally.
