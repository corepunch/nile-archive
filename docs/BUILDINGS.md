# Building specs

City buildings stand on an isometric grid of whole tiles. Every building
type says how many tiles it covers, which pixel of its sprite is the ground
centre it stands on, and how wide its base is in that sprite. The engine
derives the drawing scale, the snapping, the collision and the green/red
footprint from those three numbers, so they must match the art.

## The tile

`city.tile` is a tile's half extents in world units, 2:1 (default
`size2(32, 16)`, a 64 × 32 diamond). Set it before `c:init`: drawn sizes
are derived from it. Each game picks one tile for all its buildings:

| Game | `city.tile` | A tile in world units |
|---|---|---|
| Nile Archive | `size2(24, 12)` | 48 × 24 |
| Relic Rush | `size2(40, 20)` | 80 × 40 |

## A building

```lua
{name = "Artisan workshop", sprite_path = "buildings/2.png",
 size = size2(3, 2),        -- tiles: 3 along the front-left side, 2 along the front-right
 pivot = vec2(144, 246),    -- sprite pixel of the footprint's ground centre
 base_width = 278,          -- sprite pixels from the footprint's left corner to its right one
 cost = purse(100, 25, 15)}
```

- **`size`**, whole tiles. `w` runs along the front-left side (from the left
  corner down to the front corner), `h` along the front-right side (from the
  front corner up to the right corner). 2 × 2, 3 × 2 and 3 × 3 are typical.
  Pick the sides from the art: the ratio of the base's front-left to
  front-right edge, rounded to whole tiles.
- **`pivot`**, sprite pixels: the centre of the base on the ground, halfway
  between its left and right corners. It is the building's zero: `building.pos`
  is this point in the world, and the sprite is drawn so the pivot lands on
  it. It is not the bottom of the image: the front corner and anything in
  front of the base (steps, plants, a rug) hang below it.
- **`base_width`**, sprite pixels between the base's left and right corners.
  The engine scales the sprite so that width covers `size.w + size.h` tile
  half widths, so the drawn base matches the footprint exactly. `height`
  follows from it; don't set it by hand.

A building with no `size` falls back to a circle of `city.spacing` and a
sprite drawn `height` tall, standing on its bottom centre.

## How the grid uses it

- **Snapping.** `c:snap(p, type)` puts the footprint on whole tiles: a side
  with an odd number of tiles centres on a tile, an even one on a tile edge.
  Taps, drops and confirmations all snap; a dragged ghost follows the finger
  and snaps when let go.
- **Collision.** Footprints are rectangles in tile space: they may share an
  edge but not overlap. Every covered tile's centre and the footprint's
  corners must be open, buildable land.
- **Drawing.** The ghost's footprint is the parallelogram of its tiles with
  the tile lines inside, green when it fits and red when it doesn't.

## Measuring a sprite

```sh
python3 tools/footprint.py games/relic-rush/data/buildings/2.png --overlay /tmp/base.png
```

The script fits the base's lower V (slopes of ±½ on a 2:1 grid) to the
sprite's silhouette and prints `pivot`, `base_width` and the side ratio.
Plants or props below the base can fool the fit; then read the corners off
the image and pass them: `--bottom X,Y` (the front corner), `--left X`,
`--right X`. Open the overlay and check that the drawn diamond sits on the
base.

Then check it in the game. `--footprints` draws every building's footprint
and pivot over its sprite:

```sh
./build/relic-rush --headless --mute --fresh --size 480x900 --showcase --footprints --shot fp.png
./build/nile-archive --headless --mute --fresh --size 1200x900 --screen island --footprints --shot fp.png
```

Each diamond should outline the building's base, with the pivot dot in the
middle of it.

## Art for new buildings

Draw buildings on the same 2:1 isometric grid as the map, the base a clean
diamond or parallelogram whose sides follow the tile directions, cropped
tightly with a transparent background. Keep plants and props inside the
footprint where possible. Anything that hangs outside it overlaps the
neighbours, because footprints may touch.
