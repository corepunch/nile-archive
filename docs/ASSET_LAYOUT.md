# Asset layout

Every game's runtime art lives in `games/<game>/data/`, sorted by the screen
that uses it and then by kind, the way Cradle of Rome sorts its textures. Only
files the game loads go in `data/`. Sprites that are packed into an atlas live
in `art/registered/` beside the source paintings and prompts they come from.

## Folders

```
data/
  common/          shared by every screen
    fonts/
    icons/         small standalone icons (Nile Archive)
  city/            the island
    island.jpg     ground painting
    roads.png      road tiles (roads-<look>.png for a second look)
    buildings/  building-shadows/   one sprite per Blender building key
  board/           the match-3 board
    backs/         background.jpg, scene-1.jpg, scene-2.jpg: separate files, never packed
    pieces.png     everything that sits in a cell: gem packs, campaign, resource,
                   story pieces, market goods, bonus pieces and action icons
    blockers.png   chains, ice and stone over a cell
    cells.png      square floor tiles, grout, selection and perimeter
    hud.png        settings, score, moves, shop marks, signboard, result icons
    fx.png         particles and glows
  story/
    characters/    dialogue portraits
    floors/  scenes/  finale/   story pictures
```

Nile Archive has no board: it uses `common/`, `city/` and `story/`
(`story/scenes/` holds its scene backgrounds). Emergency keeps its imported
level backdrops in `levels/` and its native animation atlases in `sprites/`.

The engine's default skin uses the same names under `engine/data/board/`,
loaded with `texture.load_engine`. Each campaign packs the four 128 px
painted navigation icons into its own pieces atlas.

## Atlases are one kind of art each

An atlas groups art that is drawn together in one style, so a reskin redraws
one atlas at a time: all pieces in one ImageGen pass, all blockers in another.
Two kinds never share an atlas, and backgrounds, portraits, story pictures and
buildings stay separate files. A building is rendered per Blender collection
and registered by key, and a picture is too large to pack usefully.

Every piece, blocker, cell, booster and HUD icon is a 128x128 canvas, and the
atlases lay them out on an even 128-pixel grid in name order, so each sheet
reads as rows of same-sized cells. Only odd sizes (the signboard, effects) are
shelved below the grid.

`tools/match3_atlas.py` packs every registered sprite by its frame name:

| Atlas | Frames |
| --- | --- |
| `pieces` | `kind-N` aliases, `<pack>-N`, `campaign-*`, `resource-*`, `story-*`, `market-N` |
| `blockers` | `chain*`, `ice-1`, `ice-2`, `stone-*` |
| `cells` | `tile-*`, `selected`, `hint`, `guide`, `cell-mask` |
| `boosters` | `booster-*`, `bonus-*` (the engine's default skin: `pickaxe-*`, `dynamite-*`, `sunburst-*`) |
| `hud` | `pause-*`, `score`, `complete`, `life`, `shop-*`, `signboard`, result icons |
| `fx` | `fx-*`, `glow`, `spark-*`, `ice-puff-*`, `impact-*` |

Relic Rush packs its small HUD icons (score, completion, lives, shop and
result icons) into `pieces`. Its HUD definition reads those frames from
`pieces` and the jade signboard from `hud`.

It writes `lua/match3_atlases.lua` (one `{path, frames}` per atlas), the board
skin `lua/match3_skin.lua` and the board HUD `lua/match3_hud.lua`. A skin lists
`sheets`, standalone `images` (backgrounds, a portrait) and `aliases`, and
`match3.atlas` flattens them into one table of named images. Games look art up
by frame name, never by file or pixel rectangle.

```sh
python3 tools/match3_atlas.py          # repack after changing a registered sprite
python3 tools/match3_atlas.py --check  # provenance of every input and output
```

## Registered sprites

`games/<game>/art/registered/` holds the cropped, masked and resized sprites
that each game's registration tools write and the packer reads, in folders
named after their source sets: `board-states/`, `board-tiles/`, `tile-sets/`,
`expedition-hud/`, `navigation/`, `story-pieces/`, `resource-pieces/`,
and grid sheets such as `campaign-pieces.png`, `bonus-gems.png`,
`market-goods.png` and `result-icons.png`. Each set's
`--check` script verifies these files, and the game's asset check verifies that
the shipped atlases contain them.

## Adding art

1. Register the sprite into `art/registered/` with its game's tool, or add it to
   the source set and its tool.
2. Give it a frame name of the kind it belongs to (the table above), and add a
   rule in `group_of` if it is a new kind.
3. Run `python3 tools/match3_atlas.py`, then the game's asset check, and look at
   it in the game.
4. Catalogue it in the game's `docs/asset-catalogue.md`.
