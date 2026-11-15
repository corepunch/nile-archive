# Match-3 ice artwork

Relic Rush, Christmas Market and the engine's default skin share two ice overlays.
Ice holds a piece in place. A match on the frozen piece or a direct hit removes
one layer. The piece draws through the opening in either ice strength.

| Atlas frame | Appearance | Runtime use |
| --- | --- | --- |
| `ice-1` | Broken cyan shell along the lower three sides of the hex | One hit remaining. Also used for the imported ice goal. |
| `ice-2` | Complete flat-top hex shell with rounded corners, blue bevels, bubbles and a clear center | Two hits remaining. Also used in both guides. |

Built-in ImageGen painted both strengths together on one transparent sheet.
The [first pass](concept.png) used the archived Homescapes
[broken shell](../../engine/art/homescapes/sprites/ice-1.png) and
[full shell](../../engine/art/homescapes/sprites/ice-2.png) as visual references.
The [second pass](clear-shell.png) added a transparent opening to the full
shell. The [source atlas](source.png) fits both strengths to the board's
[flat-top hex](../../engine/art/hex-tile/hex-mask-preview.png). The exact prompts
are [painting](prompt.txt), [transparency](transparency-prompt.txt) and
[hex registration](hexagon-prompt.txt).

Run `python3 tools/match3_atlas.py` to pack the runtime textures at
`engine/data/match3.png` and `games/<game>/data/match3.png`. The recipe crops
each sprite, resizes it proportionally to 120 pixels wide, and centers it
horizontally on a 128×128 canvas with a shared bottom at y=112. The atlas
manifests record the exact crops, offsets and source fingerprints. The
registered sprites retain their painted alpha and pass the canonical hex
check in strict `object` and `frame` modes respectively.

The in-game before and after captures cover both supported portrait sizes
and the guide illustrations.

- [Relic Rush](../../games/relic-rush/docs/screenshots/review/ice/README.md)
- [Christmas Market](../../games/christmas-market/docs/screenshots/review/ice/README.md)
