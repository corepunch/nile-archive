#!/usr/bin/env python3
"""Generate Christmas Market's circular boosters with the shared painted-button recipe."""
import argparse
import json
from pathlib import Path
import sys

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
RELIC = ROOT.parent / "relic-rush"
sys.path.insert(0, str(RELIC / "tools"))
from prepare_bonus_gems import pack


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    spec = json.loads((ROOT / "art/manifest.json").read_text())["bonus_buttons"]
    recipe = json.loads((RELIC / "art/board-states/manifest.json").read_text())["bonus_gems"]
    frames = json.loads((ROOT / "art/match3-atlas.json").read_text())["frames"]
    icons = []
    with Image.open(ROOT / "data/market-goods.png") as goods, Image.open(ROOT / "data/match3.png") as specials:
        for key in spec["columns"]:
            source = spec["icons"][key]
            if "good" in source:
                kind = source["good"]
                image, x, y, w, h = goods, kind % 4 * 128, kind // 4 * 128, 128, 128
            else:
                image = specials
                x, y, w, h = frames[source["special"]]
            icons.append(image.crop((x, y, x + w, y + h)))
    path = ROOT / spec["runtime"]
    data = pack({**recipe, **spec}, root=RELIC, icons=icons)
    if args.check:
        assert path.read_bytes() == data, f"Run {spec['generator']}"
    else:
        path.write_bytes(data)


if __name__ == "__main__":
    main()
