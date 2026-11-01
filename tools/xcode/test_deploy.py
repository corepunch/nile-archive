"""Physical-device selection, signing and deploy failure boundaries; no Xcode build."""
import argparse
import hashlib
import json
from pathlib import Path
import plistlib
import ssl
import subprocess
import tempfile
import unittest
from unittest.mock import patch

import deploy
from generate import GAMES


def device(name='Phone', family='iPhone', identifier='core-phone', udid='phone-udid', reality='physical', legacy=False):
    hardware = dict(deviceType=family, platform='iOS', reality=reality, udid=udid, ecid=123)
    state = dict(name=name)
    if legacy:
        return dict(identifier=identifier, hardwareProperties=hardware, deviceProperties=state)
    return dict(identifier=identifier, properties=dict(hardware=hardware, state=state))


class DeviceTests(unittest.TestCase):
    def setUp(self):
        self.phone = device()
        self.pad = device('Tablet', 'iPad', 'core-pad', 'pad-udid')
        self.sim = device('Simulator', reality='simulated')

    def test_each_game_selects_its_family_among_real_and_simulated_devices(self):
        for game, meta in GAMES.items():
            with self.subTest(game=game):
                selected = deploy.select_device([self.sim, self.pad, self.phone], meta)
                self.assertIs(selected, self.phone if meta['device'] == 'iphone' else self.pad)

    def test_missing_or_ambiguous_device_requires_explicit_selection(self):
        for devices in ([], [self.sim], [self.pad], [self.phone, device('Other', identifier='other')]):
            with self.subTest(devices=devices), self.assertRaisesRegex(ValueError, 'DEVICE='):
                deploy.select_device(devices, GAMES['relic-rush'])

    def test_selection_by_exact_name_udid_coredevice_id_or_ecid(self):
        self.phone['properties']['state']['name'] = 'Igor’s iPhone with spaces'
        for key in ('Igor’s iPhone with spaces', 'phone-udid', 'core-phone', '123'):
            self.assertIs(deploy.select_device([self.phone, self.pad], GAMES['relic-rush'], key), self.phone)
        with self.assertRaises(ValueError):
            deploy.select_device([self.phone, self.pad], GAMES['nile-archive'], 'phone-udid')

    def test_universal_christmas_falls_back_to_ipad(self):
        self.assertIs(deploy.select_device([self.pad], GAMES['christmas-market']), self.pad)
        self.assertIs(deploy.select_device([self.pad, self.phone], GAMES['christmas-market'], 'pad-udid'), self.pad)

    def test_old_xcode_json_schema(self):
        phone = device(legacy=True)
        self.assertIs(deploy.select_device([phone], GAMES['relic-rush']), phone)

    def test_coredevice_filters_available_states_before_json_selection(self):
        def result(command):
            self.assertIn("State BEGINSWITH 'available' OR State BEGINSWITH 'connected'", command)
            output = command[command.index('--json-output') + 1]
            Path(output).write_text(json.dumps({'result': {'devices': [self.phone]}}))
        with patch.object(deploy, 'run', side_effect=result):
            self.assertEqual(deploy.available_devices(), [self.phone])


