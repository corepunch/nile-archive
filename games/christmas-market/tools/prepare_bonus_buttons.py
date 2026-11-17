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
from prepare_bonus_gems import pack, png_matches


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    spec = json.loads((ROOT / "art/manifest.json").read_text())["bonus_buttons"]
    recipe = json.loads((RELIC / "art/board-states/manifest.json").read_text())["bonus_gems"]
    frames = json.loads((ROOT / "art/match3-atlas.json").read_text())["frames"]
    icons = []
    with Image.open(ROOT / "art/registered/market-goods.png") as goods:
        for key in spec["columns"]:
            source = spec["icons"][key]
            if "good" in source:
                kind = source["good"]
                x, y, w, h = kind % 4 * 128, kind // 4 * 128, 128, 128
                icons.append(goods.crop((x, y, x + w, y + h)))
            else:
                # The painted icon frame, from whichever typed atlas packs it.
                frame = frames[source["frame"]]
                x, y, w, h = frame["box"]
                with Image.open(ROOT / f"data/board/{frame['atlas']}.png") as board:
                    icons.append(board.crop((x, y, x + w, y + h)))
    path = ROOT / spec["runtime"]
    atlas = pack({**recipe, **spec}, root=RELIC, icons=icons)
    if args.check:
        assert png_matches(path, atlas), f"Run {spec['generator']}"
    else:
        atlas.save(path, optimize=True)


if __name__ == "__main__":
    main()
