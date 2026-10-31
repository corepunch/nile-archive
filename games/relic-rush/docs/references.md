# Art direction and reference research

Research date: 29 October 2026. Original sprites and environment paintings were generated for this prototype; no King, Supercell or Wooga game art is redistributed.

## Island and building art direction

Pearl's Peril and June's Journey are the primary references for the island and buildings, as requested. Favor a landscaped island with organic shoreline, gardens, trees, scenic paths and coherent building scale. Let individual buildings sit in their own surroundings with breathing room. Keep a calm, detailed painted environment; retain archaeological expedition architecture for our original setting. Candy Crush informs the puzzle board and feedback, not the island composition. Roads remain decorative, without connectivity requirements. The prototype now uses a large scrolling world, explicit neighboring-region unlocks, and freely placed movable buildings with green/red footprint validation.

## Core loop
- Wooga: June's Journey, Orchid Island construction, decoration, landmarks and scene progression: https://wooga.theymes.com/hc/en/junes-journey/articles/how-do-i-play-junes-journey-394
- June's Journey official presentation: https://prod.junesjourney.com/
- Pearl's Peril: archaeological adventure era / island setting: https://www.wooga.com/games/pearls-peril
- Tropicats: direct match-3 plus island restoration reference, listed in https://www.wooga.com/games
- Cradle of Rome: the requested resource gathering / construction loop; used as a conceptual reference.
- Supercell: chunky readable silhouettes, responsive feedback, generous touch targets; visual inspiration, no borrowed assets.

Paths on our island are painted scenery. There is no road-connectivity requirement or traffic simulation. Buildings use player-selected world positions. Placement previews can be dragged, confirmed or cancelled; existing buildings can be moved. Panning is independent of placement. Region state and building positions are saved, with migration of previous saves.

## Match-3 mechanics
King's official special-piece guide: https://candycrush.zendesk.com/hc/en-us/articles/211939685-Creating-and-combining-Special-Candies
King's booster guide: https://candycrush.zendesk.com/hc/en-us/articles/211320729-What-types-of-Boosters-are-available

Implemented interpretations: four in a line → line clear; five in a line → color clear; intersecting T/L → seven-cell hex bomb; special-special combos; chains; excavated sand; ice (including double layers); adjacent fire melting ice. Limited tools give targeted hit, 3×3 blast and cross clear. No lives, purchases, timers or social backend.

## Free asset shortlist
- Kenney Puzzle Pack 2: CC0, useful coins, particles and generic UI tiles: https://kenney.nl/assets/puzzle-pack-2
- Kenney Puzzle Pack 1: CC0 generic puzzle foundations: https://kenney.nl/assets/puzzle-pack-1
These were evaluated but not bundled: original themed art gives the prototype one coherent style. There are no downloaded Kenney assets in this build.

## Typography / text rendering
- Canva effects reference (outline, shadow, echo, gradient compatibility): https://www.canva.com/help/text-effects/
- Roblox UIStroke: independently controlled stroke and layering: https://create.roblox.com/docs/reference/engine/classes/UIStroke
- Roblox UI appearance modifiers, including gradient strokes: https://create.roblox.com/docs/ui/appearance-modifiers
- Lilita One (Juan Montoreano): https://github.com/google/fonts/tree/main/ofl/lilitaone
- Lobster (Pablo Impallari): https://github.com/google/fonts/tree/main/ofl/lobster
- Both unmodified font files and their SIL OFL 1.1 licenses are bundled in `assets/fonts/`.

Rendering contract: rasterize the complete string into one alpha mask, preserving kerning; dilate that union for an outer silhouette; composite extruded shadow and stroke behind it; composite gradient-filled text last. Do not draw an outlined glyph followed by the next outlined glyph. The latter allows one glyph's border to cover its neighbor's fill, especially in script fonts. The logo is shaped as a complete Lobster string by Pillow/FreeType. Runtime Latin UI strings use a Lilita glyph atlas plus a complete kerning-pair table; each complete label is composited and cached as a single RGBA texture. Animation changes transform/opacity, never rerasterizes the font each frame. This prototype's runtime atlas covers ASCII; Cyrillic localization requires expanding/shaping the atlas or adding a shaping stack.

