"""Register Kenney and Cradle of Rome 2 particle frames in the match-3 atlas."""

from pathlib import Path

from PIL import Image

# Frame suffix: (Kenney file, packed size).
SPRITES = {
    'shock': ('circle_03', 256),    # bomb double shockwave
    'flash': ('light_01', 256),     # bomb bloom
    'burst': ('star_09', 256),      # bomb centre flare
    'ring': ('circle_02', 128),     # impact ring
    'glint': ('star_07', 128),      # impact and blast twinkle
    'twinkle': ('star_06', 128),    # spark particles
    'streak': ('trace_06', 128),    # shard particles, long axis vertical
}
ROME_HINT = Path(__file__).resolve().parents[1] / 'engine/art/match3/rome-2-cell-hint'
# Kenney smoke puffs (CC0) for the dust of breaking floor layers. Their grey
# fringe is the billow shading, so colour and alpha are kept, alpha-blended.
SMOKE = Path(__file__).resolve().parents[1] / 'engine/art/match3/kenney-smoke'
SMOKE_PUFFS, SMOKE_SIZE = ['whitePuff00', 'whitePuff04', 'whitePuff08', 'whitePuff12'], 128


def registered(root):
    frames, sources = {}, {}
    for name, (file, size) in SPRITES.items():
        key = f'fx-{name}'
        path = root / 'art/particles/kenney' / f'{file}.png'
        with Image.open(path) as source:
            alpha = source.convert('L').resize((size, size), Image.Resampling.LANCZOS)
        # White with the source brightness as alpha retains the additive glow.
        sprite = Image.new('RGBA', alpha.size, (255, 255, 255, 0))
        sprite.putalpha(alpha)
        frames[key], sources[key] = sprite, path
    for key, name in {'fx-tablet-glow': 'Star_02_16.png', 'fx-tablet-spark': 'Star_16.png'}.items():
        path = ROME_HINT / name
        with Image.open(path) as source:
            frames[key] = source.convert('RGBA')
        sources[key] = path
    for k, name in enumerate(SMOKE_PUFFS):
        key, path = f'fx-smoke-{k}', SMOKE / f'{name}.png'
        with Image.open(path) as source:
            puff = source.convert('RGBA')
        side = max(puff.size)   # centred on a square so every puff turns about its middle
        square = Image.new('RGBA', (side, side), (255, 255, 255, 0))
        square.paste(puff, ((side - puff.width) // 2, (side - puff.height) // 2))
        frames[key] = square.resize((SMOKE_SIZE, SMOKE_SIZE), Image.Resampling.LANCZOS)
        sources[key] = path
    return frames, sources
