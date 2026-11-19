# Relic Rush artwork and state catalogue

## Square board

The campaign uses matte papyrus for ordinary cells, deep blue for single-layer plaques, and olive green for double plaques. The square frame has fourteen stone layouts and four leafy variants in `data/board/cells.png`. Each draws in one empty 128 px cell and rotates to suit its neighbours. The number encodes neighbour directions clockwise from north. A rounded cap connects the two rails around a diagonally adjacent tile.

| Runtime frame | Stone and foliage within the cell |
| --- | --- |
| `square-frame-1` | North rail. |
| `square-frame-2` | Northeast rounded cap. |
| `square-frame-5` | North and east rails with a square inside corner. |
| `square-frame-5-leaf` | North and east rails with a square inside corner and leaves in the northeast corner. |
| `square-frame-9` | North rail and southeast cap. |
| `square-frame-10` | Northeast and southeast caps. |
| `square-frame-17` | North and south rails. |
| `square-frame-18` | South rail and northeast cap. |
| `square-frame-21` | North, east and south rails. |
| `square-frame-21-leaf` | North, east and south rails and leaves in the northeast corner. |
| `square-frame-34` | Northeast and southwest caps. |
| `square-frame-37` | North and east rails with a southwest cap. |
| `square-frame-37-leaf` | North and east rails with a southwest cap and leaves in the northeast corner. |
| `square-frame-41` | North rail with southeast and southwest caps. |
| `square-frame-42` | Northeast, southeast and southwest caps. |
| `square-frame-85` | Four rails around an enclosed empty cell. |
| `square-frame-85-leaf` | Four rails around an enclosed empty cell and leaves in the northeast corner. |
| `square-frame-170` | Four rounded caps. |

Built-in ImageGen painted the [floor faces](../art/papyrus-board/contact.png) and the [cracked sandstone material](../art/papyrus-board/stone-cracks.png). The [square frame generator](../../../tools/square_board_frame.py) bakes the material in Multiply mode, followed by the stone joints and the existing [painted leaves](../../../engine/art/board-frame/decorations-source.png). The [square campaign guide](square-match3.md) links the prompts, registration and reviewed captures. Rebuild with `python3 tools/match3_atlas.py`.

## Popup close button

The shared round-button renderer draws the red enamel face, brass rim and shadow at the size of the popup control. All five interaction states share the [ivory X glyph](../art/popup-close/source.png), packed as `action-close` in `data/board/pieces.png`. [Registration and prompt](../art/popup-close/README.md).

The button is pinned on the card's top right corner and overhangs it; on the full-screen build shop it sits inside the corner.

## Popup title

Every popup writes its title on the parchment in flat ink (`popup_title`), with the context line in the caption colour (`popup_subtitle`) and a thin sand rule threaded through a diamond under both (`popup_rule`). No artwork is added: the two text styles and the rule are skin paint in `lua/skin.lua`, and `match3.popup_header` lays them out. The title has one state. It replaced a jade plate with its own rim and shadow, which read as one more button above the real ones. Reviewed captures: `pause`, `phone-pause`, `building-card`, `phone-card`, `guide` and `leaderboard` in `docs/screenshots` (from `build/test/relic-rush "shot pause"` ...).

## Themed board art