## Engine selection
- Orion README describes a desktop UI framework: https://github.com/corepunch/orion-ui
- Orca UI/Lua/MoonScript framework: https://github.com/corepunch/orca
- SDL2 officially targets iOS and Android: https://wiki.libsdl.org/SDL2/Introduction
- SDL2 Android integration: https://wiki.libsdl.org/SDL2/README-android
- SDL2 CMake / iOS integration: https://wiki.libsdl.org/SDL2/README-cmake

SDL2 is the selected game runtime. No Orion or Orca code is required. Gameplay is C11 without SDL dependencies; rendering, input, audio and platform lifecycle live in the SDL front end. The browser preview compiles the same engine and front end to WebAssembly, rather than reimplementing the game in JavaScript.


## Territory model: June's Journey / Pearl's Peril / Settlers II

- June's Journey opens clouded land regions by Star and Compass requirements: https://wooga.theymes.com/hc/en/junes-journey/articles/how-do-i-get-more-space-on-orchid-island-331
- Compass currency is spent on region unlocks: https://wooga.theymes.com/hc/en/junes-journey/articles/what-are-the-compasses-for-and-how-do-i-find-them-332
- Pearl's Peril requires badges, coins and compasses for its manually opened land areas: https://wooga.theymes.com/hc/en/pearls-peril/articles/can-i-expand-the-island-164
- Pearl's Peril placement uses green/red feedback and allows later moves confirmed with a tick: https://wooga.theymes.com/hc/en/pearls-peril/articles/how-do-i-place-decorations-251

For the Settlers II comparison, inspected the primary source of Return to the Roots, an open-source reimplementation, rather than assuming access to the original 1996 source. Direction.h defines six directions per node; MapNode.h has triangular terrain facets, owner, build quality, roads and objects; TerritoryRegion.h calculates node ownership around military buildings. This informs the separation between map topology, territory membership and occupied space. No RTTR code is copied into this project.

- https://github.com/Return-To-The-Roots/s25client/blob/master/libs/s25main/gameTypes/Direction.h
- https://github.com/Return-To-The-Roots/s25client/blob/master/libs/s25main/gameTypes/MapNode.h
- https://github.com/Return-To-The-Roots/s25client/blob/master/libs/s25main/world/TerritoryRegion.h

Our original model: a hidden axial land graph, terrain membership, regionId, open-region bitset, independent building world coordinates and footprints. Multi-source flood fill creates six connected natural regions. A new region must touch open land, meet its cumulative Star requirement and be affordable in Compasses. Confirmation consumes Compasses, never Stars. Winning each prototype level awards three of each; region Star gates are 6 / 9 / 15 / 21 / 27 and Compass costs are 2 / 3 / 4 / 5 / 6. These are prototype balancing values, not copied June's Journey prices. The puzzle board has its own separate 61-cell radius-four hex graph; the island and puzzle coordinate systems are not shared. Expansion is immediate after confirmation; no waiting timer or paid bypass exists in this prototype.

## Match-3 level HUD

Reviewed 31 October 2026 against the portrait match-3 games players compare us
with: Royal Match, Toon Blast, Homescapes/Gardenscapes, Candy Crush Saga and
Tropicats. Their level screens share one layout, which the expedition HUD now follows:

- One band fixed to the top edge, under the status bar, rather than cards floating over the scenery.
- A large Moves counter is the strongest element of the band.
- Goals are icons with the remaining count beneath. A met goal shows a check instead of a number, without a "DONE" label.
- Pause/settings is a small corner button. No character art or level title sits in the HUD during play. Characters speak in story scenes and dialogue.
- Boosters sit in a tray along the bottom edge, without captions. Choosing one explains it.
- No standing hint text. The board fills the space between the band and the tray, with the scenery showing around it.
- The last few moves turn the counter red.

Background reading on HUD clutter and Royal Match's text-light UI:
- https://www.funovus.com/blogs/royal-match-dominates-match-3-what-can-all-designers-learn/
- https://thisweekinliveops.substack.com/p/5-simple-ux-lessons-from-royal-match
- https://www.andacademy.com/resources/blog/ui-ux-design/game-ui-design/
