# Homescapes match-3 art: first visual inventory

Open the [local goal-icon gallery](../../reference/homescapes-analysis/goal-icons.html)
to browse and filter the 45 images; it is generated from the installed app and
works offline. If absent, regenerate from the repository root:

```sh
python3 tools/homescapes-reference/gallery.py
```

These are original WebP files from `base.zip` under
`base_mm/Match3/vso/textures/UI/Match3TargetsBase/`. They are goal-panel icons,
not a verified inventory of board sprites or complete interaction states. Source
filenames are retained: `facelift` variants appear beside the earlier images.
A visual contact sheet is available in ignored local reference data at
`reference/homescapes-analysis/goal-icons-contact-sheet.png`.

The collection shows six regular piece icons, four named power-up types in the
source names, and goal imagery for boxes, locks, carpet, doughnuts, cherries,
plates, chocolate-like blocks, a jar and other objects. Names such as `carry`,
`piggy`, and `target_generator` are identifiers, not verified rule descriptions.
For example, the image named `magic_hat` resembles toast; do not infer an item's
rules from either the filename or this thumbnail. The variants show differences
in rendering and proportions rather than a proven chronology of use.

Visually, the icons use strong silhouettes, glossy highlights and saturated
color. Their purpose appears to be recognizability at UI size; the images do
not establish how animation, obstacles or layered states look in play. The
Tropicats atlas renders extracted board states, so a direct quality or coverage
comparison would require the Homescapes board assets and runtime mapping too.

The package also contains `base_mm/atlases/Match3_00.dds` through `_04.dds`,
plus other DDS assets and associated metadata. They use a compressed container
and an ETC2-tagged texture format. A straightforward decode did not produce a
valid image, and the matching XML metadata is encoded; the board atlas remains
unrecovered. The gallery is therefore an initial visual inventory, not the
complete set the game uses.

## Board atlas investigation

Each tested `Match3_00.dds` through `Match3_04.dds` starts in a `BLK` wrapper
with a Zstandard frame at byte 40. Decompression recovers a DDS header tagged
`etc2` (1576×1576 for these five), but the remaining data is shorter than a
raw ETC2 image of that size. Direct ETC1, ETC2 and ETC2 punch-through decoding,
including 2-, 4- and 8-byte word reversals, produced noise rather than recognizable
art. The data therefore cannot safely be treated as a raw texture; the exact
additional encoding and the mapping from atlas regions to game states remain
unknown. No invalid render is shown as an asset.
