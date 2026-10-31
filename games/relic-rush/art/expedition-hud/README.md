# Expedition header artwork

Both source PNGs were created with built-in ImageGen on 31 October 2026.

`controls.png` contains all seven icons in a single atlas call: five authored
pause interaction states, a score-goal star seal and a completed-goal check seal.
The square-tool atlas supplied the existing jade/gold style. See
[controls-prompt.txt](controls-prompt.txt) for the exact request.

`elena-investigating.png` is a separate identity-preserving edit using the game's
existing Elena dialogue portrait. She examines an ancient sun fragment through a
magnifying glass. See [elena-prompt.txt](elena-prompt.txt). This is a static pose,
with its own texture/anchor so an animation can replace it later.

[manifest.json](manifest.json) records source dimensions, measured crops, runtime
paths and reproduction. Imports crop/resize spatially with the original alpha;
every pause state is authored, with no generated tints or procedural glyphs.

```sh
python3 games/relic-rush/tools/prepare_hud.py
python3 games/relic-rush/tools/prepare_hud.py --check
```

Runtime icons are `data/expedition-hud/{pause-<state>,score,complete}.png`;
the portrait is `data/characters/elena-investigating.png`.
The [game review](../../docs/review/expedition-header/README.md) contains both phone
sizes, every new icon state, the static portrait and native popup input checks.
