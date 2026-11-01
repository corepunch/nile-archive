#!/usr/bin/env python3
"""Build, install and launch one game on an available physical iPhone/iPad."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import plistlib
import re
import shlex
import ssl
import subprocess
import sys
import tempfile

from generate import GAMES, ROOT, read_project


def run(command, **kwargs):
    print('+ ' + shlex.join(map(str, command)), flush=True)
    return subprocess.run(list(map(str, command)), check=True, **kwargs)


def available_devices():
    # CoreDevice's availability includes labels such as "available (paired)".
    # Ask the service to filter these: tunnelState=disconnected is also normal
    # for a reachable paired device before an install establishes its tunnel.
    with tempfile.TemporaryDirectory(prefix='nile-ios-') as folder:
        output = Path(folder) / 'devices.json'
        run(['xcrun', 'devicectl', 'list', 'devices', '--timeout', '30',
             '--filter', "State BEGINSWITH 'available' OR State BEGINSWITH 'connected'",
             '--json-output', output])
        return json.loads(output.read_text())['result']['devices']


def device_fields(device):
    properties = device.get('properties', {})
    hardware = properties.get('hardware', device.get('hardwareProperties', {}))
    state = properties.get('state', device.get('deviceProperties', {}))
    return hardware, state


def select_device(devices, meta, requested=''):
    preferred = 'iPhone' if meta['device'] == 'iphone' else 'iPad'
    families = meta.get('families', '1' if preferred == 'iPhone' else '2').split(',')
    allowed = {'iPhone' if family == '1' else 'iPad' for family in families}
    candidates = []
    for device in devices:
        hardware, state = device_fields(device)
        if hardware.get('reality') != 'physical' or hardware.get('platform') != 'iOS':
            continue
        if hardware.get('deviceType') not in allowed:
            continue
        identifiers = {str(device.get('identifier', '')), str(hardware.get('udid', '')),
                       str(hardware.get('ecid', '')), state.get('name', '')}
        if not requested or requested in identifiers:
            candidates.append(device)
    if not requested:
        same_family = [d for d in candidates if device_fields(d)[0]['deviceType'] == preferred]
        if same_family:
            candidates = same_family
    if len(candidates) != 1:
        names = ', '.join(device_fields(d)[1].get('name', d['identifier']) for d in candidates) or 'none'
        raise ValueError(f'Expected one available physical {preferred}' +
                         (f' matching DEVICE={requested}' if requested else '') +
                         f'; found {len(candidates)} ({names}). Run make list-devices and set DEVICE="name or UDID".')
    return candidates[0]


def project_team(project, scheme, configuration):
    objects = read_project(project / 'project.pbxproj')
    for obj in objects.values():
        if obj.get('isa') == 'PBXNativeTarget' and obj.get('name') == scheme:
            configs = objects[obj['buildConfigurationList']]['buildConfigurations']
            for ref in configs:
                config = objects[ref]
                if config['name'] == configuration:
                    return config['buildSettings'].get('DEVELOPMENT_TEAM', '')
    return ''


def signing_team(project, scheme, configuration, requested=''):
    team = requested or project_team(project, scheme, configuration)
    if team:
        return team
    identities = subprocess.check_output(['security', 'find-identity', '-v', '-p', 'codesigning'], text=True)
    valid = set()
    for line in identities.splitlines():
        match = re.search(r'\b([A-F0-9]{40})\s+"Apple Development:', line)
        if match and 'CSSMERR_' not in line:
            valid.add(match[1])
    teams = set()
    if valid:
        certificates = subprocess.check_output(
            ['security', 'find-certificate', '-a', '-c', 'Apple Development', '-p'], text=True)
        for pem in re.findall(r'-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----', certificates, re.S):
            fingerprint = hashlib.sha1(ssl.PEM_cert_to_DER_cert(pem)).hexdigest().upper()
            if fingerprint not in valid:
                continue
            # The common-name suffix is a person ID, not the development team.
            # The certificate's organizational unit is the actual Team ID.
            subject = subprocess.check_output(['openssl', 'x509', '-noout', '-subject', '-nameopt', 'RFC2253'],
                                              input=pem + '\n', text=True)
            teams.update(re.findall(r'(?:^|,)OU=([A-Z0-9]{10})(?=,|$)', subject.strip()))
    if len(teams) != 1:
        raise ValueError('No unique Apple Development signing team. Set TEAM=... or select a development team '
                         'in the game\'s Xcode project; install its signing certificate in Keychain.')
    return teams.pop()


def deploy(args):
    meta = GAMES[args.game]
    scheme = f"{args.game}-{meta['device']}"
    project = ROOT / 'games' / args.game / f'{args.game}.xcodeproj'
    device = select_device(available_devices(), meta, args.device)
    hardware, state = device_fields(device)
    # xcodebuild uses the hardware UDID; CoreDevice also accepts that identifier.
    udid = hardware.get('udid', device['identifier'])
    print(f"Selected {state.get('name', udid)} ({hardware['deviceType']}, {udid})", flush=True)
    team = signing_team(project, scheme, args.configuration, args.team)
    derived = args.build_dir.resolve()
    # Override Xcode's user-level custom build locations as well as DerivedData.
    # Otherwise a successful build can land under games/<game>/Build instead.
    products = derived / 'Build' / 'Products'
    intermediates = derived / 'Build' / 'Intermediates.noindex'
    run(['xcodebuild', '-project', project, '-scheme', scheme,
         '-configuration', args.configuration, '-sdk', 'iphoneos',
         '-destination', f'id={udid}', '-destination-timeout', '30',
         '-derivedDataPath', derived, '-allowProvisioningUpdates', '-allowProvisioningDeviceRegistration',
         f'SYMROOT={products}', f'OBJROOT={intermediates}',
         f'DEVELOPMENT_TEAM={team}', 'CODE_SIGN_STYLE=Automatic', 'build'], cwd=ROOT)
    app = products / f'{args.configuration}-iphoneos' / f'{args.game}.app'
    with (app / 'Info.plist').open('rb') as stream:
        bundle = plistlib.load(stream)['CFBundleIdentifier']
    run(['xcrun', 'devicectl', 'device', 'install', 'app', '--timeout', '120', '--device', udid, app])
    run(['xcrun', 'devicectl', 'device', 'process', 'launch', '--device', udid,
         '--timeout', '30', '--terminate-existing', bundle, '--', *args.app_args])
    print(f'Installed and launched {args.game} on {state.get("name", udid)}.', flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('game', choices=GAMES)
    parser.add_argument('--device', default=os.environ.get('DEVICE', ''))
    parser.add_argument('--team', default=os.environ.get('TEAM', ''))
    parser.add_argument('--configuration', choices=('Debug', 'Release'),
                        default=os.environ.get('CONFIGURATION') or 'Debug')
    parser.add_argument('--build-dir', type=Path, default=Path(os.environ.get('IOS_BUILD_DIR') or ROOT / 'build/ios'))
    parser.add_argument('--app-args', default=os.environ.get('ARGS', ''))
    args = parser.parse_args()
    if sys.platform != 'darwin':
        parser.error('Device deployment requires macOS with Xcode and a paired iPhone/iPad.')
    try:
        args.app_args = shlex.split(args.app_args)
        deploy(args)
    except (ValueError, OSError, KeyError, subprocess.SubprocessError) as error:
        print(f'iOS deployment failed: {error}', file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
