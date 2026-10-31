"""Register the authored expedition HUD atlas and investigating portrait.

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
    image = source.crop(asset["box"])
    image.thumbnail((120, 120), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (128, 128))
    canvas.alpha_composite(image, ((128 - image.width) // 2, (128 - image.height) // 2))
    exports[asset["runtime"]] = canvas
portrait = manifest["portrait"]
image = Image.open(ROOT / portrait["source"]).convert("RGBA").crop(portrait["box"])
image.thumbnail(tuple(portrait["max_size"]), Image.Resampling.LANCZOS)
exports[portrait["runtime"]] = image
for path, image in exports.items():
    path = ROOT / path
    if args.check:
        with Image.open(path) as current:
            assert current.mode == "RGBA" and current.size == image.size and current.tobytes() == image.tobytes(), path
    else:
        path.parent.mkdir(parents=True, exist_ok=True)
        image.save(path, optimize=True)
print("Expedition HUD: seven authored icons and investigating portrait " + ("verified" if args.check else "imported"))
