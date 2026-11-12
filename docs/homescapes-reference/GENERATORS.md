# Homescapes source queues, palettes, tiles and blinds

The lab now initializes **1,005** of the 6,184 bundled levels, up from 753.
A 12-turn exercise played **11,717 legal moves on 996 boards**, advanced goals
on 897, emitted 2,851 queued pieces and 938 palette-controlled pieces, and
reported no construction or invalid-hint errors. Nine boards start stalled.
These measurements establish simulation coverage, not original-game equivalence
or solvability. See [LAB_COVERAGE.md](LAB_COVERAGE.md) for all remaining gaps and
[FEATURES.md](FEATURES.md) for the complete implemented feature reference.

## Evidence and verification boundary

[generator_evidence.py](../../tools/homescapes-reference/generator_evidence.py)
reads every XML directly from the original `base.zip` entry
`base_mm/fs_archives/match3levels.zstd`. It does not use the decoded working copy.
The tracked [generator-evidence.json](generator-evidence.json) contains archive
and corpus SHA-256 fingerprints, token frequencies and first source examples,
all property variants, palettes, loop flags and conflicting references.

The bundle contains:

- 743 files with `BornPatterns`: 1,086 definitions, 8,904 tokens, 47 token spellings;
  714 definitions loop and 372 are finite.
- 2,662 `ARTIFACT_GEN` instances. Each references a zero-based pattern ID and also
  stores an inline sequence and loop flag.
- 321 files with `ColorChipsPattern`, 1,349 `PATTERN_COLOR_BORN` instances and
  30 distinct color palettes. All source color patterns have a single `[Cs…]`
  token and looping instances.
- Ten invalid/conflicting generator references across four files. For example,
  `base/st/st0299.xml` names pattern ID 2 but defines only IDs 0 and 1. The lab
  rejects these records rather than choosing between their ID and inline string.
- New-format properties: `CountProperty`, `DropChanceProperty`, `LevelProperty`,
  `ColorSetProperty`, `RingProperty`. Every bundled drop chance is 100; every
  serialized `loopedCount` is zero. Zero is treated as no additional repeat
  override; nonzero values are rejected pending evidence.

The publisher's [generator guide](https://playrix.helpshift.com/hc/en/14-homescapes/faq/1216-generator/)
confirms that clearing space beneath a generator produces pieces, cookies,
donuts or power-ups. It does **not** document the token language. The table below
is the lab's explicit interpretation of the serialized tokens, not a recovered
original symbol table. In particular, `c6` in `contest_101_11` accompanies color-5
goals, supporting the one-based color suffix; `t1` sequences occur on cookie
boards such as `st0065`, and `T1` sequences accompany `TRASHSTONE` goals such as
`contest_016_02`. Special-token names and horizontal/vertical suffixes also
support the mappings, but original-runtime replay remains necessary to prove
them. No such replay has been performed.

## Supported queue grammar

| Token | Lab output |
| --- | --- |
| `[c]` | Seeded random gem from the board weights, or its explicit color-set weights |
| `[c1]` … `[c6]` | Fixed gem colors 0 … 5, including colors excluded from ordinary refill |
| `[b]`, `[f]`, `[z]` | Bomb, plane, rainbow ball |
| `[l]` | Seeded choice of horizontal or vertical rocket |
| `[lh]`, `[lv]` | Horizontal or vertical rocket |
| `[t1]`, `[t2]`, `[t3]` | Cookie with 1, 2 or 3 layers |
| `[T1]`, `[T2]`, `[T3]` | Hazelnut with 1, 2 or 3 layers |

Sequences must consist entirely of nonempty bracketed tokens. Trailing text,
nested/unfinished brackets and unknown tokens fail loading. Case is significant:
`T1` and `t1` are different pieces. Parsing only a known prefix is not allowed.
Unreferenced definitions remain retained in the source tree and inventoried;
only definitions actually used by a cell control that board.

