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

`decode_plxe.py` reads the archived Android x86 library's key table and
decodes the original metadata for both iOS and Android. PLXE v3 uses raw
DEFLATE and v5 uses Zstandard after decoding the payload. The library is read
as data. The decoded iOS 9.2.601 `CdsSettings.json` names the production host,
and `cds_file_map.xml` identifies the original pack paths, sizes and SHA-1
values. Requests for the maker and colored-box packs returned HTTP 403.
[File map evidence](board-pack-evidence.json)

```sh
python3 tools/homescapes-reference/decode_plxe.py --library /path/to/6.8.5/libgame.so \
  --archive reference/Homescapes.app/base.zip --output /tmp/homescapes-9.2.601 \
  base_mm/CdsSettings.json base_mm/cds_file_map.xml base_mm/atlases/Match3_00.xml
python3 tools/homescapes-reference/decode_plxe.py \
  --key-apk reference/homescapes-analysis/historical/homescapes-1.1.0.900.apk \
  --archive reference/homescapes-analysis/historical/homescapes-1.1.0.900.apk \
  --output /tmp/homescapes-1.1.0 assets/base_mm/effects/Match3Effects_atlas1.xml
```

## Public help and wiki media

The official [element index](https://playrix.helpshift.com/hc/en/14-homescapes/section/151-match-3-elements/) links individual articles. Raw HTML in the English, Russian, German, French, Spanish, Japanese, Korean, Chinese, Portuguese and Turkish pages points to the same original PNGs: [apples](https://d2duuy9yo5pldo.cloudfront.net/playrix/c7182d99-71d3-4cd2-a521-2be37cadd21b-t.png), [generator](https://d2duuy9yo5pldo.cloudfront.net/playrix/534a4ae6-6492-455b-b4c0-b3e0acc52ae9-t.png), [donut maker](https://d2duuy9yo5pldo.cloudfront.net/playrix/f225407e-3b7c-413a-a5de-29f6cd9334dc-t.png), and [window blinds](https://d2duuy9yo5pldo.cloudfront.net/playrix/7fe73a6f-562e-45d1-bf63-f953c14f08e2-t.png). The first three are 130 × 130 pixels, the last 423 × 130; all are RGBA illustrations composited onto blue board backgrounds. The apple image depicts eight apples, the generator includes four board pieces, and the blinds show four adjacent columns. They do not isolate sprites or cover all damage and charge states, so they were not registered as runtime state art.

The English articles also embed official YouTube videos for [apples](https://www.youtube.com/watch?v=DM95WJKchfU), [donut maker](https://www.youtube.com/watch?v=6XNxRO7CMs0), and [window blinds](https://www.youtube.com/watch?v=jxR7FYsesFg). The community wiki links images for [apples](https://static.wikia.nocookie.net/playrix-homescapes/images/9/99/Apples.png/revision/latest?cb=20210624033947) and [window blinds](https://static.wikia.nocookie.net/playrix-homescapes/images/e/ec/Window_Blinds.png/revision/latest?cb=20210624034707). Those image requests returned Cloudflare challenge HTML, so their pixels, transparency and state coverage could not be inspected.

## Historical APK atlases

The 3.5.9 APK contains six `Match3` atlas pages and matching PLXE v5 XML.
The named base and glass crops share a 460 × 420 frame and use the original
trim offsets in the runtime composite. The extracted switch positions 0–4,
lamp-on and lamp-off states, raw dough, pale dough and glaze are preserved as
source components. The native 6.8.5 renderer selects the switch and lamps
from remaining output capacity. Their board placement remains open.
[3.5.9 APK archive](https://apk.gold/download?file_id=1370034/homescapes) · [Named rectangles](../../tools/homescapes-reference/maker-named-regions.json) · [Native indicator evidence](maker-native-evidence.json)

The 1.1.0.900 and 3.5.9 PBI files name five stage animations. The 6.8.5 native
dispatch groups them by activation period. The named `_0034_01` and
`_0033_02` dough textures are present in both historical atlases. The
searched atlases lack named `_0032_03`, `_0018_04` and `_0017_05` textures,
and the PBI references alone do not establish the retained pose after an
activation. Runtime dough still uses the documented preview placement.
[Animation groups and source evidence](maker-animation-evidence.json)
