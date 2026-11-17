# Shared match-3 campaign buttons

Relic Rush and Christmas Market use one painted plate for the bottom
controls. The source is Christmas Market's existing
[Pause button](../../games/christmas-market/data/expedition-hud/pause-normal.png).
The tool separates its two bars from the face, keeps the painted gold rim
and interpolates the ivory paint beneath the bars. Build, Play and Wishes
reuse the shapes of the existing Christmas Market navigation glyphs.
The boosters use their existing board artwork.

The [manifest](manifest.json) records the source, the glyph crops and the
runtime atlas order. The same generator sets the normal, selected, pressed,
hover and disabled states for both the actions and the boosters. It keeps
soft alpha at the engraved edges, renders highlights and inner shadows at
4× resolution, and downsamples the finished recess to the 128 px atlas
cell. The plate's alpha fixes the outer silhouette across every state.
[Compare the engravings at enlarged scale](engraving-review.png).

## Regeneration

Run from the repository root.

```sh
python3 tools/match3_buttons.py
python3 games/relic-rush/tools/prepare_bonus_gems.py
python3 games/christmas-market/tools/prepare_bonus_buttons.py
python3 games/christmas-market/tools/check_assets.py --update
```

Run any packer with `--check` to compare its output with the checked-in
files. Run `make test` to verify the shipped inventories and the shared atlas.
The two games load identical `data/campaign-buttons.png` sheets. The booster
sheets add the board pieces as their first row and use the same interaction
state order as the action sheet.
