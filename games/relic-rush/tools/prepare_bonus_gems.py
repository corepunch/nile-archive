"""Place the bonus icons on painted faces and engrave the disabled state."""
import argparse
import io
import json
from pathlib import Path

from PIL import Image, ImageChops, ImageEnhance, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "art/board-states/manifest.json"
BOARD_ICON_SIZE = 112
BUTTON_FACE_SIZE = 116
BUTTON_ICON_SIZE = 84


def center(image):
    frame = Image.new("RGBA", (128, 128))
    frame.paste(image, ((128 - image.width) // 2, (128 - image.height) // 2))
    return frame


def engrave(plate, icon):
    """Shade the cavity and give the edge a warm reflected glow."""
    mask = icon.getchannel("A").point(lambda a: max(0, min(255, (a - 24) * 255 // 208)))
    mask = mask.filter(ImageFilter.GaussianBlur(0.5))
    face = plate.convert("RGB")
    shade = ImageEnhance.Brightness(face)
    amber = Image.new("RGB", face.size, (255, 198, 108))

    # Reflected light falls off outside the cut and catches the lower wall.
    rim = ImageChops.subtract(mask.filter(ImageFilter.MaxFilter(5)), mask)
    halo = ImageChops.subtract(mask.filter(ImageFilter.GaussianBlur(3)), mask)
    glow = ImageChops.add(rim, halo, scale=2).filter(ImageFilter.GaussianBlur(0.7))
    stone = Image.composite(amber, face, glow)
    upper_wall = ImageChops.subtract(mask, ImageChops.offset(mask, 4, 3))
    lower_wall = ImageChops.subtract(mask, ImageChops.offset(mask, -3, -3))
    rim_light = ImageChops.subtract(mask, ImageChops.offset(mask, -1, -1))
    recess = Image.composite(shade.enhance(0.16), shade.enhance(0.32), upper_wall)
    recess = Image.composite(shade.enhance(0.72), recess, lower_wall)
    recess = Image.composite(Image.blend(face, amber, 0.48), recess, rim_light)
    result = Image.composite(recess, stone, mask)
    result.putalpha(plate.getchannel("A"))
    return result


def pack(spec):
    chips = Image.open(ROOT / spec["source"])
    faces = Image.open(ROOT / spec["button_source"])
    assert chips.mode == faces.mode == "RGBA"
    plates = [center(faces.crop(box).resize((BUTTON_FACE_SIZE, BUTTON_FACE_SIZE), Image.Resampling.LANCZOS))
              for box in spec["button_boxes"]]
    states = spec["rows"][1:]
    assert len(plates) == len(states)
    atlas = Image.new("RGBA", (128 * len(spec["columns"]), 128 * len(spec["rows"])))
    for x, bounds in enumerate(spec["chip_boxes"]):
        chip = chips.crop(bounds)
        chip.thumbnail((BOARD_ICON_SIZE, BOARD_ICON_SIZE), Image.Resampling.LANCZOS)
        atlas.paste(center(chip), (x * 128, 0))
        chip.thumbnail((BUTTON_ICON_SIZE, BUTTON_ICON_SIZE), Image.Resampling.LANCZOS)
        icon = center(chip)
        for y, (state, plate) in enumerate(zip(states, plates), 1):
            face = engrave(plate, icon) if state == "disabled" else Image.alpha_composite(plate, icon)
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
