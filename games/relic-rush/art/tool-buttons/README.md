# Square power-up buttons (retired)

The game no longer registers or ships these buttons: every board uses the
bonus toolbar. The sheet stays as provenance.

`source.png` is the selected transparent RGBA ImageGen output, created on
31 October 2026 in one built-in call containing all three tools and all five
states. The existing `art/board-states/source.png` supplied the style and tool
identities. The exact request is in [prompt.txt](prompt.txt).

The atlas has five columns (normal, selected, pressed, hover, disabled) and three
rows (pickaxe, dynamite, sunburst). The output is 1619×971; measured crop boxes
are recorded in `../board-states/manifest.json`, rather than assuming an even
grid. That manifest's `retired_tool_buttons.registration` records the spatial resize
used to fit the subtly wide authored bodies to one square footprint. Authored
alpha, colors, tool glyphs and state differences are retained.

Runtime exports keep the existing `art/registered/board-states/<tool>-<state>.png` paths.
Reproduce the registration from the repository root:

```sh
python3 games/relic-rush/tools/board_assets.py
python3 games/relic-rush/tools/board_assets.py --check
python3 games/relic-rush/tools/check_art_catalogue.py
```

The remaining board layers still use the original atlas. For reviewed in-game
captures and input checks see `../../docs/review/square-tools/README.md`.
