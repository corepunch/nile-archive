"""Register the existing painted match specials as two optional runtime atlases."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
GAMES = ("relic-rush", "christmas-market")


def largest_island(sprite):
    """Discard flecks from the adjacent illustration in the old plane crop."""
    alpha = sprite.getchannel("A")
    pixels = {(x, y) for y in range(sprite.height) for x in range(sprite.width) if alpha.getpixel((x, y))}
    largest = []
    while pixels:
        stack = [pixels.pop()]
        component = []
        while stack:
            x, y = stack.pop()
            component.append((x, y))
            for neighbor in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if neighbor in pixels:
                    pixels.remove(neighbor)
                    stack.append(neighbor)
        if len(component) > len(largest):
            largest = component
    clean = Image.new("L", sprite.size)
    for p in largest:
        clean.putpixel(p, alpha.getpixel(p))
    sprite.putalpha(clean)
    return sprite


def main():
    paint = Image.open(ROOT / "art/match3-power-up-paint/source.png").convert("RGBA")
    theme = Image.open(ROOT / "games/christmas-market/art/board-theme/source.png").convert("RGBA")
    w, h = theme.size
    plane = largest_island(theme.crop((round(w / 5), round(h * 2 / 5), round(w * 2 / 5), round(h * 3 / 5))))
    for row, game in enumerate(GAMES):
        atlas = Image.new("RGBA", (384, 128))
        w, h = paint.size
        sprites = [paint.crop((i*w//5, row*h//2, (i+1)*w//5, (row+1)*h//2)) for i in (3, 4)]
        for slot, sprite in enumerate([*sprites, plane]):
            crop = sprite.crop(sprite.getchannel("A").getbbox())
            crop.thumbnail((104, 104), Image.Resampling.LANCZOS)
            atlas.alpha_composite(crop, (128*slot + (128-crop.width)//2, (128-crop.height)//2))
        atlas.save(ROOT / "games" / game / "data/board/match-specials.png")


if __name__ == "__main__":
    main()
