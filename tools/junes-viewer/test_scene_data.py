"""Check registration and asset references against the extracted scene."""
import unittest
from pathlib import Path

from scene_data import build_scene


DATA = Path(__file__).resolve().parents[2] / 'reference/junes-journey-analysis'


@unittest.skipUnless((DATA / 'scenes/scene-001-01/objects.json').exists(),
                     'June scene extraction is unavailable')
class SceneDataTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.scene = build_scene(DATA)

    def test_scene_registration_and_assets(self):
        objects = self.scene['objects']
        self.assertEqual(len(objects), 77)
        self.assertEqual(len({item['id'] for item in objects}), 77)
        self.assertEqual((self.scene['width'], self.scene['height']), (2048, 1170))
        cat = next(item for item in objects if item['name'] == 'cat')
        self.assertAlmostEqual(cat['polygon'][0][0], 0.361083, places=5)
        self.assertAlmostEqual(cat['polygon'][0][1], 0.535156, places=5)
        for item in objects:
            self.assertTrue(item['polygons'], item['name'])
            for layer in item['layers']:
                self.assertTrue((DATA / 'scenes/scene-001-01' / layer['image']).is_file(),
                                layer['image'])

    def test_clue_mappings(self):
        clues = {item['name']: item for item in self.scene['clues']}
        self.assertEqual(len(clues), 10)
        self.assertIsNone(clues['01_clue_mrstalbot']['clue'])
        self.assertEqual((clues['02_clue_familypicture']['scene'],
                          clues['02_clue_familypicture']['clue']), (2, 1))
        for clue in clues.values():
            self.assertTrue((DATA / 'scenes/clues' / clue['image']).is_file(), clue['image'])


if __name__ == '__main__':
    unittest.main()
