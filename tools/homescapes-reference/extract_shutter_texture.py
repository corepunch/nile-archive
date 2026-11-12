#!/usr/bin/env python3
"""Convert the 3.5.9 APK's original shutter back texture to RGBA PNG."""
import argparse
from hashlib import sha256
from io import BytesIO
from pathlib import Path
from zipfile import ZipFile
from PIL import Image

p = argparse.ArgumentParser(description=__doc__)
p.add_argument('--apk', type=Path, required=True)
a = p.parse_args()
if sha256(a.apk.read_bytes()).hexdigest() != '8b1a2ac9b4bbf7c4cd3122fcde18e806d3623695c841c6af0c7e14148e1cb093':
    p.error('Unexpected APK hash')
with ZipFile(a.apk) as z:
    b = z.read('assets/base_mm/textures/Match3/Shutters/back.webp')
    im = Image.open(BytesIO(b)).convert('RGBA')
    im.save(Path(__file__).resolve().parents[2] / 'engine/art/homescapes/sprites/blind-body.png')
    print('Source WebP SHA-256:', sha256(b).hexdigest(), 'size:', im.size)
