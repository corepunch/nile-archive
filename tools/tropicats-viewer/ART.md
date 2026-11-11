# Original artwork in the Tropicats viewer

The viewer uses 102 images decoded from the user's installed Tropicats 2.5.11
`Data/Raw/AssetBundles/allscenes_be7e0be1439093721cd26af7025dad92`.
[art-catalogue.json](art-catalogue.json) records the bundle SHA-256, original
serialized file, object path ID, dimensions and PNG SHA-256 for every image.
No generated art or prompts are involved. The original images stay under ignored
`reference/tropicats-analysis/art/sprites/`; only metadata and review captures
are tracked. This is a local inspection tool, not a repackaging of the game.

## Reproduction

Use the existing inspection environment (UnityPy 1.25.4 with Pillow):

```sh
/tmp/tropicats-inspect-venv/bin/python tools/tropicats-viewer/extract_art.py --catalogue tools/tropicats-viewer/art-catalogue.json
python3 tools/tropicats-viewer/serve.py
```

Alternatively provide a Python environment with `UnityPy==1.25.4` and run the same
script. The existing environment occupies about 32 MB; decoded images occupy
less than 10 MB. No downloads are needed from the game CDN. The extraction accepts
`--app`, `--output`, and an optional `--catalogue` metadata destination.
Normal viewer startup uses only Python's standard library.

UnityPy's `Sprite.image` handles texture compression, atlas rectangle, atlas
rotation and original alpha. `board_recipe` is a decoded Texture2D. There is no
painting, recoloring, alpha replacement, or state synthesis. The browser scales
each original image uniformly into its cell; ordinary pieces use 94% of a cell,
blockers use 100%. Hidden statues and color-wheel illustrations span their source
footprints. Flipping rows moves their bounds but does not mirror the artwork.

## Runtime mapping and states

[art.mjs](art.mjs) is the composition contract. `app.mjs` uses the extracted
manifest to resolve images; the server serves only safe PNG names present in
that manifest. There are no arbitrary file or directory routes.

| Source rule/state | Original artwork | Composition / fidelity |
| --- | --- | --- |
| Red, green, blue, yellow, purple, orange | `dot_red/green/blue/yellow/purple/orange` | Original strawberry, starfruit, blueberry, banana, grapes and apple sprites |
| Random color 8 | `dot_random` and its authored special variants | Exact mode shows the original striped marker. Optional preview chooses actual fruit from the level's positive-weight color palette; deterministic by level and source coordinate, without simulating RNG, gravity, matches or solvability |
| Coins, droppable, cannonball, rainbow, treasure, colorless | Corresponding `dot_*` | Original static sprite; no animated rainbow shader |
| Climber color 12 | `ui_icon_climber` | Original static illustration of the animated character |
| ClimberGem / stacked small, medium, big | `dot_<color>_ClimberGem/StackedGemSmall/StackedGemMedium/StackedGemBig` | Authored color and size variants, including random and coin variants. Unusual non-fruit combinations retain their base image plus `T<type>` and inspector explanation |
| Diagonal types 13–16 | `diagonal_gems_DiagonalDownRight/DownLeft/UpLeft/UpRight` | Four original authored directions; no generated rotations |
| Cannon; chameleon/reduced | `cannon_tutorial`, `chameleon_1_tutorial` | Original static illustrations; direction, charge and reduced/color state are not reconstructed |
| Horizontal/vertical line; bomb / activated bomb | Base fruit + data badge | `↔`, `↕`, `B`, `AB`, `SB` retain type identity; packed shader overlays are not presented as finished art |
| Stones 1–5 | `stone_1hp` through `stone_5hp` | Five authored damage strengths |
| Resistant blockers 6–8 | `resistantBlocker_tutorial_1hp/2hp/3hp` | Three original tutorial poses; metadata constants give HP range 6–8 |
| Color wheel stones 9–12 | `ui_icon_objective_colorwheel` | One original 2×2 objective illustration. IDs 9/11 mark the top-left corner; 10/12 occupy the other three cells. Segment/configuration state is not simulated |
| Chains 1–3 | `chain_1hp/2hp/3hp` | Three authored banana-chain strengths, above pieces |
| Crates 1–3 | `crate_1hp/2hp/3hp` | Three authored strengths |
| Encoded color crates >3 | `crate_tintable_1hp/2hp/3hp` | Untinted original frame plus `C<source ID>`. Low two bits select strength; this encoding is inferred from the observed data, not a reconstructed native method |
| Ice modifiers 1–3 | `iceHp1/2/3` | Three authored overlays, above fruit |
| Dirt modifiers 4–6 | `DirtHp1/2/3` | Three authored overlays; color 14 alone does not invent a fruit |
| Precharge modifiers 7–9 | Base sprite + `Q<source ID>` | Exact source value preserved, shader gauge not reconstructed |
| Tiles 1–2; watered tile 3 | `tile_1hp/2hp`, `water_field` | Authored layers below fruit, above hidden statues |
| Hidden-object IDs | `hiddenItem` | One original statue per ID, bounded by its occupied cells, under covering tiles and stones |
| Field 2/3 | `window`, `growing_window` | Original plank/bamboo sprite; bridge connections are not reconstructed |
| Field 0 | No sprites | Non-playable space remains clickable for inspection of otherwise masked source data |
| Portal endpoints | `P<source ID>` badge | Entrance/exit direction is not guessed. Portal and route sprites are catalogued but not assigned until semantics are verified |
| Objectives | `ui_icon_objective_<family>` (`hiddenitem_monkey` for hidden statues) | Original objective artwork alongside text totals |
| Board surface | `board_recipe` | Original bundled board texture, shared by all objective families in this viewer |

