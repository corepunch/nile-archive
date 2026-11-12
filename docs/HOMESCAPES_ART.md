# Homescapes board artwork

The hex board uses original graphics for all six jelly strengths, both portal
ends, the donut exit arrow and all 36 colored-box field states. The classic
maker's five charge poses use original dough, glaze and topping layers.
Original particle timing, indicator placement and exact group composition
remain open in [issue #98](https://github.com/corepunch/nile-archive/issues/98).

## Sources and registration

- The local `reference/Homescapes.app` 9.2.601 bundle supplies the existing
  pieces/power-ups and 13 added original goal icons. The goal images are lossless
  WebP-to-PNG conversions, verified against the archive and decoded pixel hashes.
- Original Android **3.5.9** art supplies nine blocker states, tile materials,
  the apple platter, blind header/body, queue inlet, maker components, the
  jelly layers and the portal rings. The
  source archive is preserved locally at
  `reference/homescapes-analysis/historical/homescapes-3.5.9.apk` (ignored source,
  not a runtime dependency). SHA-256:
  `8b1a2ac9b4bbf7c4cd3122fcde18e806d3623695c841c6af0c7e14148e1cb093`.
  Its public archive listing is [APK.Gold 3.5.9](https://apk.gold/download?file_id=1370034/homescapes).
- Android **1.1.0.900** independently identifies portal direction and placement
  via `textures/Match3/Elements/portal/in.webp` and `out.webp`. The ignored
  source archive is
  `reference/homescapes-analysis/historical/homescapes-1.1.0.900.apk` with
  SHA-256 `e796ea6b8da7d1645845f0217b2a731f9babe327665f9a4e011c68960d3c64c2`.
  The archive listing is [APK.Gold 1.1.0](https://apk.gold/download?file_id=397849/homescapes).
- Android **6.3.2** supplies the colored-box goal icon as the original WebP.
  The original member and pixel hashes are in
  `engine/art/homescapes/color-box-goal-source.json`. Its four core Match3
  pages lack identifiable colored-box board sprites.
- Android **8.8.602** supplies independent portal evidence in the named
  `Match3_Portal.dds` pack. Byte ranges from the [8.8.602 XAPK](https://apkpure.net/homescapes-android/com.playrix.homescapes/download/8.8.602)
  covered five core Match3 pages, the pack directory and selected members.
  The shipped Match3 packs cover Bookshelf, GarbagePlate, Portal, Rug,
  Settings, SwapWall, TapeMeasure and TargetGenerator. None supplies a named
  colored-box art pack in that archive.
- A **6.8.5** APK was inspected through HTTP byte ranges. Only selected members
  were downloaded. Its four core Match3 pages, four named element pages and 24
  plausible shared/UI/Match3/playable pages did not establish the colored-box
  family. `Match3_ColorBox.pbi` references `Box_1_blue` and the `ColoredBox`
  particle texture tree, but those files are absent from the ZIP directory.
- The **9.2.601.0 Windows x64** package supplies the complete colored-box
  field atlas and the classic maker's authored charge layers. Only selected
  files were fetched by byte range. The ignored originals are preserved under
  `reference/homescapes-analysis/windows-9.2.601/`.
  [Windows source inventory](homescapes-reference/board-pack-evidence.json) · [Microsoft Store](https://apps.microsoft.com/detail/9NQ9KLZNV9SH)
- A complete local `reference/` filename, hidden-file, symlink and archive
  inventory found no additional Homescapes cache. Before the historical source
  was added, 34 ZIP-format archives were present; the archives outside the app
  were unrelated Volcano review assets. The two existing decoded board-art
  directories contain identical five-page sets by hash.

No images were generated or recolored. Object sprites preserve their source
alpha and use uniform scaling. Nuts, statues, cookie stacks, the platter, blind
header and queue shell need the documented 180° atlas rotation,
checked against official Playrix illustrations. The source ceramic interiors and shutter material are spatial crops
resized and masked to the canonical flat-top hex. The shutter crop excludes
transparent side margins; it does not invent alpha. Source PNGs remain intact.

The atlas packs source PNGs, aliases and spatial composites. All three skins
use a single board texture. Relic Rush uses a 4096×4096 atlas and Christmas
Market uses a 2048×4096 atlas.

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
| `CARRY_GEN` | `donut-maker-0..5` over the group footprint | Empty, raw, heated, glazed, green sprinkles and added yellow sprinkles. Mesh registration comes from the source atlas. Placement over the heater follows the clip. |
| Goal panel | Original goal icons, including `goal-color-box` | Uses original board sprites for nuts, statues, tiles and blinds. |
| `COLOR_BOX` | `color-box-{color}-{health}` | All 36 named Windows sprites, original color 0–5 and health 1–6. |
| `HONEY` | `jelly-1..6`, with clear and soft cherry variants for strengths 1 and 2 | Original square, flowers and cherries matched to Playrix's six-state illustration. A mask derived from the authored opening clips the soft cherry. |
| Portal pair | `tunnel-in` and `tunnel-out` | Original yellow entrance and blue output. Render at the lower and upper cell edges respectively, with insets for the hex layout. |
| `CARRY_EXIT` | `carry-exit-arrow` with three staggered copies | Original 9.2.601 `CarryExitForAnim`. Uses the original three-second period, one-second spacing and cosine fade, with hex-relative positioning. Reduced motion holds the arrows in place. |

The jelly illustration shows strengths six through one, left to right. The
center overlay progresses from a dark red flower through five pale petals,
three pale petals, pink petals, an open frame and a plain square. The first two
strengths render the corresponding original cherry only if the cell contains
`CHERRY`. Board rendering suppresses the covered piece so the cherry appears
once. The clip, scale and offsets adapt the reference to the hex layout.
[Playrix's six-state jelly illustration](https://d2duuy9yo5pldo.cloudfront.net/playrix/e387050a-8acc-410b-a29e-52cb2c67cb14-t.png)

The original base and glass layers share a 460 × 420 source frame. The three
top-origin positions are `(99,157)` for the base, `(117,90)` for the rear
glass and `(117,151)` for the front glass. The charge parts share a 276 × 274
source frame, placed at `(99,102)` between the glass planes. The atlas recipe
scales the completed image to the shared hex footprint.
[Field review](review/homescapes-windows-art/README.md)
[Playrix's donut maker illustration](https://playrix.helpshift.com/hc/en/14-homescapes/faq/1333-donut-maker/)

The portal rings in the 3.5.9 atlas match the colors and silhouettes of the
named portal textures and the official image. Gameplay continues to use the
existing discontinuous transfer animation.
[Playrix's portal illustration](https://playrix.helpshift.com/hc/en/14-homescapes/faq/1084-portals/)

The PLXE decoder verifies the original named rectangles in the 1.1.0.900,
3.5.9 and 9.2.601 archives. The 6.8.5 Android client requests
`Match3ColorBox{health}{color+1}` with six values in each dimension. The
9.2.601 Windows atlas contains all 36 named, distinct RGBA images. The
native client also confirms the maker's
animation groups and the output-capacity indicators. The official tutorial
shows the five successive maker poses and the last dough leaving the tray.
[Pack and arrow evidence](homescapes-reference/board-pack-evidence.json) · [Maker source evidence](homescapes-reference/GENERATOR_ART_SOURCES.md)

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
python3 tools/homescapes-reference/extract_portal_historical.py --apk reference/homescapes-analysis/historical/homescapes-3.5.9.apk
python3 tools/homescapes-reference/extract_historical_jelly_components.py --apk reference/homescapes-analysis/historical/homescapes-3.5.9.apk
python3 tools/homescapes-reference/extract_color_box_goal.py --check
python3 tools/homescapes-reference/extract_carry_exit.py --check
python3 tools/homescapes-reference/extract_maker_named.py --apk reference/homescapes-analysis/historical/homescapes-3.5.9.apk --check
python3 tools/homescapes-reference/extract_windows_color_boxes.py --library /path/to/6.8.5/libgame.so --check
python3 tools/homescapes-reference/extract_windows_maker_poses.py --library /path/to/6.8.5/libgame.so --check
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

[Jelly and portal captures](review/homescapes-jelly-portals/README.md),
[donut exit captures](review/homescapes-arrow-maker/README.md) and
[Windows box and maker captures](review/homescapes-windows-art/README.md)
show the recovered states in both games. Maker particle timing, output
indicator placement and exact group composition still require source
rendering evidence.
[Issue #98](https://github.com/corepunch/nile-archive/issues/98)
