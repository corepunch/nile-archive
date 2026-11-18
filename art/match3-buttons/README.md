# Shared campaign buttons

Relic Rush and Christmas Market draw the brass rim, inset enamel face and shadow
in logical screen units. The [painter](../../engine/lua/match3/buttons.lua)
fits its circle to the smaller dimension of the control. A held face sinks,
hover brightens the ivory, selection turns the face jade, and unavailable
controls show a recessed silhouette with a warm sandstone floor. The upper
lip casts a narrow, soft shadow inside the shape. Its offset is 1.4% of the
button diameter to the right and 1.8% down. Partial charge reveals the ready
button from the bottom of the same box.

| Action | Painted icon |
| --- | --- |
| Build | Ivory cottage with clay roof tiles and a blue-green timber door |
| Play | Faceted emerald triangle in a brass setting |
| Levels / Wishes | Rolled parchment chart with a red destination mark |
| Pause | Two sapphire bars with brass end caps |

ImageGen painted the set together using the [campaign resource pieces](../../games/relic-rush/art/registered/campaign-pieces.png) as the material and lighting reference.
The [master](actions-source.png), [prompt](prompt.txt) and [registration manifest](manifest.json) reproduce the shared [512×128 strip](actions.png).
Within each 128 px square, Build and Play fit inside 110 px. Levels and Pause fit inside 90 px, leaving at least 19 transparent pixels on each side for clearance inside the circular face. The same illustration is used in all five states.
Bonus buttons take their image directly from the game's board atlas.

Run `python3 tools/match3_buttons.py` to register the icons or pass `--check`
to compare the pixels. Review the live [town row](../../games/relic-rush/docs/screenshots/enamel-town.jpg),
[bonus toolbar](../../games/relic-rush/docs/screenshots/enamel-toolbar.jpg),
[Relic Rush action states](../../games/relic-rush/docs/screenshots/hud-states.jpg)
and [Christmas Market booster states](../../games/christmas-market/docs/screenshots/art-states.jpg).
