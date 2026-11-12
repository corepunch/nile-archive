# Homescapes board artwork: recovered states and source limits

The missing-art work is **not complete**. Original graphics now replace the
nut, statue, cookie-stack and tile diagnostics. Apple platters, blinds and
visible queues also render original components. Maker charge previews use
original base/dough components, but the intact dome and exact source poses have
not been recovered. Colored boxes and six jelly strengths remain unresolved.

## Sources and registration

- The local `reference/Homescapes.app` 9.2.601 bundle supplies the existing
  pieces/power-ups and 13 added original goal icons. The goal images are lossless
  WebP-to-PNG conversions, verified against the archive and decoded pixel hashes.
- Original Android **3.5.9** art supplies nine blocker states, tile materials,
  the apple platter, blind header/body, queue inlet and maker components. The
  source archive is preserved locally at
  `reference/homescapes-analysis/historical/homescapes-3.5.9.apk` (ignored source,
  not a runtime dependency). SHA-256:
  `8b1a2ac9b4bbf7c4cd3122fcde18e806d3623695c841c6af0c7e14148e1cb093`.
  Its public archive listing is [APK.Gold 3.5.9](https://apk.gold/download?file_id=1370034/homescapes).
- A **6.8.5** APK was inspected through HTTP byte ranges. Only selected members
  were downloaded. Its four core Match3 pages, four named element pages and 24
  plausible shared/UI/Match3/playable pages did not establish the colored-box
  family. `Match3_ColorBox.pbi` references `Box_1_blue` and the `ColoredBox`
  particle texture tree, but those files are absent from the ZIP directory.
- A complete local `reference/` filename, hidden-file, symlink and archive
  inventory found no additional Homescapes cache. Before the historical source
  was added, 34 ZIP-format archives were present; the archives outside the app
  were unrelated Volcano review assets. The two existing decoded board-art
  directories contain identical five-page sets by hash.

No images were generated or recolored. Object sprites preserve their source
alpha and use uniform scaling. Nuts, statues, cookie stacks, the platter, maker
base, blind header and queue shell need the documented 180° atlas rotation,
checked against official Playrix illustrations. The source ceramic interiors and shutter material are spatial crops
resized and masked to the canonical flat-top hex. The shutter crop excludes
transparent side margins; it does not invent alpha. Source PNGs remain intact.

The atlas contains 68 source PNGs and 93 registered names including aliases and
spatial composites. All three skins retain a single board texture. The default
packer now expands its canvas when additional frames exceed the old height;
Christmas Market now uses a 2048×4096 atlas.

Imported source fields now fit their actual active-cell bounds to the available
phone area between HUD and tools. Empty cells in the enclosing grid no longer
shrink or displace the board. The fit preserves proportions, keeps every hex
face on screen, and shares its shifted origin with pointer hit testing. Tool
buttons remain centred independently of asymmetric source masks.

## Runtime state coverage

| Model | Rendering now | Evidence / remaining limitation |
| --- | --- | --- |
| `TRASH_STONE` | `hazelnut-1..3` | Original exposed/split/whole states; strength order inferred from damage appearance. |
| `STATUE` | `statue-1..3` | Original carved/cut/raw stone states; strength order inferred from appearance. |
| `COOKIE_BOX` | `cookie-stack-1..3` | Original plain/strap/bow states; order and rotation checked against [Playrix's illustration](https://playrix.helpshift.com/hc/en/14-homescapes/faq/2383-cookie-stack/). |
| `BUBBLE_MEMBRANE` | `membrane-fill-1..2` below pieces | Original cracked fill and intact tile interior, canonically masked. Original square borders are omitted for the hex adaptation. |
| `TARGET_GEN` | `apple-platter-1..9`, once per four-cell footprint | Original platter and isolated original goal apple. Placement/removal order is a documented hex adaptation, not decoded prefab geometry. Nine apples use a 3×3 arrangement. |
| `SHUTTERS` | Original `blind-body` on covered cells plus `blind-top` at the anchor | Remaining height follows the existing rule group; no `BL` counter. Source square material is cropped/masked to each hex. |
| Visible `ARTIFACT_GEN` | Original `generator-shell` plus the next original piece/element | Reading the queue for drawing does not advance its cursor or RNG. Random units show the shell without pretending a specific next color is known. |
| `CARRY_GEN` | `donut-maker-0..3` over the group footprint | Original base and dough sprites; charging-stage association is inferred. The intact dome and exact charge poses remain missing, so this is **not complete original maker artwork**. |
| Goal panel | Original goal icons, with original board sprites for nuts/statues/tiles/blinds | `COLOR_BOX` is still a diagnostic label. |
| `COLOR_BOX` | Existing ordinary-box image plus `C<color>` | **Unresolved:** six colors × six original strengths; ordinary boxes are not accepted as finished colored-box art. |
| `HONEY` | Existing material preview plus `J<hits>` | **Unresolved:** six-layer original composition. A new exact source swatch is archived, but does not establish six states and is not substituted as a claimed fix. |
| Legacy tunnel/exit markers | Existing `IN`/`OUT`/`EXIT` text | **Unresolved original imagery.** Tutorial masks and unrelated arrow icons were not relabeled as portal/exit sprites. |

The original app's atlas/prefab metadata uses PLXE 5 payloads. The older raw
Zstandard recipe does not decode these payloads. That prevents verification of
named sprite regions, exact layer placements and source animation poses; it
must not be reported as recovered parity. Existing gameplay animation/effects
are retained, as requested.

## Reproduction and validation

The extraction tools use Pillow and the existing `texture2ddecoder` decoder.
Pass the installed decoder directory through `PYTHONPATH` if necessary. No
historical game executable is run.

```sh
python3 tools/homescapes-reference/extract_generator_goals.py --check
python3 tools/homescapes-reference/extract_historical_art.py --apk reference/homescapes-analysis/historical/homescapes-3.5.9.apk
python3 tools/homescapes-reference/extract_generator_historical.py --apk reference/homescapes-analysis/historical/homescapes-3.5.9.apk
python3 tools/homescapes-reference/extract_historical_tiles.py reference/homescapes-analysis/historical/homescapes-3.5.9.apk
python3 tools/homescapes-reference/extract_historical_membrane.py reference/homescapes-analysis/historical/homescapes-3.5.9.apk
python3 tools/homescapes-reference/extract_shutter_texture.py --apk reference/homescapes-analysis/historical/homescapes-3.5.9.apk
python3 tools/homescapes-reference/extract_surface_swatches.py
python3 tools/match3_atlas.py
python3 tools/match3_atlas.py --check
```

Source rectangles, hashes and rotations are recorded under
`engine/art/homescapes/*sources.json`, `surface-swatches.json` and
`tools/homescapes-reference/*historical*regions.json`. Composite positions and
input parts are recorded by `tools/homescapes_composites.py` in each atlas
manifest. The original shutter WebP member is
`assets/base_mm/textures/Match3/Shutters/back.webp`, SHA-256
`11ba4228972ef054b2824a97a65503c48ac40dac126d12b4e9762be4cc0e67af`.

[Reviewed runtime captures and checks](review/homescapes-restored-art/README.md)
cover the actual field in both games at both portrait sizes. The regression
checks verify single rendering of a shared footprint and that queue previews
cannot consume pieces. Fourteen registered cell/object states pass the
canonical strict fill/object tests. Group composites span four cells and are
reviewed as objects, not certified as single-hex fills.

Remaining acceptance criteria stay tracked in
[issue #98](https://github.com/corepunch/nile-archive/issues/98): source-supported
colored boxes, six jelly layers, complete maker artwork/poses, original
portal/exit markers, and exact source group composition where 1:1 parity is
required. Removing a diagnostic without obtaining its original artwork does
not close that requirement.
