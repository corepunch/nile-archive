#!/usr/bin/env python3
"""Resize the supplied-character cutout and single authored app-icon master."""
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]

def main():
    portrait = Image.open(ROOT / 'art/noelle.png').convert('RGBA')
    portrait_path = ROOT / 'data/characters/noelle.png'
    portrait_path.parent.mkdir(parents=True, exist_ok=True)
    portrait.resize((320, 480), Image.Resampling.LANCZOS).save(portrait_path)

    master = Image.open(ROOT / 'art/app-icon-source.png')
    assert master.width == master.height, 'App icon must be square'
    assert master.mode == 'RGB', 'App icon must be fully opaque'
    icon = master.resize((1024, 1024), Image.Resampling.LANCZOS)
    icon.save(ROOT / 'art/app-icon-1024.png')
    catalogue = ROOT / 'Assets.xcassets'
    icons = catalogue / 'AppIcon.appiconset'
    icons.mkdir(parents=True, exist_ok=True)
    info = {'author': 'xcode', 'version': 1}
    (catalogue / 'Contents.json').write_text(json.dumps({'info': info}, indent=2) + '\n')
    icon.save(icons / 'app-icon-1024.png')
    entries = [{'filename': 'app-icon-1024.png', 'idiom': 'universal',
                'platform': 'ios', 'size': '1024x1024'}]
    for point_size in (16, 32, 128, 256, 512):
        for scale in (1, 2):
            pixels = point_size * scale
            name = f'app-icon-mac-{pixels}.png'
            icon.resize((pixels, pixels), Image.Resampling.LANCZOS).save(icons / name)
            entries.append({'filename': name, 'idiom': 'mac',
                            'scale': f'{scale}x', 'size': f'{point_size}x{point_size}'})
    (icons / 'Contents.json').write_text(json.dumps({'images': entries, 'info': info}, indent=2) + '\n')

if __name__ == '__main__':
    main()
