# Testing

`make test` builds the engine and games with `-DENGINE_TEST` and runs each suite once.
One start of a test binary runs every test in its suite, in one process and one window:

| Binary | Runs |
|---|---|
| `build/test/engine` | The engine's C tests, real-renderer tests, and the Lua API and UI rules |
| `build/test/relic-rush` | Its rules, smoke runs, screens, reels and gestures |
| `build/test/nile-archive` | Its smoke run, screens and gestures |
| `build/test/christmas-market` | Its rules, smoke run and screens |
| `build/test/volcano` | Its rules, smoke run and screens |

Clayfight and audio keep their own small binaries, because neither uses this engine setup.

```sh
make test                       # everything; under xvfb-run -a on Linux
make test ONLY=smoke            # only tests whose name contains this, in every suite
build/test/relic-rush           # one suite
build/test/relic-rush rules     # part of one suite
build/test/relic-rush --list    # what it would run
```

## Reading the output

```text
relic-rush
  PASS  rules relic                              6.71s  5514 checks
  FAIL  smoke game                               1.05s
        games/relic-rush/lua/smoke.lua:28: smoke test failed at stage 7
        stack traceback:
          ...
        output:
          whatever the game printed last
  PASS  shot island-village                      0.11s  2 checks
relic-rush: 64 passed, 1 failed, 6925 checks, 59.5s
failed:
  smoke game
```

A failure or a broken script ends that test and the run carries on. What a game prints stays
out of the report unless its test fails, and the full last log is `build/test/<suite>.log`. A test
that runs longer than ten minutes fails as timed out. The exit code is non-zero when anything failed.

## Writing a test

**A game's screens and runs** are one line each in `tests/games/<game>.lua`:

```lua
rules("relic")                                  -- tests/lua/relic.lua, with this game's modules
rules("progression", "games/nile-archive/lua")  -- with another game's too
smoke()                                         -- plays the game's --smoke run
smoke("--size 456x342", "small")                -- with options, under its own name
shot("island-village", "480x900", "--showcase") -- a screen: docs/screenshots/island-village.jpg
frame("tiles-relics", "480x900", "--tiles relics") -- a picture other images are built from
reel("fx-ray", 18, 2, "480x900", "--fx ray --reel") -- 18 pictures, 2 frames apart, from one run
hold("long-press", "480x900", "240,440", "--city 3") -- a real pointer press and hold
```

Every picture is checked: not one flat colour, and the shape its size asks for. `default_frames`
sets how many frames a picture waits for, 4 unless the file changes it.

**A Lua rule test** is a file in `tests/lua/` using the global `check` and `near`:

```lua
local rules = require("rules")
check(rules.CELLS == 61, "the board has 61 cells")
near(vec2(3, 4):len(), 5, "a 3-4-5 triangle")
```

**A C test** registers itself:

```c
#include "test.h"

TEST(camera_clamps)
{
    CHECK(cam.zoom > 0);
    NEAR(cam.center.x, 100);
    CHECKF(hits == 3, "after %d taps", taps);
}
```

Put it in `tests/test_main.c`. A test that needs the real renderer calls `app_run` with its own
`app_desc`, as `tests/test_city_render.c` does.

## How it works

`-DENGINE_TEST` swaps `main` in `engine/launcher.c` for `test_main` in `engine/test_runner.c`. The
engine's few hooks are `#ifdef ENGINE_TEST` where they belong: `core.c` keeps one window and resets
state per run, `render.c` frees a finished test's textures, and `script.c` turns a Lua error into a
failure instead of exiting. Release builds contain none of it. If a test needs something more from
the engine, add it the same way rather than adding boilerplate to the test.

`make shots` runs only the picture tests, then `tools/screenshots.py` turns them into documentation
images without starting a game.

## Fast rules and deterministic injections

The same binaries and manifests support a window-free pass:

```sh
make test-fast
make test-relic-rush             # substitute nile-archive, christmas-market or volcano
make test-engine
make test-clayfight              # includes its Lua scheduler and native/JS checks
make test-extended               # CPU/rules, larger deterministic sample
build/test/relic-rush --fast     # same executable used for full screenshots and smoke
```

Fast mode runs Lua rules and the engine's CPU tests, skipping renderer tests,
smoke, screenshots, reels and gestures. The puzzle suites take about one second
per game on the development Mac. `make test` retains the full integrated suite.
CI runs `make test TEST_ARGS=--extended`, keeping the thousand opening boards
and greedy campaign simulation alongside the added coverage.

Under `#ifdef ENGINE_TEST`, the private `testing` table provides
`testing.reset()`, `testing.advance(seconds)` and `testing.input{...}`. Reset
clears frame time, input and engine UI/story/effect/city state and selects a fixed
wall-clock epoch. Advance changes frame/wall clocks and `app.dt()` instantly;
tests explicitly call updates. Input reaches the real `input.get()` without a
window. Negative and nonfinite durations are rejected. Real game runs switch
back to their normal clock. `testing.game` identifies the manifest's suite and
`testing.extended` selects the larger sample. Release builds expose none of these
hooks; declarations live with the existing test infrastructure in `engine/test.h`.

Each rule file gets a fresh Lua state and selected game + engine + test module
roots. Save output uses a unique temporary directory per suite invocation, which
is removed at exit. A rule file may return nil or a nonnegative integer failure
count; invalid return values and positive failure counts fail its job. Errors in
engine-to-Lua callbacks remain catchable by named cases, while uncaught frame
errors retain the existing job recovery path.

`tests/lua/support.lua` supplies named cases: use `suite:case(label, fn)` and
`suite:check(condition, message)`, then `return suite:finish()`. Case failures
include their fixture parameters and feed the engine's existing reporter.

Puzzle assertions live once in `tests/lua/contracts/puzzle.lua`, accepting a
configured rules instance; `match_matrix.lua` selects the game's public adapter.
There are roughly 10,000 board cases per game: every straight run/direction/colour,
an independent component oracle, every tool mask, all 512 isolated central-lane
occupancies, holes/locks, special pairs, blocker strengths, materials and final
move precedence. Lane tests isolate side cells so they allow diagonal trickling
when it is enabled on a wider board. Both games also exercise real animation
phases, paused waves, cascades and dead-board recovery.

`building_economy.lua` checks every real catalogue entry: each resource one short,
each requirement one short, exact funds, preview/cancel, exact deductions and
rewards, duplicate confirmation and free moving. Engine cases cover both quick
and confirm paths, all resource slots together, full cities, blocked terrain,
region unlocks, the income boundary and injected hold/move/cancel input. Volcano
checks all job costs, duplicate dispatch and blocked/paused/busy/unreachable work.

The embedded shared-engine module exposes `match3.new(config)`. Its direct
suite tests all 64 behavior-flag combinations, default match-3, configurable
thresholds/colours, multiple radii and the same board contract. The engine manifest
includes it automatically when `engine/match3.lua` is present. Use its direct suite:

```sh
make test-match3
```

The direct suite has also passed against a snapshot of the referenced engine
migration checkout. It loads no game modules or artwork.

This change adds test coverage and test-only hooks; no player-visible screenshots
are required for its pull request.
