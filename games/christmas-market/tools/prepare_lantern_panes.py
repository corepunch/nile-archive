"""Register the three painted lantern board surfaces to the game's flat-top hex."""
import argparse
import json
from pathlib import Path

from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    spec = json.loads((ROOT / "art/manifest.json").read_text())["lantern_panes"]
    mask = Image.open(ROOT / spec["mask"]).getchannel("A")
    source = Image.open(ROOT / spec["source"]).convert("RGBA")
    for name, state in spec["states"].items():
        face = source.crop(state["crop"]).resize(mask.size, Image.Resampling.LANCZOS)
        unpainted = face.getchannel("A").point(lambda a: 255 if a < 230 else 0)
        assert not ImageChops.multiply(unpainted, mask).getbbox(), f"{name}: paint does not cover the hex"
        face.putalpha(mask)
        path = ROOT / state["runtime"]
        if args.check:
            assert face.tobytes() == Image.open(path).tobytes(), f"Stale lantern pane: {path}"
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            face.save(path, optimize=True)


if __name__ == "__main__":
    main()
