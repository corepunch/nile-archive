#!/usr/bin/env python3
"""Launch each built game in an existing iOS Simulator and require a rendered frame.

Run on the macOS CI runner; Simulator caches stay in the cloud.

Only one simulator runs at a time: two cold devices compete for CPU, memory and
installation services on the runner. Log each slow simctl operation so install,
boot and launch time are distinguishable from time spent in game code. Launches
remain bounded, with logs and one retry on a stall.
"""
import json
from pathlib import Path
import subprocess
import time

ROOT = Path(__file__).resolve().parents[2]
LAUNCH_TIMEOUT = 120   # seconds for `simctl launch` to return
LAUNCH_ATTEMPTS = 2


def sim(*args, timeout=300):
    started = time.monotonic()
    try:
        return subprocess.check_output(['xcrun', 'simctl', *args], text=True, timeout=timeout).strip()
    finally:
        elapsed = time.monotonic() - started
        print(f'simctl {args[0]}: {elapsed:.1f}s', flush=True)


def quiet(*args, timeout=60):
    """A best-effort simctl call whose failure must not mask the real error."""
    try:
        subprocess.run(['xcrun', 'simctl', *args], capture_output=True, text=True, timeout=timeout)
    except (subprocess.SubprocessError, OSError):
        pass


def launch_logs(udid, game):
    """The last few minutes of launch services and the game's own log lines."""
    predicate = (f'process == "{game}" OR process == "SpringBoard" OR subsystem == "com.apple.FrontBoard"'
                 ' OR subsystem == "com.apple.runningboard"')
    try:
        out = subprocess.run(['xcrun', 'simctl', 'spawn', udid, 'log', 'show', '--last', '3m', '--style', 'compact',
                              '--predicate', predicate], capture_output=True, text=True, timeout=120).stdout
    except (subprocess.SubprocessError, OSError) as error:
        out = f'(log show failed: {error})'
    lines = out.strip().splitlines()
    print(f'--- {game}: last {min(len(lines), 80)} simulator log lines ---', flush=True)
    print('\n'.join(lines[-80:]), flush=True)


def launch(udid, game, bundle, *args):
    for attempt in range(1, LAUNCH_ATTEMPTS + 1):
        started = time.monotonic()
        try:
            sim('launch', udid, bundle, *args, timeout=LAUNCH_TIMEOUT)
            print(f'{game}: launched in {time.monotonic() - started:.0f}s (attempt {attempt})', flush=True)
            return
        except subprocess.TimeoutExpired:
            print(f'{game}: simctl launch did not return within {LAUNCH_TIMEOUT}s (attempt {attempt})', flush=True)
            launch_logs(udid, game)
            quiet('terminate', udid, bundle)
            time.sleep(5)
    raise RuntimeError(f'{game}: simctl launch stalled {LAUNCH_ATTEMPTS} times; see the simulator logs above')


def main():
    devices = json.loads(sim('list', 'devices', 'available', '--json'))['devices']
    candidates = [device for runtime, group in devices.items() if '.iOS-' in runtime
                  for device in group if device.get('isAvailable')]
    if not candidates:
        raise SystemExit('No installed iOS Simulator device available')
    groups = [('iPad', [('nile-archive', 'com.corepunch.nilearchive'), ('volcano', 'com.corepunch.volcano')]),
              ('iPhone', [('relic-rush', 'com.corepunch.relicrush'), ('christmas-market', 'com.corepunch.christmasmarket')])]
    plan = []
    for family, games in groups:
        matching = [d for d in candidates if d['name'].startswith(family)]
        if not matching:
            raise RuntimeError(f'No {family} Simulator device available')
        device = next((d for d in matching if d['state'] == 'Booted'), matching[0])
        plan.append((family, games, device['udid'], device['state'] != 'Booted'))
    booted_here = []
    try:
        for family, games, udid, cold in plan:
            if cold:
                sim('boot', udid)
                booted_here.append(udid)
            started = time.monotonic()
            sim('bootstatus', udid, '-b')
            print(f'{family}: booted, waited {time.monotonic() - started:.0f}s', flush=True)
            for game, bundle in games:
                app = ROOT / f'build/xcode-{game}/Build/Products/Debug-iphonesimulator/{game}.app'
                if not app.is_dir():
                    raise RuntimeError(f'{game}: Simulator app missing at {app}')
                sim('install', udid, str(app))
                data = Path(sim('get_app_container', udid, bundle, 'data'))
                shot = data / 'Documents/platform-smoke.png'
                shot.unlink(missing_ok=True)
                launch(udid, game, bundle, '--fresh', '--mute', '--frames', '4', '--shot', str(shot))
                try:
                    deadline = time.monotonic() + 60
                    png = b''
                    while time.monotonic() < deadline:
                        png = shot.read_bytes() if shot.exists() else b''
                        if len(png) > 10000 and png[-12:] == b'\0\0\0\0IEND\xaeB`\x82':
                            break
                        time.sleep(.5)
                    else:
                        raise RuntimeError(f'{game}: no complete screenshot; check UIKit lifecycle and GL setup')
                    destination = ROOT / f'build/ios-smoke/{game}.png'
                    destination.parent.mkdir(parents=True, exist_ok=True)
                    destination.write_bytes(png)
                    print(f'{game}: iOS launch and rendering passed on {family}', flush=True)
                finally:
                    quiet('terminate', udid, bundle)
            # Release this family's resources before booting the next one.
            if udid in booted_here:
                quiet('shutdown', udid, timeout=120)
                booted_here.remove(udid)
    finally:
        for udid in booted_here:
            quiet('shutdown', udid, timeout=120)


if __name__ == '__main__':
    main()
