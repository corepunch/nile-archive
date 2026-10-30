# Xcode projects

Each game has a committed project beside its sources,
`games/<game>/<game>.xcodeproj`, with macOS and iOS targets:

```sh
make xcode
open games/relic-rush/relic-rush.xcodeproj
```

Choose `nile-archive-macos` / `nile-archive-ipad`, `relic-rush-macos` /
`relic-rush-iphone`, or `volcano-macos` / `volcano-ipad`. iOS requires 16+;
macOS requires 12+. Clone recursively or run `git submodule update --init`
for the pinned Lua and corepunch/platform dependencies.

## Compilation

A build phase emits temporary unity sources into `DERIVED_FILE_DIR` using
`tools/unity.sh`, before the Sources phase compiles them:

- `u_engine.c`: engine modules and the triangle renderer.
- `u_script.c`: game scripting and generated Lua API bindings.
- `u_lua.c`: the sandbox's Lua interpreter and standard libraries.
- `u_platform.c`: the shared platform backend and audio, compiled as
  Objective-C on Apple targets. Target headers select macOS or iOS.
- `u_launcher.c`: the per-game entry point (Clayfight uses its own host).

The included individual sources remain visible for browsing, with no separate
compile membership. Xcode tracks their includes for incremental rebuilds.
Unity files are build outputs and are never committed or stored in `engine/`.
Only Apple system frameworks are linked. Make and WebAssembly stream the same
include lists into the compiler without writing unity files to disk.

Platform owns the native window, graphics context, event queue, and audio.
The renderer draws textured and colored triangles with OpenGL 3.2 on macOS
and ES 3 on iOS. UIKit drives the iOS frame callback through
`axRunApplication`; desktop builds poll events between frames. Pointer events
and gestures use the platform API. Logical coordinates, letterboxing and
Retina scaling are handled by the engine.

The `lua/` and `data/` folders are bundled as folder references and found via
`axShareDirectory`. Native save paths retain the original
`Application Support/corepunch/<game>` namespace, including sandboxed
containers. `SPRITE_SAVE_DIR` isolates test saves.

## Signing and resources

For device builds, select a team in Signing & Capabilities and use automatic
signing. macOS and Simulator builds need no team. `--unsigned` regeneration
preserves signing settings, bundle identifiers and shared schemes already in
the project; `--settings-from` reads another project and `--team` sets a team.

Generated Info.plists select the game's orientations and device family.
macOS entitlements enable App Sandbox. Each game's `Assets.xcassets`
supplies `AppIcon`; selected source artwork remains under `art/app-icon/`.

## Validation

```sh
make xcode-check
xcodebuild -project games/relic-rush/relic-rush.xcodeproj -scheme relic-rush-macos \
  -derivedDataPath build/xcode-macos build
xcodebuild -project games/relic-rush/relic-rush.xcodeproj -scheme relic-rush-iphone \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath build/xcode-ios \
  CODE_SIGNING_ALLOWED=NO build
```

Projects and identifiers are deterministic. `make test` checks committed
project freshness, including exact source build membership so duplicate
compilation cannot silently return. CI builds and launches every game's iOS target, requires a rendered screenshot,
and runs the native renderer/input integration checks under Xvfb on Linux.
