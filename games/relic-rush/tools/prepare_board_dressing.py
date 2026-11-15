"""Register the painted limestone and blue plaque faces for Relic Rush."""
import argparse
import json
from pathlib import Path

from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parents[1]
SPEC = json.loads((ROOT / "art/board-states/manifest.json").read_text())["dressing"]
SIZE, STRIDE = 128, 132


def register(source, item, mask):
    assert item["fit"] == "fill", item
    tile = source.crop(item["crop"]).resize((SIZE, SIZE), Image.Resampling.LANCZOS)
    # Full-bleed paint must reach the registered face before we cut it.
    unpainted = tile.getchannel("A").point(lambda a: 255 if a < 230 else 0)
    assert not ImageChops.multiply(unpainted, mask).getbbox(), item
    tile.putalpha(mask)
    return tile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--tiles", type=Path, help="Export individual registered frames for hex review")
    args = parser.parse_args()
    mask = Image.open(ROOT / SPEC["mask"]).getchannel("A")
    sources = {key: Image.open(ROOT / paths["source"]).convert("RGBA") for key, paths in SPEC["sources"].items()}
    cols = SPEC["columns"]
    rows = (len(SPEC["frames"]) + cols - 1) // cols
    atlas = Image.new("RGBA", (cols * STRIDE, rows * STRIDE))
    if args.tiles:
        args.tiles.mkdir(parents=True, exist_ok=True)
    for i, (name, item) in enumerate(SPEC["frames"].items()):
        tile = register(sources[item["source"]], item, mask)
        atlas.paste(tile, (i % cols * STRIDE + 2, i // cols * STRIDE + 2))
        if args.tiles:
            tile.save(args.tiles / f"{name}.png")
    path = ROOT / SPEC["runtime"]
    if args.check:
        current = Image.open(path)
        assert current.size == atlas.size and current.tobytes() == atlas.tobytes(), f"Stale dressing atlas: {path}"
    else:
        atlas.save(path, optimize=True)


if __name__ == "__main__":
    main()
