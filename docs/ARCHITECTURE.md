# Architecture and dependency boundaries

The engine owns reusable mechanics and platform integration. A game owns its
content, presentation, progression and save schema. Native, WebAssembly and
Xcode builds share the unity source lists in `tools/unity.sh`; unity compilation
is a build optimization, not permission to reach into another module's statics.

| Boundary | Owner and contract |
| --- | --- |
| Platform → engine | `third_party/platform` supplies windows, events, GL contexts, audio and native services. Engine modules adapt these behind `engine.h`. |
| Game → engine | `engine.h` is the C game API; `api.xml` generates Lua bindings, editor declarations and API documentation. API changes regenerate all outputs with `make gen`. |
| Drawing → renderer | `render.h` is private to engine drawing/platform adapters. Ordinary Lua game code draws through `gfx`, `text`, `ui`, city and story APIs. |
| Lua runtime → modules | `script.c` opens libraries, registers the generated API and embedded engine Lua, and drives callbacks. `script_modules.h` owns configured roots, module identities, cache and circular-import detection. |
| Shared Lua → game | Embedded match-3, forms, skins, motion and city mover code accepts configuration and callbacks. It must not import a game's files or know its content IDs. |
| Game → game | Production launchers supply only their game's script root. Shared behavior belongs in the engine; multiple roots are an explicit host/test-fixture facility. |
| Native game extension → runtime | Clayfight installs its `clay` table through `script_set_extension`; the shared runtime does not select or import Clayfight. |
| Test → runtime | `ENGINE_TEST` provides reset/input/clock/reporting hooks. Game manifests select rules, smoke and captures through the existing runner. Release builds omit those hooks. |

## Review findings and implemented improvement

The reviewed engine, launcher, scripting, renderer and game composition paths
already keep game content out of the shared runtime. The module loader was an
exception to the otherwise explicit ownership: it lived inside lifecycle/API
glue, shared a fixed-size root buffer with boot, and exposed its cache registry
key to embedded-module registration. Dotted and slash imports could execute
the same file twice, syntax failures lost their diagnostic, and import cycles
recursed until Lua exhausted its stack.

Module loading now has a private two-function interface. Its roots, cache and
in-progress markers live in each Lua state, paths use Lua-managed strings, and
aliases have one canonical identity. Lifecycle code only opens the loader and
registers embedded modules. The scripting contract documents accepted names,
root ordering, error handling and trusted-root limitations.

`rules modules` covers the real loader's aliases, root precedence/fallback,
embedded-module identity, nil/false exports, runtime/syntax errors, retries,
cycles and invalid names. `script_module_roots` covers independent states,
copied root configuration and root lists beyond the old fixed buffers.

## Remaining boundaries to improve incrementally

- **Game state also acts as a function registry.** Relic Rush and Christmas
  Market modules attach entry points to `R` in `state.lua`; Nile Archive uses
  `archive_state.lua` similarly. That avoids import cycles but makes dependencies
  and initialization order implicit. For a future screen change, return a
  screen/controller interface and wire it in `main.lua`; keep mutable state
  separate. Migrate one feature with its existing rules and captures.
- **Some presentation modules are duplicated between the puzzle games.** Keep
  game skins, text, artwork and economy local. Extract another shared behavior
  only when its configuration and callback contract are clear, following the
  existing match-3 engine rather than creating cross-game imports.
- **Clayfight uses private rendering functions.** Its native framebuffer bridge
  in `host.c` includes `render.h` for upload and nearest sampling. A public
  texture update/sampling API would let that adapter depend only on `engine.h`;
  it needs API generation and native/web/iOS validation as a separate change.

These are follow-up review findings, not additional changes in this module
loader refactor. Keep fixes reviewable and validate at the boundary they change.
