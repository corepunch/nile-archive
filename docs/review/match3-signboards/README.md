# Match-3 signboards and board colors

Relic Rush uses a jade and sandstone signboard with teal hexes. Christmas
Market uses a snow-trimmed spruce signboard with slate-blue hexes. The board's
outer rim uses a lighter tone from each palette, and the cell gradients
define the hex faces.

Each signboard hosts the live Moves medallion, objective counts or completion
ticks, and Settings. Goals can wrap onto two rows. Both signboards use the
authored jade-and-gold Settings artwork. The new backplates are static frames
in each game's `data/match3-hud.png`.

| Game | 480 × 900 | 390 × 844 with safe areas | Top-bar close-ups |
| --- | --- | --- | --- |
| Relic Rush | [Before and after](relic-rush-480x900.jpg) | [Before and after](relic-rush-390x844.jpg) | [Both sizes](relic-rush-top-bars.jpg) |
| Christmas Market | [Before and after](christmas-market-480x900.jpg) | [Before and after](christmas-market-390x844.jpg) | [Both sizes](christmas-market-top-bars.jpg) |

The [selected concept](../../../art/match3-signboards/concept.jpg),
[authored sheet](../../../art/match3-signboards/source.png) and
[ImageGen prompt](../../../art/match3-signboards/prompt.txt) record the source.
Each game's `art/match3-atlas.json` records its alpha-preserving crop and
resize. The screenshots show level 30 in each game.

```sh
python3 tools/match3_atlas.py
build/test/all --suite=relic-rush --suite=christmas-market 'shot delivery-finale' 'shot phone-story-level-30'
```
