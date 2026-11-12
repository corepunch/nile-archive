# Generator artwork source investigation

Current integration and remaining requirements are recorded in [the state inventory](../HOMESCAPES_ART.md). This investigation separates recovered source pixels from unverified composition metadata.

The original application bundle was inspected for the `TARGET_GEN`, `CARRY_GEN`,
`SHUTTERS`, and visible `BORN` / `ARTIFACT_GEN` / `PATTERN_COLOR_BORN` board
art. The five decoded base `Match3_00`–`Match3_04` atlas pages do not establish
identifiable platter, maker, blind or inlet state mappings. The archive contains
a target-generator goal icon, carry-generator haptic pattern and shutter shader,
but those do not establish board compositions or charge states. Do not infer a
board sprite or composition from the goal icon.

Original goal-panel images with reproducible paths, hashes and pixel-preserving
WebP-to-PNG conversion are in `engine/art/homescapes/generator-goal-sources.json`.
Run `python3 tools/homescapes-reference/extract_generator_goals.py --check` to
verify them against the source bundle.

## Downloadable content metadata

`base_mm/Assets/CDS/CdsCdnServer.vso` is a BLK container decoded by
`tools/homescapes-reference/sprite_metadata.py`. Its production entry names
`https://homescapes-cdn.playrix.com` and path `cds`; it does not identify the
required packs. `base_mm/Assets/CDS/CdsPack.xml` and
`base_mm/DownloadableFiles.xml` have PLXE headers with flags `0x00050005` and
little-endian declared output lengths 1,329,000 and 373,426 bytes. Starting a
Zstandard decoder at byte 12 fails with unsupported format for both. An older
[public PLXE description](https://www.zenhax.com/viewtopic.php%40t%3D16964.html)
describes raw Zstandard payloads for flag `0x00040004`; it does not decode these
files. No conclusion about the newer payload's algorithm follows from this test.

The bundled iOS executable `h` has `LC_ENCRYPTION_INFO_64` with `cryptid=1`,
covering 112,263,168 bytes, so its protected code cannot be inspected as plain
client instructions. Exact content URLs, pack contents, state artwork, source
layer coordinates and animation timing remain unresolved. No CDN download or
unverified extraction was used.

## Public help and wiki media

The official [element index](https://playrix.helpshift.com/hc/en/14-homescapes/section/151-match-3-elements/) links individual articles. Raw HTML in the English, Russian, German, French, Spanish, Japanese, Korean, Chinese, Portuguese and Turkish pages points to the same original PNGs: [apples](https://d2duuy9yo5pldo.cloudfront.net/playrix/c7182d99-71d3-4cd2-a521-2be37cadd21b-t.png), [generator](https://d2duuy9yo5pldo.cloudfront.net/playrix/534a4ae6-6492-455b-b4c0-b3e0acc52ae9-t.png), [donut maker](https://d2duuy9yo5pldo.cloudfront.net/playrix/f225407e-3b7c-413a-a5de-29f6cd9334dc-t.png), and [window blinds](https://d2duuy9yo5pldo.cloudfront.net/playrix/7fe73a6f-562e-45d1-bf63-f953c14f08e2-t.png). The first three are 130 × 130 pixels, the last 423 × 130; all are RGBA illustrations composited onto blue board backgrounds. The apple image depicts eight apples, the generator includes four board pieces, and the blinds show four adjacent columns. They do not isolate sprites or cover all damage and charge states, so they were not registered as runtime state art.

The English articles also embed official YouTube videos for [apples](https://www.youtube.com/watch?v=DM95WJKchfU), [donut maker](https://www.youtube.com/watch?v=6XNxRO7CMs0), and [window blinds](https://www.youtube.com/watch?v=jxR7FYsesFg). The community wiki links images for [apples](https://static.wikia.nocookie.net/playrix-homescapes/images/9/99/Apples.png/revision/latest?cb=20210624033947) and [window blinds](https://static.wikia.nocookie.net/playrix-homescapes/images/e/ec/Window_Blinds.png/revision/latest?cb=20210624034707). Those image requests returned Cloudflare challenge HTML, so their pixels, transparency and state coverage could not be inspected.

## Historical APK atlases

A Homescapes 3.5.9 APK from [APK.Gold](https://apk.gold/download?file_id=1370034/homescapes) contains six decoded `Match3` atlas pages. They contain separate aqua platter, apple, donut-maker and blind components, rather than complete registered count/charge compositions. The six adjacent atlas XML files use PLXE flag `0x00050005`, whose payload does not expose the older raw-Zstandard format. Source-layer coordinates, the order of apple removal, charge poses, and how a nine-apple group is drawn remain unverified. These components alone cannot substantiate complete state mappings.

The historical atlas crops for `apple-platter-base`, `donut-maker-base`,
`blind-top`, and `generator-shell` are rotated 180° during extraction. This
orients the platter lip, maker heating ring, blind header and inlet latch to
match the official help illustrations linked above. The transforms are recorded
per crop in `tools/homescapes-reference/generator-historical-regions.json`;
reproduce them with `extract_generator_historical.py --apk <3.5.9.apk>`. The
maker dough is positioned over the corrected heating ring in the composite;
its placement and the apple layout are manual approximations, not recovered
prefab coordinates. The maker's intact glass dome remains unavailable.
