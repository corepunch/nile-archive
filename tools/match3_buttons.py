#!/usr/bin/env python3
"""Center the painted campaign actions on their circular button faces."""
import argparse
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "art/match3-buttons/manifest.json"


def alpha_center(image):
    """Center of opacity in image coordinates measured from the top-left edge."""
    alpha = image.getchannel("A").tobytes()
    mass = sum(alpha)
    if not mass:
        raise ValueError("The icon is completely transparent")
    moment_x = moment_y = 0
    for y in range(image.height):
        row = alpha[y * image.width:(y + 1) * image.width]
        moment_x += sum(x * weight for x, weight in enumerate(row))
        moment_y += y * sum(row)
    return moment_x / mass + .5, moment_y / mass + .5


def centered_icon(image, side, fit):
    """Place the alpha-weighted center of the visible artwork at the cell center."""
    bounds = image.getchannel("A").getbbox()
    if not bounds:
        raise ValueError("The icon is completely transparent")
    artwork = image.crop(bounds)
    for limit in range(min(fit, side, max(artwork.size)), 0, -1):
        icon = artwork.copy()
        icon.thumbnail((limit, limit), Image.Resampling.LANCZOS)
        if not icon.getchannel("A").getbbox():
            continue
        cx, cy = alpha_center(icon)
        x = round(side / 2 - cx)
        y = round(side / 2 - cy)
        if 0 <= x <= side - icon.width and 0 <= y <= side - icon.height:
            cell = Image.new("RGBA", (side, side))
            cell.paste(icon, (x, y))
            return cell
    raise ValueError("The icon cannot fit visibly in the requested cell")


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
            fit = icon.get("fit", spec["fit"])
            atlas.paste(centered_icon(crop, side, fit), (side * col, 0))
    path = ROOT / spec["registered"]
    if args.check:
        with Image.open(path) as actual:
            assert actual.size == atlas.size and actual.tobytes() == atlas.tobytes(), f"Stale {path}"
    else:
        atlas.save(path, optimize=True)


if __name__ == "__main__":
    main()
