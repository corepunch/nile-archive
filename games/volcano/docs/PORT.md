# Port assessment and implementation

Porting makes sense: both projects already target C11, SDL2 and landscape touch
screens. The source game's valuable content is its five painted maps, authored
traffic networks, replacement character animations and resource/route puzzles.
The destination engine supplies almost all of the presentation and platform
infrastructure that the source maintained separately.

## Boundary

The shipped port is the complete **After the Eruption** five-map episode from
`/Users/igor/Developer/volcano-sdl2`. Its six earlier standalone experimental
missions and original Rescue Team campaigns are not included. Boat missions,
retail campaign binaries, retail save migration, original GUI/font systems,
asset mounts, XML parsers, retail declaration interpreters and compatibility
rules are not carried into the runtime. The source repository is unchanged.

This port keeps the episode's authored graphs and placements, initial supplies,
prices, rewards, five-second work/production intervals, two starting workers,
recruits, automatic evacuation, pet escorts and all-route victory conditions.
It uses its own Lua definitions, without original type codes or sprite-name
rules. The new presentation uses the destination engine's native look.

## Shared engine features

| Responsibility | Implementation |
|---|---|
| Window, input, touch, landscape, screenshot capture | Existing `core.c` and launcher |
| Camera, pan, zoom, drawing, clipping | Existing camera and graphics API |
| HUD, panels, buttons, modals, disabled states, toasts | Existing `ui` widgets and theme |
| Briefings and text layout | Existing `story` narrator dialogue and TrueType text |
| Campaign persistence | Existing `save` visitors |
| Completion feedback and sound | Existing `fx` particles/floating text and `sfx` |
| Geometric graph routes and target approach | New reusable `nav.c` |
| Trimmed atlas pivots, bounds, authored animation timing | New reusable `sprite.c` |
| Production and objective meters | New reusable `ui.progress` widget |
| Rules, resources, job reservations, queues, evacuation, campaign | Game Lua |

The route module knows points, links and circular blockers; it knows nothing
about workers, rescue games, resources or mission formats. It finds shortest
paths with Dijkstra, exempts the chosen target's blocker, validates first/last
approach segments and can stop at an elliptical footprint. It supports up to
768 nodes and 128 blockers per graph. Larger games can extend these capacities
or replace the scan with an adjacency list without changing the game interface.

The sprite module receives a texture and authored frame records with normalized
pivots. The same frame computes drawing and picking bounds. Game Lua chooses
animations; engine code samples and draws them. Damaged and repaired station
states come directly from the existing authored sheet. No visual states are
manufactured by scripts. There is no custom game widget or portrait renderer.

Game jobs spend resources exactly once when a worker is reserved. Unavailable
orders wait in a cancellable queue; one blocked order does not prevent other
jobs being dispatched. Simulation runs in fixed 1/60-second steps. Production
continues while other branches are worked; all animation derives from game
time, and pause freezes it. Queueing too much optional work before restoring
production can still consume starting resources; the campaign supplies a
solvable route rather than overriding player spending decisions.

## Native content

`lua/volcano_levels.lua` is the campaign. `lua/volcano_art.lua` is native atlas
metadata; `data/` contains self-contained PNGs and an OFL font. Neither file
requires an XML or retail reader. `tools/import_episode.py` is a one-time,
explicit developer migration tool; it is not invoked by normal builds.
The importer accepts a source repository path, preserves authored frames and
records input hashes and the source commit in the asset catalog. Replacing a
pet atlas requires changing its frame metadata, without changing simulation.

## Verification

- `make test`: engine, generated API, existing Relic Rush tests and Volcano tests.
- Volcano regression: all five maps under normal, reverse road and timber-yard
  repair priorities; no resource injection or direct job completion.
- Pause, initial rescue gates, one-time spending, resource recovery, restart,
  route blockers, final approach segments, footprint stopping and sprite pivots.
- `--smoke`: all five maps through the real engine click-input path, plus
  pause/resume, restart and final replay.
- Start, repaired and completed renders; campaign menu and dialogue renders.
- Native build, both existing games' launch screenshots and generated Xcode project freshness checks.
- New engine/API C sources compile for the arm64 iOS Simulator SDK.

The local iPad build attempt is blocked in SDL's `CompileMetalFile` step because
this Xcode installation lacks the Metal Toolchain. The simulator deployment
range also requires overriding SDL's old iOS 9 setting on this Xcode version.
A full iPad run is therefore not claimed. Web packaging is registered in the
shared build; Emscripten is not installed locally, so a web build is not claimed.
