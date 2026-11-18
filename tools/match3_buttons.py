#!/usr/bin/env python3
"""Register the four painted action icons in the shared 128px grid."""
import argparse
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "art/match3-buttons/manifest.json"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    spec = json.loads(MANIFEST.read_text())
    side = spec["cell_size"]
    atlas = Image.new("RGBA", (side * len(spec["icons"]), side))
    with Image.open(ROOT / spec["source"]) as source:
        assert source.mode == "RGBA"
        for col, icon in enumerate(spec["icons"]):
            crop = source.crop(icon["box"])
            crop = crop.crop(crop.getchannel("A").getbbox())
            fit = icon.get("fit", spec["fit"])
            crop.thumbnail((fit, fit), Image.Resampling.LANCZOS)
            x = (side - crop.width) // 2 + icon.get("offset_x", 0)
            assert 0 <= x <= side - crop.width, icon["key"]
            atlas.paste(crop, (side * col + x, (side - crop.height) // 2))
    path = ROOT / spec["registered"]
    if args.check:
        with Image.open(path) as actual:
            assert actual.size == atlas.size and actual.tobytes() == atlas.tobytes(), f"Stale {path}"
    else:
        atlas.save(path, optimize=True)


if __name__ == "__main__":
    main()
