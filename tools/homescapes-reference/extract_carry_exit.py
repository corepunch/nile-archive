#!/usr/bin/env python3
"""Extract CarryExitForAnim from the decoded Homescapes 9.2.601 atlas page.

Generate the source page first with decode_board_atlases.py. The rectangle
comes from the original decoded Match3_00.xml, whose coordinates start at the
bottom; the page PNG is already vertically flipped.
"""
import argparse
from hashlib import sha256
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
PAGE = ROOT / 'reference/homescapes-analysis/board-art/pages/Match3_00.png'
DEST = ROOT / 'engine/art/homescapes/sprites/carry-exit-arrow.png'
PAGE_SHA256 = '89ab416cbb1a1dd76676050ef3b82eb48909e5a25209d008978a12215278a7e5'
PNG_SHA256 = 'ab748d9b2d5d108b0fa7dddcb6ff1711640ae0afc43ebb64615d496d79b945e4'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    if sha256(PAGE.read_bytes()).hexdigest() != PAGE_SHA256:
        raise SystemExit('Unexpected source atlas page')
    with Image.open(PAGE) as page:
        sprite = page.crop((1021, 1222, 1101, 1254))
        if args.check:
            if not DEST.exists() or sha256(DEST.read_bytes()).hexdigest() != PNG_SHA256:
                raise SystemExit('Output differs')
        else:
            sprite.save(DEST)
            if sha256(DEST.read_bytes()).hexdigest() != PNG_SHA256:
                raise SystemExit('Unexpected output')
    print('Verified' if args.check else 'Extracted', DEST)


if __name__ == '__main__':
    main()
