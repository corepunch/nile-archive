# Christmas art direction catalogue

Current puzzle rules: adjacent swaps create straight runs of 3+ along the three
hex axes, matching Relic Rush. Four creates the existing axis shooting-star
state; five or more creates the existing rainbow-star state. Bent clusters do
not match. Existing bomb artwork remains available to review boards and tools;
there is no bent-group bomb recipe. No new artwork or growth stages are added.
The guide and campaign lessons describe these rules; existing authored control
states and runtime image inventory are unchanged.
Reviewed board and guide captures are in the
[straight-line match-3 review](review/straight-line-match3/README.md).

Status: the buildings are Blender renders with projected registration (see the [building catalogue](building-catalogue.md)); the board, HUD and character art are directional ImageGen artwork. The planned ImageGen repaint of the renders and special-colour readability remain in [#34](https://github.com/corepunch/nile-archive/issues/34).

| Asset | Source | Draft runtime | Meaning and supported states |
| --- | --- | --- | --- |
| 37 buildings and decorations | `art/building-catalogue/` (Blender scene, catalogue, registration) | `data/buildings/<key>.png` | Ten sequential construction milestones, 15 decorations, 4 trees and 6 cottages, one Blender render each; placed and placement-preview use the same sprite, with engine lift/footprint feedback. See the [building catalogue](building-catalogue.md) |
| Original building atlas | `art/buildings.png` | Retired | The first directional paintings of the twelve designs; no longer extracted |
| Labeled building sheet | `art/building-reference-sheet.png` | Reference only | All twelve designs, numbered and captioned: the Blender models follow it |
| Six festive puzzle kinds | `art/icons.png`, cells 0–5 | `data/tile-sets/festive/` | Bell, candy cane, holly, blue ornament, purple bauble, gingerbread; bell objective, candy canes thaw nearby ice |
| Specials and board layers | `art/icons.png`, cells 6–18 | `data/board-states/` | Three shooting-star axes, firework bomb, rainbow prism, snow, tinsel, two ice strengths, selection, hint, guide and cell mask |
| Tools | `art/icons.png`, cells 19–33 | `data/board-states/` | Hammer, firecracker and star wand: normal, selected, pressed, hover and disabled, authored together in one atlas |
| Pause and completion | `art/icons.png`, cells 34–39 | `data/expedition-hud/` | Five authored pause states and a completion medal; medal also represents cumulative Christmas Stars |
| Lives | Relic Rush's [authored heart](../../relic-rush/art/expedition-hud/manifest.json), copied unchanged | `data/life.png` | One static life counter icon. The capsule uses the existing skin press state |
| Terrain | `art/terrain.png` | `data/island.jpg`, `data/winter.jpg` | Empty snowy market ground and puzzle backdrop |
| Main character | User-supplied `art/noelle-reference.jpg`; ImageGen transparent cutout `art/noelle.png` | `data/characters/noelle.png` | Noelle's static dialogue and board portrait; original direction retained as `art/noelle-direction-v1.png` |
| Story cast | Built-in ImageGen, `art/story-cast.png` | `data/characters/{theo,agnes,henrik,pip,wren}.png` | Five painted dialogue busts on Noelle’s 320×480 canvas. See [Story cast](#story-cast) |
| Portrait app icon | `art/app-icon-source.png` | `Assets.xcassets/AppIcon.appiconset/` | One authored portrait composition, spatially resized for all iOS/macOS slots; opaque RGB square, no baked corner mask, no interaction states |
| Interface controls | `lua/skin.lua` (engine `ui.skin`) | Engine geometry | Four outlined Lilita text palettes, the parchment panel, the festive red button (normal, pressed sinks 2 units, disabled drains the colour; flat text variant), toggle and focus ring. Hover and selected match normal because touch has no hover; no bitmap or derived state. Captures are pixel-identical to the paint code this replaced |
| Snowfall and feedback | Lua renderer | Procedural | Transient snow particles, collection particles, beams, lift and placement feedback; no authored control state is derived with a filter |
| Effect sprites | CC0 Kenney Particle Pack, `art/particles/kenney/` | `data/particles.png` | Seven tinted additive sprites for impacts, sparks, shards and the bomb's bloom; see [Particle sprites](#particle-sprites) |

Built-in ImageGen generated all new paintings except the buildings, which are Blender renders. `art/prompts.json` records the exact source prompts; `art/reference-sheet-prompt.txt` records the labeled-sheet prompt. `art/registration.json` records the icon atlas crops and output sizing; building registration lives in `art/building-catalogue/`. Original source RGB and alpha are preserved inside extracted artwork. Control states are directly cropped from the authored atlas. The six pieces, the three tools' states, Pause and the goal star are cropped square around their own artwork, with one side per family, and scaled evenly to 128×128. That keeps their authored proportions: the earlier unequal source cells stretched them tall. Hex board states keep their whole source cell, because it registers them to the board slot.

Reproduce draft runtime extraction with `python3 games/christmas-market/tools/prepare_assets.py`; launch previews with `make run-christmas-market ARGS="--showcase --fresh --mute"` or `ARGS="--level 4 --fresh --mute"`. The PR captures all screens at 480×900, plus the market, board and dialogue at 390×844 with safe areas. All twelve directional building footprints are included across three review pages. Every building footprint is now projected from the Blender scene and checked in the ten review pages.

The font and its license are inherited unmodified from Relic Rush in `data/fonts/`. Gameplay modules were adapted locally from Relic Rush; its original archaeological paintings are not used in this draft.

## Town HUD

Lives, Gold and Christmas Stars use the same single-row layout and hit areas as
Relic Rush. Lives reuse its heart, Gold uses the festive bell and Stars use
the Christmas completion medal. Copy the heart from
`games/relic-rush/data/expedition-hud/life.png` to `data/life.png`. Region
markers open their map cards. Stars qualify the player for a region and stay
in the wallet when the region opens.

[Town, region, building and reward captures](screenshots/review/town-wallet/README.md)
show the change in the game renderer.

## Story cast

All six speaking characters have painted busts. One built-in ImageGen pass produced the [supporting cast sheet](../art/story-cast.png), using Noelle's existing cutout as the style reference. The exact prompt is under `story_cast` in [character-and-icon-prompts.json](../art/character-and-icon-prompts.json). These five exports replace the cards tracked in [issue #76](https://github.com/corepunch/nile-archive/issues/76).

| Character | Runtime | Story cue |
| --- | --- | --- |
| Theo Marsh | `data/characters/theo.png` | Tree seller with fir needles, plaid coat and resin-stained gloves |
| Agnes Holt | `data/characters/agnes.png` | Baker in a flour-dusted apron with her arms crossed |
| Henrik Strand | `data/characters/henrik.png` | Toymaker with white whiskers, leather apron and pencil |
| Pip Larkin | `data/characters/pip.png` | Post runner with his satchel and gap-toothed grin |
| Mr Wren | `data/characters/wren.png` | Grey-coated sweeper with his broom and tilted head |

Run `python3 games/christmas-market/tools/prepare_story_cast.py` from the root to reproduce the cutouts. The script crops, mirrors toward Noelle, resizes proportionally and bottom-aligns each cutout on a transparent 320×480 canvas using the atlas alpha. Each speaker has one static portrait for speech, thought, shout and listening. The engine supplies bubbles and listening dimming. All five speakers were reviewed at 480×900 and 390×844 in [the story captures](review/story/README.md#supporting-cast).

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

## Engine match-3 atlas and trickling

`data/match3.png`, registered by `lua/match3_skin.lua` and
`art/match3-atlas.json`, contains all match-board backgrounds, pieces, special
axes, blockers, selection/hint/guide frames, HUD icons and all five authored
states of each tool and Pause. The Christmas override additionally contains
its board portrait; Relic Rush includes all three piece packs and both scenes.
Existing source artwork and alpha are copied without modifying states. The
64px cubic radial light is the existing procedural transient effect, packed
in the same atlas and drawn with a per-view additive flag.

The engine's default resource skin is independent and embedded; both games
normally override it. `python3 tools/match3_atlas.py` reproduces the atlases and
registrations, and `make gen` embeds the default. No new game icon designs were
generated. FALL uses engine-authored simultaneous one-edge movement steps,
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
`python3 tools/pack_particles.py christmas-market` (from the repository root)
resizes them, turns brightness into alpha on white and writes `data/particles.png`
with its contract `lua/particle_skin.lua`. `lua/vfx.lua` draws them additively,
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

## Current-camera building paint pass

All registered buildings and decorations use the painted-v1 sources, normal sprite
and unchanged engine placement/lift/validity states documented in the
[building catalogue](building-catalogue.md) and
[review gallery](review/painted-buildings/current-camera/README.md).

## Placement alignment guides

`placement-guides` uses the shared `engine/city.c` renderer. While moving or
placing a building, other buildings show neutral cream outlines with dark
contrast edges around their occupied ground, including placement clearance.
The building in hand retains its green/red footprint; its original location
is omitted. Guides stay visible after release until Confirm/Cancel, then hide.
The guides use the existing camera and tile measurements; artwork, alpha,
footprints and collision rules are unchanged. No bitmap or ImageGen source is
added. Reproduce with the existing native-input hold/placement captures in the
[review](../../../docs/review/city-placement-guides/README.md).
