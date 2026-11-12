# Homescapes match-3 resources

## Bundled resource export

[Browse the local export](../../reference/homescapes-analysis/match3-export/index.html)
or open the [source manifest](../../reference/homescapes-analysis/match3-export/manifest.json).
The export contains **620 original files (22.0 MB)**, including **98 readable
WebPs** and **65 DDS resources**. The browser page previews the WebPs and
filters all files by path or encoding. It covers board and UI texture
containers, animation, particles, shaders, a sound bank, haptics, and level
and tuning data. The manifest records each original archive and member,
the output path, byte length, encoding signature, and SHA-256.

The selection includes every file with `match3` in its bundled path, the
dedicated `unique/MX/` haptic tree, and the complete `Match3_Settings.zip`
and `local_DoubleRainbow.zip` packs. This is an export of identifiable
match-3 resources in the local bundle. It does not resolve references inside
encoded files or include assets supplied only by the live game. A resource
may be bundled as a fallback or variant even if it is not used on a current
board. See the [mechanics comparison](MECHANICS.md) and
[board ID inventory](BOARD_IDS.md) for the rules and their evidence.

Regenerate from the repository root into a new directory:

```sh
python3 tools/homescapes-reference/export_match3.py
# Or choose a new location when the default export already exists:
python3 tools/homescapes-reference/export_match3.py --output /tmp/homescapes-match3-export
```

## Goal icons

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
raw ETC2 image with alpha of that size. Direct ETC1, ETC2 and ETC2
punch-through decoding produced noise. The payload is a second packing layer:
all five DDS files have three streams, with no gaps or trailing bytes.

Each stream begins with four little-endian 32-bit counts: total words after
the first count, command words, dictionary entries and literal words.
The invariant is `total = 3 + commands + 2 × entries + literals`. The command
bytes immediately follow the counts, then the dictionary (60 eight-byte
entries in each of these 15 streams), then literal data. In page 00 the
streams start at offsets 128, 611508 and 905396. The dictionary and literals
contain recognizably structured ETC/EAC blocks; their placement in the image
is determined by the separate command stream. Small controls in the same
bundle (`whitebox.dds` and `logo_mask.dds`) store a single literal block for
a uniform color plane, so copying the literals without interpreting the
commands cannot recover the texture. This layout is specific to these five
pages; other bundled DDS files can contain different stream layouts.

`python3 tools/homescapes-reference/inspect_board_atlases.py` checks all
stream boundaries and reports sizes from the existing extraction. The command
grammar, plane composition and PLXE sprite-region metadata are still
unresolved. No decoded board sprites are claimed.

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

## Extracted gem sources

[Open the gem image gallery](../../reference/homescapes-analysis/gems/index.html)
or the [contact sheet](../../reference/homescapes-analysis/gems/contact-sheet.png).
The local extraction contains **22 directly readable goal-panel images**: six
numbered piece icons, four distinct special icons and one combined-special icon,
each in two bundled variants. It also contains **13** matching tutorial chip
and result images, with source names preserved. These are original WebP files,
not converted or recolored assets; the files named `facelift` are not proof of
a specific runtime state or release order.

The `board-atlases/` subdirectory contains five Zstandard-unwrapped DDS files
and their original encoded XML metadata. The DDS headers identify 1576×1576
textures, but their pixels and sprite regions are still undecoded; the metadata
remains PLXE-encoded. They are source material for further investigation, not
extracted individual board gems. The manifest records source paths, SHA-256
hashes and output sizes for all 45 files. The original app bundle remains in
`reference/Homescapes.app`.

From the repository root, with `zstd` available:

```sh
python3 tools/homescapes-reference/extract_gems.py
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tools/homescapes-reference -p 'test_gems.py'
```

The extractor refuses to overwrite its destination. The gallery and outputs
are ignored local third-party reference data. The manually assembled contact
sheet is a spatial preview of the 22 goal icons and is not produced by the
extractor. No conclusion is made that these images exhaust the in-game sprite
states, animations, or remote assets.
