#!/usr/bin/env python3
"""Register paintings for mosaic reveals and verify the decoded runtime images."""
import argparse
from io import BytesIO
import json
from pathlib import Path

from PIL import Image, ImageChops, ImageOps, ImageStat

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    manifest = json.loads((ROOT / "art/board-states/manifest.json").read_text())
    for name, mosaic in manifest["story_mosaics"]["pictures"].items():
        path = ROOT / mosaic["runtime"]
        with Image.open(ROOT / mosaic["source"]) as master:
            image = ImageOps.fit(master.convert("RGB"), mosaic["size"], Image.Resampling.LANCZOS)
        encoded = BytesIO()
        image.save(encoded, format="JPEG", quality=91, subsampling=0, optimize=True)
        if args.check:
            with Image.open(path) as actual, Image.open(encoded) as expected:
                assert actual.format == "JPEG" and actual.mode == "RGB", name
                assert actual.size == expected.size, name
                # Allow minor JPEG encoder differences between platforms.
                error = ImageStat.Stat(ImageChops.difference(actual, expected))
                assert max(error.mean) <= 0.5, (
                    f"{name}: rebuild with python3 games/relic-rush/tools/prepare_story_mosaics.py"
                )
        else:
            path.write_bytes(encoded.getvalue())
        print(f"{name}: {image.width}×{image.height} authored painting")


if __name__ == "__main__":
    main()
