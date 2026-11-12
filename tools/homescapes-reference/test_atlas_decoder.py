"""Regression checks for the Homescapes texture stream decoder."""
from hashlib import sha256
import unittest

from decode_board_atlases import GEMS, PAGES, unpack_blocks, unpack_dds


class AtlasDecoderTest(unittest.TestCase):
    def test_mixed_run(self):
        # Two literals, a three-entry dictionary run, a backward reference,
        # the same distance again, then a repeat of the last output block.
        commands = bytes.fromhex('5c 18 00 42 bd 15 e1')
        blocks = [bytes([value]) * 8 for value in range(5)]
        expected = b''.join(blocks[index] for index in (0, 1, 2, 3, 4, 2, 3, 3))
        self.assertEqual(unpack_blocks(commands, b''.join(blocks[2:]), b''.join(blocks[:2]), 8), expected)

    def test_rejects_reference_before_output(self):
        with self.assertRaisesRegex(ValueError, 'backward distance'):
            unpack_blocks(bytes.fromhex('bc'), b'', b'', 1)

    @unittest.skipUnless((GEMS / 'board-atlases').is_dir(), 'Local Homescapes atlas files unavailable')
    def test_reconstructs_all_board_planes(self):
        expected = (
            '31a8199085859edc16f3cf1347d2ed9135658e0a3343317694becf44d90ff8be',
            '2efb0d5e44d739db45a9c0c904722a846f86904e3dfdbb09e42d07c2e7945784',
            '52c82a1a255e0200f1c33ecdb1760c8b9217a77a5ad1da1a3ef44c877baad600',
            'd1a63c15c78cd0fd8500dc78d3c189abd4529318828955135cb91d27fdbe83dc',
            '70d9e25eac2d2d37b53e5680b37384eb102f025ad9cee5d3c0cda616e3d68a2e',
        )
        for page, digest in zip(PAGES, expected):
            with self.subTest(page=page):
                data = (GEMS / 'board-atlases' / (page + '.dds')).read_bytes()
                width, height, planes = unpack_dds(data)
                self.assertEqual((width, height), (1576, 1576))
                self.assertEqual([len(plane) for plane in planes], [155236 * 8] * 3)
                self.assertEqual(sha256(b''.join(planes)).hexdigest(), digest)
