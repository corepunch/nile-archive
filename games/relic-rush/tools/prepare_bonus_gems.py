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
    chips = Image.open(ROOT / spec["source"])
    buttons = Image.open(ROOT / spec["button_art"]["source"])
    cols, rows = len(spec["columns"]), len(spec["rows"])
    side = spec["button_art"]["cell_size"]
    assert chips.mode == buttons.mode == "RGBA" and buttons.size == (cols * side, rows * side)
    atlas = Image.new("RGBA", (SLOT_SIZE * cols, SLOT_SIZE * rows))

    def painted_cell(x, y):
        return buttons.crop((x * side, y * side, (x + 1) * side, (y + 1) * side))

    for x, column in enumerate(spec["columns"]):
        if column in spec["button_art"]["board_chips"]:
            chip = painted_cell(x, 0)
            # Register the standalone piece by its silhouette, leaving two
            # source pixels beyond the visible edge to preserve its soft alpha.
            l, t, r, b = chip.getchannel("A").point(lambda a: 255 if a >= 128 else 0).getbbox()
            chip = chip.crop((l - 2, t - 2, r + 2, b + 2))
        elif column in spec["borrowed_chips"]:
            borrowed = spec["borrowed_chips"][column]
            chip = Image.open(ROOT / borrowed["source"]).convert("RGBA").crop(borrowed["box"])
        else:
            chip = chips.crop(spec["chip_boxes"][x])
        chip.thumbnail((BOARD_ICON_SIZE, BOARD_ICON_SIZE), Image.Resampling.LANCZOS)
        atlas.paste(center(chip), (x * SLOT_SIZE, 0))
        for y in range(1, rows):
            state = painted_cell(x, y).resize((SLOT_SIZE, SLOT_SIZE), Image.Resampling.LANCZOS)
            atlas.paste(state, (x * SLOT_SIZE, y * SLOT_SIZE))
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