Each source cell owns an independent queue cursor even if multiple cells use
the same pattern ID. Existing pieces fall before replacement begins. Refill
walks upward through the open column to its nearest source. A covered/frozen/
chained source cannot emit through its obstruction. Releasing the source
resumes its queue; it does not reset it. A looping queue wraps; a finite queue
returns to the ordinary source refill rules after its last item.

Explicit starting pieces and `RANDOM_CHIP` initialization are preserved.
Initially empty cells with an open generator route consume the sequence.
Fallback random initialization avoids immediate matches when possible; fixed
scripted colors are not changed to avoid matches. Initial queue consumption,
finite fallback, random rocket orientation and the lab's deterministic RNG are
simulation choices needing original-game timing verification. Gravity remains
straight-column: portals, diagonal routing and alternate gravity are not added.

### New-format properties

| Property | Implemented behavior | Rejected variants |
| --- | --- | --- |
| `CountProperty` | Repeat this unit `count` times, preserving order | Nonpositive/invalid counts; defensive limit 10,000 |
| `DropChanceProperty` | 100% deterministic emission | Any other chance; source does not establish retry versus skip semantics |
| `LevelProperty` | Single strength 1–3 for a cookie or hazelnut, bounded by `levelMax` | Multiple strengths, invalid bounds, other piece families |
| `ColorSetProperty` | Read the indexed `<set val="…">` beneath the matching named `colorSet`; six nonnegative weights, at least one positive | Missing/out-of-range set, unsupported token, `randomEverySpawn` other than 0 |
| `RingProperty` | Retained and reported | All runtime variants remain unsupported |

Property unit count must match token count; duplicate properties are rejected.
The known fixed-weight, fixed-strength interpretation is tested. Semantics for
randomized property variants are deliberately left unresolved. New-format
boards with other unsupported pieces remain rejected despite having some
supported property types.

## Color-source palettes and ordinary refill

`PATTERN_COLOR_BORN.id` indexes `ColorChipsPattern`. `[Cs123]` restricts emitted
gems to zero-based colors 1, 2 and 3; this differs from one-based `[c1]` tokens.
All 30 source palettes parse. Nonempty, unique digits 0–5 are required. Weights
come from `ChipSet`; a palette explicitly introducing a color absent there uses
weight 100. This absent-color default is a lab assumption. Restrictions affect
that source's new gems, not existing/falling pieces or unrelated columns.

`CarryChips`, `TrashChips` and `TrashStoneChips` now honor their explicit `<b
x="…" y="…"/>` source lists. A rule cannot produce an item from an unlisted
source. Empty source lists retain the previous unrestricted-birth-point
behavior. Population caps, strengths, `gen_limitation` and target-level chance/
maximum overrides remain implemented. Scripted queue outputs take precedence
while the queue has items; ordinary refill policies apply after exhaustion.
Conflicts in that priority have not been compared with original gameplay.

## Ceramic tiles (`BUBBLE_MEMBRANE`)

