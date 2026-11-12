#!/usr/bin/env python3
"""Geometry and alpha checks for canonical match-three tile artwork."""
import importlib.util
from pathlib import Path
import unittest

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('hex_tile_art', ROOT / 'tools/hex_tile_art.py')
checker = importlib.util.module_from_spec(spec)
spec.loader.exec_module(checker)


def rgba(alpha):
    image = Image.new('RGBA', alpha.size, 'white')
    image.putalpha(alpha)
    return image


class HexTileTest(unittest.TestCase):
    def test_canonical_mask_and_registration(self):
        for size in (128, 181):
            with self.subTest(size=size):
                expected = checker.hex_mask((size, size))
                actual = Image.open(ROOT / f'engine/art/hex-tile/hex-mask-{size}.png')
                self.assertIsNone(ImageChops.difference(expected, actual.getchannel('A')).getbbox())
                self.assertTrue(checker.inspect(actual, strict=True, exact=True)['pass'])
                self.assertEqual(expected.getpixel((size // 2, size // 2)), 255)
                self.assertEqual(expected.getpixel((size // 2, 0)), 0)

    def test_fill_rejects_undersize_spill_and_shift(self):
        mask = checker.hex_mask((128, 128))
        smaller = Image.new('L', (128, 128))
        smaller.paste(mask.resize((108, 108)), (10, 10))
        self.assertFalse(checker.inspect(rgba(smaller))['pass'])
        spill = mask.copy()
        ImageDraw.Draw(spill).rectangle((0, 0, 36, 24), fill=255)
        self.assertFalse(checker.inspect(rgba(spill))['pass'])
        shifted = Image.new('L', mask.size)
        shifted.paste(mask, (4, 0))
        self.assertFalse(checker.inspect(rgba(shifted))['pass'])
        shifted_one = Image.new('L', mask.size)
        shifted_one.paste(mask, (1, 0))
        self.assertFalse(checker.inspect(rgba(shifted_one), strict=True)['pass'])

    def test_exact_detects_single_alpha_byte_change(self):
        image = rgba(checker.hex_mask((128, 128)))
        alpha = image.getchannel('A')
        alpha.putpixel((64, 64), 254)
        image.putalpha(alpha)
        self.assertTrue(checker.inspect(image, strict=True)['pass'])
        result = checker.inspect(image, strict=True, exact=True)
        self.assertFalse(result['pass'])
        self.assertEqual(result['alpha_error_pixels'], 1)
        self.assertEqual(result['alpha_max_error'], 1)

    def test_object_and_frame_allow_intentional_holes(self):
        mask = checker.hex_mask((128, 128))
        centre = Image.new('L', mask.size)
        ImageDraw.Draw(centre).ellipse((45, 45, 82, 82), fill=255)
        self.assertFalse(checker.inspect(rgba(centre), 'fill')['pass'])
        self.assertTrue(checker.inspect(rgba(centre), 'object')['pass'])
        frame = ImageChops.subtract(mask, mask.filter(ImageFilter.MinFilter(15)))
        self.assertTrue(checker.inspect(rgba(frame), 'frame')['pass'])
        self.assertFalse(checker.inspect(rgba(Image.new('L', mask.size)), 'frame')['pass'])


if __name__ == '__main__':
    unittest.main()
