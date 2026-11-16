#!/usr/bin/env python3
"""Extract the two original PNGs embedded in Cradle of Rome 2's cell hint."""

from hashlib import sha256
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'reference/cradle-of-rome-2/resources/particles/cell_hint_blue.ptc'
OUTPUT = ROOT / 'engine/art/match3/rome-2-cell-hint'
SPRITES = {'Star_02_16.png': (16873, 3101), 'Star_16.png': (20199, 3150)}


if __name__ == '__main__':
    data = SOURCE.read_bytes()
    assert sha256(data).hexdigest() == '0cf69bd0044307b34a0114ee847d2a8c8c00ef6dc2dd396b219bb115315b29db', SOURCE
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for name, (offset, length) in SPRITES.items():
        (OUTPUT / name).write_bytes(data[offset:offset + length])
