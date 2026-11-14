"""Register a game's CC0 Kenney sprites as additive match-3 atlas frames."""

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
    return frames, sources