The live expedition uses the [campaign piece atlas](#campaign-piece-atlas) on pale papyrus. Turquoise and olive plaques mark the cells required to win. The older Relics, Jewels and Resources sheets serve the previews and imported-board diagnostics.

| Runtime frames | Rule and artwork |
| --- | --- |
| `relics-0` through `relics-5` | Round gold sun coin, red flame, jade leaf, blue scarab, violet crystal and orange amphora. Source and preview boards use these older frames. |
| `stone-1` | One front-facing carved hex stone. An adjacent match or a direct tool hit clears it. The HUD and guide reuse the board sprite. |
| `chain`, `chain-1-mirror`, `chain-2` | A silver strand bolts to two opposite hex edges. The mirrored one-hit strand uses the opposite diagonal and gold plating. Two crossed silver strands bolt to all four sloped edges for two hits. |

Built-in ImageGen authored the [base sheet](../art/board-theme/source.png) and the [accent revision](../art/board-theme/accent-revision.png). The [base prompt](../art/board-theme/prompt.txt), [revision prompt](../art/board-theme/accent-prompt.txt) and [registration manifest](../art/match3-atlas.json) identify each source and transform. Rebuild the `data/board/` atlases with `python3 tools/match3_atlas.py`. See the [art guide](../../../docs/MATCH3_ART_GENERATION.md) and [in-game review](screenshots/review/board-palette/README.md).

The round sun coin at `relics-0` is the Relics preview idol (kind 0). The wallet uses the `resource-coin` sprite. Built-in ImageGen authored the preview idol's [transparent source](../art/board-theme/sun-coin/source.png) from the [chosen round-coin concept](../art/board-theme/sun-coin/concept.png) and [production prompt](../art/board-theme/sun-coin/prompt.txt). The atlas recipe trims the transparent margin, then scales and centres the coin inside the canonical flat-top hex while preserving its authored alpha. [In-game review at both phone sizes](screenshots/review/sun-coin/README.md).

The engine has no special pieces, so the atlas carries no rocket, bomb, plane or rainbow-ball frames. Their earlier reviews ([painted power-ups](screenshots/review/power-up-paint/README.md), [Scener models](screenshots/review/scener-power-ups/README.md)) are historical.

One ImageGen atlas contains all six [edge-mounted chain sprites](../../../art/match3-chain-paint/README.md). The board uses the hex well face to place the bolts, and the guide uses a miniature of that face. [In-game comparisons](screenshots/review/chain-anchors/README.md).


The [front-facing carved hex stones](../../../art/match3-blockers/source.png) use their own ImageGen sheet. [Stone review](screenshots/review/board-floors/README.md).

## Campaign piece atlas

One built-in ImageGen edit painted the original 23 campaign objects together. It used the
[previous pieces assembled in slot order](../art/campaign-pieces/edit-target.png)
as the edit target and the original Cradle of Rome's
`reference/cradle-of-rome/visuals/board-pieces.png` as the style reference.
The objects share an upper-left light, dark contours and compact silhouettes.
The [transparent source](../art/campaign-pieces/source.png), [exact prompt](../art/campaign-pieces/prompt.txt)
and [manifest](../art/board-states/manifest.json) record the inputs and registration.
A [fruit and score revision](../art/campaign-pieces/fruit-and-score.png) redraws the
emerald as a green apple and adds a leaf and flower. The
[revision prompt](../art/campaign-pieces/fruit-and-score.prompt.txt) and named
crop boxes in the manifest register all three into the same runtime atlas.
The [relay pliers revision](../art/campaign-pieces/relay-pliers.png) uses the
[full atlas edit prompt](../art/campaign-pieces/relay-pliers.prompt.txt).
Register its row 4, column 5 object from the named crop in the manifest.
The [Rome treasures revision](../art/campaign-pieces/rome-treasures.png) paints
nine motifs together in built-in ImageGen. The [prompt](../art/campaign-pieces/rome-treasures.prompt.txt)
uses the extracted Cradle of Rome 2 pieces for motif reference and the
existing campaign artwork for style. The three-log bundle replaces the old
single log in matches.
[Side-by-side sheet](../../../docs/cradle-of-rome-reference/gem-correspondence.html) ·
[In-game review](screenshots/review/rome-treasures/README.md)

| Atlas row | Left to right |
| --- | --- |
| 1 | Sun coin, berries, green apple, timber, quarry stones |
| 2 | Amphora, water bucket, cut blocks, ration jar, helmet |
| 3 | Grain, quartz, shrimp, emerald, lamp lens |
| 4 | Relay cable, tide chart, trail arrow, tool roll, relay pliers |
| 5 | Supply satchel, shutter gear, folded note, leaf, flower |
| 6 | Silver coin, ring, scarab, harp, sandal |

Run `python3 games/relic-rush/tools/prepare_resource_pieces.py` to crop the
measured row bands, columns and revision boxes, trim the transparent exterior and
uniformly fit each object into a centered 128 px cell with a 112 px maximum
extent (108 px for the winged sandal and 94 px for the diagonal leaf). The
runtime atlas is `art/registered/campaign-pieces.png`. The same sprite appears
in matches, refills, resource flights and the guide. The existing selection,
hint and chain overlays supply their respective states. The game's shop and
wallet use their own currency artwork. The level 8 first-clear card also uses the
pliers from this atlas.
The sprites are free-standing objects. At the board's actual draw size the
30 pieces fit the canonical face in strict object mode.
[Fruit and score review](screenshots/review/fruit-and-score/README.md).
[Relay pliers review](screenshots/review/relay-pliers/README.md).
[Board fit at 480 × 900](screenshots/review/piece-fit/board-480x900.jpg) ·
[Board fit at 390 × 844](screenshots/review/piece-fit/board-390x844.jpg).

## Resource pieces

Built-in ImageGen painted the [3 × 3 source atlas](../art/board-refresh/source.png)
with seven expedition pieces and both cell faces. The [prompt](../art/board-refresh/prompt.txt)
and [hex layout](../art/board-refresh/hex-template.png) record the generation inputs
for the earlier resource set used by the wallet and art previews.
The [manifest](../art/board-states/manifest.json) records the slot order, crop and
registration. Resources are trimmed with a four-pixel margin and centred on a
transparent square. The Rome treasures atlas also supplies the standalone
Emerald, fitted inside 114 px on a 128 px canvas, and the timber for the
reward card, fitted inside 285 px on a 320 px canvas. Standalone sprites live in
`art/registered/resource-pieces/`. Selected, hinted and falling pieces reuse the same
authored sprite with existing motion and separate indicators. Specials use
their own authored art. The original scenario sheet is still the source of
the other story pieces below, alongside the trail arrow from the outlined atlas.

The opening `coin` and `silver-coin` pay 5 and 3 Coins. The campaign introduces `water`, `timber`, `rations`, `stone`, `grain`, `shrimp`, `helmet`, `ring`, `scarab`, `sandal`, `harp` and `emerald` through the [twenty building purchases](../README.md#buildings). That table records their earnings and purchase order. The alternate packs retain `berries`, `cut-blocks` and `quartz`.

Run `python3 games/relic-rush/tools/prepare_resource_pieces.py` to reproduce.
Leaves and flowers use the same board match and scoring behavior as other
pieces. Their authored slots carry no wallet yield. The amphora asset serves
legacy art previews.
Cut blocks use `art/registered/tile-sets/resources/4.png` (Resources atlas, row 3,
column 5), registered with `python3 games/relic-rush/tools/prepare_assets.py`.
The alternate packs still supply separate grain and quartz sprites at their
authored orientation and alpha. Selected, hinted and falling pieces use the normal chip
with the existing board feedback. Review `shot hex-first`, `shot hex-late`,
`shot landing-briefing`, and `shot phone-story-level-30` in the Relic Rush suite.
See the [current board and wallet review](review/blue-plaque-campaign/README.md).
The [harbor campaign review](screenshots/review/harbor-campaign/README.md)
shows the original openings and the cut blocks on level 8. The relay pliers
review above shows the current level 8 board.

`--rome-reference-art` uses the aliases in the manifest to load local
Cradle of Rome 2 crops for resource pieces and the matching coin and guide icons.
Selected, hinted and falling pieces use the same authored crop with the existing
Relic Rush overlays and motion. The source is the Windows atlas `gmf_balls_2.png`.
The [Cradle of Rome 2 extraction](../../../docs/cradle-of-rome-reference/README.md#cradle-of-rome-2-artwork)
reproduces the transparent crops. `--level 5 --size 390x844` shows the water
bucket in its live slot alongside the original story marker.


## The signal finale

| Asset | Rule meaning and states | Source and runtime |
| --- | --- | --- |
| `signal-plate` | On board 30’s first clear, the recovered signal plate appears at the cleared site before the scene cuts to the landing. | ImageGen [source](../art/finale/signal-plate.png) and [prompt](../art/finale/signal-plate.prompt.txt). Cropped and uniformly fitted into a 128 px sprite with its painted alpha. Runtime `data/story/finale/signal-plate.png`. |
| `safe-landing` | After the plate arrives, the first win cuts to Ines holding a lantern on the safe landing. She answers with the three flashes first seen on board 3. Reduced motion shows a steady light. | ImageGen [source](../art/finale/safe-landing.png) and [prompt](../art/finale/safe-landing.prompt.txt). Uncropped 864×1152 JPEG at `data/story/finale/safe-landing.jpg`. The manifest records the lantern coordinates for the glow. |

Run `python3 games/relic-rush/tools/prepare_finale_art.py` to register both assets.
The amber pulses reuse the board’s additive glow, with a shared delay and rhythm.
See the [finale and sand review](screenshots/review/signal-finale/README.md).
The old [board 8 painting](../art/story-pictures/broken-relay.png) is archived with its
[historical review](review/story-mosaic/README.md).

## Ancient keeper portrait

The Sawmill supplies timber for Tomas’s cable reel. When the Village takes up the night watch, the crew reads the keeper’s words from the watch book. The
static portrait has transparent edges and uses the standard story speaker slot.
The [ImageGen original](../art/art-direction/ancient-keeper.png) and [prompt](../art/art-direction/ancient-keeper-prompt.txt)
are retained. Run `python3 games/relic-rush/tools/prepare_assets.py --keeper-only`
to register `data/story/characters/keeper.png`. See the native review at
[480 × 900](review/chapter-one/keeper-480.jpg) and [390 × 844](review/chapter-one/keeper-390.jpg).

## Build progress

Above the existing lower-left `action-build` house, the town reuses the skin's inset resource indicators for Coins, Supplies and Food still needed for the next campaign purchase. Each compact tile uses the corresponding painted wallet icon above the missing quantity. A fully funded purchase still waiting for a clear shows its expedition requirement. Once the purchase opens, the readout clears and the existing blue `fx-tablet-glow` and `fx-tablet-spark` trail circles the enamel rim. Reduce Motion hides the trail. The same house opens the card in each state. [Review and capture commands](square-match3.md#build-progress-captures).

## Archived crew request pieces

The following records describe the former hex campaign's optional requests and their review captures. The active square campaign uses the Build house for construction progress. Its board pieces credit score, resources or bonus charges.

The crew's request pieces reuse five paintings from the campaign atlas. A request's piece stands in a free score slot while the request is open, and quartz fills the sixth slot when nothing is asked. [Rules](match4-rules.md#crew-requests) · [Story](story.md#crew-requests) · [Review captures](screenshots/review/crew-requests/README.md)

| Request | Frame | Expeditions written for | Pieces on the same board |
| --- | --- | --- | --- |
| Piece the harbor chart together | `campaign-chart` | 2–4 | Coins, leaf, water, berries |
| Fill the supper pot | `campaign-berries` | 2–4 | Coins, leaf, water, chart |
| Uncover the painted arrows | `campaign-marker` | 5–7 | Coins, bonus gem, water, tool roll |
| Dig out the keeper's tools | `campaign-tools` | 5–7 | Coins, bonus gem, water, arrow |
| Haul up the relay cable | `campaign-cable` | 8–10 | Coins, bonus gem, water, timber |
| No request (sixth slot) | `campaign-quartz` | every board | Score only |

The green arrow is scheduled from expedition 5, after the Hammer has taken the leaf's slot, so two green pieces never share a board. On the board a request piece has the same states as any piece: normal, selected, hint and refill, through the standard overlays.

On the island each open request is a round marker showing its giver's existing portrait in the brass medallion (`buttons.medallion`). The medallion has the same procedural rim and ivory face as the [shared enamel buttons](../../../art/match3-buttons/README.md), and a 16-sided `gfx.image_poly` cut, its corners hidden under the brass lip, rounds the portrait (no SDF mask, so the dive wipe's mask still clips the markers). A procedural progress gauge crosses the bottom of the marker, over the rim: a dark-cased rounded bar whose brown track fills with a jade gradient from the left by the banked share, leaving the brass rim and the portrait whole. There is no count readout. The next building's marker has the same gauge on its enamel button, filled by the share of its price held, and the same ready trail once it can be built. States: normal; hover (the brighter ivory face); pressed (sinks like the buttons); ready (no gauge; the glow shows and a blue particle trail circles the rim, using the board’s fx-tablet-glow and fx-tablet-spark frames; reduced motion keeps the steady glow); and waiting for a board slot (a pewter rim with the portrait at 55% opacity, a procedural state recorded here). The first marker is the next building's sprite on the enamel button and opens its card; the shutter field test keeps its object on the enamel button. Review capture: `--city 2 --quest-have 12`, `--city 2 --quest-have 99` and `--city 3 --quest-have 5` at 480×900. The request card shows the existing Elena, Mara or Tomas portrait inside a round brass medallion. The medallion uses the same procedural rim and ivory face as the enamel buttons (`buttons.medallion` in `engine/lua/match3/buttons.lua`). The same polygon cut rounds the portrait, with its top aligned to the top of the face. No new artwork is added. Below it, STILL NEEDED shows the painted campaign piece with the count still to gather, and YOU GET shows the Coins reward. A wider gap, with no rule, separates the two groups, as on the building card. A ready card keeps the piece under ALL GATHERED with the painted green tick (the existing `shop-built` frame in `data/board/pieces.png`, registered as the skin's `tick` image and drawn by `Skin:paint_tick`, the same tick a met goal capsule shows) in place of the figure, through the skin's `done_tick` panel role. The building card's STILL NEEDED group uses the same tick for a currency the wallet already covers. Review capture: `--city 2 --quest-have 99 --quest-card chart` and `--city 2 --card 2` at 480×900. The shutter field test has no amounts and shows its closed-shutter object. Review capture: `--city 1 --quest-offer supper --frames 120` at 480×900 and 390×844.

Reproduce: `./build/relic-rush --headless --mute --fresh --size 480x900 --city 2 --quest-have 12 --shot out.png`; add `--quest-card chart` for the card and use `--quest-have 99` for the ready state. `--level 3`, `--level 6` and `--level 9` show the pieces on their boards.

The board shows no request counters; progress appears on the island marker
and the results card.

### Crew request hand-in paintings

| Painting | Rule and state | ImageGen source and review |
| --- | --- | --- |
| `data/story/scenes/harbor-chart.jpg` | Static hand-in painting showing the pieced chart, reef and warning light before the chart dialogue. | [Master](../art/story-pictures/harbor-chart.png) · [Prompt](../art/story-pictures/harbor-chart.prompt.txt) · [480×900](screenshots/review/crew-requests/chart-handoff.jpg) |
| `data/story/scenes/broken-cable.jpg` | Static hand-in painting showing the two parted ends and Tomas's rusted pliers before the cable dialogue. | [Master](../art/story-pictures/broken-cable.png) · [Prompt](../art/story-pictures/broken-cable.prompt.txt) · [390×844](screenshots/review/crew-requests/cable-handoff-phone.jpg) |
| `data/story/scenes/reef-warning.jpg` | From Mara’s skiff, the red lamp lines up with the reef. The reveal accompanies the raised shutter. | [Master](../art/story-pictures/reef-warning.png) · [Prompt](../art/story-pictures/reef-warning.prompt.txt) · [390×844](screenshots/review/crew-requests/quest-reef-phone.jpg) |
| `data/story/scenes/shutter-closed.png` and `data/story/scenes/shutter-open.png` | The closed plate and pull ring appear on the marker and beside Tomas. The open plate exposes the red glass beside the observation. Both states were painted in one transparent strip. The marker uses the shared enamel button states. | [Master strip](../art/story-pictures/hand-shutter.png) · [Prompt](../art/story-pictures/hand-shutter.prompt.txt) · [480×900](screenshots/review/crew-requests/quest-offer-shutter.jpg) |

Run `python3 games/relic-rush/tools/prepare_finale_art.py` to reproduce the square 768 px paintings and the two centered 300 px shutter crops. The source regions and destinations are recorded in the [manifest](../art/board-states/manifest.json). Capture with `build/test/relic-rush "shot quest-handoff-" "shot quest-offer" "shot quest-reef"`.

## Archived story pieces

The active square campaign reveals the note in the first-clear scene on board 13. The old hex campaign placed a folded note on that board. The assignments below record where the art debuted, and selection, hints and refills used the standard board overlays.

| Slot | Boards | Story sprite |
| --- | --- | --- |
| Gold | 4, 13 | Tide chart, folded note |
| Red | 7 | Rolled leather tool wrap |
| Green | 5, 6, 8, 10 | Painted brass trail arrow, relay pliers, bronze shutter gear |
| Blue | 2, 9 | Lamp lens, supply pack |
| Purple | 3 | Coiled relay cable |

The campaign atlas includes all nine
story sprites. Alternate packs share its `pliers` frame. The other alternate
sprites come from the [expedition atlas](../art/resource-pieces/scenario-atlas.png)
and the [outlined source sheet](../art/resource-pieces/outlined-atlas.png).
The manifest records the crops, boards and colour slots. Run
`python3 games/relic-rush/tools/prepare_story_pieces.py` to register the individual
`art/registered/story-pieces/*.png` files. Each crop fits inside 108 px on a
centred 128 × 128 canvas. [Board captures](screenshots/review/expedition-economy/README.md)

## Additional board elements

These sprites support the reference-board previews. The campaign uses chains
and blue plaques.

The 48-cell [surface master](../../../engine/art/match3-elements/source.png) and
[exact prompt](../../../engine/art/match3-elements/prompt.txt) contain both games'
24-state families in one ImageGen call. The full-bleed tile faces are cropped,
resized and registered with the [canonical engine hex mask](../../../engine/art/hex-tile/README.md).
The
[registration manifest](../../../engine/art/match3-elements/manifest.json) records
all sources, crops and runtime paths. From the repository root, reproduce the
states with `python3 tools/match3_elements_art.py`, then pack the runtime atlas
with `python3 tools/match3_atlas.py`. No colour or damage state is generated by
tinting; each was authored. The registration check verifies all 46 full-cell
states against the canonical mask.

| Role | Runtime atlas keys | Rule and visual states |
| --- | --- | --- |
| Carved stone | `stone-1` | Solid; one adjacent match or a direct tool hit breaks it. |

The master's crate, tunnel, hidden-object, growth and delivery cells belong to
mechanics the engine no longer has. They stay
in the master image but are not registered, and their frames left the atlas.

Board rendering, guide icons and goal icons use the same named atlas artwork;
the neutral skin preview falls back to this game's authored element sprites.
Review the carved stone on the actual board with
`--element-states --headless --fresh --mute --size 480x900`, and at 390×844.
The reviewed captures are [full size](../../../docs/review/match3-elements/relic-rush-states.png)
and [narrow](../../../docs/review/match3-elements/relic-rush-state-narrow.png).


This is the review inventory for the current game, audited 31 October 2026.
The original gap and acceptance criteria are tracked in [issue #11](https://github.com/corepunch/nile-archive/issues/11).
There are **18 base pieces, 5 special modifiers, 27 authored board/control sprites,
7 expedition-header icons and one investigating Elena cutout**.
The complete filename inventory, crop rectangles, rule names and state matrix live in
[`manifest.json`](../art/board-states/manifest.json). Paths below are relative to this game.

![All packs and authored states rendered by the game](screenshots/art-catalogue.jpg)

## Earlier cell and goal alignment

The teal wells use the engine's flat-top hex geometry and a light-to-dark
vertical gradient. The atlas cell mask remains the registration reference for
authored art. Goal icons and counts share the jade signboard. Collection
flights land at the icon centres. The chain objective uses a 12% larger icon
shifted 2 logical units right. The carved-stone objective uses a 10% smaller
icon. [Current board review](../../../docs/review/match3-signboards/README.md).

Reproduce with `build/test/relic-rush "shot hex-first" "shot phone-board" "shot art-specials"`.

| Size | Before | After |
| --- | --- | --- |
| 480×900 | ![Original board and goals](screenshots/review/cell-and-goals/before-480x900.jpg) | ![Gradient wells and aligned goals](screenshots/review/cell-and-goals/after-480x900.jpg) |
| 390×844 | ![Original board on a narrower phone](screenshots/review/cell-and-goals/before-390x844.jpg) | ![Gradient wells on a narrower phone](screenshots/review/cell-and-goals/after-390x844.jpg) |

[Board with blockers and specials](screenshots/review/cell-and-goals/specials.jpg)

## Buildings and decorations

The [building catalogue](building-catalogue.md) covers **97** registered sprites,
including the twenty campaign purchases and the retired Quay Steps sprite. Its reserved ID identifies the staircase when loading an older town. It records the full
source/prompt history, runtime paths, whole-tile measurements, supported states,
import commands and reviewed in-game captures. The board manifest links the
building manifest and inventories every new runtime file.

The fifth restoration is now the **Sunstone courtyard**, a dry mosaic gathering
plaza replacing the bridge-shaped gateway. Its 3 x 2 footprint is measured from
the new artwork. The complete three-option ImageGen atlas, selection, source,
prompt and reviewed game captures are recorded in the
[replacement review](review/sunstone-courtyard/README.md).

## Reward and replay presentation

The [economy review](review/economy/README.md) records the first-clear and replay
flows, expedition list and build shop. Board matches contribute to score and
objectives. The results card and wallet use the three resource icons. First clears award
the progress count used by the shop and regions. Replays bank matched resources.

| Sprite | Presentation |
| --- | --- |
| `discovery-star` | Faceted gold star in a turquoise setting. The celebration scales and fades the same artwork, and the Discovery Stars reward row and island wallet use it at smaller sizes. |
| `next-clue` | Sealed papyrus retained in the atlas from the earlier first-clear presentation. Results show the pending restoration or the Build hammer. |

Both static icons were authored together with built-in ImageGen in a
[transparent atlas](../art/result-icons/source.png), using the Christmas Market
results stars as the visual reference. The [generation prompt](../art/result-icons/prompt.txt)
and [crop bounds and slot order](../art/board-states/manifest.json) record the
source. Run `python3 games/relic-rush/tools/prepare_result_icons.py` to crop
both sprites, fit them to 120 px preserving aspect ratio and alpha, and center
them in two 128 px cells in `art/registered/result-icons.png`. Add `--check` to verify
the exported pixels. The wallet capsule retains its skin-painted feedback.
See the [results and wallet captures](screenshots/review/discovery-stars/README.md)
for both phone sizes and reproduction commands.

## Pause menu actions

`lua/screens.lua` lays Pause out in groups, with the look in `lua/skin.lua`: a
settings well holding the Sound and Reduce motion checkboxes, then Resume, then
Restart and Quit to Island as secondary wooden buttons, and the guide as a link.
Restart asks for confirmation and resets the current puzzle; Quit to Island
suspends it without paying rewards. Island Pause hides Restart and Quit. (The
motion toggle was removed once and returned as the Reduce motion checkbox.)
Both menus measure their content before centring, including the taller
safe-area phone layout. States are listed below with the checkbox and button
variants; no artwork, source prompt, runtime file or sprite transform is added.
The menu contract is recorded in `art/board-states/manifest.json` under `pause_menu`.

Pause carries a skin-painted LEADERBOARD link above the guide link. It opens the overall rankings
in the engine's shared leaderboard dialog ([docs/GAMECENTER.md](../../../docs/GAMECENTER.md)),
a panel with Everyone / Friends tabs (the chosen one a jade button, the other a flat caption), a
scrolling list of rank, portrait, name and score rows (a round placeholder bust with the initial
while a portrait loads, "(you)" on the player's row), loading / empty / signed-out notes, and
Game Center and Close buttons. No artwork is added: every state is skin paint, and the portraits
come from Game Center at runtime. Reviewed captures: `pause`, `phone-pause`,
`leaderboard` and `phone-leaderboard` in `docs/screenshots` (from
`build/test/relic-rush "shot leaderboard"` ..., with `--gamecenter-demo`).

Reproduce and inspect both contexts at both phone sizes with
`python3 tests/fixtures/pause-actions/capture.py`; reviewed captures and exact
commands are in the [pause menu review](review/pause-actions/README.md).
The game's `--smoke` run exercises Restart, Quit to Island, hidden island actions,
resuming through Play, and unchanged banked rewards.

## Piece kinds and optional packs

All packs use the same kind IDs and rules. Colours and silhouettes are authored;
the game does not recolour one gem into other kinds.

| ID / rule name | Relics (default) | Jewels | Resources | Rule meaning |
| --- | --- | --- | --- | --- |
| 0 / IDOL | Round gold sun coin | Yellow hex gem | Coins | Idol objective and score; reused Amulet icon |
| 1 / FLAME | Coral flame | Red heart | Terracotta amphora | Ordinary matching kind |
| 2 / LEAF | Jade leaf | Green square gem | Timber | Ordinary matching kind; reused Wood purse icon |
| 3 / SCARAB | Turquoise scarab | Blue teardrop | Water | Ordinary matching kind |
| 4 / CRYSTAL | Purple crystal cluster | Purple diamond | Stone | Ordinary matching kind; reused Stone purse icon |
| 5 / AMPHORA | Amber amphora | Orange star | Wheat | Ordinary matching kind; the campaign shows quartz or a crew request's piece here |

Source: `art/tile-sets/source.png`, six columns × three packs. Runtime:
`art/registered/tile-sets/{relics,jewels,resources}/{0..5}.png`. Import:
`python3 games/relic-rush/tools/prepare_assets.py` from the repository root.
Largest-component isolation removes neighbouring sprite fragments before centring
and resizing; it does not create new colours or states.

## Special pieces

Live expeditions make no special pieces: matches of any length or shape only
clear, and power comes from the charged bonus tools (Cradle of Rome rules).
The engine has no rockets, bombs, planes or rainbow balls.

Source for every new sprite below: `art/board-states/source.png`, generated together
in one built-in ImageGen call. The exact prompt is
[`board-states.prompt.txt`](../art/board-states.prompt.txt). The manifest records the
actual generated dimensions and explicit crop boxes; the importer does not assume
the generator produced a mathematically uniform grid.

Runtime pattern: `art/registered/board-states/<name>.png`, RGBA 128 × 128.
Terrain and ice use the slot's **flat-top** mask. Special gems are
free-standing artwork.
The replacement set is authored together in
`art/board-states/clear-indicators.png` (ImageGen, 2026-11-01), with its prompt
in `clear-indicators-prompt.txt`. The manifest records measured crop boxes,
spatial axis registration and runtime paths. The importer preserves authored
RGBA and clips filled ice to the actual tile; it does not synthesize states.
Selection and hints use soft filled glows, with no hard border.
`lua/art.lua` names these textures; `lua/board.lua` uses the same artwork for
live pieces, collection flights, clearing animations and the guide.

| Rule state | Authored name | Creation / behaviour |
| --- | --- | --- |
| NORMAL (0) | Base kind image | Three equal kinds in a straight line clear normally |
| ROW (1) | `ray-row` | Line of four; full-gem stripes along the 30° board axis |
| COLUMN (2) | `ray-column` | Line of four; full-gem vertical stripes |
| DIAGONAL (3) | `ray-diagonal` | Line of four; full-gem stripes along the 150° axis |
| BOMB (4) | `bomb` | Existing/review bomb or special combination; radius-one hex blast (cell plus six neighbours) |
| PRISM (5) | `prism` | Five or more in a straight line; clears the swapped kind |

Rays use `gfx.image_striped` on the matching gem at full size. Broad cream bands
follow the 30°, 90° or 150° clear axis, masked to the gem's authored alpha and
modulated by its surface shading. Bomb and prism sprites replace the gem at full
piece size. The old `ray-row`, `ray-column`, `ray-diagonal` images remain canonical
skin compatibility regions and no longer appear as tiny board/guide badges.

The user explicitly requested engine-drawn masked stripes on 2026-11-01; this
supersedes the usual authored-state requirement for this pattern. No generated
stripe atlas is used, and existing textures/alpha remain unchanged. Relics,
Jewels, Resources and the guide share the same renderer. The
[striped-special review](../../../docs/review/striped-specials/README.md) covers
all six kinds, all axes, the full bomb, both phone sizes and blockers.
See [match rules](match4-rules.md) for special-combination resolution.

## Terrain, blockers and board interaction

| Authored name | State and meaning |
| --- | --- |
| `chain` | A silver chain holds the chip between two bolted hex edges. One hit unlocks the piece. |
| `ice-2` | Diagnostic ice pane with two hits remaining. |
| `ice-1` | Diagnostic ice pane with one hit remaining. |
| `selected` | Soft filled mint glow under the tapped piece; no outline |
| `hint` | Soft filled gold glow and sparkles under both idle-hint pieces; no outline |
| `guide` | Jade book medallion for the explorer guide; not drawn on the board since the [match-3 HUD](review/match3-hud/README.md) (the guide opens from Pause), kept for the art catalogue screen |

The campaign uses the same silver chain art on each board. One hit breaks
the chain and keeps the piece in place. A later hit clears the piece and its
blue plaque. Ice textures are recorded here for shared engine diagnostics.

### Story materials

| Frame | Meaning and use |
| --- | --- |
| `tile-cell-normal` | Slot 1, parchment lit from the upper left: ordinary and cleared cells. |
| `tile-tablet-single` | Slot 2, deep blue: plaques required for a win. The Explorer’s Guide uses the same face. |
| `tile-tablet-double` | Slot 3, green: a plaque listed in a level's `oil_double`, before its first hit. Boards author their double tablets as `P` in the level files ([LEVEL_DESIGN.md](../../../docs/LEVEL_DESIGN.md)). [Level 15 before/after](screenshots/review/level-tuning/after15.jpg). |
| `tile-light-wave` | Slot 4, a diagonal streak of pale gold: the light that sweeps across the board as it arrives. |
| `tile-hover` | Slot 5, white: the cell under a mouse pointer (not on touch). |
| `tile-selected` | Slot 6, orange corner brackets on a clear tile: the selected cell. |
| `tile-ice` | Slot 7, frosted teal with a white burst and hairline cracks: the floor under an iced piece, which keeps its `ice-1`/`ice-2` overlay. |
| `tile-bonus-area` | Slot 8, blue-gray with a soft glow: every cell an armed tool will hit, at the hovered or pressed cell. |

The eight tiles follow the slots of Cradle of Rome's board sheet and are
shared by Relic Rush and Christmas Market. `tools/board_tiles.py` bakes them
from [`engine/art/board-tiles/tiles.json`](../../../engine/art/board-tiles/tiles.json)
into each game's `art/registered/board-tiles/`. Colours and lighting are sampled from the
first Cradle of Rome's tile sheet: faces lit from the upper left, a thin edge
light on the parchment, wide cut bevels on the blue and green tablets (lit on
the upper-left edges, dark on the lower-right) so they read as thick stones,
and a bevel on the ice. The spec's options
add a warm mottle (`grain`, `grain_tint`), a glow, hairline cracks, a diagonal
light `streak`, and `brackets` for the open selected frame. The canonical
128 px flat-top mask cuts the alpha, and every filled tile passes
`tools/hex_tile_art.py --mode fill --strict`.
Regenerate with `python3 tools/board_tiles.py`; `tools/check_art_catalogue.py`
fails if a tile is stale. The `--art-states dressing` screen shows all eight, and
`--level 6 --cell-states` shows them in use on a board.

`frame-stone` (`data/board/frame/stone.png`) trims the active board silhouette
with six straight runs, six outward joins and six inward joins. Its
`frame-entrance` region follows the incoming cells. The starter bakes the
previous frame's bands, seeded grain and cracks with
`python3 tools/board_frame.py --output build/board-frame`.
The stone atlas also contains outer joins with three-leaf jungle sprigs and
an inner join with a bright front-facing leaf cluster. The broad leaves fan
diagonally out from a hub seated on top of the stone. The generator bakes the
[painted leaves](../../../engine/art/board-frame/rim-rosette-source.png)
and contact shadows into their joins and
exports `lua/board_frame_atlas.lua` with the registration.
Run `python3 tools/board_frame.py --game relic-rush --output build/board-frame/relic-rush`.
[Board close-ups, prompt and level 6 at both phone sizes](../../../docs/review/board-frame-decorations/front.md).

The painted [limestone and cobalt atlas](../art/board-refresh/flat-ground.png)
these replaced remains as a style reference. [In-game review](../../../docs/review/board-tiles/README.md).

The earlier [cover and terrain sources](../art/board-dressing/) and
[historical review](screenshots/review/board-dressing/README.md) document the
archived salt, rubble, vine, rope, cable and excavation artwork.

Hint opacity pulses; reduced motion uses a steady frame. There are no hover/pressed
states for individual pieces: a touch selects a piece or initiates a swap.
Automatic dead-board recovery shows the notice “No moves. Board reshuffled.”
Recovery and the Mixer fly the existing board pieces along staggered curves
(`engine/lua/match3.lua`), using their atlas frames and existing shadows.
Fixed pieces and floor artwork stay put. Reduce Motion settles the permutation
immediately. Review with `build/test/all --suite=relic-rush shuffle` at 480×900
for recovery and 390×844 for the Mixer. Frames go to `build/shots/frames/`.

## Campaign bonus pieces and sockets

The eight standalone pieces each have their own silhouette. Board pieces, rewards and toolbar buttons use the same 128 px frames in `data/board/pieces.png`. The four painted navigation icons also live in this atlas. The [board progression](board-progression.md#bonus-pieces) lists each construction reward and effect. All eight items are drawn together in the [painted source](../art/bonus-gems/rome-eight.png). The [manifest](../art/board-states/manifest.json) records source positions and registration. Run `python3 games/relic-rush/tools/prepare_bonus_gems.py` and `python3 tools/match3_atlas.py` to reproduce the frames.

The shared enamel painter draws the five states and exposes the ready face from
the bottom as each matched gem lands. The inset and the colored piece share an
anchor on the button face. Hammer uses the center of its silhouette bounds and
a 100 px fit. Lightning uses a 94 px fit for more clearance around the bolt.
The other bonus anchors use the center of opacity. The house, Play triangle,
expedition map and settings gear use the painted materials of the resource
pieces in the [shared action atlas](../../../art/match3-buttons/README.md).
[Hammer and Lightning across five states](screenshots/review/piece-fit/bonus-states.jpg).
[Toolbar at both sizes](screenshots/enamel-toolbar.jpg) · [All bonus states](screenshots/bonus-states.jpg).

Earlier gameplay captures follow.

[Locked sockets on expedition 1](screenshots/bonus-locked-phone.jpg) ·
[Spent Bomb](screenshots/bonus-spent.jpg) ·
[Workshop card](screenshots/bonus-workshop-card.jpg) ·
[Construction on the town card](review/chapter-one/ready-to-build.jpg) ·
[Hammer debut](screenshots/bonus-hammer-debut.jpg) ·
[Hammer debut on phone](screenshots/bonus-hammer-debut-phone.jpg) ·
[Mixer debut](screenshots/bonus-mixer-debut.jpg) ·
[Shutter Gear board](screenshots/bonus-gear.jpg).
Reproduce the views and the real tap-to-spend check with
`build/test/relic-rush 'shot bonus-' 'reel bonus-gem-flight' 'shot workshop-card-phone'`.

## Earlier tool art and reference boards

**Retired.** Every board now carries the bonus toolbar (`bonus-*` in
`data/board/pieces.png`), so these square buttons are no longer registered,
packed or shipped. The authored sheet and this record stay as provenance; to
restore them, register the fifteen cells again from `retired_tool_buttons` in
`art/board-states/manifest.json`.

Reference boards used the Pickaxe, Dynamite and Sunburst controls.
Pickaxe hits one cell, Dynamite hits its cell and six neighbours, and Sunburst
hits every piece of the tapped kind.

All fifteen buttons are separately painted in the same atlas, including their
backgrounds. The renderer never desaturates, tints or synthesizes a disabled state.
Their updated source is `art/tool-buttons/source.png`, generated together in one
built-in ImageGen call; the exact prompt is [`tool-buttons/prompt.txt`](../art/tool-buttons/prompt.txt).
The original 27-sprite atlas remains the source for hex layers and the guide.
Tool crop boxes and the separate atlas's dimensions are recorded in the manifest.
The importer spatially registers each measured button body (plus eight source
pixels of padding) into a 120×120 area on the existing 128×128 runtime canvas,
preserving authored alpha and all five painted states. This corrects the source's
roughly 4% width excess; no visual state is generated by processing.
Their registered paths were `art/registered/board-states/{pickaxe,dynamite,sunburst}-{state}.png`.
`lua/art.lua` specifies 76×76 touch targets, and `lua/board.lua` draws each texture
into a square with equal padding. The row begins at y=784 plus tall-phone offset;
labels sit below the buttons and counters stay at their upper-right corners.
Reproduce with `python3 games/relic-rush/tools/board_assets.py`; validate with
`--check`. [Actual-game captures and native-input checks](review/square-tools/README.md)
cover every tool/state plus normal and exhausted rows at both phone sizes.

| Tool | Normal | Selected | Pressed | Mouse hover | Disabled |
| --- | --- | --- | --- | --- | --- |
| Pickaxe | `pickaxe-normal` | `pickaxe-selected` | `pickaxe-pressed` | `pickaxe-hover` | `pickaxe-disabled` |
| Dynamite | `dynamite-normal` | `dynamite-selected` | `dynamite-pressed` | `dynamite-hover` | `dynamite-disabled` |
| Sunburst | `sunburst-normal` | `sunburst-selected` | `sunburst-pressed` | `sunburst-hover` | `sunburst-disabled` |

Priority: depleted or board busy → disabled; held pointer that began inside →
pressed; selected tool → selected; real mouse inside → hover; otherwise normal.
Touch never receives hover art. Charge counts are dynamic text on a counter.
The tools stand along the bottom edge on the painting, three evenly spaced
buttons without captions; choosing one names it and its effect in the toast.

## Expedition header

The campaign board centers its display-only row of Moves, Coins, Supplies
and Food. Pause sits at the right end of the booster row. The Moves medallion
shows its low-move state when needed.
Resource counts include pending earnings, and matched pieces land on their
currency icons. [Current board](screenshots/bonus-toolbar-phone.jpg)

The earlier jade `signboard` is a static backplate packed in `data/board/hud.png`.
Moves, goal counts and Settings share its face. A green check replaces a
completed count. Collected idol icons bounce on landing, and the Moves
medallion turns red over the last five moves. Settings retains the existing
authored states. The [ImageGen source](../../../art/match3-signboards/source.png),
[prompt](../../../art/match3-signboards/prompt.txt) and
[atlas registration](../art/match3-atlas.json) document the crop and preserved
alpha. Rebuild with `python3 tools/match3_atlas.py`.
[In-game captures](../../../docs/review/match3-signboards/README.md).

`art/expedition-hud/controls.png` contains **all seven new icons together in one
built-in ImageGen call**. The exact prompt is
[`controls-prompt.txt`](../art/expedition-hud/controls-prompt.txt). `pause-normal`,
`pause-selected`, `pause-pressed`, `pause-hover`, `pause-disabled` are individually
painted jade/gold medallions. `score` denotes the remaining score objective;
`complete` denotes any fulfilled objective. The runtime button uses normal,
pressed and real-mouse hover states; selected/disabled artwork is supplied for
the complete control contract. No tint or procedural bars create states.

The shared board/city Pause medallion uses a 64×64 logical-unit canvas and touch
area, enlarged from 44×44. The existing authored states scale directly. Board
goals reserve 64 units beside the button; city currency pills use 76-unit spacing
and 72-unit widths to stay clear of it. The smoke run opens board Pause at the
new left edge and city Pause at the new lower edge, outside the old touch area.
[Reviewed headers at both phone sizes](review/larger-pause/README.md).
Runtime: `art/registered/expedition-hud/<name>.png`, 128×128 RGBA.

`art/expedition-hud/elena-investigating.png` is a separate ImageGen identity edit
of the existing Elena portrait: she examines a sun fragment through a magnifying
glass. [Exact portrait prompt](../art/expedition-hud/elena-prompt.txt). It was
shown between the old goal and moves cards; the match-3 HUD retires it, so it has
no runtime export and the manifest lists it as `retired_portrait`. Dialogue
continues using the original Elena portrait.

Measured crops, source dimensions, prompts and runtime paths are recorded in
[`expedition-hud/manifest.json`](../art/expedition-hud/manifest.json), referenced
by the primary runtime manifest. Import is aspect-preserving spatial registration
with authored alpha retained, never derived state artwork:
`python3 games/relic-rush/tools/prepare_hud.py` (`--check` verifies exact exports).
`lua/art.lua` loads the contract; the measured engine list remains available for diagnostic boards.
[Reviewed game captures and native input checks](review/expedition-header/README.md)
cover both backgrounds, both phone sizes, completed goals, every pause state,
and dismissible/required popup behavior.

[Match-3 HUD before/after captures](review/match3-hud/README.md) cover both
paintings, both phone sizes, completed goals, the last moves, a tapped tool,
pause, guide and the island.

![The match-3 HUD on a late level](review/match3-hud/after-late-480x900.jpg)

## Animation and effect states

| State | Presentation / assets |
| --- | --- |
| PRESENT | The board's entrance after any dialogue: existing HUD, tool, cell, piece and blocker artwork move on the shared timeline in `engine/lua/board_intro.lua`, with transient glows, sparks and a sheen. No new art. Tap skips it. Capture: `build/test/relic-rush board-intro` (`--level 5 --present --reel`), frames in `build/shots/frames/` |
| DIVE | Town <-> board transition (`wipe` in `engine/lua/match3/dive.lua`): a diagonal edge sweeps left to right over 1.4 seconds, the town on one side and the board on the other; procedural (a masked draw of both screens), no art. Input waits for it; reduced motion skips it. Capture: `build/test/relic-rush relic-rush-town-dive` (`--city 3 --dive --reel`), frames in `build/shots/frames/` |
| Idle | Base or special frame, optional selection/hint/blocker layers |
| SWAP | Existing piece artwork moves to neighbour |
| REJECT | Existing artwork moves and returns with zero moves spent. Against a chain, ice or a carved stone only the incoming gem moves (`engine/lua/match3.lua`). Capture with `build/test/all --suite=relic-rush 'reel chain-reject' 'reel ice-reject' 'reel stone-reject'`. |
| CLEAR | Existing artwork expands briefly, then shrinks and fades; a blocked hit keeps the piece |
| FALL | Existing gem artwork follows engine gravity, then squashes and rebounds briefly on contact with its resting slot (`engine/lua/match3.lua`). Reduced motion omits the bounce. Capture with `build/test/all --suite=relic-rush 'reel relic-rush-top-edge-refill'`. |
| Last tablets | Cradle of Rome 2's original `Star_02_16.png` and `Star_16.png` are packed unchanged as `fx-tablet-glow` and `fx-tablet-spark` in `data/board/fx.png`. `engine/lua/match3/vfx.lua` sweeps them clockwise along the bevel over a soft blue wash. One to three tablets receive the first pulse with the move suggestion. The cue repeats every nine seconds until board input. Reduce Motion hides it. Reproduce the phone captures with `build/test/all --suite=relic-rush 'reel relic-rush-tablet-hints'`. [Source and extraction](../../../docs/cradle-of-rome-reference/README.md#last-puzzle-tile-glow). |
| Layer break | A hit that removes ice, a double tablet's green face or a blue tablet breaks that layer's own art (`tile-ice`, `tile-tablet-double`, `tile-tablet-single` levels) into about eight Voronoi shards (`engine/lua/match3/shatter.lua`). Cracks glow, then shards burst, tumble with a darker side face and fall over about 0.55 s, above billowing smoke: four Kenney puff sprites per cell (`fx-smoke-0..3`, below), turning slowly, tinted pale earth and fading over about 1.25 s, after the shards. The shards are procedural cut-outs of existing art with no new states; Reduce Motion hides it. Capture with `build/test/all --suite=relic-rush 'reel fx-shatter'` (`--fx shatter`). [Reviewed frames](screenshots/review/shatter/fx-shatter-480x900.jpg); smoke [before](screenshots/review/shatter/smoke-before.jpg) and [after](screenshots/review/shatter/smoke-after.jpg) (24 reel frames, 2 apart). |
| Collection | Removed resources fly to their matching wallet capsule with a trail; story pieces do not earn resources |
| Reduced motion | Suppresses trails, shake, squash and effect spawns; the board's entrance becomes a short fade; rule resolution stays active |

Transient light, beams, rings, particles, score text and sunlight motes
are intentional animation primitives, not missing static artwork. Result-card
torch sconces and their flame renderer have been removed; reviewed standard
and safe-area phone captures are in `docs/review/result-without-torches/`.
`engine/lua/match3/vfx.lua` draws the radial glow from the board atlas. See
[effects and capture modes](effects.md).

### Particle sprites

Seven sprites from Kenney's CC0 [Particle Pack](https://opengameart.org/content/particle-pack-80-sprites)
texture the impact, spark and bomb effects. The original black-background PNGs
and `License.txt` are retained in `art/particles/kenney/`;
`python3 tools/match3_atlas.py` packs the seven `fx-*` frames into
`data/board/fx.png`. Registration resizes the sources and uses their brightness as
alpha on white. `engine/lua/match3/vfx.lua` draws them additively, tinted with each piece's effect colour.
They are transient effect sprites with no interaction states. Ray beams,
prism links, special births and the bomb's leading ring stay procedural.

| Sprite | Kenney source | Use |
| --- | --- | --- |
| `shock` | `circle_03` | Soft outer band of the bomb shockwave |
| `flash` | `light_01` | Bomb bloom |
| `burst` | `star_09` | Bomb centre flare, under the glint |
| `ring` | `circle_02` | Per-cell impact ring |
| `glint` | `star_07` | Four-point twinkle on impacts, the bomb centre, ray tips and births |
| `twinkle` | `star_06` | Spark particles and shard heads |
| `streak` | `trace_06` | Shard particles, aligned to their velocity |
| `smoke-0`, `smoke-1`, `smoke-2`, `smoke-3` | `whitePuff00`, `04`, `08`, `12` | Smoke of a breaking layer (`engine/lua/match3/shatter.lua`), alpha-blended |

The smoke puffs come from Kenney's CC0 [Smoke particle assets](https://opengameart.org/content/smoke-particle-assets)
(`engine/art/match3/kenney-smoke/`, with its license). Unlike the sprites above they keep
their own colour and alpha, since the grey fringe is the billow's shading, are centred on a
square and reduced to 128 px.

Review: [kenney-particles](review/kenney-particles/README.md) (bomb and ray frames before and after;
those special pieces and their `--fx` modes have since been removed, only `--fx shatter` remains).

## Remaining runtime asset families

`cloud-fog` covers locked land with rolling cloud banks (`city.fog_clouds`, `engine/src/city.c`).
Two world-space density fields of three spatial frequencies each drift on the smooth frame
clock. Density modulates soft cloud edges, blue-grey hollows and pale sunlit lobes. The cached
closed-land mask stays fixed, and unlocking clears it immediately. Open land stays clear. This
is a continuous procedural effect, with no icon or interaction-state atlas. See the
[review](review/cloud-fog/README.md).

`building-shadows` is a separate Blender-rendered RGBA layer for all 97 objects, drawn below the
fog and every sprite; see [registration](BUILDINGS.md).

The current [97-entry catalogue](building-catalogue.md), including the dry Sunstone
courtyard, is rendered directly from its Blender master with the shared
[city camera](../../../docs/BUILDINGS.md#the-camera). The earlier
[ImageGen paint-over](../art/isometric-paintover/README.md), the
[2:1 building-art trial](../art/isometric-trial/README.md) and the
[Blender projection study](../art/isometric-blender/README.md) are preserved as source
history; all of them use the old 2:1 view, and none is runtime artwork. Painted detail is
the known gap recorded in the [building catalogue](building-catalogue.md#known-gap-no-paint-over) and [tracked here](https://github.com/corepunch/nile-archive/issues/41).

These families plus the board assets above cover every file in `data/`;
`runtime_inventory` is checked against disk by `make test`.

| Runtime files | Source / ownership | Supported states |
| --- | --- | --- |
| `data/city/buildings/<key>.png` | Blender master; `make buildings GAME=relic-rush` | Authored restored sprite; valid placement reuses it, blocked placement uses the existing engine red ghost, held placement lifts it; cards/rewards use it alone |
| `data/city/building-shadows/<key>.png` | Blender master; `make buildings GAME=relic-rush` | Separate grounded shadow for restored/valid/blocked/held states; own crop/pivot and shared pixel scale; all shadows below all buildings; omitted in cards/rewards |
| `data/story/characters/{elena,mara,tomas,adrian}.png` | `art/art-direction/expedition-cast.png`; prepare_assets.py | One authored bust each; engine supplies speech/thought/shout bubbles |
| `data/{island,jungle,scene-lagoon,scene-temple}.jpg` | Corresponding paintings in `art/` | Island, fallback jungle, and the board scenes. As in Cradle of Rome, a board shows the scene of the latest restoration in force on it (the same restored-and-reached gate as its pieces, `backdrop` in `economy.unlocks`): camp, well, workshop, market, lodge and fountain bring the lagoon; courtyard, archive, observatory and temple bring the temple. Before any, a board uses its authored `background`. Only two scenes exist, so restorations share them; per-building scenes are not yet painted |
| `art/registered/board-states/cell-mask.png` | Actual `gfx.ngon` capture in `art/board-states/cell-mask.png` | Shared flat-top slot silhouette; clip mask, not an icon/state |
| `art/registered/title.png` | `art/title.png` | Retained title asset; the current minimal HUD does not draw it |
| `data/common/fonts/LilitaOne-Regular.ttf`, `lilitaone-OFL.txt` | Bundled licensed font | Dynamic labels, counters, outlined/gradient typography |

The reusable engine UI now owns form layout, input, focus, data exchange and modal
Gaussian blur; the game supplies its skin and templates for pause, building and
guide dialogs. The guide uses one stable-key data source, a measured list and
left-aligned icon/copy rows. Speech, thought-cloud and shout-burst badges centre
on the visible outline; their puffs/spikes contribute to text padding. Framed
phone dialogue centres the portrait, visible bubble and any listener as one
measured unit within the safe screen; Skip travels with that unit. Reviewed
480×900 and safe-area 390×844 comparisons are in `docs/review/centered-dialogue/`.
The badge/padding audit is tracked in [issue #16](https://github.com/corepunch/nile-archive/issues/16).
Reviewed comparisons live in `docs/review/dialogue-stack/` (all three shapes,
one/two-line speech, 480×900 and safe-area 390×844, plus the guide). See [the UI engine](../../../docs/UI_ENGINE.md).

Board presentation restores the original 26.5-unit cell radius, fitting the
maximum nine-column grid into 371/480 logical screen units. The previous fixed
32-unit radius made the settled board about 21% too large. Base pieces, the
cell mask, specials, blockers and selection/hints share the restored geometry;
authored alpha and orientation are preserved. Cell positions, input and refill
clips use the same radius. Guide icons retain their original size. Sources:
`lua/state.lua`, `lua/board.lua`; no bitmap or interaction state is added.
The entrance settles to a 1× pose after natural completion, skipping or reduced
motion. Representative before/after captures at both phone sizes, plus
reproduction, are in
[the size correction review](review/board-size-fix/README.md).

Superseded twice (by the Goal/Moves cards and then the match-3 HUD above):
the board HUD used three small, separate jade cards with gold rims: score,
level/name and moves. Each label stays grouped with its value; objective pills
share the same near-opaque backing. The painting remains visible in the gaps.
The read-only `hud_form` in `lua/board.lua` uses engine row/column layout,
computed values and a paint-only skin. Text keeps its outlined/shadowed palettes;
score pulses and progress remain animated. No authored sprite or interaction
state is added. The earlier unbacked HUD lost contrast and is superseded by
[the grouped-card review](review/readable-hud/README.md), including both paintings,
phone safe areas, modal underlays and effects. Historical captures are in
`docs/review/floating-hud/`.

The island's redundant minus/plus/MAP button cluster has been removed from
`engine/lua/match3/game.lua` (the town hooks). Navigation uses the shared city camera: pinch or mouse
wheel to zoom and drag to pan. Placement, confirmation and long-press pickup
are unchanged. No bitmap or state mapping changed. Normal, overview and
placement captures at both phone sizes are in
[the map-control review](review/gesture-only-map/README.md).

Building pickup now uses the engine's stationary 0.5-second hold; ordinary drags
pan the map. The existing ghost/footprint, held/released, valid/blocked and
confirm/cancel states are retained. [Issue #21](https://github.com/corepunch/nile-archive/issues/21)
tracks gesture arbitration and the two-game input audit. Sources are
`engine/src/city.c`, `engine/src/core.c` and `engine/lua/match3/game.lua` (the town hooks); reviewed native-input
captures and reproduction commands are in
[the shared gesture review](../../../docs/review/city-long-press/README.md).
No bitmap or atlas mapping is added.

The island HUD has no sheet or panel over the map: one row of slim resource
pills, the shared pause medallion, and a bottom row of a large Play/Build button
between icon-only round Expeditions and Shop buttons. The side-button centres
share the Play/Build button’s centre line; captions beneath them are removed.
The round buttons are engine geometry
(gold rim, jade face) around existing artwork: the procedural compass icon and the
Jungle market sprite (`data/city/buildings/3.png`). Their pressed state shifts the face
2 units, as menu buttons do; there is no hover, selected or disabled state because
they are always available. The EXPAND pill is gone: a region that can open now
shows "+" and a glow on its fog marker, and its name is outlined text without a
plate. [Island HUD captures](review/island-hud/README.md).

The Pause menu's Sound and Reduce motion settings are engine `checkbox`
controls drawn by `lua/skin.lua` (`controls.checkbox`): a 40-unit well in the
panel's wooden rim on a jade shadow, filled with a jade face, gloss and a cream
tick with a dark rim when checked. States: unchecked, checked, pressed (box and
tick sink 2 units) and disabled (rim and fill turn grey; not used by the game).
Hover looks like normal, as for every Relic Rush control, because touch has no
hover. All of it is engine geometry, like the menu buttons, with no bitmap.
Checked = sound on / motion reduced; the binding writes the setting at once.
[Reviewed captures of every state](../../../docs/review/ui-skin-files/README.md#relic-rush-pause-checkboxes).
`--smoke` clicks Sound off and on again through real input.

Pause groups its controls, as pause menus in other match-3 games do. The two
checkboxes sit in a recessed well (`controls.panel.variants.group`: a sand
gradient with a darker rim). Below it come the jade RESUME and two secondary
actions in carved wood (`controls.button.variants.secondary`, same layers and
states as the jade button: pressed sinks 2 units, disabled drains it). EXPLORER'S
GUIDE is a gold text link (`variants.link`: no layers; pressed moves the text).
From the island Pause shows only Resume. RESTART opens a confirmation
(`OV_CONFIRM`): RESTART in jade and KEEP PLAYING as a link, which returns to
Pause. QUIT TO ISLAND keeps the unfinished board. All are engine geometry
with no bitmap. Captures at both sizes, in the board and on the island, are in
[the skin review](../../../docs/review/ui-skin-files/README.md#relic-rush-pause-grouped-with-restart-and-quit).

Resource capsules, island HUD buttons, progress bars, menu buttons, result stars, placement outlines, land
fog and dialogue chrome are intentional engine geometry/text; they are not gem
or tool artwork states. Existing island, dialogue and result captures are linked
from the [README](../README.md). App icons live in `Assets.xcassets/`, outside the
runtime data inventory; their source and selection records are in `art/app-icon/`.

## Reproduce and keep current

From the repository root:

```sh
python3 games/relic-rush/tools/capture_cell_mask.py  # when cell geometry changes
python3 games/relic-rush/tools/board_assets.py
python3 games/relic-rush/tools/board_assets.py --check
python3 games/relic-rush/tools/check_art_catalogue.py
make test
./build/relic-rush --headless --mute --fresh --art-states --shot catalogue.png
./build/relic-rush --headless --mute --fresh --art-board --shot specials.png
./build/relic-rush --headless --mute --fresh --tiles jewels --art-board --shot jewels.png
```

Use Xvfb on Linux. `tools/screenshots.py` regenerates the catalogue and special
board as well as ordinary levels, guide, effect and phone captures. Review at
480 × 900 and 390 × 844 with phone safe areas. `--art-board` freezes a deterministic
level-nine board with all five specials, selection/hints and selected/depleted
tools; `--art-states` displays every base piece and all 27 authored sprites through
the real renderer. These capture modes do not save progress.

For every addition, update this document, the manifest inventory and state mapping,
and the runtime contract together; add capture coverage. A new file without an
inventory entry, an absent authored state, or a stale atlas crop fails CI. When
changing existing definitions, audit their actual rule meaning as well as names.
If any visual gap remains, open/link a GitHub issue here before handoff. No known
placeholder board/control states remain from issue #11.

## Island connector removal

`lua/island.lua` disables the engine's procedural roads between buildings
with a transparent `city.path`. Building sprites, shadows and terrain assets
keep their existing registrations. Reviewed 480×900 and 390×844 captures are
in [the road removal comparison](review/no-auto-roads/README.md).

## Engine match-3 atlas and trickling

`data/board/` holds the following atlases. `pieces.png` contains pieces,
bonuses, action icons and the seven small HUD icons. `blockers.png` contains
blockers, `cells.png` contains floors and selection/hint frames, `hud.png`
contains the jade signboard, and `fx.png` contains additive effects.
Backgrounds are separate files in
`data/board/backs/`. `lua/match3_atlases.lua` gives each frame's pixel
rectangle; `lua/match3_skin.lua` and `lua/match3_hud.lua` choose the atlases for
the board and its HUD. `art/match3-atlas.json` records every atlas and its
source images. Board pieces and objectives also supply their own
icons to the goal display.

The HUD reads `score`, `complete`, `life`, `discovery-star`, `next-clue`,
`shop-built` and `shop-locked` from `pieces.png`. The first five use their
existing registered artwork. `shop-built` is a jade checkmark with a gold
bevel for restored buildings. `shop-locked` is a gold padlock for locked
buildings and expeditions. Both are static readouts painted together in one
transparent [ImageGen atlas](../art/expedition-hud/shop-status.png). The
[prompt](../art/expedition-hud/shop-status-prompt.txt) and
[registration manifest](../art/expedition-hud/manifest.json) record the source
and crop boxes. Run `python3 games/relic-rush/tools/prepare_hud.py` to fit each
crop into a 120 × 120 area on a 128 × 128 canvas with the painted alpha, then
`python3 tools/match3_atlas.py` to repack.
[Reviewed catalogue and expedition shots](screenshots/review/shop-status/README.md).

The engine's default resource skin is independent and embedded; both games
normally override it. `python3 tools/match3_atlas.py` reproduces the atlases and
registrations. FALL uses engine-owned
simultaneous one-edge movement steps, straight-down priority with blocked-down diagonal fallback, vertical spawning at every exposed column top and
a short landing squash; static states continue to use the existing artwork.
Input and animation timing are shared.

See [checked in-game captures and commands](review/trickling/README.md) and the
[engine contract](../../../docs/MATCH3_ENGINE.md). The default atlas's source,
prompt, all supported states and crop/rotation registration are catalogued in
`engine/art/match3/manifest.json` at repository root.

### Earlier flat-top piece artwork

The earlier flat-top sun idol and the Jewels pack's yellow hex gem come from
`art/tile-sets/source-flat-hex.png` and `flat-hex.prompt.txt`.
`piece_replacements` in the state manifest records both historical crops and
their fit to the cell. The current atlas uses the round sun coin in the Relics
pack and the six-sided yellow gem in the Jewels pack.

The clay brick belongs to the independent engine default atlas and is not used
by this game's overrides. Reproduce with `python3 tools/match3_atlas.py` and
`make gen`. Review [actual boards and guide](../../../docs/review/resource-icons/README.md).


### Cell registration and dialogue motion

The board retains its enlarged 32-unit radius and 16-unit side margins. Pieces
and state panels scale together by `32 / 26.5` from the authored registration:
the 43.7-unit piece canvas becomes about 52.77 units, while the inset 51.4-unit
cell/state canvas becomes about 62.07 units. This preserves piece padding and
keeps neighbouring cell faces, selection/hint frames and special panels apart.
Filling the entire cell diameter had removed that inset; reducing the board
radius then lost the deliberate wide layout without repairing the proportions.
The guide and HUD retain their own sizes. Artwork and alpha are unchanged. See
the [wide-board and cell-fit review](review/gem-cell-fit/README.md) for both phone
sizes, the selected/special cell view and existing capture commands.

Portraits retain finite entrance/exit slides and fades. An independent colour
tween brightens/dims active/listener states without replaying the slide. Size is
constant for speaker/listener, with no scale/rotation animation or idle wobble. See [motion, captures and timing review](../../../docs/review/motion/README.md).

### Placement confirmation controls

`engine/lua/match3/game.lua` (the town hooks) uses an engine form with `placement_cancel` and
`placement_confirm` variants from `lua/skin.lua`. These are procedural UI skin
controls like the existing checkbox: red round × (cancel) and jade round ✓
(commit build/move), normal/hover/pressed states with a keyboard-only focus ring; confirmation fades when
invalid. No texture substitution or gem-art tint is used. Their screen positions
follow the preview sprite with safe-screen clamping, at 480×900 and 390×844.
Reproduce with `--city 6 --placing` or `--placing blocked`; reviewed captures are
in `docs/review/relic-polish/` at the repository root. Existing native-input smoke
covers both cancel and confirm, including uncommitted moves and wallet changes.

## Current-camera building paint pass

All registered buildings and decorations use the painted-v1 sources, normal sprite
and unchanged engine placement/lift/validity states documented in the
[building catalogue](building-catalogue.md) and
[review gallery](review/painted-buildings/current-camera/README.md).

## Centred board indicators and placement input

The former centred lightning/bomb overlay was replaced by the engine-masked
stripes and full-size bomb described above. Ice **1**/**2** counters are centred on
their cell and drawn last, above every board layer. The guide shares the current piece rendering. Authored PNGs and alpha are unchanged;
the former corner offsets remain removed. No new bitmap assets.

Touch/mouse use removes the placement button's keyboard focus outline; Tab
restores keyboard focus. Preview movement requires dragging the building.
Pickup and release/drop emit feedback; Confirm and Cancel add none. See the
[review and reproduction commands](../../../docs/review/relic-input-feedback/README.md)
for both phone sizes and the dense special/blocker state board.

## Placement alignment guides

`placement-guides` uses the shared `engine/src/city.c` renderer. While moving or
placing a building, other buildings show neutral cream outlines with dark
contrast edges around their occupied ground, including placement clearance.
The building in hand retains its green/red footprint; its original location
is omitted. Guides stay visible after release until Confirm/Cancel, then hide.
The guides use the existing camera and tile measurements; artwork, alpha,
footprints and collision rules are unchanged. No bitmap or ImageGen source is
added. Reproduce with the existing native-input hold/placement captures in the
[review](../../../docs/review/city-placement-guides/README.md).

## Settings gear

Relic Rush's expedition and town Settings buttons use `action-pause` from the
[shared action atlas](../../../art/match3-buttons/README.md). `lua/art.lua` takes
a centered view of five-sixths of the transparent sprite frame's width and
height, so the sapphire gear draws 20% larger in every button state. The crop
lies outside the painted gear. Reproduce the board captures with
`build/test/relic-rush 'shot hex-first' 'shot phone-board'`.
[480 × 900](screenshots/review/gear-size/board-480x900.jpg) ·
[390 × 844](screenshots/review/gear-size/board-390x844.jpg).

## Earlier settings gear and three-resource wallet

The `pause-normal`, `pause-hover`, `pause-pressed`, `pause-selected` and `pause-disabled` keys draw the authored settings gear from `art/expedition-hud/settings-lives.png`. The same atlas includes the archived `life` heart. The top wallet shows the sun coin, `wallet-supplies` and `wallet-food` in that order. The shared header keeps the gear slot square and scales the wallet capsule widths to fit beside it.

Built-in ImageGen painted the timber-and-stone bundle and bread-and-fruit
basket in one [transparent atlas](../art/resource-pieces/wallet-supplies-food.png).
The [prompt](../art/resource-pieces/wallet-supplies-food.prompt.txt) and [asset manifest](../art/board-states/manifest.json)
record the source and registration. Run `python3 games/relic-rush/tools/prepare_resource_pieces.py`
to crop the left and right cells, fit each to 120 px and center it on a 128 px
canvas with the authored alpha. The static icons appear in the top wallet,
shop prices and expedition rewards. The wallet uses the [round button painter](../../../engine/lua/match3/buttons.lua)
for its brass rim and shadow. The skin supplies the translucent green fill and the
bezel lowers on press. Compare the headers before (top) and after (bottom) in
the [480×900](screenshots/review/wallet-rim-480.png) and [390×844](screenshots/review/wallet-rim-390.png)
captures from `shot floating-hud` and `shot phone-board`.
[In-game comparison](screenshots/review/three-resource-wallet/README.md).

All five gear states were generated together by ImageGen; `settings-lives-prompt.txt` records the prompt and alpha cutout edit. `python3 games/relic-rush/tools/prepare_hud.py` performs only grid crops and thumbnail registration to 128px RGBA canvases, preserving authored alpha and paint. `tools/match3_atlas.py` then packs the five gear states. No tint-generated interaction state is used. Captures: `docs/screenshots/hud-states.jpg`, `hex-first.jpg`, `phone-board.jpg`, `island-village.jpg` and `phone-island.jpg`. Normal, selected, pressed, hover and disabled use the same authored outer medallion, with distinct painted state feedback.

The larger Buildings and Play actions reuse the existing jade button skin in all its states. Expeditions remains the smaller compass action. Building name/subtitle bubbles use the existing story bubble renderer and persist until the next press.

## Archived island image actions and prominent resources

The **bottom of the town screen** has Build (left), a large Play (center)
and Settings (right). Build and Settings have equal slots; Play is larger and
carries the number of the level it starts as its caption (the skin's `cream`
figure style, set on the `navigation_play` variant). There is no level list:
the `navigation_levels` role and its button were removed. Its `action-levels`
frame is still packed in the pieces atlas, unused. Game boards and
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
160×160 RGBA image under `art/registered/navigation/`, so the visible buttons are
centred in their slots and `town_config.lua`'s `bottom` puts Play's lower edge as
far from the screen edge as Build and Levels are from the sides.

| Role | Runtime state names (all `.png`) |
|---|---|
| `navigation_build` | `build-normal`, `build-hover`, `build-pressed`, `build-selected`, `build-disabled` |
| `navigation_play` | `play-normal`, `play-hover`, `play-pressed`, `play-selected`, `play-disabled` |
| retired with the level list (archived art, no role) | `levels-normal`, `levels-hover`, `levels-pressed`, `levels-selected`, `levels-disabled` |

Reproduce: `python3 games/relic-rush/tools/prepare_hud.py --navigation-only`;
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


The shared form still owns hit testing, focus and activation. The smaller Expeditions compass remains between the primary actions. Resource icons are drawn at 60 units beside 36-unit counter bars; they deliberately protrude beyond the pills, including their interactive bounds. The island settings gear uses an 88-unit art/touch box; expedition-board geometry stays unchanged. Toasts sit above the taller image actions. New art and every authored state are reviewed in `docs/screenshots/image-buttons-after/hud-states.jpg`; actual home UI at 480x900 and 390x844 is in the same review folder.

Straight-line match-3 rules: ordinary triples, four-in-line rays on all three axes, and five-plus prisms reuse the existing authored states. The guide now shows a prism alone for the five-plus recipe. Bomb artwork remains for existing pieces, tools/effect reviews and special combinations; no nonlinear group creates one. See [rules](match4-rules.md).

## Three-episode story presentation

All 46 scenes / 120 lines reuse the authored cast sheet `art/art-direction/expedition-cast.png` and its four RGBA crops `data/story/characters/{elena,mara,tomas,adrian}.png`. Original prompts and crop reproduction are in [art direction](art-direction-v2.md) and `python3 games/relic-rush/tools/prepare_assets.py`. No character is missing: Elena investigates, Mara pilots the Marigold, Tomas is the archivist, and Adrian funds the expedition. Cornelius is an off-screen missing person, not a speaking fifth portrait. Kessler, the Meridian Society's man, speaks but is deliberately never seen: his radio and loudhailer lines are engine captions with a name tag and no bust, which is the intended final state, not a missing asset.

The runtime cast all face right. The portrait import mirrors Adrian’s crop from the original lineup to match the other three. It also isolates Mara’s bust from a stray fragment of the neighboring portrait while keeping her canvas and anchors. Run `python3 games/relic-rush/tools/prepare_assets.py --portraits-only` to reproduce the exports. The story renderer mirrors the portrait on the right side and keeps partners facing one another across turns. [Phone captures](review/portrait-facing/README.md) show the staging. Body text is 31.5 points, names/building bubbles 22.5 points, retaining the cream/ink palette. All thirty boards use the existing packs and the Lagoon/Temple paintings; the island and all ten wonder sprites/registration remain unchanged. Narrative-specific building bubbles reveal only clues the player has reached. The implementation intentionally stages scenes over existing paintings rather than adding cinematic panel assets.

Runtime contract: `lua/art.lua:A.story`; mapping: `art/board-states/manifest.json:story`. Script compilation: `python3 games/relic-rush/tools/prepare_story.py`. Reproduction and inspected game captures are in [story review](review/story/README.md); use `--story-beat before-11`, `--story-beat after-28`, or `--story-beat after-30 --story-line 9`.

## Island streets

| Asset | Source | Runtime | States and use |
|---|---|---|---|
| Old stone paths | `python3 tools/roads.py relic-rush` (Scener model; palette in `art/roads.json`) | `data/city/roads.png` | Fifteen paved road pieces, one per combination of joined neighbours, with rounded turns and junction corners, plus eight looks of each straight direction so a long street does not repeat (8 × 4 atlas): worn, uneven flagstones of weathered limestone in keeping with the valley's ruins: no kerb and no bed, wide joints and the odd missing stone, so the grass shows between them (`rough`, `gap`, `missing` in the palette). The engine lays them from every building's front and joins them ([Roads](../../../docs/BUILDINGS.md#roads)); they replace the curved connectors removed in [the earlier review](review/no-auto-roads/README.md). No interaction states. Captures: `screenshots/island-village.jpg` (`--showcase`), `screenshots/phone-island.jpg` (`--city 3`) |

## Building card: what a building brings

The building card lists its price and what the building brings side by side as
the engine's icon-and-figure amounts (the `resource_indicator` prefab). It reuses
existing art and adds none. `R.building_gets` in `lua/screens.lua` maps each
ladder unlock to its reward. A new piece shows its board art above the currency icon and a plain number. The food and supplies icons use the extra space beside a single digit. A bonus shows its `bonus-<key>` gem alone. Reproduce with
`./build/relic-rush --headless --mute --fresh --size 390x844 --card 3 --shot out.png`.
Reviewed in game at 480×900 and 390×844 for a piece (Workshop, Well, Temple), a
bonus (Camp), a built building with both (Museum) and five amounts in one row.

### Moves capsule concept

The [review board](review/moves-capsule/board.jpg) places remaining moves in the
first wallet-style capsule. ImageGen painted the [static icon](review/moves-capsule/moves.png)
using the [wallet coin](../art/registered/resource-pieces/coin.png) as its reference.
Two recessed clockwise arrows replace the stamped sun on the warm gold face.
The transparent sprite is registered at the same 128 × 128 px as the wallet coin. The [header comparison](review/moves-capsule/comparison.jpg)
shows the shipped hex counter above the concept. To render this preview from
the repository root:

```sh
build/relic-rush --headless --fresh --mute --size 480x900 --level 9 --lua 'games/relic-rush/docs/review/moves-capsule;games/relic-rush/lua;.' --shot /tmp/moves-capsule.png
```

The [eight-variant comparison](review/moves-capsule/variants.jpg) shows all
icons at wallet scale on the expedition backdrop. ImageGen painted eight round
badges with two curved arrows in a single [transparent atlas](review/moves-capsule/variants-atlas.png).
Reading order follows the 4 × 2 grid. Materials are hammered gold, cobalt glass,
sandstone with terracotta inlay, jade, painted clay, carved wood, silver, and
amethyst. The preview reads the authored cells directly as texture regions and
uses the same icon scale, capsule, and count for all eight. Add
`--moves-variants` to the command above and crop the top 141 logical pixels for
the comparison sheet.
