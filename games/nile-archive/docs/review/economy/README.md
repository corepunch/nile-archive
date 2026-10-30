# nile-archive economy and progression review

Reviewed 31 October 2026 using the actual native macOS renderer. Compare the
base commit `ac69ea7` with the revised reward and progression rules. Review JPGs
are proportionally downscaled captures with no artwork edits.
See the [source-backed research and budgets](../../../../../docs/ECONOMY_RESEARCH.md).

Scene results now pay Coins with an explicit first-clear / improved-Star /
clean-search breakdown. Influence comes from construction. Chapter cards
require the preceding clue as well as Influence. The measured building list
shows price, Influence return and chapter availability; a purchase preview
charges only on confirmation. Opening / first-build fixtures demonstrate the
minimum-income route. Existing art and shared control states are reused.

## 1200x900

| Screen | Before | After |
| --- | --- | --- |
| win | ![Before win 1200x900](before-win-1200x900.jpg) | ![After win 1200x900](after-win-1200x900.jpg) |
| chapters | ![Before chapters 1200x900](before-chapters-1200x900.jpg) | ![After chapters 1200x900](after-chapters-1200x900.jpg) |
| build | ![Before build 1200x900](before-build-1200x900.jpg) | ![After build 1200x900](after-build-1200x900.jpg) |
| island | ![Before island 1200x900](before-island-1200x900.jpg) | ![After island 1200x900](after-island-1200x900.jpg) |

## 1368x1026

| Screen | Before | After |
| --- | --- | --- |
| win | ![Before win 1368x1026](before-win-1368x1026.jpg) | ![After win 1368x1026](after-win-1368x1026.jpg) |
| chapters | ![Before chapters 1368x1026](before-chapters-1368x1026.jpg) | ![After chapters 1368x1026](after-chapters-1368x1026.jpg) |
| build | ![Before build 1368x1026](before-build-1368x1026.jpg) | ![After build 1368x1026](after-build-1368x1026.jpg) |
| island | ![Before island 1368x1026](before-island-1368x1026.jpg) | ![After island 1368x1026](after-island-1368x1026.jpg) |

## 1600x900

| Screen | Before | After |
| --- | --- | --- |
| win | ![Before win 1600x900](before-win-1600x900.jpg) | ![After win 1600x900](after-win-1600x900.jpg) |
| chapters | ![Before chapters 1600x900](before-chapters-1600x900.jpg) | ![After chapters 1600x900](after-chapters-1600x900.jpg) |
| build | ![Before build 1600x900](before-build-1600x900.jpg) | ![After build 1600x900](after-build-1600x900.jpg) |
| island | ![Before island 1600x900](before-island-1600x900.jpg) | ![After island 1600x900](after-island-1600x900.jpg) |

## New states

| State | Captures |
| --- | --- |
| opening | ![opening 1200x900](after-opening-1200x900.jpg) ![opening 1368x1026](after-opening-1368x1026.jpg) ![opening 1600x900](after-opening-1600x900.jpg) |
| first-build | ![first-build 1200x900](after-first-build-1200x900.jpg) ![first-build 1368x1026](after-first-build-1368x1026.jpg) ![first-build 1600x900](after-first-build-1600x900.jpg) |
| purchase | ![purchase 1200x900](after-purchase-1200x900.jpg) ![purchase 1368x1026](after-purchase-1368x1026.jpg) ![purchase 1600x900](after-purchase-1600x900.jpg) |
| first-win | ![first-win 1200x900](after-first-win-1200x900.jpg) ![first-win 1368x1026](after-first-win-1368x1026.jpg) ![first-win 1600x900](after-first-win-1600x900.jpg) |

## Reproduce and validate

```sh
make CFLAGS="-O2 -g -Werror"
make test
python3 tools/economy_audit.py
python3 tools/capture_economy_review.py --before-ref ac69ea7
```

Use Xvfb and `LIBGL_ALWAYS_SOFTWARE=1` for renderer work on Linux. Native PNG
intermediates and the base commit's temporary Lua/data export are removed by
the capture tool. No new dependency environment or model is installed.

- 146 economy checks cover minimum payouts, duplicate claims, Gold-only replays,
  complete restoration/expansion budgets, best-Star improvements, clue order
  and legacy visited-scene access.
- `make test`: 5,514 Relic Rush checks, 54 UI-form checks and 161 engine checks,
  plus existing rule/asset checks for the other games.
- Real-input Relic Rush smoke at 480 x 900 and 390 x 844 with safe areas covers
  first discovery, restoration, catalogue cancellation/purchase, free movement,
  the expedition browser, a completed replay and entering level two.
- Real-input Nile smoke at 1200 x 900 and 1600 x 900 covers scene one, free
  movement, purchase preview/cancel/confirm, the fountain, scene two, the temple
  and entering scene three without earning Influence from scenes.
- Shared nested-modal smoke and Volcano smoke pass. Renderer/input, safe-area,
  Gaussian backdrop/cache and dialogue layout checks pass. All 27 authored
  Relic Rush atlas crops remain unchanged and verify successfully.
- Every capture was inspected for clipping, incomplete text and missing art.
  Final fixtures are deterministic review states, not claims of human playtest
  difficulty; see the research document for limitations and follow-up metrics.
