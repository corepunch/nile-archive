#!/usr/bin/env python3
"""Export selected atlas artwork to Emergency's iOS and macOS AppIcon slots."""
import hashlib
import json
from pathlib import Path

from PIL import Image

GAME = Path(__file__).resolve().parents[1]


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2) + '\n')


def main():
    selection_path = GAME / 'art/app-icon/selection.json'
    selection = json.loads(selection_path.read_text())
    sheet = Image.open(GAME / selection['source_grid']).convert('RGB')
    selected = sheet.crop(tuple(selection['square_crop_pixels']))
    assert selected.width == selected.height, 'Selected app icon must be square'
    selected_path = GAME / 'art/app-icon/selected.png'
    selected.save(selected_path)
    icon = selected.resize((1024, 1024), Image.Resampling.LANCZOS)
    icon.save(GAME / selection['master'])
    catalog = GAME / 'Assets.xcassets'
    icons = catalog / 'AppIcon.appiconset'
    icons.mkdir(parents=True, exist_ok=True)
    info = {'author': 'xcode', 'version': 1}
    write_json(catalog / 'Contents.json', {'info': info})
    icon.save(icons / 'app-icon-1024.png')
    entries = [{'filename': 'app-icon-1024.png', 'idiom': 'universal', 'platform': 'ios', 'size': '1024x1024'}]
    for points in (16, 32, 128, 256, 512):
        for scale in (1, 2):
            pixels = points * scale
            filename = f'app-icon-mac-{pixels}.png'
            icon.resize((pixels, pixels), Image.Resampling.LANCZOS).save(icons / filename)
            entries.append({'filename': filename, 'idiom': 'mac', 'scale': f'{scale}x', 'size': f'{points}x{points}'})
    write_json(icons / 'Contents.json', {'images': entries, 'info': info})

    # Native app icons live outside the runtime data/ inventory, as in Relic Rush.
    paths = [GAME / selection['source_grid'], GAME / selection['prompt'], selection_path,
             selected_path, GAME / selection['master'], *sorted(catalog.rglob('*'))]
    inventory = {str(path.relative_to(GAME)): hashlib.sha256(path.read_bytes()).hexdigest()
                 for path in paths if path.is_file()}
    catalog_path = GAME / 'docs/asset-catalog.json'
    manifest = json.loads(catalog_path.read_text())
    manifest['app_icon'] = {'selection': str(selection_path.relative_to(GAME)), 'files': inventory}
    write_json(catalog_path, manifest)
    print('Emergency AppIcon: option 12 exported to iOS and 10 macOS slots')


if __name__ == '__main__':
    main()
