# Inner board decorations

Relic Rush's jungle vine projects down and right from the inner side of its
arch. Christmas Market's bell projects into the left opening from its left
wall, and the frosted pinecone enters the right opening from its right wall.
The open-top chamber uses larger diagonal fir sprigs on its inner walls.

| Board | Before | Diagonal side mounts |
| --- | --- | --- |
| Relic Rush level 6, 480×900 | ![Vine centred below the arch](relic-480-inner.jpg) | ![Diagonal vine on the inner left wall](relic-480-diagonal.jpg) |
| Relic Rush level 6, 390×844 | ![Vine centred below the arch at the smaller size](relic-390-inner.jpg) | ![Diagonal vine at the smaller size](relic-390-diagonal.jpg) |
| Christmas Market level 4, 480×900 | ![Ornaments centred below the openings](christmas-480-inner.jpg) | ![Bell and pinecone projecting diagonally from the sides](christmas-480-diagonal.jpg) |
| Christmas Market level 4, 390×844 | ![Ornaments centred below the openings at the smaller size](christmas-390-inner.jpg) | ![Side-mounted ornaments at the smaller size](christmas-390-diagonal.jpg) |
| Christmas Market level 7, 390×844 | ![Open channel before inner trim](christmas-open-before.jpg) | ![Fir sprigs inside the open channel](christmas-open-inner.jpg) |

The three hanging variants were generated together with the built-in ImageGen
tool using the existing [outer artwork](../../../engine/art/board-frame/decorations-source.png)
and the two earlier board captures. Their stems attach at the centre of each
registered 96×96 RGBA sprite. The renderer seats the stem on the inner stone
and turns the artwork 48° into the opening. The source registration crops and
scales the paintings and trims stray matte alpha around the painted silhouette.
[Hanging source atlas](../../../engine/art/board-frame/hanging-source.png) ·
[Prompt](../../../engine/art/board-frame/hanging.prompt.txt) ·
[Crop and anchor settings](../../../engine/art/board-frame/decorations.json)

The atlas exports stay separate from the stone. Christmas Market's snow uses
the snowy stone slot on the exposed north rim, including on boards with open
channels. The inner channel floor uses the bare stone slot.

```sh
python3 tools/board_frame_decor.py
python3 tools/board_frame_decor.py --check
build/test/all --suite=relic-rush --suite=christmas-market \
  "shot dressing-shore" "shot main-character-board" "shot phone-board" "shot designed-chambers"
```
