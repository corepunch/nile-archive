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
