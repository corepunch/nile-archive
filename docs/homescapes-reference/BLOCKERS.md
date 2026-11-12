# Homescapes blocker and generator implementation

This is a simulation lab for the local 9.2.601 bundle, not an original-runtime
reimplementation. The additions raise accepted boards from 232 to 753. A
12-move corpus exercise played 8,791 legal moves on 747 boards, with goal
progress on 665. Six accepted boards start stalled; 5,431 still have unsupported
vocabulary. No board construction or invalid-hint errors occurred. These
measurements establish execution coverage, not solvability or rule equivalence.

## Original resource evidence

[`mechanic_evidence.py`](../../tools/homescapes-reference/mechanic_evidence.py)
reads named records from `Library.xml.meta`, decompresses their VSO sections,
and records source offsets, sizes, SHA-256 and identifier strings in
[mechanic-evidence.json](mechanic-evidence.json). This is bounded record
inspection, not a complete binary schema decoder. The accompanying Python
tests protect the identities and capability names relied on by the Swift code.

| Serialized model | Source record/evidence | Implemented behavior |
| --- | --- | --- |
| `HONEY` | `ElementHoneySettings`: blocks match/fall/swap; adjacent-match and near-explosion damage | Jelly covering a cell, strengths 1–6; hides its gem from matching and releases a cherry when the last layer is removed |
| `COLOR_BOX` | `ElementColorBoxSettings`: `HasColor`, `CanClearByNearColoredMatch`, explosion damage | Colors 0–5 and serialized strengths; matching-color neighbor or explosion removes a layer; final removal credits `COLOR_BOX` |
| `TRASH_STONE` | `ElementTrashStoneSettings`: fall/swap, explosion-only damage, `TRASHSTONE` target | Movable hazelnut strengths 1–3; ordinary neighboring matches do not damage it |
| `STATUE` | `ElementStatueSettings`: target and explosion-only damage | Fixed strengths 1–3; final explosion credits `STATUE` |
| `TARGET_GEN` | `TargetGenerator` prefab names `ModelToTargetApple`; settings name `TARGET_GENERATOR` | Apple platter, not toaster; shared 2×2 occupancy, one apple per resolution, disappears at zero |
| `CARRY_GEN` / `CARRY_GEN_CELLS` | `ElementCarryGeneratorSettings`; XML `mainX/mainY`, `carryGenMax`, `carryGenActivatePer` | Shared maker counter, marked output cells, capped by outstanding donut goals; see inference limits below |
| `COOKIE_BOX` | `ElementCookieBoxSettings`: target generator with near-match/explosion damage; serialized strength 3 | Three hits release three movable cookies, pending if no free gem slots are available |
| `FISH` | `ElementBonusFishSettings` names `plane` | Loads the existing paper-plane piece and uses the existing plane sprite |
| `BORN` plus refill sections | `ElementBornPointSettings` names `IsBornPoint`; `CarryChips`, `TrashChips`, `TrashStoneChips`, nested target params | Refill honors explicit chance, maximum population, strength and goal limitation when a column has an unobstructed route to a birth point |
| Existing `TRASH` / `CARRY` | Original settings explicitly include fall/swap; cookies also name `StopsLineExplosion` | Cookies now move with their strength and block rocket rays; donuts can participate in a valid swap without matching |

