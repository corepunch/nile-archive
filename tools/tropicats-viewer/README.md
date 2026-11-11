# Tropicats level atlas

Local browser for the data described in [the analysis](../../docs/TROPICATS_ANALYSIS.md).
No build step or network access is needed for viewing. Requires Python 3 and
the already extracted `reference/tropicats-analysis/` directory.

From the repository root:

```sh
python3 tools/tropicats-viewer/serve.py
```

Open <http://127.0.0.1:8765>. Use `--port 8766` for another port or
`--data /absolute/path/to/tropicats-analysis` for another extraction location.
The server binds only to loopback and exposes five static UI files, a campaign
index, numbered-level JSON and manifest-listed PNG artwork. It cannot edit the extracted data or serve
arbitrary repository files. Stop it with Ctrl+C.

## Browsing

- Search by level number, quest title/ID or objective; filter by chapter and goal.
- Compare easy, medium and hard together, including move budgets and explicit goals.
- Choose a board layer, or the combined sprite view; highlight differences from easy.
- Toggle Original sprites to return to the schematic. Disable Preview random fruit
  to see the original striped random-color markers.
- Click a cell to inspect the same coordinate across all tiers. Arrow keys move
  the selection. Flip rows changes presentation while preserving source indexes.
- Expand raw definitions for exact spawning parameters, piece palette and JSON.
- Copy a level URL such as `http://127.0.0.1:8765/#level=2730`.

The combined view uses the game's original sprites when the local art extraction
is present. See [ART.md](ART.md) for extraction, the complete source catalogue,
layer mapping, reconstructed bomb/line materials, colored-crate LUT rendering,
portal registration, cannon gauges, skeletal chameleon colors, wheel segments and remaining fidelity work. The optional
random-fruit preview is clearly labeled: it uses a deterministic sample from the
level palette and does not reproduce the game's RNG or simulate play. Changing
this display option never changes source values or the difference counts.

Cannons use their native tint map and mouth gauge: low/medium/high precharge is
0/15/30 out of 45. None of the 3,668 campaign cannon placements encode a direction;
the viewer preserves the authored facing pose. Chameleons use the original skeleton,
body/next-color shader and left/right facing. Wheels use the level palette and the
original 3–6 segment assets, including coins. Reduced palettes omit weights below
25, an inference grounded in metadata and checked against every wheel layout.
Chameleon next-color order and clockwise wheel order are illustrative; cannon
cover travel is fitted to the original mask. These limits are visible in the inspector.

The optional cached `m3_themes` bundle supplies objective-specific original board textures; otherwise the recipe texture is used. Vertical window bridges use original sprites with inferred adjacency, and the growing bridge variant is illustrative. See the artwork audit for remaining fidelity gaps.

Without extracted artwork the viewer falls back to its schematic. Numeric layer
views and the inspector remain available in either mode, including zero-field
cells and details not rendered by the static artwork.

Some goals are inferred by the game at runtime. The viewer shows explicit
`data.objectives`, distinct hidden-object IDs, and initial treasure cells;
otherwise it explicitly says the target comes from board layers. Occupied cell
counts are not hit points. Field-mask values other than zero are counted without
assuming they all behave like normal playable cells. Board rows follow source
array order; runtime orientation has not been independently verified.

Piece colors/types/modifiers, direction and spawn enum values were checked against the
app's IL2CPP v31 field defaults. The table layout was interpreted using the
[Il2CppDumper metadata definitions](https://github.com/Perfare/Il2CppDumper/blob/master/Il2CppDumper/Il2Cpp/MetadataClass.cs).
For the small nonnegative enum values used here, compressed default bytes decode
as byte / 2; values were read, not inferred from string-table ordering. Unknown
values remain numeric. `Field.TILE_AMOUNT_FOR_WATERED` is 3.

## Verification

```sh
node --test tools/tropicats-viewer/model.test.mjs tools/tropicats-viewer/art.test.mjs
/tmp/tropicats-inspect-venv/bin/python -m unittest discover -s tools/tropicats-viewer -p 'test_*.py'
make lint
```

The Node tests cover comparisons, row orientation, goals, filters, palette preview,
layer stacking, multi-cell footprints and non-fruit special cases. With local
reference data, the artwork test checks sprite-name resolution for all 8,190
campaign variants in exact and preview modes. HTTP tests require local data and
loopback access; they cover campaign data, tiers, artwork serving and path rejection.
Local-data checks skip when their reference files are absent. The material checks
use Pillow in the extraction environment; standard-library-only HTTP checks can
still run with `python3`. Tests also cover original shader channels, LUT brightness
orientation, all crate alpha planes, line axes and every campaign portal boundary/pair.
Mechanic tests cover charge mapping, reduced palettes, wheel layers, chameleon
facing, unequal shader texture sizes and alpha preservation for all 49 color pairs.

Verified 2026-11-11: fifteen Node tests **2.38 s**, ten material/HTTP tests **0.89 s**,
repository lint **1.10 s** (measured wall time). There is no build step and no changed game or
engine dependency. Browser checks and before/after captures are recorded in
[the artwork audit](ART.md#visual-audit).
