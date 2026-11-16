"""Fit all six authored story objects on the normal festive chip canvas."""
import argparse
import json
from pathlib import Path
import sys

from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT.parents[1] / 'tools'))
from match3_theme_art import fit_object, reference_areas, silhouette


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    spec = json.loads((ROOT / 'art/manifest.json').read_text())['story_pieces']
    mask = silhouette(Image.open(ROOT / spec['mask'])).filter(ImageFilter.MinFilter(5))
    source = Image.open(ROOT / spec['source'])
    assert source.mode == 'RGBA' and source.size == (1536, 1024)
    target = reference_areas()['chip']
    for name, entry in spec['frames'].items():
        cell = source.crop(entry['crop'])
        left, top, right, bottom = silhouette(cell).getbbox()
        art = cell.crop((left - 5, top - 5, right + 5, bottom + 5))
        frame, _, _ = fit_object(art, mask, 128, target)
        path = ROOT / entry['runtime']
        if args.check:
            assert Image.open(path).tobytes() == frame.tobytes(), f'Stale story piece: {name}'
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            frame.save(path, optimize=True)


if __name__ == '__main__':
    main()
