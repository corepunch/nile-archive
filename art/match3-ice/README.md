# Match-3 ice artwork

Relic Rush, Christmas Market and the engine's default skin share two ice overlays.
Ice holds a piece in place. A match on the frozen piece or a direct hit removes
one layer. Both ice overlays tint the piece underneath through their baked alpha.

| Atlas frame | Appearance | Runtime use |
| --- | --- | --- |
| `ice-1` | Translucent cyan ice with a broken upper edge | One hit remaining. Also used for the imported ice goal. |
| `ice-2` | Translucent cyan pane with continuous faceted glass across the entire hex face | Two hits remaining. Also used in both guides. |

Built-in ImageGen painted both strengths together on one transparent sheet.
The [first pass](concept.png) used the archived Homescapes
[broken shell](../../engine/art/homescapes/sprites/ice-1.png) and
[full shell](../../engine/art/homescapes/sprites/ice-2.png) as visual references.
The [second pass](clear-shell.png) added a transparent opening to the full
shell. The [third pass](open-hex.png) fitted that pair to the board's
[flat-top hex](../../engine/art/hex-tile/hex-mask-preview.png). The
[current source atlas](source.png) has both strengths painted together with a
continuous face in the full state. See the exact prompts for [painting](prompt.txt),
[the opening](transparency-prompt.txt), [the hex shape](hexagon-prompt.txt)
and [the filled pane](filled-pane-prompt.txt).

Run `python3 tools/match3_atlas.py` to pack the runtime textures at
`engine/data/match3.png` and `games/<game>/data/match3.png`. The recipe crops
matching 690×690 source squares and resizes them to 128×128. The full pane's
alpha is exactly the canonical mask scaled to 128/255. The fractured state
multiplies its painted alpha by the same mask and scales the result to 150/255.
The crop preserves the painted color and the mask aligns the outer sides to
both games' well-face radius. The atlas manifests record the crops, opacity,
mask path and source fingerprints. Both states pass the strict hex check
with opacity normalized for measurement.

The in-game before and after captures cover both supported portrait sizes
and the guide illustrations.

- [Relic Rush](../../games/relic-rush/docs/screenshots/review/ice/README.md)
- [Christmas Market](../../games/christmas-market/docs/screenshots/review/ice/README.md)
