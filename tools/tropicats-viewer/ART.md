# Original artwork in the Tropicats viewer

The viewer uses 109 decoded source images and 143 static material renders from the user's installed Tropicats 2.5.11
`Data/Raw/AssetBundles/allscenes_be7e0be1439093721cd26af7025dad92` and the separately cached original `m3_themes` bundle.
[art-catalogue.json](art-catalogue.json) records the bundle SHA-256, original
serialized file, object path ID, dimensions and PNG SHA-256 for every image.
No generated art or prompts are involved. The material renders evaluate the original
meshes, packed texture channels, skeletal pose, stencil mask and color lookup tables. The original images stay under ignored
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
less than 10 MB. The board theme textures additionally use the optional cached `reference/tropicats-analysis/bundles/m3_themes`; when absent the viewer falls back to the recipe board. No downloads are needed from the game CDN. The extraction accepts
`--app`, `--output`, and an optional `--catalogue` metadata destination.
Normal viewer startup uses only Python's standard library.

UnityPy's `Sprite.image` handles texture compression, atlas rectangle, atlas
rotation and original alpha. `board_recipe` is a decoded Texture2D. There is no
painting or invented state artwork. Colored crates now use the game’s own LUT
shader mapping; the source alpha remains byte-for-byte unchanged. The browser scales
each original image uniformly into its cell; ordinary pieces use 94% of a cell,
blockers use 100%. Hidden statues and composited color wheels span their source
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
| Climber color 12 | `material_climber` | Native Spine `Idle` first frame, including the prefab’s half-cell vertical offset |
| ClimberGem / stacked small, medium, big | `dot_<color>_ClimberGem/StackedGemSmall/StackedGemMedium/StackedGemBig` | Authored color and size variants, including random and coin variants. Unusual non-fruit combinations retain their base image plus `T<type>` and inspector explanation |
| Diagonal types 13–16 | `diagonal_gems_DiagonalDownRight/DownLeft/UpLeft/UpRight` | Four original authored directions; no generated rotations |
| Cannon | `material_cannon_<color>_<charge>` | Original tint map, background, stencil mask, gauge cover and face. Charge is 0/15/30 out of 45; review also includes full charge. Authored orientation retained: every campaign cannon has direction 0 |
| Chameleon/reduced | `material_chameleon_<current>_<next>` | Original Spine mesh, Blink pose at t=0, two-color mask/LUT. Encoded body color; illustrative next color from the tier palette, excluding low weights for reduced type 12. Left-facing pose is mirrored; vertical directions remain the resting pose |
| Horizontal/vertical line; bomb | `material_line_horizontal/line_vertical/bomb` | Original meshes and packed shader inputs evaluated at time zero, layered on the fruit and clipped to its alpha. Activated types retain the static bomb depiction; detonation is not simulated |
| Stones 1–5 | `stone_1hp` through `stone_5hp` | Five authored damage strengths |
| Resistant blockers 6–8 | `material_resistant_1/2/3` | Original Spine `IdleHp1/2/3` first frames, corresponding to encoded strengths 6–8 |
| Color wheel stones 9–12 | `material_wheel_*` | Original wedges, count-specific frame, background and cat face, registered to native pivots; 3–6 segments from the level palette. IDs 11/12 use the inferred reduced palette. Clockwise color order is illustrative. IDs 9/11 mark the 2×2 corner and 10/12 its occupancy |
| Chains 1–3 | `chain_1hp/2hp/3hp` | Three authored banana-chain strengths, above pieces |
| Crates 1–3 | `crate_1hp/2hp/3hp` | Three authored strengths |
| Encoded color crates >3 | `material_crate_<color>_<hp>` | Original strength sprite evaluated through `LookUpTableGemColorRangePot`: seven colors × three strengths. Encoding is color × 4 + HP; stride 4 is confirmed by metadata |
| Ice modifiers 1–3 | `iceHp1/2/3` | Three authored overlays, above fruit |
| Dirt modifiers 4–6 | `DirtHp1/2/3` | Three authored overlays; color 14 alone does not invent a fruit |
| Precharge modifiers 7–9 | Native cannon gauge | Metadata maps to 30/15/0 out of 45; cover travel fitted to source mask bounds. Non-cannon combinations retain an explicit `Q` source badge |
| Tiles 1–2; watered tile 3 | `tile_1hp/2hp`, `water_field` | Authored layers below fruit, above hidden statues |
| Hidden-object IDs | `hiddenItem` | One original statue per ID, bounded by its occupied cells, under covering tiles and stones |
| Field 2/3 | `window`, `growing_window`, `window_bridge`, `growing_window_bridge_01` | Original sprites; vertically adjacent fields of the same type are connected by an inferred bridge. Growing bridge variant 01 is illustrative. Exact native neighbor rules and variant selection remain unknown |
| Field 0 | No sprites | Non-playable space remains clickable for inspection of otherwise masked source data |
| Portal endpoints | `portal_entrance`, `portal_exit` | Original sprites placed from prefab offsets, pixels-per-unit, trim offsets and pivot. Odd IDs are entrances at the lower edge; even IDs are exits at the upper edge. Pair numbers remain in the inspector. Drop/climber route indicators remain unassigned |
| Objectives | `ui_icon_objective_<family>` (`hiddenitem_monkey` for hidden statues) | Original objective artwork alongside text totals |
| Board surface | `board_DirtAndTreasure`, `board_water`, `board_hiddenitem`, `board_drop`, `board_recipe` | Original LevelTheme references for treasure, water, hiddenitem and droppable; chameleon and resistant blocker themes also reference `board_water`. Recipe and climber fall back to `board_recipe`; the climber theme bundle is unavailable |

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
animated transitions, exact native gauge travel, runtime color order,
non-portal route indicators, exact window bridge selection, the climber board skin and remaining objective theme details.
Bomb/line static overlays, color-crate materials, portal artwork, static cannon gauges, skeletal chameleon colors and wheel palette segments are implemented. The table above records every current fallback. Exact data remains
available in the layer selector, inspector and raw JSON. Static compositions and disclosed approximations are not claimed as pixel-identical runtime states.

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


