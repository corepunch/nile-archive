#!/usr/bin/env python3
"""Writes docs/island-catalogue.md from catalogue.json, so the list has one source."""
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "..", "docs", "island-catalogue.md")
rows = json.load(open(os.path.join(HERE, "catalogue.json")))
SECTIONS = (("wonder", "Wonders (the story campaign)"), ("building", "Income buildings"), ("tree", "Trees"), ("bush", "Bushes"),
            ("flower", "Flowers"), ("statue", "Statues and monuments"), ("water", "Water features"),
            ("garden", "Garden furniture and structures"), ("camp", "Camp props"), ("animal", "Animals"), ("rock", "Rocks"))
CHARM_PER_GOLD = 5   # one charm per this much gold, the same ratio for everything, as June's Journey does

decor = [r for r in rows if r[2] not in ("wonder", "building")]
tiles_one_each = sum(r[3] * r[4] for r in rows)
lines = [f"""# Island catalogue

Proposed content for Relic Rush's first release: {len(rows)} assets. **Proposal, not runtime content.** Nothing here
is wired into the game yet. Prices, unlocks and charm are first-pass numbers to tune in play.

The models are procedural Blender geometry in `art/isometric-blender/build_scene.py`, in the casual block style, on
the 2:1 grid of `docs/BUILDINGS.md`. They are review blockouts, not finished runtime sprites. The original `art/buildings.png`
and runtime sprites are unchanged.

## What June's Journey does, and what we take from it

From the community [June's Journey Wiki](https://junes-journey.fandom.com/wiki/June%27s_Journey_Wiki) (CC-BY-SA;
player-maintained, so some numbers may be out of date). Its pages cover only part of the game's current content.

| June's Journey | Detail | Relic Rush |
|---|---|---|
| [Buildings](https://junes-journey.fandom.com/wiki/Buildings) | 28 3×3 income buildings and a 4×4 Estate, unlocked by stars, 7 to 1836 | 26: 10 wonders and 16 income buildings, 2×2 to 4×4 |
| [Landmarks](https://junes-journey.fandom.com/wiki/Landmarks) | Five fixed story restorations | The wonders fill this role, but the player places them |
| [Decorations](https://junes-journey.fandom.com/wiki/Decorations) | About 120 permanent items, almost all 1×1 or 2×2, unlocked in batches | {len(decor)}, all 1×1 or 2×2 |
| Flowers | Every coin decoration gives the same flowers per coin (1 per 30) and flowers raise the level | Charm, one per {CHARM_PER_GOLD} gold, the same for everything |
| [Shop](https://junes-journey.fandom.com/wiki/Shop) | Tiles, Permanent Decorations, Buildings, Seasonal Sets, Limited Edition | Tabs by the sections below |
| [Seasonal sets](https://junes-journey.fandom.com/wiki/Tropical_Paradise_Set_(2021)) | Monthly themed sets, such as Tropical Paradise | Later: not needed for the first release |
| [Gift bushes](https://junes-journey.fandom.com/wiki/Bushes) | Placed on friends' islands | Later: needs a social layer |

Left out on purpose: tiles, paths, roads, fences and walls that connect, because of their joining logic. Also train
items, which are tied to June's Journey's setting. Names here are our own; the "Closest in June's Journey" column
is only a reference for scale and role. **Don't copy their art or names into the game.**

## Rules

- **Footprints** are whole tiles. `w` runs along the front-left side, `h` along the front-right. The Blender pivot is the
  footprint's ground centre.
- **Wonders and buildings** stand on a slab exactly the size of their footprint. Decorations stand straight on the grass.
- **Stars** is the number of stars needed to unlock. The six regions open at 0, 6, 9, 15, 21 and 27 stars today, and these thresholds follow them.
- **Wonder sizes** are the ones in the Blender scene. Five differ from `lua/island.lua`: gateway 4×2 (game 3×2), lodge 3×3 (3×2),
  archive 3×3 (2×2), fountain 3×3 (2×2), temple 4×4 (3×3). Wonder prices are the gold part of today's costs.

## Engine work this list needs

- **Clearance per type.** `city.clearance` is one value for all types. At today's `size2(1, 1)` a 1×1 bush takes 2×2
  tiles, so decorations can't sit together. Decorations need 0.
- **More placed items.** `CITY_MAX` is 160. One of every asset uses {len(rows)}, leaving little room to repeat
  decorations, which is most of what players do in this genre.
- **Not one of each, in order.** `island_place_next` treats `c.count` as the next wonder. Decorations need a shop that buys any unlocked
  type, any number of times.
- **Charm and shop.** Neither exists yet: a charm total, shop tabs, unlock filtering.
- **Space.** The lawn is about 1146 tiles. One of each covers {tiles_one_each} before clearance, so there's room to repeat.

"""]
for cat, title in SECTIONS:
    items = [r for r in rows if r[2] == cat]
    lines.append(f"## {title} ({len(items)})\n\n")
    lines.append("| Asset | Size | Gold | Stars | Charm | Closest in June's Journey |\n|---|---|---:|---:|---:|---|\n")
    for key, name, _, w, h, gold, stars, like in items:
        lines.append(f"| {name} | {w}×{h} | {gold} | {stars if cat != 'wonder' else 'story'} | {gold // CHARM_PER_GOLD} | {like} |\n")
    lines.append("\n")
lines.append("""## Reproduce

Open Blender with its MCP add-on, then run `build_scene.py` inside it with `runpy.run_path`, and save the scene. From `art/isometric-blender/`:

```sh
/Applications/Blender.app/Contents/MacOS/Blender -b relic_rush_buildings.blend -S RelicRushIso -f 1
python3 annotate.py                # overlays footprints from the grid formula and measures them
python3 make_catalogue_doc.py      # regenerates this page from catalogue.json
```
""")
open(OUT, "w").write("".join(lines))
print(len(rows), tiles_one_each)
