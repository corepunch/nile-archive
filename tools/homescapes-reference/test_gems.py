"""Check gem inventory selection against the bundled source."""
import hashlib
import json
from pathlib import Path
import struct
import unittest
import zipfile

from extract_gems import DEST, SOURCE, selected


@unittest.skipUnless(SOURCE.exists(), 'Homescapes bundle unavailable')
class GemExtractionTest(unittest.TestCase):
    def test_selection_and_source_assets(self):
        with zipfile.ZipFile(SOURCE) as archive:
            names = [n for n in archive.namelist() if selected(n)]
            self.assertEqual(sum(selected(n) == 'goal-icons' for n in names), 22)
            self.assertEqual(sum(selected(n) == 'tutorial-art' for n in names), 13)
            for name in names:
                data = archive.read(name)
                self.assertEqual(data[:4], b'RIFF')
                self.assertEqual(data[8:12], b'WEBP')

    @unittest.skipUnless(DEST.exists(), 'Gem extraction unavailable')
    def test_manifest_matches_extraction_and_source(self):
        rows = json.loads((DEST / 'manifest.json').read_text())
        self.assertEqual(len(rows), 45)
        with zipfile.ZipFile(SOURCE) as archive:
            for row in rows:
                with self.subTest(output=row['output']):
                    data = (DEST / Path(row['output'])).read_bytes()
                    self.assertEqual(hashlib.sha256(data).hexdigest(), row['sha256'])
                    if row['kind'] != 'unwrapped-dds':
                        self.assertEqual(data, archive.read(row['source']))
                    else:
                        self.assertEqual(data[:4], b'DDS ')
                        self.assertEqual(struct.unpack_from('<II', data, 12), (1576, 1576))
                        self.assertEqual(hashlib.sha256(archive.read(row['source'])).hexdigest(),
                                         row['source_sha256'])


if __name__ == '__main__':
    unittest.main()
