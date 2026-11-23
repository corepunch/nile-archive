#!/usr/bin/env python3
"""Register the shared painted town Play button."""
import argparse
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "art/match3-buttons/town-play.json"
STATES = ("normal", "hover", "pressed", "disabled")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    spec = json.loads(MANIFEST.read_text())
    side, fit = spec["cell_size"], spec["fit"]
    atlas = Image.new("RGBA", (2 * side, 2 * side))
    with Image.open(ROOT / spec["source"]) as source:
        assert source.mode == "RGBA"
        for index, state in enumerate(STATES):
            frame = source.crop(spec["frames"][state])
            frame.thumbnail((fit, fit), Image.Resampling.LANCZOS)
            x = index % 2 * side + (side - frame.width) // 2
            y = index // 2 * side + (side - frame.height) // 2
            atlas.paste(frame, (x, y))
    path = ROOT / spec["runtime"]
    if args.check:
        with Image.open(path) as actual:
            assert actual.size == atlas.size and actual.tobytes() == atlas.tobytes(), f"Stale {path}"
    else:
        atlas.save(path, optimize=True)


if __name__ == "__main__":
    main()
