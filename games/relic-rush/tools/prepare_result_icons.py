"""Register the two authored Relic Rush result icons in their runtime atlas."""
import argparse
import json
from pathlib import Path

from PIL import Image


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    root = Path(__file__).resolve().parents[1]
    spec = json.loads((root / "art/board-states/manifest.json").read_text())["result_icons"]
    cell_size, art_size = spec["cell_size"], spec["art_size"]
    source = Image.open(root / spec["source"])
    assert source.mode == "RGBA" and list(source.size) == spec["source_size"]
    atlas = Image.new("RGBA", (cell_size * len(spec["icons"]), cell_size))
    for i, icon in enumerate(spec["icons"].values()):
        crop = source.crop(icon["box"])
        crop.thumbnail((art_size, art_size), Image.Resampling.LANCZOS)
        x = i * cell_size + (cell_size - crop.width) // 2
        y = (cell_size - crop.height) // 2
        atlas.paste(crop, (x, y))

    runtime = root / spec["runtime"]
    if args.check:
        with Image.open(runtime) as current:
            assert (current.mode, current.size, current.tobytes()) == (atlas.mode, atlas.size, atlas.tobytes()), \
                f"Stale atlas: run {spec['registration']}"
    else:
        atlas.save(runtime, optimize=True)


if __name__ == "__main__":
    main()
