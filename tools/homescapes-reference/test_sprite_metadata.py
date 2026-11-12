import unittest
from zipfile import ZipFile

from sprite_metadata import SOURCE, references


@unittest.skipUnless(SOURCE.is_file(), 'Local Homescapes archive unavailable')
class SpriteMetadataTest(unittest.TestCase):
    def test_reads_prefabs_from_multiframe_library(self):
        with ZipFile(SOURCE) as archive:
            found = references(archive)
        self.assertIn('Match3Chip_3_base_facelift', found['NormalChipBlue']['references'])
        self.assertIn('Match3Chip_0_base_facelift', found['NormalChipRed']['references'])
        self.assertIn('BlocksSwap', found['ElementLocksSettings']['flag_names'])
