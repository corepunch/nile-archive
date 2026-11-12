"""Keep the tracked generator inventory tied to the original compressed level bytes."""
import json
import unittest
from pathlib import Path
from generator_evidence import SOURCE, evidence


@unittest.skipUnless(SOURCE.exists(), 'Local Homescapes bundle unavailable')
class GeneratorEvidenceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.report = evidence()

    def test_tracked_inventory_matches_original_archive(self):
        path = Path(__file__).resolve().parents[2] / 'docs/homescapes-reference/generator-evidence.json'
        self.assertEqual(self.report, json.loads(path.read_text()))

    def test_source_formats_and_conflicts_remain_explicit(self):
        self.assertEqual(self.report['levels'], 6184)
        self.assertEqual(self.report['counts']['BornPatterns'], 743)
        self.assertEqual(self.report['counts']['ARTIFACT_GEN_instances'], 2662)
        self.assertEqual(self.report['counts']['ColorChipsPattern'], 321)
        self.assertEqual(len(self.report['reference_conflicts']), 10)
        self.assertFalse(self.report['original_runtime_verified'])
        for item in self.report['properties']:
            if item['attributes']['name'] == 'DropChanceProperty':
                self.assertEqual(item['attributes']['value'], '100')


if __name__ == '__main__':
    unittest.main()
