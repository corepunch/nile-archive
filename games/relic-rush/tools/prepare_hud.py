"""Register the authored expedition HUD atlas.

python3 games/relic-rush/tools/prepare_hud.py [--check]
"""
import argparse
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--check", action="store_true")
args = parser.parse_args()
manifest = json.loads((ROOT / "art/expedition-hud/manifest.json").read_text())
source = Image.open(ROOT / manifest["controls"]["source"]).convert("RGBA")
assert list(source.size) == manifest["controls"]["size"]
exports = {}
for name, asset in manifest["icons"].items():
    sheet=Image.open(ROOT/asset["source"]).convert("RGBA") if "source" in asset else source
    image = sheet.crop(asset["box"])
    image.thumbnail((120, 120), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (128, 128))
    canvas.alpha_composite(image, ((128 - image.width) // 2, (128 - image.height) // 2))
    exports[asset["runtime"]] = canvas
# Navigation is a separate authored atlas, outside the match-piece GPU atlas.
nav = json.loads((ROOT / "art/navigation/manifest.json").read_text())
sheet = Image.open(ROOT / nav["source"]).convert("RGBA")
assert list(sheet.size) == nav["size"]
for asset in nav["icons"].values():
    image = sheet.crop(asset["box"])
    image.thumbnail((152, 152), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (160, 160))
    canvas.alpha_composite(image, ((160 - image.width) // 2, (160 - image.height) // 2))
    exports[asset["runtime"]] = canvas
for path, image in exports.items():
    path = ROOT / path
    if args.check:
        with Image.open(path) as current:
            assert current.mode == "RGBA" and current.size == image.size and current.tobytes() == image.tobytes(), path
    else:
        path.parent.mkdir(parents=True, exist_ok=True)
        image.save(path, optimize=True)
print("Expedition HUD: authored settings/lives/goal icons " + ("verified" if args.check else "imported"))
