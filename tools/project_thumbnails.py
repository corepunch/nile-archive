"""Register the paintings and sandstone for a match-3 town bar."""
import argparse
import json
from pathlib import Path
import re

from PIL import Image


def render(game):
    root = Path(__file__).resolve().parents[1] / "games" / game
    manifest_path = "art/board-states/manifest.json" if game == "relic-rush" else "art/manifest.json"
    manifest = json.loads((root / manifest_path).read_text())
    frames = manifest["construction_backdrops"]["frames"]
    bar = manifest["project_thumbnails"]
    cell = bar["cell"]
    # Four buildings per epoch, in full color.
    sheet = Image.new("RGB", (4 * cell, 5 * cell))
    economy = (root / "lua/economy.lua").read_text().split("E.unlocks = {", 1)[1].split("\n}", 1)[0]
    purchases = [
        backdrop or building
        for building, backdrop in (
            re.search(r'building="([^"]+)"(?:[^\n]*?backdrop="([^"]+)")?', row).groups()
            for row in economy.splitlines() if row.lstrip().startswith("{building=")
        )
    ]
    assert len(purchases) == 20 and set(purchases) == set(bar["crop_top"])
    for index, key in enumerate(purchases):
        top = bar["crop_top"][key]
        with Image.open(root / frames[key]["runtime"]) as source:
            side = source.width
            assert 0 <= top <= source.height - side, key
            crop = source.crop((0, top, side, top + side))
            tile = crop.resize((cell, cell), Image.Resampling.LANCZOS)
        x, y = index % 4 * cell, index // 4 * cell
        sheet.paste(tile, (x, y))
    runtime = root / bar["runtime"]
    runtime.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(runtime, quality=92, subsampling=0, optimize=True)

    panel = manifest["town_bar_panel"]
    with Image.open(root / panel["source"]) as sandstone:
        strip = sandstone.crop(tuple(panel["crop"])).convert("RGB")
        strip.resize((960, 240), Image.Resampling.LANCZOS).save(
            root / panel["runtime"], quality=91, optimize=True
        )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("game", choices=["relic-rush", "christmas-market"])
    render(parser.parse_args().game)