Publisher cross-checks: [cherries and jelly](https://playrix.helpshift.com/hc/en/14-homescapes/faq/1210-cherries/),
[colored boxes](https://playrix.helpshift.com/hc/en/14-homescapes/faq/11953-colored-boxes/),
[hazelnuts](https://playrix.helpshift.com/hc/en/14-homescapes/faq/1209-hazelnuts/),
[apples](https://playrix.helpshift.com/hc/en/14-homescapes/faq/1212-apples/),
[donut makers](https://playrix.helpshift.com/hc/en/14-homescapes/faq/1333-donut-maker/),
[generators](https://playrix.helpshift.com/hc/en/14-homescapes/faq/1216-generator/).
The element index also describes three-hit cookie stacks and explosion-only
statues. These are current publisher rules, which can differ from the bundle.

## Interpretation limits

- `carryGenActivatePer` is interpreted as the hit threshold and `carryGenMax`
  as batch size. Output selects marked, unrestrained gem cells in coordinate
  order, and waits if none are available. That scheduling and the batch-size
  interpretation need original-game observation; they are not proven by field
  names alone. Maker boards suppress ordinary donut refill to avoid duplicate
  production. Makers stop producing when enough donuts exist for the goal.
- Legacy apple anchors reserve the cells at `(x,y)`, `(x+1,y)`, `(x,y-1)`,
  `(x+1,y-1)`. Explicit `mainX/mainY` references are validated against those
  shared footprints. Mismatched/missing anchors fail loading rather than
  silently becoming four independent objects.
- Cookie stacks use deterministic free-gem placement and retain pending output.
  Exact original scatter order and simultaneous hit scheduling remain unknown.
- Explicit refill values are obeyed. Legacy donut sections omit chance and
  population defaults; the lab assumes 100% chance and preserves the initial
  donut population (at least one). Those defaults are unverified. Random rolls
  use the lab's seeded generator, not the original game's RNG.
- Refill is still straight-column with a random-fill fallback; diagonal flow,
  portals, alternate gravity, `ARTIFACT_GEN` and its `BornPatterns` grammar are
  not implemented. `BORN.isLooped` is retained but not interpreted. Unknown artifact generators remain rejected. The lab does
  not claim every initialized board's routing or scripting is understood.
- Blast overlap is a single damage pass. Matching groups that resolve together
  also share a pass; original multi-hit timing can differ. This especially
  affects platter/maker activation counts.
- There is no replay against the original executable. Computer Use could not
  open the original Homescapes application; the visual review below is the lab.

## Runtime visual catalogue

No new bitmap artwork was fabricated or recolored. Existing decoded sprites
remain unchanged. Every incomplete state below is explicitly diagnostic and
tracked by [issue #98](https://github.com/corepunch/nile-archive/issues/98).

| State family | Runtime presentation | Source/reproduction | Reviewed capture |
| --- | --- | --- | --- |
| Jelly strengths 1–6, with covered gem/cherry | Existing `honey-material` preview plus `Jelly N` label; not authored strength art | Existing `model_sprites.json` mapping, `Cell.artModels`, `BoardScene.drawBoard` | [Jelly](screenshots/lab-jelly.jpg) |
| Apple platter count and all four footprint cells | `Apples N` labels; no substituted sprite | Original `TARGET_GEN` record and `mainX/mainY`; `--level base/st/st0051.xml` | [Before hit](screenshots/lab-apples.jpg), [after real drag](screenshots/lab-apples-hit.jpg) |
| Maker idle/charging/release counter and statue strengths 1–3 | `Maker H/P` and `Statue N` labels | `--level base/st/st0255.xml`; original counters/strengths | [Makers/statues](screenshots/lab-makers-statues.jpg) |
| Hazelnut strengths 1–3 and restrained plane | `Nut N` labels; existing plane and restraint sprites | `--level packs/contest/contest_005_06.xml`; `FISH` prefab identity | [Hazelnuts/plane](screenshots/lab-hazelnuts-plane.jpg) |
| Cookie stack strengths 3→2→1 and generated cookies | `Stack N` labels, then original cookie sprites | `--level packs/contest/contest_026_01.xml` | [Stacks](screenshots/lab-cookie-stacks.jpg) |
| Colored-box colors 0–5 × strengths 1–6 | `Box Ccolor:strength` labels; no tint-based replacement art | `--level packs/contest/contest_172_04.xml` | [Normal window](screenshots/lab-colored-boxes.jpg), [wide window](screenshots/lab-colored-boxes-wide.jpg) |
| Birth points and refill policies | No added generator sprite; generated piece uses its existing art or diagnostic label | Original `BORN` and refill sections; `RefillTests` | Covered by blocker boards above |

The default Mac window captures are 1520×1496 physical pixels; the zoomed window
is 4324×2458. Each image was inspected. Real input on `st0051` consumed one move,
credited one apple, and changed all four cells of the affected platter from
8 to 7. The capture set is representative, not an artwork sign-off for every
strength/color. Exhaustive authored state art remains in issue #98.

## Reproduction and checks

From the repository root:

```sh
swift test --package-path prototypes/homescapes-match3
swift run --package-path prototypes/homescapes-match3 HomescapesLab --root "$PWD" --audit --exercise > /tmp/homescapes-lab-audit.json
swift run --package-path prototypes/homescapes-match3 HomescapesLab --root "$PWD" --all-levels
swift run --package-path prototypes/homescapes-match3 HomescapesLab --root "$PWD" --level base/st/st0051.xml
python3 tools/homescapes-reference/mechanic_evidence.py
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tools/homescapes-reference -p test_mechanic_evidence.py
make lint
```

The locally retained machine report is
`reference/homescapes-analysis/lab-audit.json`. `--audit --exercise` records
turns, goal progress, stalls, complete unsupported vocabulary, and errors per
level. `--all-levels` exposes all accepted paths in the picker; `--level` loads
one specified relative source path. Neither changes the original reference data.

Measured checks: Swift build 7.76 s, 30 tests 9.54 s; subsequent UI-only build 2.54 s. Corpus exercise 16.60 s; original-record tests
0.116 s; lint 1.94 s. No dependencies or large data were downloaded.
