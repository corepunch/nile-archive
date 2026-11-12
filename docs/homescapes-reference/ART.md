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

## Explore bundled board definitions

Run the local-only board explorer from the repository root:

```sh
python3 tools/homescapes-reference/serve.py
```

Open <http://127.0.0.1:8767/>. Search source paths, choose a file, flip Y and
select a cell to inspect its coordinates, model layers and attributes. The
server binds only to loopback and serves only indexed level XML data. It reads
one level at a time, avoiding a large duplicate data file.

The level archive contains **6,184 XML files**, including **500** files in
`base/st/`; all 6,184 parse as XML `Level` definitions. The default
`base/st/st0001.xml` has 42 cells, 26 moves and a CHIPS target of 12 with subtype
1. These are serialized values, not verified current runtime settings. Selection
and tuning files remain encoded; `st0001` is a source filename, not a verified
campaign-level assignment. Event and contest files are included.

The board uses original goal-panel WebP icons as approximations for six numbered
`NORMAL` chips and selected model IDs. The icon-to-model and color mappings are
inferred from filenames; they are not verified runtime sprites. Jelly and rug
icons are layered below normal pieces, with mapped obstacle icons above; the
actual draw order and visual states remain unverified. Unmapped or random models
show a question mark when no mapped layer is present, and all model IDs remain
visible in cell labels and details. Y orientation is selectable
because runtime orientation has not been confirmed. Random pieces and generators
are not simulated. Nested model elements are retained in cell details. For the
actual packaged art and remaining decoding problem, see the atlas investigation
above and the goal-icon gallery.

Data comes from `base_mm/fs_archives/match3levels.zstd`, a `pzsd` archive with
an embedded Zstandard dictionary. Run
`python3 tools/homescapes-reference/extract_archives.py` if the local decoded
directory is missing; this also extracts the screenplay archive. The two outputs
total about 59.4 MB of file contents (roughly 71 MiB on disk); no game download
or remote content is needed. The script checks index bounds and paths, decoded
lengths and decompression errors, and refuses to overwrite existing output.

For `Match3/vso/textures/Elements/Carpet/Border.dds`, the Zstandard-unwrapped
payload was also checked at offsets 128–191 with zlib framing, raw DEFLATE,
gzip framing and raw LZ4 against plausible ETC output sizes. None yielded a
valid texture. This only rules out those exact trials for this one texture; it
does not identify the format of the atlas pixels.

The icon mapping currently covers `BOX`, `TRASH`, `JELLY`, `LOCK`, `RUG`, `CARRY`, `CHERRY`, `TAPE_MEASURE`, `JAR`, `TARGET_GEN`, `BOMB`, `LINE` and `LIGHTNING`. `CHERRY` uses the cherry-looking `piggy.webp`; that association is visual inference. Icons are read directly from the original app archive and served from a filename whitelist.
