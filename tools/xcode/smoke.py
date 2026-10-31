#!/usr/bin/env python3
"""Launch each built game in an existing iOS Simulator and require a rendered frame.

Run on the macOS CI runner; Simulator caches stay in the cloud.
"""
import json
from pathlib import Path
import subprocess
import time

ROOT = Path(__file__).resolve().parents[2]


def sim(*args):
    return subprocess.check_output(['xcrun', 'simctl', *args], text=True, timeout=300).strip()


def main():
    devices = json.loads(sim('list', 'devices', 'available', '--json'))['devices']
    candidates = [device for runtime, group in devices.items() if '.iOS-' in runtime
                  for device in group if device.get('isAvailable')]
    if not candidates:
        raise SystemExit('No installed iOS Simulator device available')
    groups = [('iPad', [('nile-archive', 'com.corepunch.nilearchive'), ('volcano', 'com.corepunch.volcano'), ('clayfight', 'com.corepunch.clayfight')]),
              ('iPhone', [('relic-rush', 'com.corepunch.relicrush'), ('christmas-market', 'com.corepunch.christmasmarket')])]
    for family, games in groups:
        matching = [d for d in candidates if d['name'].startswith(family)]
        if not matching:
            raise RuntimeError(f'No {family} Simulator device available')
        device = next((d for d in matching if d['state'] == 'Booted'), matching[0])
        udid = device['udid']
        booted_here = device['state'] != 'Booted'
        try:
            if booted_here:
                sim('boot', udid)
            sim('bootstatus', udid, '-b')
            for game, bundle in games:
                app = ROOT / f'build/xcode-{game}/Build/Products/Debug-iphonesimulator/{game}.app'
                if not app.is_dir():
                    raise RuntimeError(f'{game}: Simulator app missing at {app}')
                sim('install', udid, str(app))
                data = Path(sim('get_app_container', udid, bundle, 'data'))
                shot = data / 'Documents/platform-smoke.png'
                shot.unlink(missing_ok=True)
                sim('launch', udid, bundle, '--fresh', '--mute', '--frames', '4', '--shot', str(shot))
                try:
                    deadline = time.monotonic() + 60
                    png = b''
                    while time.monotonic() < deadline:
                        png = shot.read_bytes() if shot.exists() else b''
                        if len(png) > (2000 if game == 'clayfight' else 10000) and png[-12:] == b'\0\0\0\0IEND\xaeB`\x82':
                            break
                        time.sleep(.5)
                    else:
                        raise RuntimeError(f'{game}: no complete screenshot; check UIKit lifecycle and GL setup')
                    destination = ROOT / f'build/ios-smoke/{game}.png'
                    destination.parent.mkdir(parents=True, exist_ok=True)
                    destination.write_bytes(png)
                    print(f'{game}: iOS launch and rendering passed on {family}', flush=True)
                finally:
                    sim('terminate', udid, bundle)
        finally:
            if booted_here:
                sim('shutdown', udid)


if __name__ == '__main__':
    main()