class SigningTests(unittest.TestCase):
    def test_project_team_and_explicit_override_do_not_inspect_keychain(self):
        with patch.object(deploy, 'project_team', return_value='PROJECT'), patch.object(deploy.subprocess, 'check_output') as identities:
            self.assertEqual(deploy.signing_team(Path('.'), 'scheme', 'Debug'), 'PROJECT')
            self.assertEqual(deploy.signing_team(Path('.'), 'scheme', 'Debug', 'OVERRIDE'), 'OVERRIDE')
            identities.assert_not_called()

    def test_missing_team_uses_only_unique_development_identity(self):
        certificate = b'fixture certificate'
        fingerprint = hashlib.sha1(certificate).hexdigest().upper()
        listing = f'1) {fingerprint} "Apple Development: Test Person (PERSON1234)"'
        pem = ssl.DER_cert_to_PEM_cert(certificate)
        # Team ID comes from OU, which intentionally differs from the CN suffix.
        outputs = [listing, pem, 'subject= C=US,OU=TEAM123456,CN=Apple Development: Test Person (PERSON1234)']
        with patch.object(deploy, 'project_team', return_value=''), patch.object(deploy.subprocess, 'check_output', side_effect=outputs):
            self.assertEqual(deploy.signing_team(Path('.'), 'scheme', 'Debug'), 'TEAM123456')
        for outputs in ([listing, pem, 'subject= OU=OTHER12345,CN=Example'], ['', '', '']):
            # A certificate for a different (or missing) identity is not selected.
            if outputs[0]:
                outputs[1] = ssl.DER_cert_to_PEM_cert(b'certificate without private key')
            with patch.object(deploy, 'project_team', return_value=''), patch.object(deploy.subprocess, 'check_output', side_effect=outputs):
                with self.assertRaisesRegex(ValueError, 'TEAM='):
                    deploy.signing_team(Path('.'), 'scheme', 'Debug')

    def test_multiple_certificate_teams_require_an_override(self):
        certificates = [b'one certificate', b'another certificate']
        identities = '\n'.join(f'{hashlib.sha1(cert).hexdigest().upper()} "Apple Development: Person"' for cert in certificates)
        pem = ''.join(ssl.DER_cert_to_PEM_cert(cert) for cert in certificates)
        with patch.object(deploy, 'project_team', return_value=''), patch.object(deploy.subprocess, 'check_output',
                side_effect=[identities, pem, 'subject= C=US,OU=TEAM123456,CN=One', 'subject= C=US,OU=OTHER12345,CN=Another']):
            with self.assertRaisesRegex(ValueError, 'TEAM='):
                deploy.signing_team(Path('.'), 'scheme', 'Debug')


class PipelineTests(unittest.TestCase):
    def test_build_sign_install_launch_and_failure_boundaries_for_all_games(self):
        for game, meta in GAMES.items():
            for failure in (None, 'build', 'install'):
                with self.subTest(game=game, failure=failure), tempfile.TemporaryDirectory() as folder:
                    calls = []
                    family = 'iPad' if meta['device'] == 'ipad' else 'iPhone'
                    args = argparse.Namespace(game=game, device='', team='TEAM123456', configuration='Debug',
                                              build_dir=Path(folder), app_args=['--screen', 'some value'])
                    app = Path(folder).resolve() / 'Build/Products/Debug-iphoneos' / f'{game}.app'
                    bundle = 'com.test.' + game

                    def command(command, **kwargs):
                        calls.append(list(map(str, command)))
                        if command[0] == 'xcodebuild':
                            self.assertIn(f'{game}-{meta["device"]}', command)
                            self.assertIn('id=phone-udid', command)
                            self.assertIn('DEVELOPMENT_TEAM=TEAM123456', command)
                            self.assertIn(f'OBJROOT={Path(folder).resolve() / "Build/Intermediates.noindex"}', command)
                            self.assertNotIn('CODE_SIGNING_ALLOWED=NO', command)
                            if failure == 'build':
                                raise subprocess.CalledProcessError(65, command)
                            product_dir = next(str(arg).removeprefix('SYMROOT=') for arg in command if str(arg).startswith('SYMROOT='))
                            built_app = Path(product_dir) / 'Debug-iphoneos' / f'{game}.app'
                            built_app.mkdir(parents=True)
                            (built_app / 'Info.plist').write_bytes(plistlib.dumps({'CFBundleIdentifier': bundle}))
                        elif 'install' in command and failure == 'install':
                            raise subprocess.CalledProcessError(1, command)

                    with patch.object(deploy, 'available_devices', return_value=[device(family=family)]), patch.object(deploy, 'run', side_effect=command):
                        if failure:
                            with self.assertRaises(subprocess.CalledProcessError):
                                deploy.deploy(args)
                        else:
                            deploy.deploy(args)
                    self.assertEqual(len(calls), {None: 3, 'build': 1, 'install': 2}[failure])
                    if not failure:
                        self.assertIn(str(app), calls[1])
                        self.assertEqual(calls[2][-4:], [bundle, '--', '--screen', 'some value'])


if __name__ == '__main__':
    unittest.main()
