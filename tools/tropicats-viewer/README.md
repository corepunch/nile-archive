# Tropicats level atlas

Local browser for the data described in [the analysis](../../docs/TROPICATS_ANALYSIS.md).
No installation, build step or network access is needed. Requires Python 3 and
the already extracted `reference/tropicats-analysis/` directory.

From the repository root:

```sh
python3 tools/tropicats-viewer/serve.py
```

Open <http://127.0.0.1:8765>. Use `--port 8766` for another port or
`--data /absolute/path/to/tropicats-analysis` for another extraction location.
The server binds only to loopback and exposes four static UI files, a campaign
index and numbered-level JSON. It cannot edit the extracted data or serve
arbitrary repository files. Stop it with Ctrl+C.

## Browsing

- Search by level number, quest title/ID or objective; filter by chapter and goal.
- Compare easy, medium and hard together, including move budgets and explicit goals.
- Choose a board layer, or the combined schematic; highlight differences from easy.
- Click a cell to inspect the same coordinate across all tiers. Arrow keys move
  the selection. Flip rows changes presentation while preserving source indexes.
- Expand raw definitions for exact spawning parameters, piece palette and JSON.
- Copy a level URL such as `http://127.0.0.1:8765/#level=2730`.

Boards are labeled data schematics, not original game artwork or simulations.
Random cells remain `?`; the viewer never invents a random starting board.
The combined view prioritizes stones and pieces, with compact special/chain/
hidden-object/portal labels. Other layers remain available through the selector
and inspector. Zero-field cells remain inspectable. Multi-layer badges may be
abbreviated with `+`; the inspector always exposes every layer.

Some goals are inferred by the game at runtime. The viewer shows explicit
`data.objectives`, distinct hidden-object IDs, and initial treasure cells;
otherwise it explicitly says the target comes from board layers. Occupied cell
counts are not hit points. Field-mask values other than zero are counted without
assuming they all behave like normal playable cells. Board rows follow source
array order; runtime orientation has not been independently verified.

Piece colors/types/modifiers and spawn enum values were checked against the
app's IL2CPP v31 field defaults. The table layout was interpreted using the
[Il2CppDumper metadata definitions](https://github.com/Perfare/Il2CppDumper/blob/master/Il2CppDumper/Il2Cpp/MetadataClass.cs).
For the small nonnegative enum values used here, compressed default bytes decode
as byte / 2; values were read, not inferred from string-table ordering. Unknown
values remain numeric. `Field.TILE_AMOUNT_FOR_WATERED` is 3.

## Verification

```sh
node --test tools/tropicats-viewer/model.test.mjs
python3 -m unittest discover -s tools/tropicats-viewer -p 'test_*.py'
make lint
```

The Node tests use small independent examples for comparison, row orientation,
goal interpretation and intersecting filters. HTTP tests require local reference
data and loopback access, and skip when that data is absent. They cover real
campaign data, tier loading, module serving, and rejection of arbitrary file
paths/invalid level numbers. No game or engine behavior is changed by this tool.

Verified 2026-11-11: five model tests (0.24 s process time), three HTTP tests
(0.71 s process time), and repository lint (1.06 s). There is no build step.
Browser checks covered level search, chapter/objective filter intersection,
levels 1/8/2730, layer selection, change highlighting, keyboard cell inspection,
row flipping, and the desktop/narrow layouts. No browser console errors were
observed. Review captures: [desktop](../../docs/review/tropicats-viewer/desktop.jpg)
and [narrow](../../docs/review/tropicats-viewer/narrow.jpg).
