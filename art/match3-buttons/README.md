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
| Build | Coral roof, cream walls and a single teal doorway |
| Play | Rounded green triangle with a soft highlight |
| Levels / Wishes | Cream folded map with one teal landmass and a coral X |
| Pause | Two softly rounded blue bars |

Both ImageGen passes used the full set. The final master keeps the approved house from the first pass and registers the other three glyphs from the second.
The [master](actions-source.png), [prompt](prompt.txt) and [registration
manifest](manifest.json) reproduce the shared [512×128 strip](actions.png).
Each registered crop is trimmed to its alpha bounds, fitted to 110 px, and centered in
its own 128×128 frame. The same illustration is used in all five states.
Bonus buttons take their image directly from the game's board atlas.

Run `python3 tools/match3_buttons.py` to register the icons or pass `--check`
to compare the pixels. Review the live [town row](../../games/relic-rush/docs/screenshots/enamel-town.jpg),
[bonus toolbar](../../games/relic-rush/docs/screenshots/enamel-toolbar.jpg),
[Relic Rush action states](../../games/relic-rush/docs/screenshots/hud-states.jpg)
and [Christmas Market booster states](../../games/christmas-market/docs/screenshots/art-states.jpg).
