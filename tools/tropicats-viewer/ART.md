# Original artwork in the Tropicats viewer

The viewer uses 102 decoded source images and 24 static material renders from the user's installed Tropicats 2.5.11
`Data/Raw/AssetBundles/allscenes_be7e0be1439093721cd26af7025dad92`.
[art-catalogue.json](art-catalogue.json) records the bundle SHA-256, original
serialized file, object path ID, dimensions and PNG SHA-256 for every image.
No generated art or prompts are involved. The material renders evaluate the original
meshes, packed texture channels and color lookup table at time zero. The original images stay under ignored
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
painting or invented state artwork. Colored crates now use the game’s own LUT
shader mapping; the source alpha remains byte-for-byte unchanged. The browser scales
each original image uniformly into its cell; ordinary pieces use 94% of a cell,
blockers use 100%. Hidden statues and color-wheel illustrations span their source
footprints. Flipping rows moves their bounds but does not mirror the artwork. Portal anchors
move to the mirrored cell edge when rows are flipped.

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
| Horizontal/vertical line; bomb | `material_line_horizontal/line_vertical/bomb` | Original meshes and packed shader inputs evaluated at time zero, layered on the fruit and clipped to its alpha. Activated types retain the static bomb depiction; detonation is not simulated |
| Stones 1–5 | `stone_1hp` through `stone_5hp` | Five authored damage strengths |
| Resistant blockers 6–8 | `resistantBlocker_tutorial_1hp/2hp/3hp` | Three original tutorial poses; metadata constants give HP range 6–8 |
| Color wheel stones 9–12 | `ui_icon_objective_colorwheel` | One original 2×2 objective illustration. IDs 9/11 mark the top-left corner; 10/12 occupy the other three cells. Segment/configuration state is not simulated |
| Chains 1–3 | `chain_1hp/2hp/3hp` | Three authored banana-chain strengths, above pieces |
| Crates 1–3 | `crate_1hp/2hp/3hp` | Three authored strengths |
| Encoded color crates >3 | `material_crate_<color>_<hp>` | Original strength sprite evaluated through `LookUpTableGemColorRangePot`: seven colors × three strengths. Encoding is color × 4 + HP; stride 4 is confirmed by metadata |
| Ice modifiers 1–3 | `iceHp1/2/3` | Three authored overlays, above fruit |
| Dirt modifiers 4–6 | `DirtHp1/2/3` | Three authored overlays; color 14 alone does not invent a fruit |
| Precharge modifiers 7–9 | Base sprite + `Q<source ID>` | Exact source value preserved, shader gauge not reconstructed |
| Tiles 1–2; watered tile 3 | `tile_1hp/2hp`, `water_field` | Authored layers below fruit, above hidden statues |
| Hidden-object IDs | `hiddenItem` | One original statue per ID, bounded by its occupied cells, under covering tiles and stones |
| Field 2/3 | `window`, `growing_window` | Original plank/bamboo sprite; bridge connections are not reconstructed |
| Field 0 | No sprites | Non-playable space remains clickable for inspection of otherwise masked source data |
| Portal endpoints | `portal_entrance`, `portal_exit` | Original sprites placed from prefab offsets, pixels-per-unit, trim offsets and pivot. Odd IDs are entrances at the lower edge; even IDs are exits at the upper edge. Pair numbers remain in the inspector. Drop/climber route indicators remain unassigned |
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

## Reconstructed materials and portal evidence

`materials.py` is a small CPU evaluator, requiring only the existing Pillow and
UnityPy environment. It does not execute the game. The bundle's LZ4 shader blobs
contain readable Metal vertex and fragment programs; decoded evidence stays in
ignored `art/shader-evidence/`. Their fingerprints are recorded in the catalogue.
The installed native executable is encrypted, so portal parity is established
from serialized board topology, not claimed as a disassembled native method.

