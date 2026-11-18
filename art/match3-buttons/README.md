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
| Play | Loose triangular emerald, optically centered on the enamel face |
| Levels / Wishes | Rolled parchment chart with a red destination mark |
| Options (pause menu) | Eight-tooth sapphire cog with a brass-lined open center |

ImageGen painted the set together using the [campaign resource pieces](../../games/relic-rush/art/registered/campaign-pieces.png) as the material and lighting reference.
The [master](actions-source.png), [prompt](prompt.txt) and [registration manifest](manifest.json) reproduce the shared [512×128 strip](actions.png).
Within each 128 px square, Build and Play fit inside 110 px. Levels and Options fit inside 90 px for extra clearance inside the circular face. Registration centers each resized silhouette by pixel opacity on both axes, to the nearest pixel. If that placement would clip an edge, registration reduces the fit until the entire illustration fits. The same illustration is used in all five states.
Bonus buttons take their image directly from the game's board atlas. The atlas builder records the center of opacity for each bonus frame. The painter aligns that point to the enamel center for both the inset silhouette and the color revealed from the bottom, at the original scale.

Run `python3 tools/match3_buttons.py` to register the icons or pass `--check`
to compare the pixels. Review the live [town row](../../games/relic-rush/docs/screenshots/enamel-town.jpg),
[bonus toolbar](../../games/relic-rush/docs/screenshots/enamel-toolbar.jpg),
[Relic Rush action states](../../games/relic-rush/docs/screenshots/hud-states.jpg)
and [Christmas Market booster states](../../games/christmas-market/docs/screenshots/art-states.jpg).
