# Testing

The default workflow is: select affected checks, capture a baseline when needed,
edit, build affected targets, run the selected checks and lint, then stop. Expand
coverage only for shared changes, a failure, an explicit request, or a concrete
unresolved concern. A pull request does not itself require a full local run.

For a game-local fix, use the affected tests and representative captures.
For example, a Relic Rush board-size correction can use:

```sh
time make CFLAGS="-O2 -g -Werror" relic-rush build/test/relic-rush
time build/test/relic-rush "rules relic_board" "shot hex-first" "shot phone-board"
time make lint
```

Filters match substrings of `kind name`. Including the kind avoids selecting
unrelated captures: `phone-board` also matches an entrance reel, whereas
`"shot phone-board"` selects just the screenshot. Check `--list` when unsure.
Use before/after pairs at the two relevant sizes for a uniform visual change;
add state boards or reels when the behaviour they cover changes. Run full local
coverage for shared engine changes or a concrete unresolved concern. CI always
runs the complete suite. See [AGENTS.md](../AGENTS.md) for scope rules.

When reporting timings, use measured elapsed seconds and distinguish builds,
tests/captures and lint. Label estimates and do not compare a full-task duration
with a test-only duration. Reuse successful results until relevant code changes;
documentation-only workflow edits do not require rerunning game tests.

Review exporters reuse canonical captures. `capture_match3_default.py` takes
board/HUD states from each game's existing state shots and Relic Rush's effect
from `effect-bomb`; `capture_resource_icons.py` reuses the pack, guide and phone
shots. Only the engine's default skin needs separate resource-icon frames.
Use either script's `--existing` option to export a completed run without
rendering again. Avoid adding another manifest entry just to give an existing
view a different review filename.

`make test` builds the test binaries, then runs correctness checks within a
five-second wall-clock budget. Four independent workers run every rule suite,
the engine's real-renderer/input assertions, audio, generated-code/project checks, asset audits and launcher contracts.
Each game suite starts once. Results are grouped by suite, every invocation
executes the checks again, and failures or budget overruns fail the target.

Build time is separate: the five-second timer starts after compilation. The
timer includes test process startup, waiting for workers, preflight checks,
reporting and teardown. Timed-out jobs and their children are terminated.
`TEST_WORKERS` defaults to four; `TEST_BUDGET` defaults to five seconds.

Measured on the development Mac: `make test` passed in 3.66 seconds (the
launcher measured 3.54 seconds); the separate test-binary build took 4.19
seconds, and `make lint` took 0.88 seconds. No prior passing results were
cached. The previous 215-second workflow also exported the complete capture
library and ran long game smoke scenarios, now selected with `test-full`.

Bulk screenshot/reel exports and long game smoke scenarios are explicit
integration checks. `make test-full` retains them all and is used by cloud CI;
`make shots` and `make smoke` select those workflows independently. Screenshots
check dimensions and non-flat pixels; repeatedly exporting them adds little to
the rule and renderer assertions on every local edit.

Direct test binaries retain their complete integration manifest by default:

| Binary | Runs |
|---|---|
| `build/test/engine` | The engine's C tests, real-renderer tests, and the Lua API and UI rules |
| `build/test/relic-rush` | Its rules, smoke runs, screens, reels and gestures |
| `build/test/nile-archive` | Its smoke run, screens and gestures |
| `build/test/christmas-market` | Its rules, smoke run and screens |
| `build/test/emergency` | Its rules, smoke run and screens |

Audio keeps its own small binary for tone playback, muting and device lifecycle.
Clayfight and its native/JavaScript checks
now live in the [standalone repository](https://github.com/corepunch/clayfight).

```sh
make test                       # correctness + renderer + preflight, budget 5s
make test-fast                  # same checks without a window/GPU
make test-full                  # complete smoke/capture integration, deliberately slow
make test-full ONLY=smoke        # only smoke jobs, in every suite
make test TEST_BUDGET=10         # explicit allowance for slower hardware
build/test/relic-rush           # one suite
build/test/relic-rush --check   # rules only; engine --check also retains all C tests
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
make test-relic-rush             # substitute nile-archive, christmas-market or emergency
make test-engine
make test-extended               # CPU/rules, larger deterministic sample
build/test/relic-rush --fast     # same executable used for full screenshots and smoke
```

Fast mode runs Lua rules and the engine's CPU tests, skipping renderer tests,
smoke, screenshots, reels and gestures. The aggregate target also retains
preflight and native audio checks. `make test-extended` deliberately raises
the budget to 60 seconds for the larger deterministic sample. CI runs
`make test-full TEST_ARGS=--extended`, keeping the thousand opening boards,
greedy campaign simulation and complete integration captures.

The budgeted path does not reduce puzzle seeds or remove rule assertions.
The city renderer compares identical-time pixels, advances the existing test
clock by four seconds, then checks changed fog pixels; it no longer waits four
real seconds. Test builds present with vsync disabled. These changes leave
release rendering and timing unchanged.

Under `#ifdef ENGINE_TEST`, the private `testing` table provides
`testing.reset()`, `testing.advance(seconds)` and `testing.input{...}`. Reset
clears frame time, input, engine UI/story/effect/city state and every tween
(`tween.reset()`), and selects a fixed wall-clock epoch. Tweens advance only
through `tween.update(dt)`, since no frame runs. Advance changes frame/wall clocks and `app.dt()` instantly;
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
region unlocks, the income boundary and injected hold/move/cancel input. Emergency
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


## Fail early and measure slow steps

`make test-assets` checks artwork without compiling or launching a game. CI runs
it with generated-code/project checks and Lua lint in a preflight job before
native, WebAssembly or iOS builds. Atlas validation verifies SHA-256 fingerprints
of the authoring recipe, every input and each registered output. The registered
RGBA assets are the authored deliverables; CI does not resample them again on a
different CPU or JPEG decoder. Run `python3 tools/match3_atlas.py` to deliberately
reauthor registration, then `make gen` and inspect the game captures.

The measured previous iOS run spent about 96 seconds building and 7m 20s in
simulator smoke; approximately four minutes elapsed between boot completion and
the first launch. The new smoke script reports each simctl operation and boots
one device family at a time to reduce contention. Fast local rules take about
5–6 seconds; the full native renderer/smoke suite took about 2m 20s. A complete
native run writes many review/reel frames; prefer targeted local runs and cloud
CI for the full output set, then discard regenerable intermediates.
