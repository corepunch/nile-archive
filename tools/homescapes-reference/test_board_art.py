"""Checks for the goal-icon approximations used by the board explorer."""
import json
import shutil
import subprocess
import unittest
import zipfile

from level_viewer import PAGE
from sprite_coverage import MAPPINGS
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

    def test_original_art_layers_and_strengths(self):
        start = PAGE.index('function pickSprites(')
        end = PAGE.index('function options()')
        check = """
const assert = require('node:assert/strict');
const mappings = JSON.parse(process.argv[1]);
const available = new Set(['carpet', 'chip-2', 'ice-2', 'chain-1-mirror', 'box-6', 'cookie-3', 'honey-material', 'web-2']);
const ids = models => pickSprites(models, available, mappings).map(sprite => sprite.id);
assert.deepEqual(ids([{modelId:'ICE',level:'2'},{modelId:'NORMAL',color:'2'},{modelId:'JELLY'}]),
                 ['carpet', 'chip-2', 'ice-2']);
assert.deepEqual(ids([{modelId:'LOCK',level:'1',mirror:'true'},{modelId:'NORMAL',color:'2'}]),
                 ['chip-2', 'chain-1-mirror']);
assert.deepEqual(ids([{modelId:'BOX',level:'6'},{modelId:'TRASH',level:'3'}]), ['box-6', 'cookie-3']);
assert.deepEqual(ids([{modelId:'RANDOM_CHIP'},{modelId:'BOX',level:'7'}]), []);
assert.deepEqual(ids([{modelId:'WEB',level:'1'},{modelId:'WEB',level:'2'}]), ['web-2']);
assert.equal(pickSprites([{modelId:'HONEY',level:'3'}], available, mappings)[0].status, 'material');
"""
        subprocess.run(['node', '-e', PAGE[start:end] + check, MAPPINGS.read_text()],
                       check=True, capture_output=True, text=True)


if __name__ == '__main__':
    unittest.main()
