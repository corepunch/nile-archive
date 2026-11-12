#!/usr/bin/env python3
"""Check registered RGBA sprites against the engine's flat-top tile face."""
import argparse
import json
import math
from pathlib import Path
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]


def hex_mask(size):
    """Rasterize the engine's regular hex, at four times resolution for antialiasing."""
    w, h = size
    if w != h:
        raise ValueError('a registered tile canvas must be square')
    supersample = 4
    c = w * supersample / 2
    r = c
    dy = math.sqrt(3) * r / 2
    result = Image.new('L', (w * supersample, h * supersample))
    ImageDraw.Draw(result).polygon([(0, c), (r / 2, c - dy), (3 * r / 2, c - dy),
                                    (2 * r, c), (3 * r / 2, c + dy), (r / 2, c + dy)], fill=255)
    return result.resize(size, Image.Resampling.LANCZOS)


def binary(image):
    return image.point(lambda value: 255 if value >= 128 else 0)


def count(image):
    return image.histogram()[255]


def inspect(image, mode='fill', strict=False, exact=False):
    if image.mode != 'RGBA':
        raise ValueError('art must be RGBA with authored alpha')
    reference = hex_mask(image.size)
    raw_alpha = image.getchannel('A')
    difference = ImageChops.difference(raw_alpha, reference)
    alpha_error_pixels = image.width * image.height - difference.histogram()[0]
    alpha_max_error = difference.getextrema()[1]
    mask = binary(reference)
    alpha = binary(raw_alpha)
    inside = ImageChops.multiply(alpha, mask)
    outside = ImageChops.subtract(alpha, mask)
    inner = mask.filter(ImageFilter.MinFilter(5))
    edge = ImageChops.subtract(mask, inner)
    inside_count, outside_count = count(inside), count(outside)
    pixels, edge_pixels = count(mask), count(edge)
    coverage = inside_count / pixels if pixels else 0
    spill = outside_count / max(1, inside_count + outside_count)
    edge_coverage = count(ImageChops.multiply(alpha, edge)) / edge_pixels if edge_pixels else 0
    # A fill is required to cover the face and reach its boundary. Frame and
    # object art may leave intentional transparent holes or use a small centre.
    passed = inside_count > 0 and spill <= (.005 if strict else .01)
    if mode == 'fill':
        passed = passed and coverage >= (.995 if strict else .97) and edge_coverage >= (.95 if strict else .80)
    if exact:
        passed = passed and alpha_error_pixels == 0
    return {'coverage': coverage, 'spill': spill, 'edge_coverage': edge_coverage,
            'alpha_error_pixels': alpha_error_pixels, 'alpha_max_error': alpha_max_error,
            'inside_pixels': inside_count, 'outside_pixels': outside_count, 'pass': passed}


def overlay(image):
    mask = binary(hex_mask(image.size))
    alpha = binary(image.getchannel('A'))
    result = Image.new('RGB', image.size, (36, 43, 45))
    result.paste((98, 108, 112), (0, 0), mask)
    result.paste((231, 228, 204), (0, 0), ImageChops.multiply(alpha, mask))
    result.paste((255, 70, 70), (0, 0), ImageChops.subtract(alpha, mask))
    edge = ImageChops.subtract(mask, mask.filter(ImageFilter.MinFilter(3)))
    result.paste((61, 230, 183), (0, 0), edge)
    return result



def write_reference():
    out = ROOT / 'engine/art/hex-tile'
    out.mkdir(parents=True, exist_ok=True)
    for n in (128, 181):
        mask = hex_mask((n, n))
        image = Image.new('RGBA', (n, n), 'white')
        image.putalpha(mask)
        image.save(out / f'hex-mask-{n}.png')
    n = 181
    mask = hex_mask((n, n))
    cell = Image.new('RGB', (n, n), (24, 37, 38))
    cell.paste((199, 220, 211), (0, 0), mask)
    cell.save(out / 'hex-mask-preview.png')
    atlas = Image.new('RGB', (8 * n, 6 * n), (24, 37, 38))
    for y in range(6):
        for x in range(8):
            atlas.paste(cell, (x * n, y * n))
    atlas.save(out / 'atlas-template-8x6-181.png')

def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('images', nargs='*', type=Path, help='RGBA tiles or registered atlases')
    parser.add_argument('--write-reference', action='store_true', help='regenerate the canonical PNG masks and reference sheet')
    parser.add_argument('--strict', action='store_true', help='require 99.5%% fill, 95%% edge and at most 0.5%% spill')
    parser.add_argument('--exact', action='store_true', help='require byte-for-byte canonical alpha (fill mode only)')
    parser.add_argument('--mode', choices=('fill', 'frame', 'object'), default='fill')
    parser.add_argument('--atlas', metavar='COLSxROWS', help='check each equal, square source cell before resizing (e.g. 8x6)')
    parser.add_argument('--cells', help='comma-separated zero-based atlas cell indices to check')
    parser.add_argument('--overlay-dir', type=Path, help='write overlays: grey missing, cream covered, red spill, green expected edge')
    args = parser.parse_args(argv)
    if args.write_reference:
        write_reference()
        if not args.images: return 0
    if not args.images:
        parser.error('supply at least one image or --write-reference')
    if args.exact and args.mode != 'fill':
        parser.error('--exact requires --mode fill')
    if args.cells and not args.atlas:
        parser.error('--cells requires --atlas')
    try:
        grid = tuple(map(int, args.atlas.lower().split('x'))) if args.atlas else None
        if grid and (len(grid) != 2 or min(grid) <= 0):
            raise ValueError('atlas grid must be COLSxROWS')
        cells = {int(x) for x in args.cells.split(',')} if args.cells else None
        if cells and (min(cells) < 0 or max(cells) >= grid[0] * grid[1]):
            raise ValueError('atlas cell index outside grid')
        reports = []
        for path in args.images:
            with Image.open(path) as opened:
                image = opened.copy()
            if image.mode != 'RGBA':
                raise ValueError(f'{path}: art must be RGBA with authored alpha')
            if grid:
                cols, rows = grid
                if image.width % cols or image.height % rows:
                    raise ValueError(f'{path}: atlas dimensions do not divide evenly by grid')
                w, h = image.width // cols, image.height // rows
                if w != h:
                    raise ValueError(f'{path}: atlas cells must be square')
                items = [(i, image.crop(((i % cols) * w, (i // cols) * h,
                                          (i % cols + 1) * w, (i // cols + 1) * h)))
                         for i in range(cols * rows) if cells is None or i in cells]
            else:
                items = [(None, image)]
            for index, tile in items:
                result = inspect(tile, args.mode, args.strict, args.exact)
                result.update({'file': str(path), 'cell': index, 'mode': args.mode, 'strict': args.strict, 'exact': args.exact})
                reports.append(result)
                if args.overlay_dir:
                    args.overlay_dir.mkdir(parents=True, exist_ok=True)
                    suffix = '' if index is None else f'-{index:02d}'
                    overlay(tile).save(args.overlay_dir / f'{path.stem}{suffix}-overlay.png')
        print(json.dumps(reports, indent=2))
        return 0 if all(row['pass'] for row in reports) else 1
    except (OSError, ValueError) as error:
        print(str(error), file=sys.stderr)
        return 2


if __name__ == '__main__':
    sys.exit(main())
