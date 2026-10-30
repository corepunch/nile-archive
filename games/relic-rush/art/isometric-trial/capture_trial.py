"""Preview the trial in the real game, with no edits to runtime assets.

Run from the repo root after building build/relic-rush. Only crops and uniform
resizing register authored artwork; no recolouring or perspective correction.
"""
from pathlib import Path
import os
import shutil
import subprocess
import sys
import tempfile
from PIL import Image

HERE = Path(__file__).resolve().parent
GAME = Path(os.environ.get('RR_ISO_GAME', str(HERE.parents[1]))).resolve()
ROOT = GAME.parents[1]
sys.path.insert(0, str(GAME / 'tools'))
from prepare_assets import isolate_sprite
OUT = HERE.parents[1] / 'docs/review/isometric-trial'
if 'max_height = 230' not in (GAME / 'lua/island.lua').read_text():
    raise SystemExit('Historical capture helper: set RR_ISO_GAME to a game checkout at 5ea3e97 '
                     '(before the city size/pivot API change), with its matching build/relic-rush. '
                     'The saved trial captures use that earlier API.')
OUT.mkdir(parents=True, exist_ok=True)

# Explicit crop boundaries avoid trusting the generator's requested cell layout.
COLUMNS = [(0, 340), (340, 640), (640, 962), (962, 1281), (1281, 1619)]
ROWS = [(140, 521), (521, 940)]

with tempfile.TemporaryDirectory(prefix='relic-isometric-') as tmp:
    tmp = Path(tmp)
    data, lua = tmp / 'data', tmp / 'lua'
    shutil.copytree(GAME / 'data', data)
    shutil.copytree(GAME / 'lua', lua)
    # This review-only overlay uses exact 2:1 diamonds for BOTH captures.
    view_path = lua / 'island_view.lua'
    view = view_path.read_text()
    view = view.replace('    c:draw(inp, app.clock())', '''    c:draw(inp, app.clock())
    for i = 1, c.count do
        local b = c.items[i]
        local p = c.cam:to_screen(b.pos)
        local w = c.defs[b.type + 1].width * .5 * c.cam.zoom
        local h = w * .5
        local pts = {p - vec2(w, 0), p - vec2(0, h), p + vec2(w, 0), p + vec2(0, h)}
        for k = 1, 4 do gfx.line(pts[k], pts[k % 4 + 1], 1, color(221, 255, 210, 220)) end
        gfx.circle(p, 3, color(255, 70, 190))
    end''')
    view_path.write_text(view)
    def shot(label):
        for size in ('480x900', '390x844'):
            subprocess.run([str(ROOT / 'build/relic-rush'), '--headless', '--mute', '--fresh',
                            '--lua', str(lua), '--data', str(data), '--showcase',
                            '--size', size, '--shot', str(OUT / f'{label}-{size}.png')], cwd=ROOT, check=True)
    shot('before')
    sheet = Image.open(HERE / 'buildings-2to1-v2.png').convert('RGBA')
    for i in range(10):
        x0, x1 = COLUMNS[i % 5]
        y0, y1 = ROWS[i // 5]
        # The game's existing importer extracts the largest sprite component,
        # preventing isolated leaves from a neighbouring cell leaking through.
        sprite = isolate_sprite(sheet.crop((x0, y0, x1, y1)))
        sprite.save(data / 'buildings' / f'{i}.png')
    island_path = lua / 'island.lua'
    island = island_path.read_text().replace('max_height = 230', 'max_height = 0')
    island = island.replace('sink = math.floor(w * .19), footprint = size2(math.floor(w * .4), math.floor(w * .19))',
                            'sink = w * .29, footprint = size2(w * .5, w * .25)')
    island_path.write_text(island)
    shot('trial')
print(OUT)
