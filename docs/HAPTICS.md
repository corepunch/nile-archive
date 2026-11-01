# Haptic feedback

All games use the generated `haptic` Lua module, backed by the shared C engine.
Feedback is independent of sound and reduced motion. It defaults on;
`haptic.enable(false)` disables it for the app session. `--no-haptics`
suppresses physical output, as do headless, screenshot, smoke and test runs.

```lua
haptic.play(haptic.MATCH, .7)
haptic.play(haptic.COMBO, math.min(1, .6 + .1 * combo))
haptic.play(haptic.SUCCESS) -- default strength 1
```

`haptic.available()` reports backend support, independently of enablement.
Unsupported devices are silent. Strength clamps to [0,1]; zero, negative,
nonfinite strengths and unknown effect IDs are ignored. The generated reference
and editor annotations come from `engine/api.xml`; regenerate with `make gen`.

## Event ownership

| Owner | Events |
| --- | --- |
| Engine match presentation, used by Relic Rush and Christmas Market | MATCH for the first clear, COMBO for later waves or activated specials, TICK for completed simultaneous gravity steps, ERROR for rejected swaps/failure, SUCCESS for victory. Tools use the same clear-wave path. |
| Engine city transactions, used by Nile Archive and both portrait games | MATCH when a hold/preview drag lifts a building, PLACE on release/drop or a successful quick purchase; COLLECT after income is collected |
| Nile Archive scene input | MATCH for an object found, COMBO for consecutive finds, ERROR for a miss, TICK for a requested hint, SUCCESS for the final object |
| Emergency presentation adapter | PLACE for completed station repairs, MATCH for other completed jobs, COLLECT for income, SUCCESS for rescues and district victory |

Rule matching, hints, simulations and speculative move searches never request
feedback. City seed/loading calls, continuous dragging, camera pan/zoom, cancellation and
failed confirmation stay silent. Pickup requests MATCH at .6 strength; release
requests PLACE at full strength, which can preempt the pickup cooldown. Pointer
cancellation does not count as a drop. Confirm/Cancel never request feedback.
Relic Rush entrances request the same TICK at .35 strength as normal refill,
coalescing simultaneous landings. An opening release cannot skip the entrance;
skipping requires a new press and release during it. Rendering never emits feedback.

## Engine and platform boundary

`engine/haptic.c` collects requests during a frame. After the game frame the
engine emits at most one effect: SUCCESS, PLACE, COMBO/ERROR, MATCH, COLLECT,
then TICK in descending priority. Equal effects retain the greatest strength.
Ticks use a 75 ms cooldown; other events use 100 ms, or 240 ms after SUCCESS.
A higher-priority event can preempt the cooldown. Suppressed requests are
discarded. Focus loss clears pending requests and releases platform resources;
app/test resets clear all policy state.

`engine/haptic_platform.c` compiles in the platform unity unit, separately
from engine C and generated Lua glue:

- iOS uses cached UIKit impact and notification generators, with Core Haptics
  hardware detection. Notification patterns have fixed strength. Devices without
  haptic hardware, including iPads, remain silent. See
  [Apple's hardware guidance](https://developer.apple.com/documentation/corehaptics/preparing-your-app-to-play-haptics).
- macOS uses AppKit's current haptic performer for a Force Touch trackpad.
  AppKit chooses the device and respects system preferences; strength is ignored.
  `available()` indicates a performer API, not proof of an attached actuator.
- Web uses feature-detected `navigator.vibrate`, after user activation and only
  while visible. Browser/device policy may decline a request; unsupported
  browsers remain silent. Patterns are short and bounded.
- Other desktop platforms use a no-op backend.

No new package or runtime installation is required. Xcode iOS targets link the
system CoreHaptics framework; `make xcode` regenerates the committed projects.

## Verification

`make test` includes engine priority/cooldown/focus/reset tests, generated Lua
API checks, city purchase/relocation input checks, both real match presentation
adapters, hidden-object finds/combos/misses/hints/completion, and Emergency events.
`testing.haptics()` flushes the pending frame and reports count, effect and
strength without driving hardware; it exists only in test builds.

This change has no visual output, so screenshots cannot demonstrate it. Physical
feel still needs review on an iPhone or Force Touch trackpad; simulators and
automated tests verify routing and timing, not actuator feel.
