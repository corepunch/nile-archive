"""Register the painted bonus chips and the authored button atlas."""
import argparse
import io
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "art/board-states/manifest.json"
SLOT_SIZE = 128
BOARD_ICON_SIZE = 112


def center(image):
    frame = Image.new(image.mode, (SLOT_SIZE, SLOT_SIZE))
    frame.paste(image, ((SLOT_SIZE - image.width) // 2, (SLOT_SIZE - image.height) // 2))
    return frame


def pack(spec):
    source = Image.open(ROOT / spec["source"])
    cols, rows = len(spec["columns"]), len(spec["rows"])
    side = spec["cell_size"]
    assert source.mode == "RGBA" and source.size == (cols * side, rows * side)
    atlas = Image.new("RGBA", (SLOT_SIZE * cols, SLOT_SIZE * rows))

    for x in range(cols):
        for y in range(rows):
            frame = source.crop((x * side, y * side, (x + 1) * side, (y + 1) * side))
            if y == 0:
                # Leave two source pixels beyond the silhouette for soft alpha.
                l, t, r, b = frame.getchannel("A").point(lambda a: 255 if a >= 128 else 0).getbbox()
                frame = frame.crop((l - 2, t - 2, r + 2, b + 2))
                frame.thumbnail((BOARD_ICON_SIZE, BOARD_ICON_SIZE), Image.Resampling.LANCZOS)
                frame = center(frame)
            else:
                frame = frame.resize((SLOT_SIZE, SLOT_SIZE), Image.Resampling.LANCZOS)
            atlas.paste(frame, (x * SLOT_SIZE, y * SLOT_SIZE))
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
