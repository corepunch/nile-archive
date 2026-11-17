#!/usr/bin/env python3
"""Export the XML-defined board artwork from Cradle of Rome Beta or Cradle of Rome 2."""

import argparse
import re
import struct
from pathlib import Path

from PIL import Image, ImageDraw

from analyze import DEFAULT_ROOT, legacy_xml


BOARD_SCRIPT = Path("settings/scenes/game/game_graphics.xml")
BOARD_ART = re.compile(r"gmbn_(?:\d+|skull)|bns_\w+_fld|gm_back_\d+")

# ETC1 RGB8 modifier magnitudes, in codeword order.
# https://registry.khronos.org/OpenGL/extensions/OES/OES_compressed_ETC1_RGB8_texture.txt
MODIFIERS = ((2, 8), (5, 17), (9, 29), (13, 42), (18, 60), (24, 80), (33, 106), (47, 183))


def palette(color, codeword):
    small, large = MODIFIERS[codeword]
    return [bytes(max(0, min(255, channel + delta)) for channel in color)
            for delta in (small, large, -small, -large)]


def decode_etc(path):
    data = path.read_bytes()
    if len(data) < 128 or data[:8] != b"DDS |\x00\x00\x00" or data[84:88] != b"ETC ":
        raise ValueError(f"{path}: expected a DDS texture with the ETC FourCC")
    height, width, length = struct.unpack_from("<III", data, 12)
    mipmaps, = struct.unpack_from("<I", data, 28)
    if (not width or not height or width % 4 or height % 4 or mipmaps != 1
            or length != width * height // 2 or len(data) != 128 + length):
        raise ValueError(f"{path}: unexpected ETC texture dimensions or payload length")

    rgb = bytearray(width * height * 3)
    blocks_per_row = width // 4
    for i, (red, green, blue, mode, selectors) in enumerate(
            struct.iter_unpack(">4BI", memoryview(data)[128:])):
        channels = red, green, blue
        if mode & 2:
            first = [channel >> 3 for channel in channels]
            deltas = [(channel & 3) - (channel & 4) for channel in channels]
            second = [base + delta for base, delta in zip(first, deltas)]
            if any(not 0 <= channel < 32 for channel in second):
                raise ValueError(f"{path}: invalid ETC1 differential block {i}")
            first, second = ([c << 3 | c >> 2 for c in color] for color in (first, second))
        else:
            first = [(channel >> 4) * 17 for channel in channels]
            second = [(channel & 15) * 17 for channel in channels]
        colors = palette(first, mode >> 5), palette(second, (mode >> 2) & 7)
        block_y, block_x = divmod(i, blocks_per_row)
        for y in range(4):
            row = ((4 * block_y + y) * width + 4 * block_x) * 3
            for x in range(4):
                subblock = (y if mode & 1 else x) // 2
                bit = x * 4 + y
                selector = ((selectors >> bit) & 1) | ((selectors >> (bit + 15)) & 2)
                start = row + x * 3
                rgb[start:start + 3] = colors[subblock][selector]
    return Image.frombytes("RGB", (width, height), bytes(rgb))


def export_textures(root, output):
    decoded = {}
    for path in sorted(root.rglob("*.etc")):
        logical = path.relative_to(root).with_suffix("")
        target = (output / logical).with_suffix(".png")
        target.parent.mkdir(parents=True, exist_ok=True)
        decode_etc(path).save(target)
        decoded[logical.as_posix()] = target
    return decoded


def export_sprites(root, apk_assets, output, decoded, board_only):
    count = 0
    scripts = [root / BOARD_SCRIPT] if board_only else sorted(root.rglob("*.xml"))
    for script in scripts:
        if b"<Texture " not in script.read_bytes():
            continue
        folder = output / "sprites" / script.relative_to(root).with_suffix("")
        for texture in legacy_xml(script).iter("Texture"):
            sprites = texture.findall("Sprite")
            if board_only:
                sprites = [sprite for sprite in sprites if BOARD_ART.fullmatch(sprite.attrib["alias"])]
            if not sprites:
                continue
            name = texture.attrib["file"].lower().replace("\\", "/")
            source = decoded.get(name, root / name)
            if not source.is_file():
                source = apk_assets / name
            with Image.open(source) as original:
                image = original.convert("RGBA")
            folder.mkdir(parents=True, exist_ok=True)
            for sprite in sprites:
                alias = sprite.attrib["alias"]
                if not re.fullmatch(r"[\w-]+", alias):
                    raise ValueError(f"{script}: invalid sprite alias {alias!r}")
                frames = sprite.findall("Frame") or [sprite]
                for number, frame in enumerate(frames, 1):
                    x, y, width, height = map(int, frame.attrib["rect"].split())
                    if (min(x, y) < 0 or min(width, height) <= 0
                            or x + width > image.width or y + height > image.height):
                        raise ValueError(f"{script}: invalid rectangle for {alias}")
                    target = folder / f"{alias}.png"
                    if len(frames) > 1:
                        target = folder / alias / f"{number:02}.png"
                        target.parent.mkdir(exist_ok=True)
                    crop = image.crop((x, y, x + width, y + height))
                    crop.save(target)
                    count += 1
    return count


def contact_sheet(paths, target, columns, cell):
    width, height = cell
    rows = (len(paths) + columns - 1) // columns
    sheet = Image.new("RGB", (width * columns, height * rows), "#253135")
    draw = ImageDraw.Draw(sheet)
    for index, path in enumerate(paths):
        row, column = divmod(index, columns)
        cx = column * width + width // 2
        with Image.open(path) as source:
            thumb = source.convert("RGBA")
            thumb.thumbnail((width - 12, height - 24), Image.Resampling.LANCZOS)
            sheet.paste(thumb, (cx - thumb.width // 2, row * height + 6), thumb)
        label = path.parent.name if path.stem.isdecimal() else path.stem
        draw.text((cx, (row + 1) * height - 6), label, fill="white", anchor="ms")
    sheet.save(target)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=DEFAULT_ROOT, help="extracted resources directory")
    parser.add_argument("--apk-assets", type=Path, help="defaults to apk/assets next to the resources directory")
    parser.add_argument("--output", type=Path, help="new output directory, defaults to visuals next to resources")
    parser.add_argument("--board-only", action="store_true", help="export board pieces, bonuses and backdrops")
    args = parser.parse_args()
    output = args.output or args.root.with_name("visuals")
    apk_assets = args.apk_assets or args.root.with_name("apk") / "assets"
    output.mkdir()
    decoded = export_textures(args.root, output)
    count = export_sprites(args.root, apk_assets, output, decoded, args.board_only)
    board = output / "sprites" / BOARD_SCRIPT.with_suffix("")
    chips = [board / f"gmbn_{n}.png" for n in range(1, 17)] + [board / "gmbn_skull.png"]
    multiball = board / "gmbn_17/01.png"
    if multiball.is_file():
        chips.append(multiball)
    chips.extend(sorted(board.glob("bns_*_fld.png")))
    contact_sheet(chips, output / "board-pieces.png", 5, (118, 84))
    contact_sheet(sorted(board.glob("gm_back_*.png")), output / "board-backgrounds.png", 4, (236, 188))
    print(f"Decoded {len(decoded)} textures and exported {count} sprite and frame PNGs to {output}")


if __name__ == "__main__":
    main()
