# Shared board tiles

Relic Rush and Christmas Market share eight generated hex tiles that follow the
slots of Cradle of Rome's board sheet. Parchment cells and teal-blue tablets
are the floor in both games; the other six show cell states.

![The eight tiles](tiles.png)

Colours are matched to Cradle of Rome's tile sheet. Parchment is flat and lit
from above with a soft south-east glow; the single and double tablets are thick,
bevelled stones.

![Cradle of Rome's sheet above ours](strip-vs-reference.png)

The board frame follows Cradle of Rome's: from the cells out, a dark line, a
brown band, a cream highlight, a dark line and a tan-gold ledge, lit from above,
with dark brown grout between cells:

![Frame against Cradle of Rome](frame-vs-reference.jpg)

The parchment is a north-west to south-east gradient between the average
colours of the reference tile's two corners, under a fine warm mottle:

![Parchment against Cradle of Rome](parchment-vs-reference.jpg)

| Slot | Tile | Use |
| --- | --- | --- |
| 1 | `cell-normal` | Normal and cleared cells |
| 2 | `tablet-single` | Plaques / panes required for a win |
| 3 | `tablet-double` | Two-hit tablet from a level's `oil_double` (no campaign level yet) |
| 4 | `light-wave` | Light sweeping across the board as it arrives |
| 5 | `hover` | Mouse hover |
| 6 | `selected` | Selected cell |
| 7 | `ice` | Floor under an iced piece |
| 8 | `bonus-area` | Cells an armed tool will hit |

| Screen | Before | After |
| --- | --- | --- |
| Relic Rush level 6, 480×900 | ![](relic-480-before.jpg) | ![](relic-480-after.jpg) |
| Relic Rush level 6, 390×844 | ![](relic-390-before.jpg) | ![](relic-390-after.jpg) |
| Christmas Market level 4, 480×900 | ![](christmas-480-before.jpg) | ![](christmas-480-after.jpg) |
| Christmas Market level 4, 390×844 | ![](christmas-390-before.jpg) | ![](christmas-390-after.jpg) |

| Explorer's Guide | Market Keeper's Guide | All tiles in game (`--art-states dressing`) |
| --- | --- | --- |
| ![](relic-guide.jpg) | ![](christmas-guide.jpg) | ![](tiles-screen.jpg) |

## Cell states in play

`--cell-states` pins a selected cell (top left), a hovered cell, an armed
Dynamite's area (light blue), an iced piece and a double tablet (green).

| Relic Rush level 6 | Christmas Market level 4 |
| --- | --- |
| ![](relic-states.jpg) | ![](christmas-states.jpg) |

The light wave during the board's entrance, frames 30, 45 and 60:

![Light wave](relic-wave.jpg)

Every tile passes `tools/hex_tile_art.py --mode fill --strict` (coverage 1.0, no spill).

```sh
python3 tools/board_tiles.py            # writes both games' data/board-tiles/
./build/relic-rush --headless --mute --fresh --size 480x900 --art-states dressing --shot tiles.png
./build/relic-rush --headless --mute --fresh --size 480x900 --level 6 --cell-states --shot states.png
./build/relic-rush --headless --mute --fresh --size 480x900 --level 6 --present --frames 45 --shot wave.png
```
