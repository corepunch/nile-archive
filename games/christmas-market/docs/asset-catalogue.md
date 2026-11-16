# Christmas art direction catalogue

## Themed board art

The six live chips are market goods. Their silhouettes and dominant colours
make the gold bell, red candy cane, green holly, sky-blue knitted mitten, plum
bauble and toasted gingerbread readable over both parchment and deep blue.
The bell also identifies Gold in the wallet and shop.

| Runtime frames | Rule and artwork |
| --- | --- |
| `festive-0` through `festive-5` | Bell, candy cane, holly, knitted mitten, bauble and gingerbread, in atlas order. |
| `ray-row`, `ray-column`, `ray-diagonal` | One capped rocket modelled in Scener and rendered on the +30°, 90° and −30° axes. Cranberry-red collars and waist, with vanilla-ivory long cone tips and diagonal bands. |
| `bomb`, `prism`, `plane` | Evergreen bomb with a warm-gold belt and inset socket disc, a rope fuse and a lit tip. The folded paper plane is icy blue, painted in the base sheet. The rainbow ball has pillowed enamel tiles in three rows of six on a dark violet sphere. The bomb and rainbow gem are painted over Scener renders. |
| `carpet-swatch`, `goal-carpet` | Warm apricot light spreads across the paving when a match touches a lit cell. A bronze lantern identifies the goal. |
| `oil-material`, `goal-oil` | Pale matte snow drifts beneath treats. Matching on it clears it. If the turn clears none, snow drifts into a neighbouring cell. A snow mound identifies the goal. |
| `stone-1` | One front-facing carved hex stone. An adjacent match or direct power-up hit clears it. The HUD and guide reuse the board sprite. |
| `delivery` | The campaign's red parcel. Source boards use the original donut. |
| `chain`, `chain-1-mirror`, `chain-2` | A silver strand bolts to two opposite hex edges. The mirrored one-hit strand uses the opposite diagonal and gold plating. Two crossed silver strands bolt to all four sloped edges for two hits. |

ImageGen painted all six market goods in one [transparent atlas](../art/festive-pieces/source.png)
using the [prompt](../art/festive-pieces/prompt.txt) and
[3×2 layout guide](../art/festive-pieces/layout.png). The atlas packer crops
the six 512 px bays and fits the artwork to the canonical 128 px canvas with
its authored alpha. Each chip uses the same artwork when moved, selected or
hinted. The board animates the pose and uses its existing authored selection,
hint and chain overlays. The [registration manifest](../art/match3-atlas.json)
records the crop and fitted size per chip. Rebuild `data/match3.png` with
`python3 tools/match3_atlas.py`.
[Live board and state captures](screenshots/review/market-wishes/README.md).

The [earlier base sheet](../art/board-theme/source.png) and
[accent revision](../art/board-theme/accent-revision.png) document the first
festive palette. The base sheet remains the source for certain reference elements.
[Earlier in-game art review](screenshots/review/board-palette/README.md).

Built-in ImageGen painted the three rocket axes, bomb and rainbow gem together for both games. The [painted sheet](../../../art/match3-power-up-paint/source.png) and its [prompt](../../../art/match3-power-up-paint/prompt.txt) are saved with the [Scener edit target](../../../art/match3-power-up-paint/scener-strip.png). The [atlas manifest](../art/match3-atlas.json) records the crop, fitted size and position of each frame inside the canonical inset hex. Rebuild with `python3 tools/match3_atlas.py`. [Before and after at both phone sizes](screenshots/review/power-up-paint/README.md).

`python3 tools/match3_specials.py christmas-market` reproduces the five geometry renders used to make the edit target. [Scener models and original board review](screenshots/review/scener-power-ups/README.md).

One ImageGen atlas contains all six [edge-mounted chain sprites](../../../art/match3-chain-paint/README.md). The board uses the hex well face to place the bolts, and the guide uses a miniature of that face. [In-game comparisons](screenshots/review/chain-anchors/README.md).

The [terrain atlas](../../../art/match3-terrain/source.png) was painted in one built-in ImageGen call for both games using the [approved concepts](../../../art/match3-terrain/christmas-market-concepts.png). The [prompt](../../../art/match3-terrain/prompt.txt) and [registration manifest](../art/match3-atlas.json) record the opaque swatch crops and alpha-preserving goal icon placement. Rebuild with `python3 tools/match3_atlas.py`. [Before and after at both phone sizes](screenshots/review/themed-terrain/README.md).

The [front-facing carved hex stones](../../../art/match3-blockers/source.png) use their own ImageGen sheet. [Stone review](screenshots/review/board-floors/README.md).

## Additional board elements

The 48-cell [surface master](../../../engine/art/match3-elements/source.png) and
[exact prompt](../../../engine/art/match3-elements/prompt.txt) contain both games'
24-state families in one ImageGen call. The full-bleed tile faces are cropped,
resized and registered with the [canonical engine hex mask](../../../engine/art/hex-tile/README.md).
The two free-standing delivery pieces retain their authored alpha from the earlier
[master](../../../engine/art/match3-elements/source-v1.png) and
[prompt](../../../engine/art/match3-elements/prompt-v1.txt). The
[registration manifest](../../../engine/art/match3-elements/manifest.json) records
all sources, crops and runtime paths. From the repository root, reproduce the
states with `python3 tools/match3_elements_art.py`, then pack the runtime atlas
with `python3 tools/match3_atlas.py`. No colour or damage state is generated by
tinting; each was authored. The registration check verifies all 46 full-cell
states against the canonical mask.

