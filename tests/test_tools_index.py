#!/usr/bin/env python3
"""Every script under tools/ and games/*/tools/ is listed in tools/README.md.

Run by `make test-assets`. The browser viewers in tools/reference/ are listed
by folder; their own files need no rows.
"""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = {'.py', '.lua', '.sh', '.txt'}
VIEWERS = {'junes-viewer', 'tropicats-viewer'}


def scripts():
    for folder in [ROOT / 'tools', *sorted((ROOT / 'games').glob('*/tools'))]:
        for path in sorted(folder.rglob('*')):
            parts = path.relative_to(folder).parts
            if path.suffix not in SCRIPTS or '__pycache__' in parts or path.name.endswith('.xcodeproj'):
                continue
            if folder.name == 'tools' and folder.parent == ROOT and len(parts) > 1 and parts[-2] in VIEWERS:
                yield path, f'`{parts[-2]}/`'
            else:
                yield path, f'`{"/".join(parts[-2:]) if parts[:-1] and parts[-2] in ("xcode", "cradle-of-rome") else path.name}`'


def main():
    index = (ROOT / 'tools/README.md').read_text()
    missing = sorted({str(path.relative_to(ROOT)) for path, name in scripts() if name not in index})
    for path in missing:
        print(f'tools/README.md does not list {path}; add a row for it')
    print(f'tools index: {len(missing)} missing')
    sys.exit(1 if missing else 0)


if __name__ == '__main__':
    main()
