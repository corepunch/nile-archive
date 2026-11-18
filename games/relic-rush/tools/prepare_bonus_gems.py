"""Register the eight standalone bonus pieces used by the board and toolbar."""
import argparse
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "art/board-states/manifest.json"


def pack(spec):
    cols, cell = spec["source_columns"], 128
    atlas = Image.new("RGBA", (len(spec["columns"]) * cell, cell))
    with Image.open(ROOT / spec["source"]) as sheet:
        rows = (len(spec["columns"]) + cols - 1) // cols
        assert sheet.mode == "RGBA"
        for i, key in enumerate(spec["columns"]):
            x, y = i % cols, i // cols
            chip = sheet.crop((x * sheet.width // cols, y * sheet.height // rows,
                               (x + 1) * sheet.width // cols, (y + 1) * sheet.height // rows))
            left, top, right, bottom = chip.getchannel("A").point(lambda a: 255 if a >= 128 else 0).getbbox()
            chip = chip.crop((left - 2, top - 2, right + 2, bottom + 2))
            fit = spec["icon_sizes"].get(key, {}).get("board", 112)
            chip.thumbnail((fit, fit), Image.Resampling.LANCZOS)
            atlas.paste(chip, (i * cell + (cell - chip.width) // 2, (cell - chip.height) // 2))
    return atlas


def png_matches(path, expected):
    # PNG compression can differ across platforms even when the pixels match.
    with Image.open(path) as actual:
        return (actual.format == "PNG" and actual.mode == expected.mode
                and actual.size == expected.size and actual.tobytes() == expected.tobytes())


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    spec = json.loads(MANIFEST.read_text())["bonus_gems"]
    path, atlas = ROOT / spec["runtime"], pack(spec)
    if args.check:
        assert png_matches(path, atlas), "Run games/relic-rush/tools/prepare_bonus_gems.py"
    else:
        atlas.save(path, optimize=True)


if __name__ == "__main__":
    main()