The base fruit, strength and layer choices were checked against the
`BuildPlayer-M3_Level.sharedAssets` prefab TypeTrees: `GemView` (2237),
`FieldView` (2247), `GemColorSpriteManager` (2249), `HiddenItemView` (2252),
and the field sprite managers. Relative sorting is grounded in the prefab's
SpriteRenderer layers: hidden object 2, tile 4, fruit 6, stone 8, chain/crate 9,
window 11. Browser z-indices preserve these relationships. Modifier ordering
is a static approximation; no claim of pixel-identical game rendering is made.

Selection, hover, keyboard focus and difference highlighting use the viewer's
ordinary HTML control outlines, without replacing or tinting the game sprites.
There are no generated game-button states. No animation, pressed/exhausted tool
state or gameplay transitions are implemented in this inspection viewer.

## Remaining fidelity work

[Issue #97](https://github.com/corepunch/nile-archive/issues/97) tracks the remaining
shader overlays, animated poses, gauge/direction states, color-crate tint,
wheel configurations, portals/routes, window bridges and objective-specific
board skins. The table above records every current fallback. Exact data remains
available in the layer selector, inspector and raw JSON. These illustrations
and badges are not claimed as faithful runtime states.

## Visual audit

The decoded sprite sheet was visually inspected for original color, transparency,
blocker strengths, ice/dirt strengths, stacked sizes and diagonal directions.
Browser review covered level 8 (fruit, hidden objects, stones, tiles), 1080
(resistant blockers, 2×2 wheels, ice and special badges), and 2191 (feathers,
crates, character illustrations, portals and irregular field mask).
The default combined view and numeric view, exact random markers, random preview,
row flip, keyboard selection and source difference outlines were exercised.

Representative before/after captures are kept in `docs/review/tropicats-viewer/`:

| Size | Previous schematic | Original sprites |
| --- | --- | --- |
| Desktop 1368×1026 viewport | [desktop.jpg](../../docs/review/tropicats-viewer/desktop.jpg) | [sprites-desktop.png](../../docs/review/tropicats-viewer/sprites-desktop.png) |
| Narrow 390×844 viewport | [narrow.jpg](../../docs/review/tropicats-viewer/narrow.jpg) | [sprites-narrow.png](../../docs/review/tropicats-viewer/sprites-narrow.png) |

[Dense special-piece view](../../docs/review/tropicats-viewer/sprites-specials.png).
Captures include the full scrollable page. No new game or engine art path is
changed, so renderer/game builds are outside this tool's verification scope.
