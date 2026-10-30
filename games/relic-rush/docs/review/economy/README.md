# relic-rush economy and progression review

Reviewed 31 October 2026 using the actual native macOS renderer. Compare the
base commit `ac69ea7` with the revised reward and progression rules. Review JPGs
are proportionally downscaled captures with no artwork edits.
See the [source-backed research and budgets](../../../../../docs/ECONOMY_RESEARCH.md).

The result distinguishes restoration funding from discretionary Gold. The
shop distinguishes spendable Gold from the protected restoration amount.
Expeditions supports Gold-only replay, the next discovery and locked future
stages. Discovery Stars remain cumulative; the new Compass schedule funds all
land by discovery nine. The finale provides a play-for-Gold route. Existing
normal/hover/pressed/disabled/focus controls are used without new bitmap art.

## 480x900

| Screen | Before | After |
| --- | --- | --- |
| result | ![Before result 480x900](before-result-480x900.jpg) | ![After result 480x900](after-result-480x900.jpg) |
| island | ![Before island 480x900](before-island-480x900.jpg) | ![After island 480x900](after-island-480x900.jpg) |
| shop | ![Before shop 480x900](before-shop-480x900.jpg) | ![After shop 480x900](after-shop-480x900.jpg) |
| wonder | ![Before wonder 480x900](before-wonder-480x900.jpg) | ![After wonder 480x900](after-wonder-480x900.jpg) |
| expansion | ![Before expansion 480x900](before-expansion-480x900.jpg) | ![After expansion 480x900](after-expansion-480x900.jpg) |
| finale-island | ![Before finale-island 480x900](before-finale-island-480x900.jpg) | ![After finale-island 480x900](after-finale-island-480x900.jpg) |

## 390x844

Safe-area insets: 47 top, 34 bottom.

| Screen | Before | After |
| --- | --- | --- |
| result | ![Before result 390x844](before-result-390x844.jpg) | ![After result 390x844](after-result-390x844.jpg) |
| island | ![Before island 390x844](before-island-390x844.jpg) | ![After island 390x844](after-island-390x844.jpg) |
| shop | ![Before shop 390x844](before-shop-390x844.jpg) | ![After shop 390x844](after-shop-390x844.jpg) |
| wonder | ![Before wonder 390x844](before-wonder-390x844.jpg) | ![After wonder 390x844](after-wonder-390x844.jpg) |
| expansion | ![Before expansion 390x844](before-expansion-390x844.jpg) | ![After expansion 390x844](after-expansion-390x844.jpg) |
| finale-island | ![Before finale-island 390x844](before-finale-island-390x844.jpg) | ![After finale-island 390x844](after-finale-island-390x844.jpg) |

## New states

| State | Captures |
| --- | --- |
| replay-result | ![replay-result 480x900](after-replay-result-480x900.jpg) ![replay-result 390x844](after-replay-result-390x844.jpg) |
| expeditions-1 | ![expeditions-1 480x900](after-expeditions-1-480x900.jpg) ![expeditions-1 390x844](after-expeditions-1-390x844.jpg) |
| expeditions-2 | ![expeditions-2 480x900](after-expeditions-2-480x900.jpg) ![expeditions-2 390x844](after-expeditions-2-390x844.jpg) |
| expeditions-3 | ![expeditions-3 480x900](after-expeditions-3-480x900.jpg) ![expeditions-3 390x844](after-expeditions-3-390x844.jpg) |
| expeditions-4 | ![expeditions-4 480x900](after-expeditions-4-480x900.jpg) ![expeditions-4 390x844](after-expeditions-4-390x844.jpg) |
| expeditions-resume | ![Resume 480x900](after-expeditions-resume-480x900.jpg) ![Resume 390x844](after-expeditions-resume-390x844.jpg) |

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
  the expedition browser, a completed replay, resuming its unfinished board and entering level two.
- Real-input Nile smoke at 1200 x 900 and 1600 x 900 covers scene one, free
  movement, purchase preview/cancel/confirm, the fountain, scene two, the temple
  and entering scene three without earning Influence from scenes.
- Shared nested-modal smoke and Volcano smoke pass. Renderer/input, safe-area,
  Gaussian backdrop/cache and dialogue layout checks pass. All 27 authored
  Relic Rush atlas crops remain unchanged and verify successfully.
- Every capture was inspected for clipping, incomplete text and missing art.
  Final fixtures are deterministic review states, not claims of human playtest
  difficulty; see the research document for limitations and follow-up metrics.
