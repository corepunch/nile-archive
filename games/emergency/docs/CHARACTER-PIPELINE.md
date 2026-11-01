# Rendering and editing Emergency's characters

This is how Emergency's workers and civilians get from Kenney's model to the game:
how the sprite sheets are rendered, and how to change characters, poses and
textures. [CHARACTERS.md](CHARACTERS.md) covers attribution.

```text
Kenney FBX + skins                  source/assets/kenney-characters/source/survivors/
   | build_rescue_characters.py     retarget, pose, add tools, bake the uniform
   v
rescue-characters.blend             the saved scene
   | render_rescue_characters.py    8 directions, every pose
   v
6,368 PNG frames                    build/kenney-character-frames/ (a cache, not committed)
   | pack_rescue_characters.py      trim, pack, write pivots
   v
29 atlases + kenney.sprites.xml     source/assets/kenney-characters/sprites/
   | games/emergency/tools/import_episode.py    keep what the game uses
   v
data/sprites.png + lua/emergency_art.lua        what actually ships
```

Normal game builds use only the last step's committed output. Nobody needs Blender
to build or run the game.

## Read this before changing anything

1. **Never render inside `games/emergency/source`.** `source/build` is a symlink to
   `reference/volcano-backup/build`, so that is where the frame cache lives. When
   the scene or the renderer changes, the renderer deletes its whole cache with
   `shutil.rmtree`. In place, that would destroy 6,368 preserved backup frames.
   Always use the [work copy](#1-make-a-work-copy).
2. **`source/` is hash-checked.** `preserve_source.py --verify` compares every
   preserved file with `docs/source-preservation.json`. `make test` and CI don't run
   it, so a mismatch goes unnoticed until someone runs it by hand. Any change you
   copy back needs [its hashes refreshed](#6-refresh-the-preservation-hashes).
3. **Editing a texture PNG doesn't change the scene.** The scene renders the copies
   packed inside the `.blend`. In the committed scene those copies remember paths
   under the deleted `volcano-sdl2` checkout, so `reload()` logs "Keeping packed
   image" and keeps the old pixels. Use a [rebuild or re-bake](#recolour-or-redraw-the-uniform-or-hard-hat),
   or the [hand-paint recipe](#paint-the-atlas-or-a-civilian-skin-by-hand).
4. **A rebuild replaces the saved scene.** Anything edited only in the Blender window
   is lost. Put lasting changes in the tools.

## Where everything is

Paths are relative to `games/emergency/`.

| What | Where |
|---|---|
| Saved scene | `source/assets/kenney-characters/blender/rescue-characters.blend` |
| Kenney's download, FBX files, skins and SVGs | `source/assets/kenney-characters/source/` |
| Uniform atlas | `source/assets/kenney-characters/textures/rescue-worker.png` |
| Scene builder, poses, tools, camera, lights | `source/tools/build_rescue_characters.py` |
| Uniform painting and hard hat | `source/tools/texture_rescue_uniform.py` |
| Run and carry motion | `source/tools/animate_rescue_run.py` |
| Renderer | `source/tools/render_rescue_characters.py` |
| Packer and sprite-name mapping | `source/tools/pack_rescue_characters.py` |
| Atlases, `catalog.json`, `kenney.sprites.xml` | `source/assets/kenney-characters/sprites/` |
| Review sheets | `source/assets/kenney-characters/previews/` |
| Original animation names, frame counts and FPS | `source/assets/kenney-characters/retail-worker-actions.json` |
| Import into the game | `tools/import_episode.py` |
| Shipped sprites | `data/sprites.png`, `lua/emergency_art.lua` |

`reference/volcano-backup/build/workers-before-outfit.blend` is a snapshot from before
the blue uniform. Nothing uses it. It is in the git-ignored `reference/` folder, so it
exists only on this machine.

[source/docs/rendering-characters.md](../source/docs/rendering-characters.md) is the
original guide, kept as history. It predates the move into this repository: its
"repository root" means `games/emergency/source`, and its render commands run in place,
which is now unsafe. Where the two differ, follow this page.

## What's in the scene

The scene has 21 objects in one flat collection, 18 actions and 3 packed images.

| Object | Notes |
|---|---|
| `RescueWorker_Rig` | 58-bone armature; custom property `character`: `0` worker, `1` male, `2` female |
| `RescueWorker_Body` | Kenney's body, unchanged: 804 vertices, 1,604 triangles, with an added `RescueAtlas` UV layer |
| `Hard hat` | 62 vertices, 120 triangles, follows `Head` |
| `Civilian_Male`, `Civilian_Female` | The same mesh with Kenney's skins |
| `Hammer`, `axe`, `pickaxe` handles and heads | Follow `RightHand` |
| `Supply sack`, `Sack tie` | Follow `Chest` |
| `Hand radio`, `Radio antenna` | Follow `RightHand` |
| `Life ring` | Follows `Hips`; shown for civilians too |
| `Direction_Pivot` | Parent of every character part; rotating it turns the character |
| `Sprite_Camera` | Orthographic, scale 6.2, at `(0, -10, 7.8)` looking at `(0, 0, 1.75)` |
| `Key`, `Fill`, `Rim` | Area lights at 650, 350 and 450 W |

Each action keys `gear_*` properties on the rig, and drivers on each part read them
together with `character`. So selecting an action shows the right tool for you.

The civilians' red skin and stained shirts come from Kenney's `survivorFemaleA` and
`survivorMaleB` skins. They aren't a rendering fault.

### Actions

| Action | Frames | Prop | Sprite names | In the game today |
|---|---:|---|---|---|
| Stand | 32 | | `worker_wait0`, `worker_wait2`, `*_idle0` | `worker_wait0`, `man_idle0`, `wman_idle0` |
| Look | 32 | | `worker_wait1`, `*_idle1` | No |
| Run | 16 | | `worker_run0..7`, `*_run0..7` | Yes, all three characters |
| Carry | 16 | sack | `worker_bag0..7` | No |
| Chop | 24 | axe | `worker_wood0..7` | Yes |
| Gather | 24 | | `worker_gather0..7` | No |
| Hammer | 24 | hammer | `worker_srepair0..7` | Yes |
| Repair | 24 | hammer | `worker_repair0..7` | Yes |
| Pickaxe | 24 | pickaxe | `worker_pick0..7` | Yes |
| Valve | 32 | | `worker_tap0..7` | No |
| Call | 32 | radio | `worker_call0..7` | No |
| Pet | 24 | | `worker_pet0..7` | Yes |
| Sit | 32 | | `worker_sit0..1` | No |
| Ill, Alert | 32 | | `*_ill`, `*_ill_alert` | No |
| Sink | 32 | ring | `*_sink` | No |
| Jump | 12 | | None; rendered and packed only | No |
| KenneyIdle | 32 | | None; reference motion, never rendered | No |

Workers are rendered for every action except KenneyIdle. Civilians are rendered for
Stand, Look, Run, Ill, Alert and Sink. That makes 29 clips: 17 worker and 6 each for
male and female.

## Render the sheets

Run these from the repository root. On macOS:

```sh
export BLENDER=/Applications/Blender.app/Contents/MacOS/Blender
```

You need Blender 5.2 or newer, and Python 3 with Pillow.

### 1. Make a work copy

```sh
mkdir -p build/emergency-characters/assets build/emergency-characters/build
cp -cR games/emergency/source/tools build/emergency-characters/tools
cp -cR games/emergency/source/assets/kenney-characters build/emergency-characters/assets/kenney-characters
cp -cR reference/volcano-backup/build/kenney-character-frames build/emergency-characters/build/kenney-character-frames
cd build/emergency-characters
```

`cp -c` is a macOS copy-on-write clone; on Linux use `cp -R`. The last copy is only a
head start, and a fresh clone won't have it because `reference/` isn't in Git. The
renderer then creates every frame. `make clean` deletes the top-level `build/` folder,
work copy included, so copy your work back before running it.

The steps below edit and render here, in `build/emergency-characters`.

### 2. Make your change

Use [the recipes](#change-something) below. To re-render without changes, skip this.

### 3. Render

```sh
"$BLENDER" -b assets/kenney-characters/blender/rescue-characters.blend --python tools/render_rescue_characters.py
```

The scene and renderer are fingerprinted. If either changed, the whole cache is
deleted and rendered again, 6,368 frames in all. That took about 21 minutes on the
CPU of a Mac that was busy with other work. If neither changed, existing frames are
skipped and this takes a few seconds. An
interrupted render resumes from where it stopped, but it checks only that each file
exists, so delete any half-written PNG first.

To look at poses before a full render, this renders four poses of each clip, facing
south-east:

```sh
cat > build/preview.py <<'PY'
from pathlib import Path
script = Path('tools/render_rescue_characters.py').resolve()
scope = {'__file__': str(script), 'RESCUE_PREVIEW_ONLY': True}
exec(compile(script.read_text(), str(script), 'exec'), scope)
PY
"$BLENDER" -b assets/kenney-characters/blender/rescue-characters.blend --python build/preview.py
```

Preview mode leaves an incomplete cache, so finish with the full render before packing.

If you changed only one action and have confirmed nothing else is affected, you can
keep the other clips. Delete that action's folders under
`build/kenney-character-frames/` (for example `worker-Run`, `male-Run`, `female-Run`),
then stamp the cache so the renderer keeps the rest:

```sh
python3 - <<'PY'
from pathlib import Path
import hashlib
blend = Path('assets/kenney-characters/blender/rescue-characters.blend').read_bytes()
tool = Path('tools/render_rescue_characters.py').read_bytes()
Path('build/kenney-character-frames/fingerprint.txt').write_text(hashlib.sha256(blend + tool).hexdigest())
PY
```

Anything that changes how every clip looks (texture, mesh, lights, camera, rig) needs
the full render. Carry is built from Run, so a change to Run means deleting
`worker-Carry` as well.

#### Settings

| Setting | Value |
|---|---|
| Engine | Cycles, 12 samples, denoised, transparent film |
| Frame size | 128×160; 160×160 for Hammer, Repair, Chop and Pickaxe |
| Directions | `0=E, 1=NE, 2=N, 3=NW, 4=W, 5=SW, 6=S, 7=SE` |
| Turning | `Direction_Pivot.rotation_euler.z = pi/2 + direction*pi/4` |
| Output | `build/kenney-character-frames/<character>-<Action>/<direction>-<index>.png`, zero-based |
| Loops | Frame count excludes the matching end frame, so a 16-frame Run keys 17 |

Keep `use_persistent_data = False`. Reusing Cycles state once produced near-black
silhouettes with valid alpha.

### 4. Pack

```sh
python3 tools/pack_rescue_characters.py --pack --declare
```

`--pack` writes the atlases, `sprites/catalog.json` and the review sheets. It trims each
frame, keeps the ground pivot, and stops with an error on a wrong size, an empty frame,
a frame touching its edge (clipped) or a nearly black one (unlit). A clipped pose usually
needs adding to the 160-wide list in the renderer.

`--declare` writes `sprites/kenney.sprites.xml`, which maps sprite names to frames. It
keeps each original animation's frame count and FPS from `retail-worker-actions.json`
by repeating or skipping poses. Civilian clips not in that file use their own counts, at
10 FPS for Stand and Look and 15 FPS otherwise. It also picks a direction for names that
have none: `wait0`, `wait1` and `idle*` face south, `wait2` faces south-east, and `ill`,
`ill_alert`, `sink` and `sit0` face south-east.

Check `assets/kenney-characters/previews/worker-actions.jpg` and
`worker-directions.jpg`. The first shows four poses of each worker action, the second
Stand, Run and Hammer in all eight directions. `rescue-worker.gif` shows them moving.
Neither sheet covers civilians, so open their atlases in `sprites/` if you changed them.

### 5. Copy back and import into the game

From the repository root:

```sh
cd ../..
rsync -a --exclude='*.blend1' --exclude=.DS_Store build/emergency-characters/assets/kenney-characters/ games/emergency/source/assets/kenney-characters/
rsync -a --include='*rescue*' --exclude='*' build/emergency-characters/tools/ games/emergency/source/tools/
python3 games/emergency/tools/import_episode.py
python3 games/emergency/tools/check_assets.py
```

`import_episode.py` regenerates `data/sprites.png`, `data/pets-to-replace.png`,
`lua/emergency_art.lua`, `lua/emergency_levels.lua`, the five backgrounds and
`docs/asset-catalog.json`. With unchanged sources all of them come out byte-identical,
so `git status` shows only what your change touched. It needs the pet art in
`reference/rescue-team/`, so it can't run from a fresh clone. It copies frames at
scale 0.5 and removes duplicates.

The game ships only the animations in the `wanted` list in `import_episode.py`. Add a
name there if the game starts using another one.

### 6. Refresh the preservation hashes

This records your intended changes to `source/`, so `--verify` still protects
everything else:

```sh
python3 - <<'PY'
from pathlib import Path
import hashlib, json
manifest = Path('games/emergency/docs/source-preservation.json')
data = json.loads(manifest.read_text())
for entry in data['entries']:
    path = Path(entry['destination'])
    if entry['kind'] == 'file' and entry['destination'].startswith('games/emergency/source/') and path.is_file():
        sha = hashlib.sha256(path.read_bytes()).hexdigest()
        if sha != entry['sha256']:
            entry.update(sha256=sha, bytes=path.stat().st_size)
            print('updated', entry['destination'])
manifest.write_text(json.dumps(data, indent=2) + '\n')
PY
python3 games/emergency/tools/preserve_source.py --verify
```

Read the printed list; it should contain only files you meant to change. The original
versions stay in Git and in `reference/volcano-backup/volcano-history.bundle`. Files new
to `source/` aren't in the manifest, and `--verify` doesn't check them.

### 7. Check it in the game

```sh
make
make test
SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy ./build/emergency --fresh --smoke --mute --size 456x342
./build/emergency --fresh --mute --size 1368x1026 --level 3 --preview repaired --shot build/emergency-check.png
make shots
```

The preview stage plays real jobs, so workers appear at work. Look at the capture
closely, zooming in on the characters. Pull requests need before-and-after screenshots
at 1200×900 and 1368×1026, and new art must be catalogued in [ASSETS.md](ASSETS.md); see
the repository's `AGENTS.md`.

## Change something

| You want to | Do this | Then render |
|---|---|---|
| Recolour or redraw the uniform or hard hat | [Edit the paint, then re-bake](#recolour-or-redraw-the-uniform-or-hard-hat) | Full |
| Change a tool's or the sack's colour | [Edit the palette](#change-a-tool-colour) | Full |
| Paint on the atlas or a skin by hand | [Hand-paint recipe](#paint-the-atlas-or-a-civilian-skin-by-hand) | Full |
| Change a pose or its speed | [Edit the pose](#change-a-pose) | That action, or full |
| Add a tool | [Add a prop](#add-a-tool-or-prop) | Full, or new clip only |
| Add an animation | [Add an action](#add-an-action) | New clip only |
| Move the camera or lights, or resize frames | [Edit the builder](#change-the-camera-lights-or-frame-size) | Full |
| Change a name's frame count or FPS | Edit `retail-worker-actions.json` | None; pack with `--declare` |

### Rebuild or re-bake?

| | Rebuild | Re-bake |
|---|---|---|
| What it does | Recreates the whole scene from Kenney's files and the tools | Repaints the atlas in the saved scene |
| Keeps edits made in the Blender window | No | Yes |
| Cleans up stale paths and old materials | Yes | No; adds another set of `Uniform paint` materials |
| Time | About 4 seconds | Seconds |

Use a rebuild unless the saved scene holds something the tools don't. It is the simpler
choice, and the tools do describe the current scene: after a rebuild, three sampled
worker frames differed from the cache by at most one colour level out of 255. Sampled
civilian frames differ from the cache in edge colour only, with or without a rebuild,
because the cached ones were reconstructed from their atlases. A fresh render still
packs into civilian atlases identical to the committed ones.

```sh
"$BLENDER" -b --factory-startup --python tools/build_rescue_characters.py
```

A rebuild also rewrites `actions.json`, `textures/rescue-worker.png` and
`textures/uniform.json`, and it leaves a `.blend1` backup that the copy-back step skips.

### Recolour or redraw the uniform or hard hat

The uniform is painted by shader nodes in `bake_uniform()` in
`tools/texture_rescue_uniform.py`, then baked into the atlas. Colours are **linear**
RGBA, not sRGB hex, so `(.012, .095, .38)` appears as a mid blue in the PNG.

| Change | Where in `bake_uniform()` |
|---|---|
| Shirt and trousers | `blue` |
| Seams, collar, cuffs, knee bands | `seam` |
| Hard hat | `yellow`, then the two darker values for its ridge and brim |
| Belt | `leather`, and the pouch colour in the `pouch` line |
| Boots and hands | `black` from the palette, and the skin tone, split at height `z > 1.0` |
| Pockets, placket, belt, knee band shapes | The `p.band(...)` ranges |

Shapes are drawn in the character's rest-pose coordinates: `p.z` is height (the belt is
near 1.5), `p.y` below zero is the front, and `ax` is distance from the centre line.
Which paint a polygon gets depends on its strongest bone group: `Head` is face, `Hand`,
`Foot` and `Toes` are boots and hands, `Leg` and `Hips` are trousers, `Arm` and
`Shoulder` are sleeves, and the rest is shirt.

Keep the original body. Paint details into the texture rather than adding clothing
geometry; the body stays at 804 vertices.

Then rebuild. To keep edits made in the Blender window instead, re-bake with this script:

```sh
cat > build/rebake.py <<'PY'
import importlib, sys
from pathlib import Path
import bpy

root = Path.cwd()
sys.path.insert(0, str(root / 'tools'))
import texture_rescue_uniform
importlib.reload(texture_rescue_uniform)

parts = [o for o in bpy.data.objects if o.get('rescue_worker_part')]
# Keep this order: it sets each swatch's place in the atlas.
palette = dict(orange=(.95, .19, .025, 1), navy=(.025, .065, .11, 1), silver=(.8, .87, .84, 1),
               lime=(.78, .9, .04, 1), black=(.025, .032, .035, 1), steel=(.36, .45, .5, 1),
               wood=(.45, .22, .075, 1), canvas=(.58, .43, .21, 1), red=(.75, .035, .025, 1))
texture_rescue_uniform.bake_uniform(bpy.data.objects['RescueWorker_Rig'], bpy.data.objects['RescueWorker_Body'],
    bpy.data.objects['Hard hat'], parts, root / 'assets/kenney-characters', palette)
bpy.data.images['Rescue worker atlas'].filepath = '//../textures/rescue-worker.png'
bpy.ops.wm.save_as_mainfile(filepath=str(root / 'assets/kenney-characters/blender/rescue-characters.blend'))
PY
"$BLENDER" -b assets/kenney-characters/blender/rescue-characters.blend --python build/rebake.py
```

### The uniform atlas

`textures/rescue-worker.png` is 1024×1280.

| Area | Holds |
|---|---|
| Top 1024 rows | Kenney's body layout, unchanged: face and hair, shirt and sleeves, trousers, hands, boots |
| Bottom-left 256×256 | Hard hat, seen from above |
| Bottom row, from x=256, 128 px each | orange, navy, silver, lime, black, steel |
| Row above it | wood, canvas, red, then three free slots |

Tools are flat colours: each of their UVs points at one swatch.

### Change a tool colour

Tools take their colour from the `material(...)` definitions in
`tools/build_rescue_characters.py`, such as `steel` and `wood`. The bake passes these to
`bake_uniform()` as the palette, and each tool is matched to the nearest swatch. Edit the
value, rebuild, and keep `build/rebake.py`'s copy of the palette in step if you use it.

The palette has room for 12 swatches and uses 9. To add a colour, add a `material(...)`,
add it to the end of the `palette` dict passed to `bake_uniform()`, and give it to the
tool.

### Paint the atlas or a civilian skin by hand

The worker's atlas and the two civilian skins are PNGs you can paint on. Kenney's SVG
sources are in `source/survivors/Skins/Source/`. Edit the PNG in the work copy, then run
this to replace the packed copy. Plain `reload()` isn't enough, as noted at the top; the
image has to be unpacked first.

```sh
cat > build/repack.py <<'PY'
import bpy

for name, path in {
    'Rescue worker atlas': '//../textures/rescue-worker.png',
    'survivorMaleB.png': '//../source/survivors/Skins/survivorMaleB.png',
    'survivorFemaleA.png': '//../source/survivors/Skins/survivorFemaleA.png',
}.items():
    image = bpy.data.images[name]
    image.unpack(method='REMOVE')
    image.filepath = path
    image.reload()
    image.pack()
bpy.ops.wm.save_mainfile()
PY
"$BLENDER" -b assets/kenney-characters/blender/rescue-characters.blend --python build/repack.py
```

- **A rebuild or re-bake overwrites paint on `rescue-worker.png`.** Keep the change in
  `bake_uniform()` if it has to last.
- The worker's face is baked from `survivorMaleB.png`. Painting that skin changes the male
  civilian at once, but the worker's face only after a rebuild or re-bake.
- Keep the atlas at 1024×1280 and the skins at 1024×1024, and leave the layout alone:
  the UVs depend on it.
- Changing Kenney's skins means the files no longer match the
  `source/kenney_animated-characters-survivors.zip` download they came from, so record
  the change in [ASSETS.md](ASSETS.md).

### Change a pose

Poses are generated one frame at a time in `tools/build_rescue_characters.py`, in the
long `if name == ...` chain. `t` runs through one full cycle (0 to 2π) and `p` runs from
0 to 1. The helpers are:

| Helper | Does |
|---|---|
| `arm(side, upper, lower)` | Points the upper and lower arm along world directions |
| `aim(bone, direction)` | Points any bone along a world direction |
| `rotate_world(bone, axis, angle)` | Turns a bone around a world axis, in radians |
| `root_drop(amount, forward)` | Lowers the hips |
| `kneel()` | The shared kneeling legs |
| `tool_grip(direction)` | Points the right hand, and so the tool, along a direction |

The character faces −Y in these directions, so `(0, -1, 0)` is forward and `(0, 0, 1)`
up. To change an action's speed, change its count in the `counts` dict, then rebuild.

Run and Carry work differently. `enhance_run()` and `carry_arms()` in
`tools/animate_rescue_run.py` add the bounce, recoil and arm drive after retargeting.
Don't run `enhance_run()` twice on the same action. In the Blender window,
`reduce_head_swing(rig, factor)` scales the current head swing, and `rebuild_carry(rig)`
must follow any edit to Run so that Carry inherits it. Kenney's clips have different rest
poses, so keep the builder's retargeting rather than copying tracks between rigs.

To edit by hand in the Blender window, select `RescueWorker_Rig`, assign a `Rescue_*`
action **and** its action slot, and pose. Evaluate the action switch before assigning
bone matrices, or the first update replaces your pose with the old keys. Save, and remember
that the next rebuild discards the edit unless you also add it to the tools.

### Add a tool or prop

In `tools/build_rescue_characters.py`, next to the other props:

```python
tool_cube('Flag pole', (0, .19, .5), (.05, .05, 1.1), wood, 'flag')
tool_cube('Flag cloth', (0, .45, .9), (.03, .5, .32), red, 'flag')
```

`tool_cube(name, location, size, material, kind)` attaches to `RightHand`, using that
bone's coordinates. Use `cube(..., bone='Chest', prop='flag')` for another bone. Then
list the kind against an action in the `visibility` dict: `Wave=['flag']`. Every other
step is automatic, including the `gear_flag` property, drivers and swatch. Props are hidden
on civilians, except `ring`, which `visibility_driver` handles as a special case.

### Add an action

This example adds `Wave`. Change these in the work copy:

1. **`tools/build_rescue_characters.py`:** add `Wave=8` to `counts` and a pose branch
   before `key_pose(frame)`:
   ```python
   elif name=='Wave':
       arm('Right',(-.6,-.1,.8),(.05+.25*math.sin(t),-.15,1))
       tool_grip((0,-.15,1))
   ```
2. **`tools/render_rescue_characters.py`:** add `'Wave'` to the worker job list, and to
   the 160-wide list if the pose reaches far from the body.
3. **`tools/pack_rescue_characters.py`:** add `wave='Wave'` to `actions` in `mapping()`.
4. **`retail-worker-actions.json`:** add `worker_wave0` to `worker_wave7`, for example
   `{"animation": "worker_wave0", "frames": 8, "fps": 15}`. The packer only declares
   names in this file.
5. **`tools/import_episode.py`** (in `games/emergency/tools/`, not the work copy): add
   `'wave'` to the action list that fills `wanted`.
6. **The game:** the sprite is now `worker_wave<direction>`. For a job, set
   `action='wave'` on its definition in `lua/emergency_sim.lua`; `lua/main.lua` picks the
   sprite with `'worker_'..action..direction`.

Rebuild, keep the other clips by stamping the cache as in [Render](#3-render), then
render and pack. Stamping is safe for the other clips only if the rest of the scene is
unchanged.

### Change the camera, lights or frame size

The camera and lights are near the end of `tools/build_rescue_characters.py`. Frame sizes
are at the top of the job loop in `tools/render_rescue_characters.py`, and the packer
reads them from `render-manifest.json`. The game draws sprites at scale 0.5, so frames
are rendered at twice their on-screen size; keep `texture_scale` and the `.5` in
`import_episode.py` in step if you change that. The camera angle has to match the painted
level backgrounds, so check it against a real level.

## Using the Blender MCP server

Running Blender directly, as above, needs no extension. The older route sends the same
scripts to a dedicated background Blender and gives the same results:

```sh
"$BLENDER" --background assets/kenney-characters/blender/rescue-characters.blend --online-mode --command blender_mcp --host 127.0.0.1 --port 9877
python3 tools/blender_mcp.py tools/render_rescue_characters.py
```

Stop that server when you're done, and restart it after saving the scene from elsewhere,
because it keeps its own loaded copy. The `*_for_cli` tools in an agent's Blender MCP
connection need `BLENDER_PATH` set to the executable.

## Troubleshooting

| Symptom | Cause and fix |
|---|---|
| `Image ... not available. Keeping packed image` | Normal for the committed scene: see [point 3](#read-this-before-changing-anything). The packed pixels still render. A rebuild removes it |
| A texture edit doesn't show | The packed copy wasn't refreshed. Rebuild, re-bake or run `build/repack.py` |
| `clipped character` from the packer | A pose reaches the frame's edge. Add the action to the 160-wide list and render it again |
| `unlit or missing-texture render` | Delete the frame and render again; check `use_persistent_data` is off |
| `character atlas changed without repacking` | An atlas was edited after packing. Run `--pack --declare` |
| `unmapped character animation` | A name in `retail-worker-actions.json` has no entry in `mapping()` |
| `Asset changed without updating its catalog` | Run `import_episode.py` |
| `File mismatch` from `--verify` | A preserved file changed. Refresh the hashes if it was intended; otherwise restore it from Git |
| Frames disappeared from `reference/` | The renderer ran in place. Restore from another copy; `--verify` will show which files are gone |
| Tool or head floating away from the body | The action was switched without its slot, or pose matrices were set before the switch was evaluated |

## How this was checked

On 31 October 2026, on Blender 5.2.2 and in isolated clones, not the real tree:

- Packing the existing frames and importing them reproduced every committed atlas,
  review sheet, `data/` file, `emergency_art.lua`, `emergency_levels.lua` and the catalog
  byte for byte.
- The direct and MCP render routes both found the cache complete and rewrote an
  identical `render-manifest.json`.
- A rebuild reproduced `actions.json` and `rescue-worker.png` byte for byte.
- A red hard hat went through the whole pipeline, running this page's commands as
  written in a full clone of the repository: work copy, rebuild, preview, pack, copy back,
  import, hash refresh and `--verify`. The render step had a finished cache by then,
  from a full 6,368-frame render of the same colours started from a re-bake. Only worker
  atlases changed, the backup frames stayed intact, the smoke test passed and the hat
  appeared in `--preview repaired`.
- The Wave and flag examples above went through build, render, pack and import into
  `emergency_art.lua`. They weren't played in the game: nothing in the campaign calls them.
- The hand-paint recipe changed the worker's hat and the male civilian's hair, which
  rendered correctly and survived reopening the scene. An edit to the female skin reached
  the packed copy but wasn't rendered.

Not checked: the camera, light and frame-size changes, step 7's `make`, `make test` and
`make shots` against a changed character, and editing poses by hand in the Blender window.