The original `ElementBubbleMembraneSettings` names `TunerUnder`, the target
`BUBBLE_MEMBRANE` and two visual states. Across all 280 files with placed tiles,
the goal equals the **number of tile cells**, rather than the sum of layers.
The [publisher tile guide](https://playrix.helpshift.com/hc/en/14-homescapes/faq/2381-tiles/)
requires a power-up to crack the intact tile, then a match to remove the remainder.

The lab represents tiles as stationary ground layers, separate from falling
pieces. Strength 2 ignores normal matches and takes one direct blast to become
strength 1. Strength 1 clears on a direct match or blast and credits one target.
Adjacent matches/blasts do not clear the tile. Ice, chains and solid covers
protect it for that resolution; the exact original simultaneous cover/tile
hit ordering remains unverified. Tiles do not restrict swaps, matches or gravity.
Invalid strengths are rejected. Tile generators remain unsupported.

## Window blinds (`SHUTTERS`)

The original `ElementShuttersSettings` names `IsBig`, `HidesChip`, adjacent-match
and explosion damage. XML anchors store `shutterHeight` (1–9 in this bundle),
with proxies naming `mainX/mainY`. The
[publisher blind guide](https://playrix.helpshift.com/hc/en/14-homescapes/faq/1421-window-blinds/)
describes rolling up by one cell per nearby match/power-up hit.

The lab validates a one-column footprint descending from the anchor. It retains
covered pieces, prevents their matching/movement, and gathers all affected
proxies into one hit per resolution. Each hit uncovers the lowest remaining
cell. Removing the last cell credits `SHUTTERS` once. Exposed pieces rejoin
normal gravity/refill. Missing anchors, out-of-footprint proxies and conflicting
footprints fail loading. Exact original simultaneous-hit scheduling remains
unverified, as with the existing apple platters and donut makers.

## Diagnostics, artwork and captures

No sprite was generated, recolored or substituted. Existing emitted pieces use
their decoded artwork; missing states remain textual diagnostics. The expanded
states are linked to [artwork issue #98](https://github.com/corepunch/nile-archive/issues/98):

| State | Runtime presentation | Reproduction/capture |
| --- | --- | --- |
| Visible artifact source, idle/emitting/exhausted | `Gen N`, the cumulative number of emitted queue pieces; source remains visible after exhaustion. Hidden source records have no label. This is not the original queue preview. | `--level packs/contest/contest_016_02.xml`; [generator capture](screenshots/lab-generators.jpg) |
| Intact/cracked ceramic ground | `Tile 2` / `Tile 1`; disappears on removal | `--level packs/contest/contest_011_15.xml`; [tile capture](screenshots/lab-tiles.jpg) |
| Blinds from height 9 down to 1, released cells | `Blind N` on covered cells; disappears on release | `--level base/st/st0401.xml`; [initial blind](screenshots/lab-blinds.jpg), [after hit](screenshots/lab-blinds-hit.jpg) |
| Stacked diagnostics on the same cell | Separate bounded lines so generator, piece and ground labels do not overlap adjacent cells | Generator and tile captures above |

Missing artwork acceptance criteria: extract/register original generator housing
and output preview including exhaustion, both ceramic states, every blind height
and roll transition; verify combinations with covered/falling pieces in runtime
captures. Text labels and existing blocker sprites do not satisfy that art work.

## Reproduction and checks

```sh
swift test --package-path prototypes/homescapes-match3
swift run --package-path prototypes/homescapes-match3 HomescapesLab --root "$PWD" --audit --exercise
python3 tools/homescapes-reference/generator_evidence.py
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tools/homescapes-reference -p 'test_*evidence.py'
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=tools/homescapes-reference python3 -m unittest test_archives.ArchiveTest.test_all_level_files_match_archive
make lint
```

The Swift audit reports `unsupportedConfigurations` separately from unknown
model/goal identifiers and actual load/execution errors, including generator
issues on boards already rejected for unrelated blockers. `patternSpawns` and
`paletteSpawns` include initial-fill emissions and subsequent moves, providing
execution evidence beyond vocabulary acceptance. No original source file is
modified. The local full report is `reference/homescapes-analysis/lab-audit.json`.

Measured verification: the latest Swift test build took 2.77 s; 44 tests ran in
5.92 s. The 6,184-level exercise took 20.79 s. Six original-resource inventory
tests took 2.13 s; the byte-for-byte original archive check took 1.76 s. UI-only
rebuilds took 3.12 s and 4.29 s; lint took 1.54 s with zero warnings/errors.
Native captures above are 1520×1496 and were inspected. A real drag on `st0401`
consumed one move (29→28), rolled the left blind from five covered cells to four,
released its bottom cell, and spread carpet from 12 to 14. A real match on the
tile board consumed one move while leaving intact strength-2 tiles unbroken.
The visual pass corrected overflowing stacked labels and hid pieces beneath
closed blinds. No original-game executable replay was possible in this session.
