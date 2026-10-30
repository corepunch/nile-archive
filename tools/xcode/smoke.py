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
    return subprocess.check_output(['xcrun', 'simctl', *args], text=True).strip()


def main():
    devices = json.loads(sim('list', 'devices', 'available', '--json'))['devices']
    candidates = [device for runtime, group in devices.items() if '.iOS-' in runtime
                  for device in group if device.get('isAvailable')]
    if not candidates:
        raise SystemExit('No installed iOS Simulator device available')
    device = next((d for d in candidates if d['state'] == 'Booted'), candidates[0])
    udid = device['udid']
    booted_here = device['state'] != 'Booted'
    try:
        if booted_here:
            sim('boot', udid)
        sim('bootstatus', udid, '-b')
        for game, bundle in [('nile-archive', 'com.corepunch.nilearchive'),
                             ('relic-rush', 'com.corepunch.relicrush'),
                             ('volcano', 'com.corepunch.volcano')]:
            apps = list((ROOT / f'build/xcode-{game}').glob(f'Build/Products/Debug-iphonesimulator/{game}.app'))
            if len(apps) != 1:
                raise RuntimeError(f'{game}: expected one built Simulator app, found {apps}')
            sim('install', udid, str(apps[0]))
            data = Path(sim('get_app_container', udid, bundle, 'data'))
            shot = data / 'Documents/platform-smoke.png'
            shot.unlink(missing_ok=True)
            sim('launch', udid, bundle, '--fresh', '--mute', '--frames', '4', '--shot', str(shot))
            try:
                deadline = time.monotonic() + 60
                while time.monotonic() < deadline and not shot.exists():
                    time.sleep(.5)
                if not shot.exists() or shot.stat().st_size < 10000:
                    raise RuntimeError(f'{game}: no rendered screenshot; check UIKit lifecycle and GL setup')
                destination = ROOT / f'build/ios-smoke/{game}.png'
                destination.parent.mkdir(parents=True, exist_ok=True)
                destination.write_bytes(shot.read_bytes())
                print(f'{game}: iOS launch and rendering passed', flush=True)
            finally:
                sim('terminate', udid, bundle)
    finally:
        if booted_here:
            sim('shutdown', udid)


if __name__ == '__main__':
    main()