| Render | Original objects in `BuildPlayer-M3_Level.sharedAssets` | Interpretation |
| --- | --- | --- |
| Bomb | Material 5, mesh 314, texture 124, shader 331 | `Custom/Unlit/BombGemOverlay`, including its time-zero vertex displacement |
| Horizontal line | Material 59, mesh 317, texture 289, shader 349 | `Custom/Unlit/LineGemOverlay` |
| Vertical line | Material 59, mesh 321, texture 289, shader 349 | Separate authored vertical mesh, not a rotated horizontal bitmap |
| Colored crates | Material 95, LUT texture 304, sprites 685/645/617 | `Sprites/Default-LUT`; source strength alpha is retained |
| Entrance / exit | Sprites 597/669, transforms 1273/1216 | Prefab Y offsets −0.860 / +0.716, 178 pixels per unit, original trim registration |

The overlay fragments use red coverage, blue edge shading, green highlight and
the material tint: RGB = tint × (0.8 + 0.2 × blue), alpha = red × blue × tint alpha
× (1 + highlight green). UVs and secondary UVs are interpolated over the original
triangles. The secondary coordinates are clamped at vertices before interpolation,
as in the native vertex shader. The evaluator uses each texture's wrap mode,
bilinear sampling, and 2× supersampling. Browser alpha masking keeps the overlay
on the displayed fruit; ice, stones, chains and crates retain their higher layers.
These are static material evaluations, not animated pulses or explosion effects.

The crate shader indexes LUT U = color / 10 + 0.05 and V = source red. Metadata
field defaults confirm `Crate.COUNT_DIFFERENT_HP = 4`,
`FieldView.COUNT_COLOR_COLUMNS_LUT = 10` and
`FieldView.OFFSET_TO_COLUMN_MIDDLE = 0.05`. The shader outputs premultiplied RGB;
the PNG stores equivalent straight RGB and the original alpha. No hue rotations
or hand-picked replacement colors are used.

Across all 8,190 campaign variants, every odd portal has an open lower boundary,
every even portal has an open upper boundary, and every endpoint has its paired
partner. The two sprite prefab names and positions agree with this topology.
Level 51 is the introductory example: odd IDs 1/3/5/7 terminate the lower left
columns; even IDs 2/4/6/8 feed the upper right columns. Paired endpoints need not
be vertically ordered in the same direction in later layouts. The viewer reserves
space outside the board so boundary portals are not clipped.

## Remaining fidelity work

[Issue #97](https://github.com/corepunch/nile-archive/issues/97) tracks the remaining
animated poses and transitions, gauge/direction states, wheel configurations,
non-portal route indicators, window bridges and objective-specific board skins.
Bomb/line static overlays, color-crate materials and portal artwork are now implemented. The table above records every current fallback. Exact data remains
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

### Material update review

Level 606 contains bombs, both line axes, colored crates and portals together,
including overlays covered by ice and crates. Checked the inspector's exact
portal ID/pair and crate color/HP, source difference highlighting, row flip,
raw portal layer, and schematic toggle. Level 8 checks exposed bomb/line overlays.
All 21 crate color/strength combinations and the three overlay renders were
reviewed on the decoded material sheet; automated checks preserve every crate's
alpha plane and verify horizontal/vertical mesh orientation.

| Viewport | Before badges | After materials |
| --- | --- | --- |
| 1368×1026 | [Before](../../docs/review/tropicats-viewer/materials-before-desktop.png) | [After](../../docs/review/tropicats-viewer/materials-after-desktop.png) |
| 390×844 | [Before](../../docs/review/tropicats-viewer/materials-before-narrow.png) | [After](../../docs/review/tropicats-viewer/materials-after-narrow.png) |

Verification: 12 Node tests (2.93 s), 7 Python material/HTTP tests (0.85 s),
repository lint (1.48 s), measured wall time. All campaign artwork references and
portal pairs/boundaries passed the corpus check. No game/engine build is needed.
