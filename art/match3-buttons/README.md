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
| Build | Terracotta-roof cottage |
| Play | Green enamel triangle |
| Levels / Wishes | Folded map marked with a red X |
| Pause | Two blue bars |

The four illustrations were drawn together with built-in ImageGen.
The [master](actions-source.png), [prompt](prompt.txt) and [registration
manifest](manifest.json) reproduce the shared [512×128 strip](actions.png).
Each quadrant is trimmed to its alpha bounds, fitted to 110 px, and centered in
its own 128×128 frame. The same illustration is used in all five states.
Bonus buttons take their image directly from the game's board atlas.

Run `python3 tools/match3_buttons.py` to register the icons or pass `--check`
to compare the pixels. Review the live [town row](../../games/relic-rush/docs/screenshots/enamel-town.jpg),
[bonus toolbar](../../games/relic-rush/docs/screenshots/enamel-toolbar.jpg),
[Relic Rush action states](../../games/relic-rush/docs/screenshots/hud-states.jpg)
and [Christmas Market booster states](../../games/christmas-market/docs/screenshots/art-states.jpg).
