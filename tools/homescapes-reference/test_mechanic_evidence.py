"""Validate the source identities and damage capabilities used by lab rules."""
import unittest
from mechanic_evidence import SOURCE, evidence


@unittest.skipUnless(SOURCE.exists(), 'Local Homescapes bundle unavailable')
class MechanicEvidenceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.records = evidence()

    def test_source_identities(self):
        self.assertIn('plane', self.records['ElementBonusFishSettings']['identifiers'])
        self.assertIn('ModelToTargetApple', self.records['TargetGenerator']['identifiers'])
        self.assertIn('TARGET_GENERATOR', self.records['ElementTargetGeneratorSettings']['identifiers'])

    def test_damage_and_mobility_capabilities(self):
        for record in ('ElementTrashStoneSettings', 'ElementStatueSettings'):
            flags = self.records[record]['identifiers']
            self.assertIn('CanClearByExplosion', flags)
            self.assertNotIn('CanClearByNearMatch', flags)
        flags = self.records['ElementTrashStoneSettings']['identifiers']
        self.assertIn('CanFall', flags)
        self.assertIn('CanSwap', flags)
        flags = self.records['ElementColorBoxSettings']['identifiers']
        self.assertIn('CanClearByNearColoredMatch', flags)
        self.assertNotIn('CanClearByNearMatch', flags)
        self.assertIn('CanClearByNearExplosion', self.records['ElementHoneySettings']['identifiers'])
        self.assertIn('StopsLineExplosion', self.records['ElementTrashSettings']['identifiers'])

    def test_generator_capabilities(self):
        for record in ('ElementTargetGeneratorSettings', 'ElementCarryGeneratorSettings', 'ElementCookieBoxSettings'):
            flags = self.records[record]['identifiers']
            self.assertIn('IsTargetGenerator', flags)
            self.assertIn('CanClearByNearMatch', flags)
            self.assertIn('CanClearByExplosion', flags)

    def test_ground_and_shared_cover_identities(self):
        tile = self.records['ElementBubbleMembraneSettings']['identifiers']
        self.assertIn('BUBBLE_MEMBRANE', tile)
        self.assertIn('TunerUnder', tile)
        blind = self.records['ElementShuttersSettings']['identifiers']
        for flag in ('SHUTTERS', 'IsBig', 'HidesChip', 'CanClearByNearMatch', 'CanClearByExplosion'):
            self.assertIn(flag, blind)