| Role | Runtime atlas keys | Rule and visual states |
| --- | --- | --- |
| Carved stone | `stone-1` | Solid; one adjacent match or direct power-up hit breaks it. |
| Delivery | `delivery`, `delivery-exit` | A nonmatching movable piece and its fixed destination. |

The master's crate, tunnel, hidden-object and growth cells belong to mechanics
the engine no longer has (they are not in Homescapes' story levels). They stay
in the master image but are not registered, and their frames left the atlas.

Board rendering, guide icons and goal icons use the same named atlas artwork;
the neutral skin preview falls back to this game's authored element sprites.
Review the carved stone and the delivery on the actual board with
`--element-states --headless --fresh --mute --size 480x900`, and at 390×844.
The reviewed captures are [full size](../../../docs/review/match3-elements/christmas-market-states.png)
and [narrow](../../../docs/review/match3-elements/christmas-market-state-narrow.png).


The earlier straight-line rules and striped treat artwork are recorded in the [straight-line match-3 review](review/straight-line-match3/README.md).

Status: the buildings are Blender renders with projected registration (see the [building catalogue](building-catalogue.md)); the board, HUD and character art are directional ImageGen artwork. The planned ImageGen repaint of the renders and special-colour readability remain in [#34](https://github.com/corepunch/nile-archive/issues/34).

| Asset | Source | Draft runtime | Meaning and supported states |
| --- | --- | --- | --- |
| 37 buildings and decorations | `art/building-catalogue/` (Blender scene, catalogue, registration) | `data/buildings/<key>.png` | Ten sequential construction milestones, 15 decorations, 4 trees and 6 cottages, one Blender render each; placed and placement-preview use the same sprite, with engine lift/footprint feedback. See the [building catalogue](building-catalogue.md) |
| Original building atlas | `art/buildings.png` | Retired | The first directional paintings of the twelve designs; no longer extracted |
| Labeled building sheet | `art/building-reference-sheet.png` | Reference only | All twelve designs, numbered and captioned: the Blender models follow it |
| Six festive puzzle kinds | `art/festive-pieces/source.png` | `data/match3.png` | Gold bell, candy cane, holly, blue mitten, plum bauble and gingerbread. The original `art/icons.png` crops under `data/tile-sets/festive/` are legacy exports. |
| Specials and board layers | `art/icons.png`, cells 6–18 | `data/board-states/` | Three shooting-star axes, firework bomb, rainbow prism, snow, tinsel, two ice strengths, selection, hint, guide and the original atlas cell mask |
| Tools | `art/icons.png`, cells 19–33 | `data/board-states/` | Hammer, firecracker and star wand: normal, selected, pressed, hover and disabled, authored together in one atlas |
| Pause and completion | `art/icons.png`, cells 34–39 | `data/expedition-hud/` | Five authored pause states and a completion medal; medal also represents cumulative Christmas Stars |
| Board tiles | Shared set generated by `tools/board_tiles.py` from `engine/art/board-tiles/tiles.json` | `data/board-tiles/*.png` | The eight Cradle of Rome slots; parchment cells and deep blue tablets are in use. See [Board tiles](#lantern-panes) |
| Lives | Relic Rush's [authored heart](../../relic-rush/art/expedition-hud/manifest.json), copied unchanged | `data/expedition-hud/life.png` | One static life counter icon. The capsule uses the existing skin press state |
| Buildable market terrain | `art/terrain.png` | `data/island.jpg` | Empty snowy market ground used for building placement |
| Market streets | `tools/roads.py christmas-market` (Scener model; palette in `art/roads.json`) | `data/roads.png` | Fifteen paved road pieces, one per combination of joined neighbours, with rounded turns and junction corners, plus eight looks of each straight direction so a long street does not repeat (8 × 4 atlas): grey-brown setts, stone kerbs and a snow shoulder. The engine lays them from every building's front and joins them ([Roads](../../../docs/BUILDINGS.md#roads)); no interaction states. Captures: `screenshots/market.jpg`, `screenshots/phone-market.jpg` |
| Market streets, second look | `tools/roads.py christmas-market --style sandstone` (palette in `art/roads-sandstone.json`, copied from Relic Rush's first sandstone streets) | `data/roads-sandstone.png` | The same pieces as warm sandstone setts with pale kerbs and no snow shoulder. An option under review, not the default: start the game with `--roads sandstone` to see it. Capture: `screenshots/market-sandstone.jpg` |
| Puzzle backdrop | Built-in ImageGen, `art/lantern-panes/spruce-backdrop.png` | `data/winter.jpg` → `data/match3.png` | One static dusk market painting for all puzzles |
| Main character | User-supplied `art/noelle-reference.jpg`; ImageGen transparent cutout `art/noelle.png` | `data/characters/noelle.png` | Noelle's static dialogue and board portrait; original direction retained as `art/noelle-direction-v1.png` |
| Story cast | Built-in ImageGen, `art/story-cast.png` | `data/characters/{theo,agnes,henrik,pip,wren}.png` | Five painted dialogue busts on Noelle’s 320×480 canvas. See [Story cast](#story-cast) |
| Portrait app icon | `art/app-icon-source.png` | `Assets.xcassets/AppIcon.appiconset/` | One authored portrait composition, spatially resized for all iOS/macOS slots; opaque RGB square, no baked corner mask, no interaction states |
| Interface controls | `lua/skin.lua` (engine `ui.skin`) | Engine geometry | Four outlined Lilita text palettes, the parchment panel, the festive red button (normal, pressed sinks 2 units, disabled drains the colour; flat text variant), toggle and focus ring. Hover and selected match normal because touch has no hover; no bitmap or derived state. Captures are pixel-identical to the paint code this replaced |
| Snowfall and feedback | Lua renderer | Procedural | Two world-anchored layers of village snowfall, mission banner, kudos, collection particles, beams, lift and placement feedback |
| Effect sprites | CC0 Kenney Particle Pack, `art/particles/kenney/` | `data/match3.png` | Seven tinted additive sprites for impacts, sparks, shards and the bomb's bloom; see [Particle sprites](#particle-sprites) |

Built-in ImageGen generated all new paintings except the buildings, which are Blender renders. `art/prompts.json` records the exact source prompts; `art/reference-sheet-prompt.txt` records the labeled-sheet prompt. `art/registration.json` records the icon atlas crops and output sizing; building registration lives in `art/building-catalogue/`. Original source RGB and alpha are preserved for the original free-standing artwork and controls. The additional full-cell states use the canonical mask as described above. Control states are directly cropped from the authored atlas. The six pieces, the three tools' states, Pause and the goal star are cropped square around their own artwork, with one side per family, and scaled evenly to 128×128. That keeps their authored proportions: the earlier unequal source cells stretched them tall. Hex board states keep their whole source cell, because it registers them to the board slot.

Reproduce draft runtime extraction with `python3 games/christmas-market/tools/prepare_assets.py`; launch previews with `make run-christmas-market ARGS="--showcase --fresh --mute"` or `ARGS="--level 4 --fresh --mute"`. The PR captures all screens at 480×900, plus the market, board and dialogue at 390×844 with safe areas. All twelve directional building footprints are included across three review pages. Every building footprint is now projected from the Blender scene and checked in the ten review pages.

The font and its license are inherited unmodified from Relic Rush in `data/fonts/`. Gameplay modules were adapted locally from Relic Rush; its original archaeological paintings are not used in this draft.

## Town HUD

Lives, Gold, Treats, Supplies and Christmas Stars share the top wallet on
the market and puzzle. Lives use the existing heart, Gold uses the bell,
Treats use gingerbread, Supplies use holly, and Stars use the completion
medal. On a board the three resource totals include the current attempt.
On a winning match the result card shows the resources to bank, including
any delivery for the next stall. The shop uses the same three resource icons
to show prices. [Wallet and shop review](screenshots/review/resources-and-finds/README.md).

## Story pieces

One normal chip kind is replaced for an entire wish, including refills.
The find uses a shared selection pose and overlay, and regular chain art
can cover it. The first-clear card uses the same isolated artwork.

| Wish | Runtime `data/story-pieces/` | Replaces |
| --- | --- | --- |
| 9 | `cocoa.png` | Red candy cane |
| 16 | `scarf.png` | Blue mitten |
| 19 | `letter.png` | Gingerbread |
| 24 | `ribbon.png` | Red candy cane |
| 25 | `telegram.png` | Blue mitten |
| 27 | `lantern.png` | Gold bell |

ImageGen painted all six in one [transparent atlas](../art/story-pieces/source.png)
using the [prompt](../art/story-pieces/prompt.txt), the
[layout guide](../art/festive-pieces/layout.png) and the
[ordinary festive sheet](../art/festive-pieces/source.png) as style reference.
The [manifest](../art/manifest.json) records all six 512 px bays, active wishes,
replacement kinds, runtime paths and canonical mask. Reproduce with
`python3 games/christmas-market/tools/prepare_story_pieces.py`. The exporter
scales the painted area using the same fit as a normal piece and preserves
its authored alpha. [Board and first-clear capture review](screenshots/review/resources-and-finds/README.md).

## Puzzle backdrop

The [game-screen concept](../art/lantern-panes/concept.png) was generated from
the real festive chips, story pieces and a rendered story board. Its palette
guides the [master dusk painting](../art/lantern-panes/spruce-backdrop.png)
and the three playing surfaces. Snow, fir boughs and amber stall lights frame
a quiet green playing area. The game anchors the scene at the bottom and
crops from the top according to the phone's proportions.

The [background prompt](../art/lantern-panes/spruce-backdrop-prompt.txt) and
output recipe are in the [manifest](../art/manifest.json). From the repository
root, run `python3 games/christmas-market/tools/prepare_assets.py --backdrop`
to fit the painting to a 600×900 JPEG, then `python3 tools/match3_atlas.py`
to pack it. [Before and after on both phone sizes](screenshots/review/spruce-palette/README.md).

## Story floors

The paintings appear on first clears as the pieces fade away over 0.6 seconds.
The image holds for 1.2 seconds before the scene. Reduce Motion shows the
image without the fade. During play and on replays the board shows its regular
tablet and parchment states.

| Level | Rule and story | Built-in ImageGen master and prompt | Runtime |
| --- | --- | --- | --- |
| 24, A Ribbon for Home | The last pane gives way to a lantern-lit view of Noelle's childhood wish ribbon. | [Painting](../art/story-floors/wish-ribbon.png), [prompt](../art/story-floors/wish-ribbon.prompt.txt) | `data/story-floors/wish-ribbon.jpg` |
| 25, Word from the Station | The board gives way to Pip's telegram, with his scarf and a stamp beside it. | [Painting](../art/story-floors/telegram.png), [prompt](../art/story-floors/telegram.prompt.txt) | `data/story-floors/telegram.jpg` |
| 28, The Last Train | A slowly arriving train and lamps in the snow lead into Pip's reunion. | [Painting](../art/story-floors/last-train.png), [prompt](../art/story-floors/last-train.prompt.txt) | `data/story-floors/last-train.jpg` |

The three 1190×1322 RGB masters are downsampled without cropping to fit 720×800
with Lanczos, then encoded as JPEG (quality 91, 4:4:4, optimized). Reproduce
from the repository root with Pillow.

```sh
python3 - <<'PY'
from pathlib import Path
from PIL import Image

game = Path("games/christmas-market")
for master in (game / "art/story-floors").glob("*.png"):
    with Image.open(master) as source:
        image = source.convert("RGB")
        image.thumbnail((720, 800), Image.Resampling.LANCZOS)
        image.save(game / "data/story-floors" / f"{master.stem}.jpg",
                   quality=91, subsampling=0, optimize=True)
PY
```

The renderer center-crops each painting to the active board bounds and uses
the connected board mask. [First-clear review](screenshots/review/lantern-panes/README.md).

## Village snow

Snowfall uses two layers over the village (84 small and 44 large flakes).
Their pattern is anchored to the world origin, so panning carries the flakes
with the market while they keep falling. Larger foreground flakes fall faster,
and both layers fade toward the bottom controls. Reduce
Motion holds the flakes still. The HUD and dialogue draw above the snowfall.

Run `build/test/christmas-market "shot main-character-board" "shot phone-board"
"shot market" "shot phone-market" "shot specials-board"` for both portrait
sizes and a board with blockers and specials.

| View | Before | After |
| --- | --- | --- |
| Board, 480×900 | ![Beveled wells](screenshots/review/winter-polish/board-before-480x900.jpg) | ![Flat wells and slim rim](screenshots/review/winter-polish/board-after-480x900.jpg) |
| Board, 390×844 | ![Beveled wells on a narrower phone](screenshots/review/winter-polish/board-before-390x844.jpg) | ![Slim rim on a narrower phone](screenshots/review/winter-polish/board-after-390x844.jpg) |
| Village, 480×900 | ![Village before layered snowfall](screenshots/review/winter-polish/village-before-480x900.jpg) | ![Snow drifting over the village](screenshots/review/winter-polish/village-after-480x900.jpg) |
| Village, 390×844 | ![Village before layered snowfall on a narrower phone](screenshots/review/winter-polish/village-before-390x844.jpg) | ![Village snowfall on a narrower phone](screenshots/review/winter-polish/village-after-390x844.jpg) |

[Board with blockers and specials](screenshots/review/winter-polish/board-specials.jpg)

## Cell and goal alignment

The powder-snow goal uses the full authored sprite. On the board, the renderer
samples its opaque interior and maps it to the exact centre, radius and rotation
of the cell hex. The 128px source rectangle is `18,14,96,95` for Christmas and
`32,35,63,58` for the embedded fallback. The atlas and its source alpha stay intact.
Slate-blue wells shade from light at the top to dark at the bottom. The
spruce `signboard` in `data/match3-hud.png` is one static backplate for Moves,
goal counts and Settings. Its `board-pause-*` frames reuse the five authored
jade-and-gold Settings states from Relic Rush. The tinsel objective uses a
12% larger icon shifted 2 logical units right, and Lanternlight sits 2 units
farther left. The [ImageGen source](../../../art/match3-signboards/source.png),
[prompt](../../../art/match3-signboards/prompt.txt) and
[atlas registration](../art/match3-atlas.json) document the crop and preserved
alpha. Rebuild with `python3 tools/match3_atlas.py`.
[In-game captures](../../../docs/review/match3-signboards/README.md).

Reproduce with `build/test/christmas-market "shot main-character-board" "shot phone-board" "shot specials-board"`.

| Size | Before | After |
| --- | --- | --- |
| 480×900 | ![Original snow edge and goal alignment](screenshots/review/cell-and-goals/before-480x900.jpg) | ![Hex-aligned snow and green gradients](screenshots/review/cell-and-goals/after-480x900.jpg) |
| 390×844 | ![Original board on a narrower phone](screenshots/review/cell-and-goals/before-390x844.jpg) | ![Aligned snow and goals on a narrower phone](screenshots/review/cell-and-goals/after-390x844.jpg) |

[Board with blockers and specials](screenshots/review/cell-and-goals/specials.jpg)

## Tinsel on the cell edge

The board scales the existing `chain` atlas frame around the painted ring's
centreline, measured at 92 × 86 px and centred at (63.5, 59.5) in its 128px
canvas. That line follows the cell perimeter, with gold extending both inward
and outward. The ring draws beneath treats so its overhang leaves adjacent
pieces legible. The goal capsule and guide use the original icon framing.

Reproduce with `build/test/christmas-market "shot main-character-board" "shot phone-board" "shot specials-board"`.

| Size | Before | After |
| --- | --- | --- |
| 480×900 | ![Inset tinsel](screenshots/review/cell-and-goals/after-480x900.jpg) | ![Tinsel centred on the cell edge](screenshots/review/tinsel-edge/after-480x900.jpg) |
| 390×844 | ![Inset tinsel on a narrower phone](screenshots/review/cell-and-goals/after-390x844.jpg) | ![Edge-centred tinsel on a narrower phone](screenshots/review/tinsel-edge/after-390x844.jpg) |

[Adjacent rings among blockers and specials](screenshots/review/tinsel-edge/specials.jpg)

## Striped treats

Line specials (ROW, COLUMN, DIAGONAL) draw the treat itself through
`gfx.image_striped`: four cream bands (`A.stripes` in `lua/art.lua`) at 30°,
90° or 150°, masked to the treat's alpha, exactly as Relic Rush does. The user
asked for stripes instead of shooting stars on 2026-11-09. No new artwork.

## Market navigation

The **bottom of the town screen** now has Build (left), a large Play (center),
and Levels (right). Build and Levels have equal 88×88 slots; Play has a 144×144
slot. The shared `town` form centers the controls and routes Levels to the
existing expedition / winter-wishes level-selection action. Game boards and
other menus keep their existing controls.

The replacement artwork is deliberately simple: one hammer, one Play triangle,
and one level-list icon, each filling a plain face with a thin rim. No stalls,
roofs, foliage, ribbons, star crests or decorative surrounds. Christmas retains
only a light snow edge; Relic Rush uses jade and amber faces.

Source: `art/navigation/controls.png`, an authored transparent **5×3** atlas;
exact ImageGen prompt: `art/navigation/prompt.txt`; deterministic bounds and
runtime paths: `art/navigation/manifest.json`. Columns are normal, hover,
pressed, selected and disabled; rows are Build, Play and Levels. Pressed faces
are recessed, selected faces have a simple double rim, and disabled icons are
engraved into dull material. All states are authored separately; no runtime
recolouring or procedural icon overlays. Each manifest box is a 324×324
square centred on its atlas column's and row's visible art (the earlier
equal-fifths grid cut the art off-centre and clipped some rims); the row-wide
vertical centre keeps the pressed drop. The crop is scaled evenly into a
160×160 RGBA image under `data/navigation/`, so the visible buttons are
centred in their slots and `town.json`'s `bottom` puts Play's lower edge as
far from the screen edge as Build and Levels are from the sides.

| Role | Runtime state names (all `.png`) |
|---|---|
| `navigation_build` | `build-normal`, `build-hover`, `build-pressed`, `build-selected`, `build-disabled` |
| `navigation_play` | `play-normal`, `play-hover`, `play-pressed`, `play-selected`, `play-disabled` |
| `navigation_levels` | `levels-normal`, `levels-hover`, `levels-pressed`, `levels-selected`, `levels-disabled` |

Reproduce: `python3 games/christmas-market/tools/prepare_hud.py`;
append `--check` to verify exact exported pixels. Runtime inventory and asset
catalogue checks cover the added files. `lua/art.lua` documents all three roles;
`--hud-states` uses the live skin to draw all fifteen states.

**Pending validation:** genuine before/after town captures at 480×900 and
390×844 (safe area 0,47,0,34), plus the existing HUD state shot. Native builds
remain blocked here by missing OpenGL/X11/EGL headers and Xvfb, and Lua lint by
missing `luacheck`. Assets and Lua syntax can be checked independently; no
fabricated game screenshots are supplied. Follow-up tracked by
[#84](https://github.com/corepunch/nile-archive/issues/84). Unpublished review
only; PR publication and merging require user approval.

## Fitted specials and thin tinsel

The bomb, rainbow star, selection and hint use the
same flat-top cell alpha mask. Each authored frame is fitted from its measured
source box in `art/registration.json`. The mask preserves the hollow centres of
selection and hint, and the board draws these frames at the cell face radius.

`data/board-states/chain-board.png` compresses the original tinsel by half on
both sides of its centreline. The board keeps that line on the hex edge and
draws it beneath the treats. The original `chain` frame serves the goal icon
and guide.

Regenerate with `python3 games/christmas-market/tools/prepare_assets.py --board-fit`
and `python3 tools/match3_atlas.py`. Review with
`build/test/christmas-market "shot main-character-board" "shot phone-board" "shot specials-board" "shot guide"`.

| View | Before | After |
| --- | --- | --- |
| Board, 480×900 | ![Wide tinsel](screenshots/review/tinsel-edge/after-480x900.jpg) | ![Thin tinsel](screenshots/review/fitted-gold/after-480x900.jpg) |
| Board, 390×844 | ![Wide tinsel on a narrower phone](screenshots/review/tinsel-edge/after-390x844.jpg) | ![Thin tinsel on a narrower phone](screenshots/review/fitted-gold/after-390x844.jpg) |
| Blockers and specials | ![Inset gold frames](screenshots/review/tinsel-edge/specials.jpg) | ![Gold frames fitted to the cell](screenshots/review/fitted-gold/specials.jpg) |

[Fitted art in the Market Keeper’s Guide](screenshots/review/fitted-gold/guide.jpg)

## Lantern panes

The board uses the shared tile set (see the
[Relic Rush catalogue](../../relic-rush/docs/asset-catalogue.md#story-materials)
for all eight). Both games ship identical copies, loaded as `tile-<name>`:

| Runtime art key | Use here |
| --- | --- |
| `tile-cell-normal` | Unmarked and cleared panes (parchment) |
| `tile-tablet-single` | A pane that still needs a match or tool hit (deep blue) |
| `tile-selected`, `tile-hover`, `tile-bonus-area` | Selected cell, mouse hover and the cells an armed tool will hit |
| `tile-light-wave` | The light that sweeps across the board as it arrives |
| `tile-ice`, `tile-tablet-double` | Under an iced treat; a two-hit pane from a level's `oil_double` (none yet) |

Regenerate the eight tiles with `python3 tools/board_tiles.py`;
`tools/check_assets.py` fails if a tile is stale. The painted
[spruce atlas](../art/lantern-panes/spruce-atlas.png) and
[game-screen concept](../art/lantern-panes/concept.png) remain as references.
[In-game review](../../../docs/review/board-tiles/README.md).

`frame-stone` (`data/board-frame/stone.png`) trims exposed board edges
and the two openings in the level 4 board. Its six straight runs, six outward
joins, six inward joins and `frame-entrance` rim use the previous bands,
seeded grain and cracks. The alternate north edge incorporates painted snow
from the [registered source atlas](../../../engine/art/board-frame/decorations.json).
It replaces the exposed horizontal north edge in each hex column. Generate
this atlas with `python3 tools/board_frame.py --winter --output build/winter-frame`.

The settled board has four separate paintable sprites under `data/board-frame/`.
`fir-ribbon` and `fir-pinecone` sit at the outer shoulders at small scale.
They also decorate the walls of the open-top chamber at larger scale.
`hanging-bell` and `hanging-pinecone` project diagonally from the inner
sides of enclosed cutouts and fill most of the visible empty hex with matte
fir, muted berries and a bronze bell.
Rebuild them from the [outer source](../../../engine/art/board-frame/decorations-source.png)
and [cutout source](../../../engine/art/board-frame/cutout-source.png) with
`python3 tools/board_frame_decor.py --game christmas-market`.
[Paint guide, prompt and phone captures](../../../docs/review/board-frame-decorations/interior.md).

The shared renderer gives each face a 0.18-unit inset over a dark spruce
backing that supplies the hairline seams. The guide reuses the tablet
and one-hit chain art. The board uses existing authored selection and hint
layers, and the three tools use their five authored interaction states.
[Regular, chained and partly lit boards](screenshots/review/spruce-palette/README.md).

## Ice

`ice-2` is a continuous translucent cyan pane with high-contrast facets across
the hex face and takes two hits. `ice-1` is translucent ice with a broken
upper edge and takes one hit. Both states follow the canonical hex mask.
Both states were drawn together in the shared ImageGen atlas and are packed
into `data/match3.png`. The legacy board art review shows the full shell. The
[ice catalogue](../../../art/match3-ice/README.md) records the source, prompts,
registration and [portrait captures](screenshots/review/ice/README.md).

The snow floor (the engine's former `soil` layer) and the snow and ice rims
(`sand-edge`, `ice-1-edge`, `ice-2-edge`) are retired: Homescapes' story levels
have only carpet and oil floors, and no screen drew the rims. Their frames
left the atlas. The `art/icons.png` cell for snow keeps its place on the sheet
but is no longer registered. The earlier
[frost-edge review](screenshots/review/frost-edges/after-480x900.jpg) shows the
retired rims.

## Story cast

All six speaking characters have painted busts. One built-in ImageGen pass produced the [supporting cast sheet](../art/story-cast.png), using Noelle's existing cutout as the style reference. The exact prompt is under `story_cast` in [character-and-icon-prompts.json](../art/character-and-icon-prompts.json). These five exports replace the cards tracked in [issue #76](https://github.com/corepunch/nile-archive/issues/76).

| Character | Runtime | Story cue |
| --- | --- | --- |
| Theo Marsh | `data/characters/theo.png` | Tree seller with fir needles, plaid coat and resin-stained gloves |
| Agnes Holt | `data/characters/agnes.png` | Baker in a flour-dusted apron with her arms crossed |
| Henrik Strand | `data/characters/henrik.png` | Toymaker with white whiskers, leather apron and pencil |
| Pip Larkin | `data/characters/pip.png` | Post runner with his satchel and gap-toothed grin |
| Mr Wren | `data/characters/wren.png` | Grey-coated sweeper with his broom and tilted head |

Run `python3 games/christmas-market/tools/prepare_story_cast.py` from the root to reproduce the cutouts. The script crops and proportionally resizes the right-facing source art, then bottom-aligns each cutout on a transparent 320×480 canvas. The shared dialogue renderer mirrors the right slot so conversation partners face each other. [Dialogue bar captures](review/dialogue-bar/README.md)

The script also calls for eight optional illustrated panels (six episode panels plus levels 27 and 28). The scenes currently use the live market.

## Main character and app icon review

The user selected the supplied portrait as the main character. Built-in ImageGen used it as the identity reference for the app icon and for transparent background extraction. Exact prompts are preserved in `art/character-and-icon-prompts.json`. Reproduce the runtime exports with `python3 games/christmas-market/tools/prepare_character.py` (also called by the full asset preparation script). All eleven iOS/macOS catalogue entries were checked for the declared pixel dimensions and opaque RGB, and the 64px icon was visually inspected. Xcode project freshness checks pass.

The portrait appears only in dialogue; see the [390×844 dialogue with safe areas](screenshots/main-character-dialogue.jpg) capture.


## Reviewed state coverage

- [All six kinds, three special axes, bomb/prism, snow/tinsel, both ice strengths and all five tool states](screenshots/art-states.jpg).
- [All five pause states, completion medal and Noelle portrait](screenshots/hud-states.jpg).
- [Specials, selection/hint and exhausted tool on an actual board](screenshots/specials-board.jpg).
- All 37 buildings with footprints, four a page: [1](screenshots/building-review-1.jpg), [2](screenshots/building-review-2.jpg), [3](screenshots/building-review-3.jpg), [4](screenshots/building-review-4.jpg), [5](screenshots/building-review-5.jpg), [6](screenshots/building-review-6.jpg), [7](screenshots/building-review-7.jpg), [8](screenshots/building-review-8.jpg), [9](screenshots/building-review-9.jpg), [10](screenshots/building-review-10.jpg), and [market footprints](screenshots/footprints.jpg).
- [Valid placement](screenshots/placement.jpg), [blocked placement](screenshots/blocked-placement.jpg), [shop](screenshots/shop.jpg), [building card](screenshots/building-card.jpg), and [reward](screenshots/reward.jpg).

`art/manifest.json` records hashes for every runtime file. Update it with `python3 games/christmas-market/tools/check_assets.py --update` only alongside the corresponding catalogue/source changes. The full native build with `-Werror`, rule tests, Lua lint (59 files, zero warnings), inventory checks and real-input game smoke pass on macOS. Linux Xvfb, WebAssembly and iOS Simulator coverage run in CI.

Settings uses the shared match-3 form. The checked, unchecked, pressed and
disabled checkbox looks come from `lua/skin.lua`, and the form paints keyboard
focus with the skin's focus style. Sound and Reduce Motion use the same
checkbox control. Review the panel with
`build/test/christmas-market "shot pause" "shot phone-pause"`.

Settings also has a LEADERBOARD link (the results card has none), which opens
the engine's shared leaderboard dialog ([docs/GAMECENTER.md](../../../docs/GAMECENTER.md)) in this
game's skin: Everyone / Friends tabs (the chosen one a red button, the other a flat caption), rows of
rank, portrait, name and score, loading / empty / signed-out notes, and Game Center and Close buttons.
No artwork is added: every state is skin paint, and portraits come from Game Center at runtime.
Reviewed captures: [Settings](screenshots/pause.jpg), [the stars board](screenshots/leaderboard.jpg),
[a wish's board](screenshots/level-leaderboard.jpg), [the 390×844 phone](screenshots/phone-leaderboard.jpg)
and [the results card](screenshots/reward.jpg), from `build/test/christmas-market "shot leaderboard"` ...
with `--gamecenter-demo`.

## Engine match-3 atlas and trickling

`data/match3.png` holds the backgrounds, piece packs, power-ups, blockers,
materials, selection/hint frames and additive effects. `lua/match3_skin.lua`
gives each frame's pixel rectangle. The HUD uses `data/match3-hud.png` and
`lua/match3_hud.lua` for all five states of each tool and Pause, goal and
wallet counters, and the shop icons. `art/match3-atlas.json` records both atlases
and their source images. Board pieces and objectives also supply their own
icons to the goal display.

The shop's built and locked tiles use `data/expedition-hud/shop-built.png`
(checkmark) and `shop-locked.png` (padlock), packed into the HUD atlas as
`shop-built` and `shop-locked`. Relic Rush and Christmas Market ship the same
two files. Their source, prompt and per-game styling are not yet recorded:
[#90](https://github.com/corepunch/nile-archive/issues/90).

The engine's default resource skin is independent and embedded; both games
normally override it. `python3 tools/match3_atlas.py` reproduces the atlases and
registrations. FALL uses engine-authored simultaneous one-edge movement steps,
straight-down priority with blocked-down diagonal fallback, vertical spawning at every exposed column top and a short landing squash; static states
continue to use the existing artwork. Input and animation timing are shared.

See [checked in-game captures and commands](review/trickling/README.md) and the
[engine contract](../../../docs/MATCH3_ENGINE.md). The default atlas's source,
prompt, all supported states and crop/rotation registration are catalogued in
`engine/art/match3/manifest.json` at repository root.


### Cell registration and dialogue motion

Board state canvases now span the complete hex diameter. The authored 112px
piece interior on a 128px canvas is registered explicitly: hex silhouettes fill
the hex, other objects fit its inscribed square. Guide and HUD sizes retain their
own registration. Artwork and its alpha remain unchanged. Reproduce the reviewed
boards with the test suite's `resource-icons`, `atlas-` and `trickling-` filters.

Portraits retain finite entrance/exit slides and fades. An independent colour
tween brightens/dims active/listener states without replaying the slide. Size is
constant for speaker/listener, with no scale/rotation animation or idle wobble. See [motion, captures and timing review](../../../docs/review/motion/README.md).

## Particle sprites

Seven sprites from Kenney's CC0 [Particle Pack](https://opengameart.org/content/particle-pack-80-sprites)
texture the impact, spark and bomb effects, as in Relic Rush. The original
black-background PNGs and `License.txt` are retained in `art/particles/kenney/`;
`python3 tools/match3_atlas.py` packs the seven `fx-*` frames into
`data/match3.png`. Registration resizes the sources and uses their brightness as
alpha on white. `engine/match3_vfx.lua` draws them additively,
tinted with each piece's effect colour. They are transient effect sprites with no
interaction states. Shooting-star beams, prism links, special births and the
bomb's leading ring stay procedural.

| Sprite | Kenney source | Use |
| --- | --- | --- |
| `shock` | `circle_03` | Soft outer band of the bomb shockwave |
| `flash` | `light_01` | Bomb bloom |
| `burst` | `star_09` | Bomb centre flare, under the glint |
| `ring` | `circle_02` | Per-cell impact ring |
| `glint` | `star_07` | Four-point twinkle on impacts, the bomb centre, beam tips and births |
| `twinkle` | `star_06` | Spark particles and shard heads |
| `streak` | `trace_06` | Shard particles, aligned to their velocity |

Review: [kenney-particles](review/kenney-particles/README.md) (bomb and shooting-star frames
before and after, `--fx bomb|ray --frames N`).

## Board entrance

After any dialogue the board presents itself on the engine's shared timeline
(`engine/board_intro.lua`, see [the engine guide](../../../docs/ENGINE.md#board-entrance)):
the goal card and tools land, Noelle springs up behind the card, cells ripple
out, treats rain down their columns, ice and tinsel slam on and a sheen runs
across. It moves existing artwork with transient glows and sparks, so it adds no
new assets. A tap skips it and reduced motion makes it a short fade. Capture:
`build/test/christmas-market board-intro` (`--level 4 --present --reel`), frames
in `build/shots/frames/`.

Pressing Play in the market (and returning to it) runs the shared town <-> board
transition (`wipe` in `engine/match3_dive.lua`): a diagonal edge sweeps left to
right over 1.4 seconds, the market on one side and the board on the other. It is
procedural (a masked draw of both screens) and adds no art;
input waits for it and reduced motion skips it. Capture:
`build/test/christmas-market christmas-market-town-dive` (`--city 3 --dive --reel`),
frames in `build/shots/frames/`.

## Current-camera building paint pass

All registered buildings and decorations use the painted-v1 sources, normal sprite
and unchanged engine placement/lift/validity states documented in the
[building catalogue](building-catalogue.md) and
[review gallery](review/painted-buildings/current-camera/README.md).
The 18 slab-based sprites register their painted foundations to the 3D
ground-contact edges. See the [adjacent foundation captures](review/foundations/README.md).

## Placement alignment guides

The shared `engine/city.c` renderer draws cream outlines around occupied
ground during placement. Building sprites cover the lines behind them. The
building in hand retains its green/red footprint, and the old plot of a
building being moved is free. Confirm or Cancel hides the guides. Debug
`--footprints` draws the full outlines above the sprites. See the
[phone captures](review/placement-guides/README.md).

## Original Homescapes board atlas

Before the themed board art above, the Homescapes import replaced the earlier striped-gem and themed-piece mappings. `ray-row`, `ray-column`, `ray-diagonal`, `bomb`, `prism` and `plane` were standalone original power-ups and all piece packs aliased `kind-0` through `kind-5`. Original cookies, donut, cherry, box strengths, ice and chain variants share `data/match3.png` with retained board controls. No new art was generated and no states were recolored.

See [the shared feature/asset catalogue](../../../docs/HOMESCAPES_HEX.md) and `art/match3-atlas.json` for source PNGs, original regions, exact registration transforms, hashes, reproduction command and reviewed captures. Diagnostic blocker/generator states are tracked in [issue #98](https://github.com/corepunch/nile-archive/issues/98); these are not finished 1:1 artwork. Existing selected/hint/pressed/hover/disabled control artwork remains in the atlas.

Live field correction: removed all legacy gold/snow/sand edges, selection/hint frames and ice badges. Only original Homescapes sprites plus the temporarily retained quest resource appear on the flat hex field. Surrounding interface artwork is retained by explicit user choice. The donut collection exit remains diagnostic under issue #98.

## Recovered original blocker and generator artwork

The shared [source/state inventory](../../../docs/HOMESCAPES_ART.md) records every added state, the 9.2.601/3.5.9 source versions, exact crops/rotations/hashes, original goal icons, manually registered group composites, reproduction commands and unresolved requirements under issue #98. [Actual game review](../../../docs/review/homescapes-restored-art/README.md) includes both portrait sizes. No state recoloring or generated artwork was used. All six jelly layers, the glass dome and the colored-box goal icon use original parts. Exact maker charge poses and colored-box field artwork remain open. [Jelly, portal and maker captures](../../../docs/review/homescapes-jelly-portals/README.md).

Original atlas orientation: statues, nuts, cookie stacks, platter, maker base, blind header and queue shell use recorded 180° extraction rotations. Active source fields now fit the available phone area; both sizes and pointer registration are covered in the [review](../../../docs/review/homescapes-restored-art/README.md).

The donut exit uses the original `CarryExitForAnim` sprite. The maker base and
both glass layers use the original shared-frame offsets. See the [source
registration and portrait review](../../../docs/review/homescapes-arrow-maker/README.md).

The Windows 9.2.601 x64 atlas supplies the
classic donut maker charge layers. See the [source registration and portrait
review](../../../docs/review/homescapes-windows-art/README.md).

The maker plays queued, approximate source-video stage transitions on the field;
[durations, uncertainty and review command](../../../docs/HOMESCAPES_ART.md)
are recorded in the shared inventory. Original particle curves remain open in
[issue #98](https://github.com/corepunch/nile-archive/issues/98).
