"""Checks for the goal-icon approximations used by the board explorer."""
import json
import shutil
import subprocess
import unittest
import zipfile

from level_viewer import PAGE
from story_index import SOURCE


@unittest.skipUnless(SOURCE.exists() and shutil.which('node'), 'App bundle or Node unavailable')
class BoardArtTest(unittest.TestCase):
    def test_mapped_icons_exist_and_layer_in_order(self):
        start = PAGE.index('const iconModels=')
        end = PAGE.index('function options()', start)
        mapping = PAGE[start:end]
        check = """
const assert = require('node:assert/strict');
assert.deepEqual(pickIcons([{modelId:'NORMAL',color:'2'},{modelId:'JELLY'}]),
                 ['jelly.webp','chip_2.webp']);
assert.deepEqual(pickIcons([{modelId:'NONE_CHIP'},{modelId:'BOX'}]), ['box.webp']);
assert.deepEqual(pickIcons([{modelId:'RANDOM_CHIP'}]), []);
console.log(JSON.stringify([...new Set(Object.values(iconModels))]));
"""
        result = subprocess.run(['node', '-e', mapping + check], check=True,
                                capture_output=True, text=True)
        names = json.loads(result.stdout)
        names += ['chip_' + str(i) for i in range(6)]
        prefix = 'base_mm/Match3/vso/textures/UI/Match3TargetsBase/'
        with zipfile.ZipFile(SOURCE) as archive:
            for name in names:
                with self.subTest(name=name):
                    self.assertTrue(archive.read(prefix + name + '.webp').startswith(b'RIFF'))


if __name__ == '__main__':
    unittest.main()