### Cannon, chameleon and wheel reconstruction

`mechanics.py` evaluates the bundled shader equations and composes native layers;
`skeleton.py` reads the features needed by the bundled Spine 3.2.01 character skeletons.
Unknown versions, unsupported constraints, attachment types and nontrivial selected deform or draw-order keys fail explicitly. No third-party runtime is installed or vendored. Binary field ordering
was checked against the official format readers for
[3.1.07](https://github.com/EsotericSoftware/spine-runtimes/blob/3.1.07/spine-csharp/src/SkeletonBinary.cs)
and [3.4.02](https://github.com/EsotericSoftware/spine-runtimes/blob/3.4.02/spine-csharp/src/SkeletonBinary.cs).
The 3.2 file has shear-aware bones and separate weighted-mesh attachments.

| Mechanic | Bundled source objects | Registered rendering |
| --- | --- | --- |
| Cannon | `CannonView` 2279, color map 2270, sprites 594/600/604/653, stencil materials 90/91 | Background × the original RGBA color; cover clipped to the alpha-test mask (threshold .1, mask scale 1.06), then face. Sprite trim offsets and pivots restored to the original 128-pixel coordinate system |
| Chameleon | Material 85, main texture 279, mask 273, LUT 304, skeleton 361, atlas 353, skeleton data 2187 | 24 bones and 25 active attachments, original weighted vertices, triangle UVs and draw order, at 128 pixels/unit. The authored first frame of `Blink` opens the eyelids; no invented facial pose |
| Wheel | `ColorWheelView` 2302, sprite manager 2342, material 96, LUT 285 | Wedges 651/661/689/679 and frames 657/598/677/692 for 3/4/5/6 segments; background 623 and face 599. Trim registration restored to 256×256 around the original pivot; wedges rotated by 360/count in the browser |

Cannon metadata defaults `CANNON_PRE_CHARGE_SMALL/MEDIUM/BIG/MAX_CHARGE`
are **0/15/30/45** (compressed bytes 00/1e/3c/5a). The source modifier names
are Little/Medium/Much, IDs 9/8/7. The private native initializers `minYPos`
and `chargeRange` are not available in the encrypted executable, so the cover's
travel is fitted to the source mask's top/bottom bounds. The numerical charge is
exact; the pixel height is an approximation. Transient charge glow and explosions
are not rendered. All 3,668 campaign cannon placements have direction 0; there
is no encoded left/up/right/down cannon art state to reconstruct. The native
CannonView method list also has no facing setter.

Chameleon's `Unlit/Unlit-RecolorLUT` clamps source red to .02–.98, samples the
current and next colors from LUT columns `color/10+.05`, mixes next→current by
mask red, then original→colored by mask green. Alpha remains the original main
texture alpha. Main texture is 512×128, mask is 256×64: mask sampling uses matching
UVs, not matching pixel indexes. The evaluator restores straight alpha for PNG,
then rasterizes the original triangles with 2× supersampling. Baking the shader
before triangle filtering approximates GPU edge filtering; it does not reproduce
half-float precision or color-space conversion exactly.

Direction defaults confirm 1=Left, 2=Up, 3=Right, 4=Down. ChameleonView exposes
`SetFacingDirection`, `scaleRight` and `scaleLeft`. The viewer mirrors the native
right-looking pose for Left; it does not rotate it upside down for vertical movement.
The precise native facing choice after vertical motion remains unverified.

Wheel uses its own `LookUpTableColorWheelPot` 285, not the crate/chameleon LUT.
`BoardFactory.STANDARD_GEM_AMOUNT` is **25** (compressed byte 32). Metadata names
`GetColorsFromConfig(skipLowAmountColors)`, `isColorWheelVariant` and
`ChameleonVariant.Reduced` ground the reduced-palette interpretation: include
positive-weight match colors normally, and weights ≥25 for stone IDs 11/12 or
chameleon type 12. Coins are included. Across the campaign this produces 3–6
segments for **every wheel**, matching all four authored frames. The actual
native predicate and runtime permutations were not executed; membership remains
an explicit inference. Wedges follow the config's color order clockwise, and
chameleon spots preview its first other eligible color. Neither ordering is
serialized as a runtime state, and both are labeled illustrative in the UI.

The generated catalogue adds 32 cannon compositions (neutral plus seven colors,
four charge states), 49 chameleon color pairs, 28 colored wedges, four frames,
one background and one face. Retained tutorial/objective sprites remain available
for objectives and unsupported segment counts, although no campaign wheel uses
that fallback. Raw source and decoded shaders stay in ignored `art/shader-evidence/`.
[Issue #97](https://github.com/corepunch/nile-archive/issues/97) retains acceptance
criteria for exact gauge travel, facing after vertical motion, reduced-palette
predicate, native color permutations and animation transitions.

Review covered level 2422's red/purple charge differences and reduced wheels,
and 2726's opposite-facing chameleons and wheel compositions. No broken images
or browser errors; row flip moves complete wheel groups, schematic toggle removes
them, difference highlighting remains source-based, and random markers still work.
The complete [state review sheet](../../docs/review/tropicats-viewer/mechanics-states.png)
was inspected, including full charge, all 49 chameleon pairs, every wheel segment
count and every color column. Reproduce it after extraction:

```sh
/tmp/tropicats-inspect-venv/bin/python tools/tropicats-viewer/mechanics.py reference/tropicats-analysis/art/sprites docs/review/tropicats-viewer/mechanics-states.png
```

| View | Before | After |
| --- | --- | --- |
| 2422 · 1368×1026 | [Before](../../docs/review/tropicats-viewer/mechanics-before-desktop.png) | [After](../../docs/review/tropicats-viewer/mechanics-after-desktop.png) |
| 2422 · 390×844 | [Before](../../docs/review/tropicats-viewer/mechanics-before-narrow.png) | [After](../../docs/review/tropicats-viewer/mechanics-after-narrow.png) |
| 2726 · chameleon facing/colors | [Before](../../docs/review/tropicats-viewer/mechanics-before-chameleons.png) | [After](../../docs/review/tropicats-viewer/mechanics-after-chameleons.png) |

Focused verification: 15 Node tests **2.38 s**, 10 material/HTTP tests **0.89 s**,
repository lint **1.10 s**, measured wall time. No build step; no game or shared
engine behavior changed. Additional local storage remains below 30 MB; no new
environment, model or game-data download was needed.


### Objective themes and bridge update

The optional `m3_themes` bundle contains `LevelTheme` records linking treasure, water, hiddenitem and droppable directly to the four board textures in the catalogue. The cached `m3_themes_chameleon` and `m3_themes_resistant_blocker` records both point to `board_water`. The recipe record has a null board reference; the recipe board already extracted from the scene remains the fallback. The climber theme bundle was not available locally. Missing cached theme assets fall back to the recipe board.

The field prefab contains `WindowBridge` (sprite 696; transform 1277) and two growing bridge variants (sprites 690/649; transforms 1352/1300). Those transforms place the growing bridge at a vertical half-cell. Connecting vertically adjacent matching field IDs is a viewer inference: the encrypted native code does not establish adjacency or variant choice. The second growing bridge is extracted and catalogued but not selected until that choice is understood. Issue #97 tracks the exact connection and variant rules.

The climber and resistant blocker use the original Spine skeletons, atlas textures, default skin and `Idle` / `IdleHp1`, `IdleHp2`, `IdleHp3` animation keys at time zero. Their slot timelines select the inactive wings and feet, and the different shell, hand and body attachments at each strength. Bone inheritance and region quads follow the official [Spine 3.4 Bone](https://github.com/EsotericSoftware/spine-runtimes/blob/3.4.02/spine-csharp/src/Bone.cs) and [RegionAttachment](https://github.com/EsotericSoftware/spine-runtimes/blob/3.4.02/spine-csharp/src/Attachments/RegionAttachment.cs) algorithms; the serialized file is 3.2.01. The climber child prefab is translated down 0.5 world units, applied as −64 authored pixels at 128 pixels per unit. Blocker prefabs use an identity transform. Rasterization preserves the original textures and attachment draw order; it does not execute the native game or simulate transitions.

| Pose | Source skeleton / atlas / texture | Authored state |
| --- | --- | --- |
| Climber | 358 / 360 / 227 | `Idle`, t=0; inactive wings and feet, prefab transform 1285 |
| Resistant 1–3 HP | 355 / 354 / 168 | `IdleHp1`, `IdleHp2`, `IdleHp3`, t=0; prefab 971 |

Controller 453 names all three blocker idle clips and defaults to the 3-HP state; controller 456 defaults to the climber idle clip. All skeleton attachment paths and source hashes are recorded in the catalogue.

The source textures, bridge sprites and [four character idle renders](../../docs/review/tropicats-viewer/native-idle-states.png) were inspected directly. Browser review covered level 1764's water theme, vertical window bridges, ice and portals at desktop and narrow sizes, plus level 892's climber, resistant eggs and growing windows. There were no broken images, console warnings/errors or horizontal page overflow at either checked size. Row flip and schematic fallback were exercised; returning to sprites restored the native poses and original theme.

| View | Before | After |
| --- | --- | --- |
| 1764 · 1368×1026 | [Before](../../docs/review/tropicats-viewer/themes-before-desktop.jpg) | [After](../../docs/review/tropicats-viewer/themes-after-desktop.jpg) |
| 1764 · 390×844 | [Before](../../docs/review/tropicats-viewer/themes-before-narrow.jpg) | [After](../../docs/review/tropicats-viewer/themes-after-narrow.jpg) |
| 892 · native creatures | [Before](../../docs/review/tropicats-viewer/creatures-before-desktop.jpg) | [After](../../docs/review/tropicats-viewer/creatures-after-desktop.jpg) |

Before captures use viewer commit `c6322df` with the same extracted level data.
Focused verification: 18 Node tests **2.52 s**, 12 Python material/HTTP tests
**0.94 s**, repository lint **1.09 s**; extraction **65.27 s**, measured wall time.
There is no build step for this viewer. No playable game or shared engine changed.
