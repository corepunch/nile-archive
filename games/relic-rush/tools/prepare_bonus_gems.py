"""Generate the bonus button states from a painted base and the bonus icons."""
import argparse
import io
import json
import math
import random
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter, ImageOps

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "art/board-states/manifest.json"
SLOT_SIZE = 128
BOARD_ICON_SIZE = 112
BUTTON_ICON_SIZE = 84
ENGRAVE_SCALE = 4


def center(image, side=SLOT_SIZE):
    frame = Image.new(image.mode, (side, side))
    frame.paste(image, ((side - image.width) // 2, (side - image.height) // 2))
    return frame


def circular_plate(base, radius):
    """Map the painted rim to a circle while keeping its directional lighting."""
    width, height = base.size
    center_x, center_y = width / 2, height / 2
    opacity = base.getchannel("A").getpixel
    directions = 720
    max_radius = math.ceil(math.hypot(center_x, center_y))

    def sample_alpha(x, y):
        left, top = math.floor(x), math.floor(y)
        if not (0 <= left < width - 1 and 0 <= top < height - 1):
            return 0
        u, v = x - left, y - top
        upper = (1 - u) * opacity((left, top)) + u * opacity((left + 1, top))
        lower = (1 - u) * opacity((left, top + 1)) + u * opacity((left + 1, top + 1))
        return (1 - v) * upper + v * lower

    # Find the painted rim along each ray at the midpoint of its soft alpha edge.
    contour = []
    for i in range(directions):
        angle = math.tau * i / directions
        dx, dy = math.cos(angle), math.sin(angle)
        lo, hi = 0, max_radius
        for _ in range(16):
            mid = (lo + hi) / 2
            if sample_alpha(center_x + dx * mid - .5, center_y + dy * mid - .5) >= 128:
                lo = mid
            else:
                hi = mid
        contour.append((lo + hi) / 2)

    def source_point(x, y):
        dx, dy = x - center_x, y - center_y
        angle = math.atan2(dy, dx) * directions / math.tau
        i = math.floor(angle)
        blend = angle - i
        boundary = (1 - blend) * contour[i % directions] + blend * contour[(i + 1) % directions]
        return center_x + dx * boundary / radius, center_y + dy * boundary / radius

    # Inverse mapping keeps the alpha edge and painted texture in one resample.
    mesh = []
    for y in range(0, height, 2):
        for x in range(0, width, 2):
            quad = (source_point(x, y) + source_point(x, y + 2)
                    + source_point(x + 2, y + 2) + source_point(x + 2, y))
            mesh.append(((x, y, x + 2, y + 2), quad))
    return base.transform(base.size, Image.Transform.MESH, mesh, Image.Resampling.BICUBIC)


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


def rim_glow(face, mask, color, strength=1):
    rim = ImageChops.subtract(mask.filter(ImageFilter.MaxFilter(5)), mask)
    halo = ImageChops.subtract(mask.filter(ImageFilter.GaussianBlur(3)), mask)
    glow = ImageChops.add(rim, halo, scale=2).filter(ImageFilter.GaussianBlur(0.7))
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


def cutout_floor(plate, cut):
    floor = recolor(plate, cut["floor_palette"])
    rng = random.Random(0)
    grain = Image.new("L", floor.size)
    strength = cut["floor_grain"]
    grain.putdata([128 + rng.randint(-strength, strength) for _ in range(floor.width * floor.height)])
    grain = grain.filter(ImageFilter.GaussianBlur(0.55)).convert("RGB")
    return ImageChops.add(floor, grain, offset=-128)


def engrave(plate, mask, floor, style):
    """Light a dark floor through the cutout and reflect light around its edge."""
    face = plate.convert("RGB").resize(mask.size, Image.Resampling.BICUBIC)
    floor = floor.resize(mask.size, Image.Resampling.BICUBIC)
    cut = style["cutout"]
    halo = mask.filter(ImageFilter.GaussianBlur(cut["glow_radius"] * ENGRAVE_SCALE))
    glow = ImageChops.multiply(halo, ImageChops.invert(mask))
    glow = glow.point(lambda a: min(255, round(a * cut["glow_strength"])))
    highlight = Image.new("RGB", face.size, tuple(style["palette"][-1]))
    stone = Image.composite(highlight, face, glow)

    shadow = ImageEnhance.Brightness(floor).enhance(cut["shadow_brightness"])
    dx, dy = (d * ENGRAVE_SCALE for d in cut["shadow_offset"])
    light = mask.filter(ImageFilter.GaussianBlur(cut["shadow_softness"] * ENGRAVE_SCALE)).transform(
        mask.size, Image.Transform.AFFINE, (1, 0, -dx, 0, 1, -dy), Image.Resampling.BICUBIC,
    )
    recess = Image.composite(floor, shadow, light)
    return Image.composite(recess, stone, mask).resize(plate.size, Image.Resampling.LANCZOS)


def pack(spec, root=ROOT, icons=None):
    base = Image.open(root / spec["button_base"])
    cols, rows = len(spec["columns"]), len(spec["rows"])
    if icons is None:
        side = spec["cell_size"]
        with Image.open(root / spec["source"]) as chips:
            assert chips.size == (cols * side, side), "Expected a single strip of standalone gems"
            icons = [chips.crop((col * side, 0, (col + 1) * side, side)) for col in range(cols)]
    assert base.mode == "RGBA" and base.size == (SLOT_SIZE, SLOT_SIZE)
    assert len(icons) == cols and all(icon.mode == "RGBA" for icon in icons)
    base = circular_plate(base, spec["button_outer_radius"])
    base_alpha = base.getchannel("A")
    outside_button = base_alpha.point(lambda a: 255 if a < 128 else 0)
    mask = rounded_mask(base.size, **spec["button_inset"])
    plates = {state: button_face(base, mask, spec["button_states"][state]) for state in spec["rows"][1:]}
    disabled_style = spec["button_states"]["disabled"]
    floor = cutout_floor(plates["disabled"], disabled_style["cutout"])
    atlas = Image.new("RGBA", (SLOT_SIZE * cols, SLOT_SIZE * rows))
    sizes = spec.get("icon_sizes", {})
    for x, (key, source) in enumerate(zip(spec["columns"], icons)):
        bounds = sizes.get(key, {})
        board_size = bounds.get("board", BOARD_ICON_SIZE)
        button_size = bounds.get("button", BUTTON_ICON_SIZE)
        # Preserve the board glyph's existing visible bounds and soft alpha.
        l, t, r, b = source.getchannel("A").point(lambda a: 255 if a >= 128 else 0).getbbox()
        source = source.crop((l - 2, t - 2, r + 2, b + 2))
        chip = source.copy()
        chip.thumbnail((board_size, board_size), Image.Resampling.LANCZOS)
        atlas.paste(center(chip), (x * SLOT_SIZE, 0))
        chip.thumbnail((button_size, button_size), Image.Resampling.LANCZOS)
        icon = center(chip)
        # Keep subpixel alpha coverage through the engraving and inner shadow.
        # The small optical softness also smooths outlines from prepacked glyphs.
        size = (chip.width * ENGRAVE_SCALE, chip.height * ENGRAVE_SCALE)
        outline = source.getchannel("A").resize(size, Image.Resampling.LANCZOS)
        outline = outline.filter(ImageFilter.GaussianBlur(.28 * ENGRAVE_SCALE))
        cut = center(outline, SLOT_SIZE * ENGRAVE_SCALE)
        assert not ImageChops.multiply(icon.getchannel("A"), outside_button).getbbox(), "Icon extends beyond the button"
        for y, (state, plate) in enumerate(plates.items(), 1):
            face = engrave(plate, cut, floor, disabled_style) if state == "disabled" else Image.alpha_composite(plate, icon)
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
