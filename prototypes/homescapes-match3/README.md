# Homescapes Match-3 Lab

This standalone macOS Swift package opens match-3 boards from the
Homescapes 9.2.601 bundle. It reads the extracted XML, including the board
shape, fixed pieces, blocker strengths, goals and move budget, and displays
the decoded art in SpriteKit. The game has no animation. Eight sample boards open by default; `--all-levels`
loads every board accepted by the simulator (currently 753).

Run from the Nile Archive checkout root with Xcode's Swift toolchain:

```sh
swift run --package-path prototypes/homescapes-match3 HomescapesLab --root "$PWD"
```

The app reads the local reference assets in place. See the
[Homescapes art reference](../../docs/homescapes-reference/ART.md) for the
extraction commands. The package manifest also opens directly in Xcode.

Use the menu to choose `st0004`, `st0008`, `st0011`, `st0016`, `st0022`,
`st0031`, `st0131` or `st0136`. Swap with a drag or two clicks. Click a
special twice to activate it. Restart replays the same seed, and New seed
changes the random fill. Hint highlights a legal move. The names are source
file IDs.

The rules cover horizontal and vertical matches, 2 × 2 planes, rockets,
bombs and rainbow balls, gravity, refill, cascades, locks, ice, boxes,
cookies, carpet spread and donut exits. Sprite states use the same
[model map](../../tools/homescapes-reference/model_sprites.json) as the web
explorer. The original refill algorithm, level scripting, spawn routing,
the exact hit and targeting order remain
unverified. The lab uses seeded weighted fills and straight gravity.
Unsupported models, goals and malformed supported configurations are rejected
when loading a playable board. Newly simulated blockers use explicit diagnostic
labels wherever verified original state artwork is unavailable.

```sh
swift test --package-path prototypes/homescapes-match3
swift run --package-path prototypes/homescapes-match3 HomescapesLab --root "$PWD" --check
```

The first command verifies special creation and held-piece damage. The
second loads the eight local boards and plays up to 12 legal moves on each.

The loader also retains the exact source XML and a generic element tree, including
unknown configuration and nested model data, for future mechanic implementation.
Retention does not imply that those mechanics are understood or playable. The
corpus test checks every locally extracted XML file; the archive test checks the
extracted bytes against the original bundled archive.

## Power-up combination coverage

The lab combines two rockets into a one-row/one-column cross, regardless of
rocket orientation. A bomb and rocket clear three rows and three columns.
Both ingredients are consumed once, other power-ups inside the footprint chain,
and the swap costs one move. Blasts now damage only cells in their footprint;
adjacent-match damage still applies to boxes and cookies.

These shapes follow Playrix's [combination rules](https://playrix.helpshift.com/hc/en/14-homescapes/faq/16363-what-power-up-combinations-are-available-in-the-game/)
and [rocket rules](https://playrix.helpshift.com/hc/en/14-homescapes/faq/16313-power-ups-and-how-to-use-them/),
checked on 2026-11-12. The local 9.2.601 XML corpus contains 1,227 `LINE`
instances (678 with `line_orient=0`, 471 with `2`, and 78 with `-2`),
1,131 `BOMB` instances and 292 `LIGHTNING` instances. The tests exercise all
three serialized rocket orientations and both ingredient orders.

This is verification against publisher documentation and source identifiers,
not an original-runtime replay. The bundled executable targets iPhoneOS and
was not run for this change. The publisher describes the current game, which
may differ from this bundle. The lab centres combinations at the dragged
piece's destination; the original centre and hit scheduling still need
recorded gameplay confirmation. Every pair now has combination dispatch; see the evidence and limitations below. Bomb radius, plane targeting, refill and cascades
also retain the limitations described above. No new artwork or state mapping
was introduced.

`CombinationTests` checks footprint boundaries, single-layer damage, both
ingredient orders, all bundled rocket orientations, chain activation and the
public swap path. The full Swift test suite also checks all 6,184 source files.

## Additional rules and verification

The lab now implements these additional combination behaviors from the same
publisher guide: bomb+bomb doubles the lab bomb radius; plane+plane selects
three distinct destinations; plane+bomb/rocket delivers the payload; rainbow
with a bomb, rocket or plane converts the most common color and detonates the
converted pieces; two rainbows hit every cell once. Existing sprites are reused
unchanged. No new artwork or artwork mappings were added.

These remain **approximations**, not verified reproductions of version 9.2.601:

- The bomb uses a square radius of one cell (two when doubled). The original
  footprint is not established by the decoded level XML.
- Plane destinations use deterministic obstacle-first ordering, not the
  original random target selection. Rocket conversions preserve the partner's
  orientation. Ties between common colors use stable numeric order.
- Frozen/chained gems are excluded from rainbow conversion. Explosions merged
  into one resolution damage each cell once; original sequential multi-hit
  behavior and carpet propagation through chained power-ups remain unverified.
- Double rainbow retains donuts for exit collection and removes one restraint
  layer before touching the covered object. Exact interaction with every
  original obstacle is not claimed.

Restraints now protect cookies until cleared. This follows the publisher's
[ice](https://playrix.helpshift.com/hc/en/14-homescapes/faq/1081-ice/) and
[chains](https://playrix.helpshift.com/hc/en/14-homescapes/faq/1079-chains/) rules.
Stacked donuts settle through marked exits before refill, following the
[donut collection rule](https://playrix.helpshift.com/hc/en/14-homescapes/faq/1085-donuts/).
Source-configured donut generation is now implemented with documented limits;
portal routing and alternate gravity remain unimplemented.

## Full corpus audit

Run from the repository root:

```sh
swift run --package-path prototypes/homescapes-match3 HomescapesLab --root "$PWD" --audit > /tmp/homescapes-level-audit.json
```

The audit reads every level, records all unsupported model and goal identifiers
per path, counts configuration sections, and tries board construction only when
the identifiers are accepted. Parse/construction failures produce a nonzero
exit; unsupported vocabulary is report data. `originalRuntimeVerified` is
explicitly false. A successful initialization is not proof of full simulation
support: serialized generators, scripts and routing can still be ignored.
See [the coverage record](../../docs/homescapes-reference/LAB_COVERAGE.md).

## Blockers, generators and access to more boards

The current source audit accepts **753 boards**, up from 232. A 12-turn exercise
played 8,791 legal moves on 747 of them; six start without a legal move. This is
execution coverage, not a claim of exact reproduction or guaranteed solvability.

The new rules cover jelly around cherries, colored boxes, movable hazelnuts,
fixed statues, shared apple platters, donut makers and cookie stacks. Source
`FISH` pieces now load as planes. Cookies move with their strength and stop
rocket beams. Refill reads the original chance/capacity/strength/goal-limit
configuration for cookies, hazelnuts and donuts. See the
[blocker evidence, limitations and visual catalogue](../../docs/homescapes-reference/BLOCKERS.md).

```sh
swift run --package-path prototypes/homescapes-match3 HomescapesLab --root "$PWD" --all-levels
swift run --package-path prototypes/homescapes-match3 HomescapesLab --root "$PWD" --level base/st/st0051.xml
swift run --package-path prototypes/homescapes-match3 HomescapesLab --root "$PWD" --audit --exercise > /tmp/homescapes-level-audit.json
```

The picker lists source paths to distinguish files with the same basename.
App bundles can set `LabRoot` and `LabAllLevels` in Info.plist for the same
behavior without command-line arguments. Command-line root takes precedence.

The missing authored blocker/generator states are tracked in
[issue #98](https://github.com/corepunch/nile-archive/issues/98). The labels and
material preview are intentional diagnostics, not finished game artwork.
