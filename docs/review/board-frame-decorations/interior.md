# Inner board decorations

Relic Rush hangs a jungle vine from the ceiling of its arch. Christmas Market
hangs a ribbon and bell in one opening and a frosted pinecone in the other.
The open-top chamber uses larger fir sprigs on its inner walls. The small outer
sprigs leave the cutouts as the main places for trim.

| Board | Before | Inner trim |
| --- | --- | --- |
| Relic Rush level 6, 480×900 | ![Relic Rush before inner trim](relic-480.jpg) | ![Vine under the Relic Rush arch](relic-480-inner.jpg) |
| Relic Rush level 6, 390×844 | ![Relic Rush before inner trim at the smaller size](relic-390.jpg) | ![Vine under the Relic Rush arch at the smaller size](relic-390-inner.jpg) |
| Christmas Market level 4, 480×900 | ![Christmas Market before inner trim](christmas-480-north.jpg) | ![Swags inside the Christmas Market cutouts](christmas-480-inner.jpg) |
| Christmas Market level 4, 390×844 | ![Christmas Market before inner trim at the smaller size](christmas-390-north.jpg) | ![Swags inside the cutouts at the smaller size](christmas-390-inner.jpg) |
| Christmas Market level 7, 390×844 | ![Open channel before inner trim](christmas-open-before.jpg) | ![Fir sprigs inside the open channel](christmas-open-inner.jpg) |

The three hanging variants were generated together with the built-in ImageGen
tool using the existing [outer artwork](../../../engine/art/board-frame/decorations-source.png)
and the two earlier board captures. Their stems attach at the centre of each
registered 96×96 RGBA sprite. The source registration crops and scales the
paintings and trims stray matte alpha around the painted silhouette.
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
