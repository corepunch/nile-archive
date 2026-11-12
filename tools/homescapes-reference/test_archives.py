"""Focused checks of the bundled pzsd reader and board interpretation."""
import unittest
import zipfile

from extract_archives import Zstd, read_archive
from level_viewer import SOURCE as LEVELS, load_level
from story_index import SOURCE


@unittest.skipUnless(SOURCE.exists(), 'Homescapes bundle unavailable')
class ArchiveTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.codec = Zstd()
        with zipfile.ZipFile(SOURCE) as bundle:
            cls.archive = bundle.read('base_mm/fs_archives/match3levels.zstd')
            cls.script_archive = bundle.read('base_mm/fs_archives/screenplays.zstd')

    @classmethod
    def tearDownClass(cls):
        cls.codec.close()

    def test_index_and_first_xml(self):
        dictionary, entries = read_archive(self.archive, self.codec)
        self.assertEqual(len(entries), 6184)
        name, data, size = entries[0]
        self.assertEqual(str(name), 'Match3/Levels/base/View/ply-water.xml')
        self.assertTrue(self.codec.unpack(data, size, dictionary).startswith(b'<root>'))

    def test_first_screenplay(self):
        dictionary, entries = read_archive(self.script_archive, self.codec)
        self.assertEqual(len(entries), 1329)
        name, data, size = entries[0]
        self.assertEqual(str(name), 'Screenplays/compiled/AWSale_UniqueDecor.lua')
        self.assertIn(b'function RunCompiledScript', self.codec.unpack(data, size, dictionary))

    def test_truncated_archive_rejected(self):
        with self.assertRaises(ValueError):
            read_archive(self.archive[:30], self.codec)

    @unittest.skipUnless(LEVELS.exists(), 'Decoded levels unavailable')
    def test_first_named_board(self):
        level = load_level(LEVELS / 'base/st/st0001.xml')
        self.assertEqual(level['level']['movesLimitLocal'], '26')
        self.assertEqual(level['targets'][0]['type'], 'CHIPS')
        self.assertEqual(len(level['cells']), 42)
        cell = next(c for c in level['cells'] if c[:2] == [102, 102])
        self.assertEqual(cell[3][0]['modelId'], 'NORMAL')
        self.assertEqual(cell[3][0]['color'], '1')


if __name__ == '__main__':
    unittest.main()
