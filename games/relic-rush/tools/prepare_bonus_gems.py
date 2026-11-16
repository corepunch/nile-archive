"""Register all authored bonus chips and sockets to the same atlas grid."""
import argparse
import io
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "art/board-states/manifest.json"


def pack(spec):
    source = Image.open(ROOT / spec["source"])
    assert source.mode == "RGBA"
    atlas = Image.new("RGBA", (128 * len(spec["columns"]), 128 * len(spec["rows"])))
    for y, (top, bottom) in enumerate(spec["row_ranges"]):
        for x, (left, right) in enumerate(spec["column_ranges"]):
            box = (left, top, right, bottom) if y else tuple(spec["object_boxes"][x])
            chip = source.crop(box)
            # The sockets share one size and centre, so their fill layers align.
            chip.thumbnail((116, 116) if y else (112, 112), Image.Resampling.LANCZOS)
            atlas.paste(chip, (x * 128 + (128 - chip.width) // 2, y * 128 + (128 - chip.height) // 2))
    output = io.BytesIO()
    atlas.save(output, format="PNG", optimize=True)
    return output.getvalue()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    spec = json.loads(MANIFEST.read_text())["bonus_gems"]
    path, data = ROOT / spec["runtime"], pack(spec)
    if args.check:
        assert path.read_bytes() == data, "Run games/relic-rush/tools/prepare_bonus_gems.py"
    else:
        path.write_bytes(data)


if __name__ == "__main__":
    main()
