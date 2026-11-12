# Homescapes match-3 resources

[Open the decoded atlas and sprite gallery](../../reference/homescapes-analysis/board-art/index.html).
It shows all five 1576 × 1576 board pages and 32 sprite crops. The
gallery links to the full PNGs, the auxiliary planes, and a source manifest.
For those sprites on level layouts, open the [board explorer](#explore-bundled-board-definitions).

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

## Decoded board atlases

The five `base_mm/atlases/Match3_00.dds` through `Match3_04.dds` files
each contain a BLK wrapper with a Zstandard frame at byte 40. Unwrapping
recovers an ETC2-tagged DDS with three packed streams. Each stream has four
little-endian counts, followed by commands, an eight-byte block dictionary,
and literal blocks. The count invariant is
`total = 3 + command_words + 2 × dictionary_entries + literal_words`.

The decoder expands commands in most significant bit order. It reads
short runs, nested length prefixes, dictionary entries and backward distances.
One selector repeats the previous distance. Each plane reconstructs exactly
155,236 eight-byte blocks. ETC2 gives RGB and EAC R11 gives the opacity plane.
The third plane is exported separately. The PNG export flips Y to orient the
art. The manifest records checksums for the unpacked blocks and the DDS files.

The sprite gallery includes six regular gems, both rocket directions, bombs,
planes, rainbow balls, two ice shells, single and crossed chains, six box
variants, three cookies, carpet, a carpet roll, donuts and cherries. The
sprite rectangles were identified visually. The crossed-chain crop excludes
two neighboring atlas fragments. The PLXE region files remain encoded, so
original region names, animation timing, placement and complete state
assignments are still unverified. All five complete atlas pages are available
for inspecting additional art.

The supplemental honey and web crops come from the named
`Elements/Honey/Border.dds` and `Elements/Web/2.dds` resources. The
explorer marks honey and rolled carpet as material previews because the
strength-specific artwork remains unresolved. Web 2 uses the named
texture, and web 1 remains unmapped.

## Prefab and settings metadata

`Library.xml.meta` indexes named records by offset and length in the
binary prefab library. The BLK directory supplies the Zstandard frame
boundaries. The decoder reconstructs both frames of `Vso.vso` and reads
the corresponding named records in `M3Settings.vso` from the base archive
and the Match3 settings pack. The names establish the color numbering:
`NormalChipRed` references `Match3Chip_0_base_facelift`,
`NormalChipBlue` references `Match3Chip_3_base_facelift`, and the other
four color prefab records supply the remaining IDs. The settings index
also exposes field names such as `BlocksSwap` and
`CanClearByNearColoredMatch`. It records the names and source offsets.
Field values, execution order and sprite rectangles are still separate
research questions.

The five PLXE atlas files carry version words 5 and 5. Their payloads at
offset 12 did not produce data with standard Zstandard framing, with
the Zstandard magic restored, or with Brotli. The sprite regions in
the gallery remain visual identifications. See the
[recovered prefab references](../../reference/homescapes-analysis/board-art/prefab-references.json)
and the [board sprite coverage table](SPRITE_COVERAGE.md).

```sh
python3 tools/homescapes-reference/sprite_metadata.py
python3 tools/homescapes-reference/sprite_coverage.py
```

## Reproduce the PNG export

From the repository root, install Pillow and the
[texture2ddecoder package](https://pypi.org/project/texture2ddecoder/) in
your Python environment, and run `extract_gems.py` first if the unwrapped
DDS files are absent.

```sh
python3 tools/homescapes-reference/decode_board_atlases.py
python3 tools/homescapes-reference/inspect_board_atlases.py
```

The decoder writes into a new directory. Pass `--output` for a second export.
The default output and the third-party PNGs stay in ignored reference data.

## Explore bundled board definitions

Run the local-only board explorer from the repository root:

```sh
python3 tools/homescapes-reference/serve.py
```

Open <http://127.0.0.1:8767/>. Use the example links to compare gems, ice,
chains, boxes and cookies. Search source paths, flip Y or select a cell to
inspect its coordinates, models, attributes and selected sprite IDs. The
server binds to loopback and reads one level at a time. It serves only
indexed levels and allowlisted art files.

The level archive contains **6,184 XML files**, including **500** files in
`base/st/`; all 6,184 parse as XML `Level` definitions. The default
`base/st/st0001.xml` has 42 cells, 26 moves and a CHIPS target of 12 with subtype
1. These are serialized values, not verified current runtime settings. Selection
and tuning files remain encoded; `st0001` is a source filename, not a verified
campaign-level assignment. Event and contest files are included.

With the decoded art available, the board draws original sprites for
`NORMAL`, `BOX`, `TRASH`, `JELLY`, `CARRY`, `CHERRY`, `BOMB`, `LINE`,
`LIGHTNING`, `ICE`, `LOCK` and web state 2. The explorer draws carpet under chips and
ice or chains over them. It selects visually identified crops by serialized
color, strength and orientation where mapped. Unmapped models and random
chips retain their labels. Use the raw cell details for authored metadata and
nested models. The bundled goal icons provide a fallback when no board art
has been exported. The viewer depicts static layouts. The
[Swift and SpriteKit lab](../../prototypes/homescapes-match3/README.md)
plays eight sample boards with the same sprite map.

Data comes from `base_mm/fs_archives/match3levels.zstd`, a `pzsd` archive with
an embedded Zstandard dictionary. Run
`python3 tools/homescapes-reference/extract_archives.py` if the local decoded
directory is missing; this also extracts the screenplay archive. The two outputs
total about 59.4 MB of file contents (roughly 71 MiB on disk); no game download
or remote content is needed. The script checks index bounds and paths, decoded
lengths and decompression errors, and refuses to overwrite existing output.

## Extracted gem sources

[Open the gem image gallery](../../reference/homescapes-analysis/gems/index.html)
or the [contact sheet](../../reference/homescapes-analysis/gems/contact-sheet.png).
The local extraction contains **22 directly readable goal-panel images**: six
numbered piece icons, four distinct special icons and one combined-special icon,
each in two bundled variants. It also contains **13** matching tutorial chip
and result images, with source names preserved. These are original WebP files,
not converted or recolored assets; the files named `facelift` are not proof of
a specific runtime state or release order.

The `board-atlases/` subdirectory contains the five unwrapped DDS inputs
and their encoded XML region metadata. The separate
[board art export](#decoded-board-atlases) contains the decoded PNGs. The
gem sources manifest records source paths, SHA-256 hashes and sizes for its
45 files. The original app bundle remains in `reference/Homescapes.app`.

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

## Lab blocker and generator states

The lab now simulates additional original models and labels unresolved artwork
explicitly. `HONEY` is the jelly covering cherries, and `TARGET_GEN` is an apple
platter (the prefab names `ModelToTargetApple`), not a toaster. `FISH` is the
paper plane and uses the existing decoded plane sprite. See the
[blocker visual catalogue and reviewed captures](BLOCKERS.md#runtime-visual-catalogue)
for supported states, diagnostic presentations, source references and commands.
Missing authored states remain tracked in [issue #98](https://github.com/corepunch/nile-archive/issues/98).

### Queue, tile and blind diagnostics

The lab now labels visible artifact sources with their emitted count, ceramic
tiles with strength 1/2, and blinds with their shared remaining height. Stacked
labels stay within the cell; pieces beneath closed blinds are hidden. These
are diagnostic states pending original artwork, linked to
[issue #98](https://github.com/corepunch/nile-archive/issues/98). The full state
catalogue, reproduction commands, acceptance criteria and inspected native
captures are in [GENERATORS.md](GENERATORS.md#diagnostics-artwork-and-captures).
Existing piece textures and mappings are unchanged.
