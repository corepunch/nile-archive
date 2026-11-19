# Square match-3 tiles and frames

The built-in ImageGen tile sheet, [source.png](source.png), supplies the
selection rim and grout for both games, plus the Christmas Market faces and trim.
[The first prompt](prompt.txt) specifies
the two material families. [Lighting revisions](lighting-prompt.txt)
record the target colors and the final correction to the ordinary tile.
[Christmas Market ornaments](ornaments.png) use a separate transparent sheet, with its
[export prompt](ornaments-prompt.txt). All painted objects are original.
The [Relic Rush board](../../games/relic-rush/docs/square-match3.md#levels-and-art)
has its own papyrus floor and sandstone frame atlas.

## Reference study

Read the original papyrus tile from Cradle of Rome I's local
`reference/cradle-of-rome/visuals/sprites/settings/scenes/game/game_graphics/cell_normal.png`.
Its brightest interior is at upper left. Cradle of Rome II has a
different plain tile in `resources/textures/scenes/game/g_field_cells.png`.
Its teal and olive target states inform the two target gradients here.

Mean RGB values use boxes inside the bevel, from 16% to 32% and from 68%
to 84% along both axes. The center box spans 43% to 57%.

| Ordinary tile | Upper left | Center | Lower right | Upper left minus lower right, luma |
| --- | --- | --- | --- | ---: |
| Cradle of Rome I papyrus | 240, 222, 141 | 201, 169, 91 | 180, 138, 70 | 78.0 |
| Cradle of Rome II plain | 198, 166, 105 | 229, 201, 129 | 218, 188, 119 | −21.0 |
| Earlier Relic Rush limestone | 250, 220, 114 | 224, 175, 73 | 189, 132, 49 | 80.6 |
| Relic Rush papyrus | 243, 217, 151 | 214, 175, 110 | 175, 127, 70 | 84.6 |
| Christmas Market maple | 250, 221, 116 | 225, 175, 75 | 191, 133, 51 | 80.2 |

Cradle of Rome I stores the wood and leaf frame at
`resources/textures/scenes/game/g_corners.png`. The second game's
`resources/settings/scenes/city/city_graphics.xml` identifies its frame
strip as the bottom row in `textures/scenes/city/construct/ct_built_01.png`.
In both reference games, tile type 10 places its leaf art in an empty frame
cell that touches two playable cells at right angles. Relic Rush alternates
bare and leafy recessed corner tiles. Christmas Market places its ornaments
over the carved strip.

## Register and review

Run `python3 tools/match3_atlas.py` from the repository root. It crops and
resizes the painted square faces and trim, isolates the painted gold
selection rim, and registers the ornament crops with their original alpha.
The runtime frames and exact crop rectangles are recorded in each game's
`art/match3-atlas.json` under `square_cells`.

- [Relic Rush captures](../../games/relic-rush/docs/square-match3.md#captures)
- [Christmas Market captures](../../games/christmas-market/docs/square-match3.md#captures)
