"""Register the signal plate and the safe-landing scene from their authored sources."""
import argparse
from io import BytesIO
import json
from pathlib import Path

from PIL import Image, ImageChops, ImageStat

ROOT = Path(__file__).resolve().parents[1]
spec = json.loads((ROOT / "art/board-states/manifest.json").read_text())["finale"]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--check", action="store_true")
args = parser.parse_args()

for name, item in spec["assets"].items():
    with Image.open(ROOT / item["source"]) as master:
        if "crop" in item:
            sprite = master.crop(item["crop"])
            sprite.thumbnail(tuple(item["paint_size"]), Image.Resampling.LANCZOS)
            image = Image.new("RGBA", item["size"])
            image.paste(sprite, ((image.width - sprite.width) // 2, (image.height - sprite.height) // 2))
        else:
            image = master.convert("RGB").resize(item["size"], Image.Resampling.LANCZOS)
    path = ROOT / item["runtime"]
    buf = BytesIO()
    save = {"optimize": True}
    if path.suffix == ".jpg":
        save.update(quality=92, subsampling=0)
    image.save(buf, format="JPEG" if path.suffix == ".jpg" else "PNG", **save)
    if args.check:
        with Image.open(buf) as expected, Image.open(path) as actual:
            assert actual.mode == expected.mode and actual.size == expected.size, name
            tolerance = .5 if actual.format == "JPEG" else 0
            assert max(ImageStat.Stat(ImageChops.difference(actual, expected)).mean) <= tolerance, name
    else:
        path.write_bytes(buf.getvalue())
