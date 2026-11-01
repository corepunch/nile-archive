# Xcode projects

Each game has a committed project beside its sources,
`games/<game>/<game>.xcodeproj`, with macOS and iOS targets:

```sh
make xcode
open games/relic-rush/relic-rush.xcodeproj
```

Choose `nile-archive-macos` / `nile-archive-ipad`, `relic-rush-macos` /
`relic-rush-iphone`, or `emergency-macos` / `emergency-ipad`. iOS requires 16+;
macOS requires 12+. Clone recursively or run `git submodule update --init`
for the pinned Lua and corepunch/platform dependencies.

## Deploy to a connected iPhone or iPad

Like orion-ui's `ipad-deploy`, each game's `ios` Make target builds, signs,
installs and launches on an available physical device:

```sh
make -C games/nile-archive ios       # iPad
make -C games/relic-rush ios         # iPhone
make -C games/christmas-market ios   # prefers iPhone; also supports iPad
make -C games/emergency ios            # iPad

# Equivalent repository-root targets:
make ios-nile-archive
make ios-relic-rush
make ios-christmas-market
make ios-emergency
make ios GAME=relic-rush            # GAME defaults to nile-archive
make list-devices
make ios-relic-rush DEVICE="Igor’s iPhone 14 Pro Max"
make ios-emergency DEVICE=<UDID> TEAM=<development-team-id>
```

`tools/xcode/deploy.py` queries `xcrun devicectl` using JSON, excluding
unavailable devices and simulators. It chooses the only available device in
the game's preferred family. Christmas Market falls back to iPad if no iPhone
is available; `DEVICE` may select either supported family. Missing or ambiguous
selection stops before building and lists the matching names. `DEVICE` accepts
an exact device name, hardware UDID, CoreDevice identifier or ECID.

Connect/pair the device in Xcode, enable Developer Mode and unlock it. Device
deployment requires macOS and Xcode 16+. The helper uses the project's existing
signing team, or the unique team in installed Apple Development certificates
with valid signing identities if the project has none. The certificate's OU
supplies the team; its common-name suffix is a person ID. Set `TEAM` to override
it. Xcode automatic provisioning and
device registration are enabled; a valid development certificate and an Xcode
account or matching installed provisioning profile are still needed. The helper
never edits the committed signing configuration or bundle identifier.

`CONFIGURATION=Release` selects a release build; Debug is the default.
`IOS_BUILD_DIR=/path` overrides the shared `build/ios` DerivedData directory.
`ARGS='--fresh --mute'` forwards arguments only to the launched game. Installation
runs only after a successful build, and launch only after a successful install.
The app's actual built Info.plist supplies its bundle identifier.

Device builds stay local because they use connected hardware and local signing
keys. Xcode intermediates, copied app assets and SDK caches may exceed 500 MB;
the shared build directory avoids separate SDK caches for each game.
`make test-ios-deploy` checks both device JSON formats, all games' family/scheme
selection, signing fallback, and failure boundaries without building or touching
a device. These checks also run in the default test suite and CI preflight.

## Compilation

A build phase emits temporary unity sources into `DERIVED_FILE_DIR` using
`tools/unity.sh`, before the Sources phase compiles them:

- `u_engine.c`: engine modules and the triangle renderer.
- `u_script.c`: game scripting and generated Lua API bindings.
- `u_lua.c`: the sandbox's Lua interpreter and standard libraries.
- `u_platform.c`: the shared platform backend and audio, compiled as
  Objective-C on Apple targets. Target headers select macOS or iOS.
- `u_launcher.c`: the per-game entry point.

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
