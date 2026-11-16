"""Generate the bonus button states from a painted base and six icons."""
import argparse
import io
import json
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter, ImageOps

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "art/board-states/manifest.json"
SLOT_SIZE = 128
BOARD_ICON_SIZE = 112
BUTTON_ICON_SIZE = 84


def center(image):
    frame = Image.new(image.mode, (SLOT_SIZE, SLOT_SIZE))
    frame.paste(image, ((SLOT_SIZE - image.width) // 2, (SLOT_SIZE - image.height) // 2))
    return frame


def rounded_mask(size, bounds, radius):
    """Antialias the inset outline at the base plate's scale."""
    scale = 8
    left, top, right, bottom = bounds
    mask = Image.new("L", (size[0] * scale, size[1] * scale))
    ImageDraw.Draw(mask).rounded_rectangle(
        (left * scale, top * scale, right * scale - 1, bottom * scale - 1),
        radius=radius * scale, fill=255,
    )
    return mask.resize(size, Image.Resampling.LANCZOS)


def bevel(face, mask, width, shadow=0.56, highlight=1.28):
    """Light the inside walls of the shape. Negative widths raise the bevel."""
    shade = ImageEnhance.Brightness(face)
    upper = ImageChops.subtract(mask, ImageChops.offset(mask, width, width))
    upper = ImageChops.multiply(mask, upper.filter(ImageFilter.GaussianBlur(abs(width) / 3)))
    lower = ImageChops.subtract(mask, ImageChops.offset(mask, -width, -width))
    face = Image.composite(shade.enhance(shadow), face, upper)
    return Image.composite(shade.enhance(highlight), face, lower)


def rim_glow(face, mask, color, strength=1, spread=2):
    rim = ImageChops.subtract(mask.filter(ImageFilter.MaxFilter(2 * spread + 1)), mask)
    halo = ImageChops.subtract(mask.filter(ImageFilter.GaussianBlur(1.5 * spread)), mask)
    glow = ImageChops.add(rim, halo, scale=2).filter(ImageFilter.GaussianBlur(0.35 * spread))
    glow = glow.point(lambda a: min(255, round(a * strength)))
    return Image.composite(Image.new("RGB", face.size, tuple(color)), face, glow)


def recolor(face, palette):
    shadow, midtone, highlight = map(tuple, palette)
    return ImageOps.colorize(face.convert("L"), shadow, highlight, midtone, midpoint=182)


def button_face(base, mask, style):
    face = base.convert("RGB")
    if "palette" in style:
        face = recolor(face, style["palette"])
    if "brightness" in style:
        face = ImageEnhance.Brightness(face).enhance(style["brightness"])
    if "inset_palette" in style or "bevel" in style:
        inset = recolor(face, style["inset_palette"]) if "inset_palette" in style else face
        inset = bevel(inset, mask, style.get("bevel", 0))
        face = Image.composite(inset, face, mask)
    if "glow" in style:
        face = rim_glow(face, mask, style["glow"], style.get("glow_strength", 1))
    face.putalpha(base.getchannel("A"))
    return face


def engrave(plate, mask, highlight):
    """Cut the disabled icon into the plate and light its rim."""
    face = plate.convert("RGB")
    stone = rim_glow(face, mask, highlight, spread=1)
    floor = ImageEnhance.Brightness(face).enhance(0.32)
    recess = bevel(floor, mask, 3, shadow=0.5, highlight=2.25)
    rim_light = ImageChops.subtract(mask, ImageChops.offset(mask, -1, -1)).filter(ImageFilter.GaussianBlur(0.35))
    lit_edge = Image.blend(face, Image.new("RGB", face.size, tuple(highlight)), 0.48)
    recess = Image.composite(lit_edge, recess, rim_light)
    result = Image.composite(recess, stone, mask)
    result.putalpha(plate.getchannel("A"))
    return result


def pack(spec):
    chips = Image.open(ROOT / spec["source"])
    base = Image.open(ROOT / spec["button_base"])
    assert chips.mode == base.mode == "RGBA" and base.size == (SLOT_SIZE, SLOT_SIZE)
    base_alpha = base.getchannel("A")
    outside_button = base_alpha.point(lambda a: 255 if a < 128 else 0)
    mask = rounded_mask(base.size, **spec["button_inset"])
    states = [(state, button_face(base, mask, spec["button_states"][state])) for state in spec["rows"][1:]]
    disabled_highlight = spec["button_states"]["disabled"]["palette"][-1]
    atlas = Image.new("RGBA", (SLOT_SIZE * len(spec["columns"]), SLOT_SIZE * len(spec["rows"])))
    for x, bounds in enumerate(spec["chip_boxes"]):
        source = chips.crop(bounds)
        chip = source.copy()
        chip.thumbnail((BOARD_ICON_SIZE, BOARD_ICON_SIZE), Image.Resampling.LANCZOS)
        atlas.paste(center(chip), (x * SLOT_SIZE, 0))
        chip.thumbnail((BUTTON_ICON_SIZE, BUTTON_ICON_SIZE), Image.Resampling.LANCZOS)
        icon = center(chip)
        # Sample the cut once from the original outline. Only the lighting is soft.
        outline = source.getchannel("A").point(lambda a: 255 if a >= 128 else 0)
        cut = center(outline.resize(chip.size, Image.Resampling.BICUBIC))
        assert not ImageChops.multiply(icon.getchannel("A"), outside_button).getbbox(), "Icon extends beyond the button"
        for y, (state, plate) in enumerate(states, 1):
            face = engrave(plate, cut, disabled_highlight) if state == "disabled" else Image.alpha_composite(plate, icon)
            face.putalpha(base_alpha)
            atlas.paste(face, (x * SLOT_SIZE, y * SLOT_SIZE))
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
