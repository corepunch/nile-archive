"""Register the bonus atlas and cut the disabled sockets' recessed motifs."""
import argparse
import io
import json
from pathlib import Path

from PIL import Image, ImageChops, ImageEnhance, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "art/board-states/manifest.json"


def center(image):
    frame = Image.new("RGBA", (128, 128))
    frame.paste(image, ((128 - image.width) // 2, (128 - image.height) // 2))
    return frame


def engrave(plate, chip):
    """Cut a shallow recess with a shadowed top wall and a lit lower edge."""
    chip = chip.copy()
    chip.thumbnail((84, 84), Image.Resampling.LANCZOS)
    mask = center(chip).getchannel("A").point(lambda a: max(0, min(255, (a - 32) * 255 // 200)))
    mask = mask.filter(ImageFilter.GaussianBlur(0.5))
    top = ImageChops.subtract(mask, ImageChops.offset(mask, 2, 2))
    bottom = ImageChops.subtract(mask, ImageChops.offset(mask, -2, -2))
    face = plate.convert("RGB")
    shade = ImageEnhance.Brightness(face)
    recess = Image.composite(shade.enhance(0.34), shade.enhance(0.56), top)
    recess = Image.composite(shade.enhance(1.18), recess, bottom)
    result = Image.composite(recess, face, mask)
    result.putalpha(plate.getchannel("A"))
    return result


def pack(spec):
    source = Image.open(ROOT / spec["source"])
    assert source.mode == "RGBA"
    atlas = Image.new("RGBA", (128 * len(spec["columns"]), 128 * len(spec["rows"])))
    for x, bounds in enumerate(spec["boxes"][0]):
        chip = source.crop(tuple(bounds))
        chip.thumbnail((112, 112), Image.Resampling.LANCZOS)
        atlas.paste(center(chip), (x * 128, 0))
        for y, (state, boxes) in enumerate(zip(spec["rows"][1:], spec["boxes"][1:]), 1):
            # Every face occupies the same square so the charge layers align.
            face = center(source.crop(tuple(boxes[x])).resize((116, 116), Image.Resampling.LANCZOS))
            if state == "disabled":
                face = engrave(face, chip)
            atlas.paste(face, (x * 128, y * 128))
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
