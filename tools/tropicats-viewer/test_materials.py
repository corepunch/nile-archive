"""Shader-channel and decoded-art checks; Pillow is supplied by the extraction env."""
import json
from pathlib import Path
import unittest
try:
    from PIL import Image
    from materials import overlay_fragment, render_crate, sample
except ImportError:
    Image = None

ART = Path(__file__).resolve().parents[2] / 'reference/tropicats-analysis/art'


@unittest.skipIf(Image is None, 'Run in the UnityPy extraction environment for material checks')
class MaterialTests(unittest.TestCase):
    def test_packed_overlay_uses_red_coverage_blue_shading_and_green_highlight(self):
        rgba = overlay_fragment((.5, .99, .25, 0), (0, .5, 0, 0), (1, 1, 1, .8))
        self.assertAlmostEqual(rgba[0], .85)
        self.assertAlmostEqual(rgba[3], .15)
        self.assertEqual(overlay_fragment((1, 1, 0, 1), (1, 1, 1, 1), (1, 1, 1, 1))[3], 0)

    def test_lut_uses_bottom_up_brightness_and_preserves_source_alpha(self):
        lut = Image.new('RGBA', (10, 2), (0, 0, 0, 255))
        lut.putpixel((1, 0), (255, 200, 100, 255))
        lut.putpixel((1, 1), (100, 20, 10, 255))
        sprite = Image.new('RGBA', (2, 1))
        sprite.putdata([(64, 0, 255, 73), (191, 255, 0, 0)])
        result = render_crate(sprite, lut, 1)
        low, high = result.getpixel((0, 0)), result.getpixel((1, 0))
        self.assertLess(low[1], high[1])
        self.assertEqual([low[3], high[3]], [73, 0])
        self.assertEqual(sample(lut, .15, .25), (100/255, 20/255, 10/255, 1))

    @unittest.skipUnless((ART / 'sprites/material_bomb.png').exists(), 'Material extraction unavailable')
    def test_rendered_axes_and_all_crate_alpha_planes(self):
        def bounds(name):
            with Image.open(ART / 'sprites' / f'{name}.png') as image:
                box = image.getchannel('A').getbbox()
            return box[2]-box[0], box[3]-box[1]
        w, h = bounds('material_line_horizontal')
        self.assertGreater(w, h*1.5)
        w, h = bounds('material_line_vertical')
        self.assertGreater(h, w*1.5)
        for color in [1,2,3,4,5,6,9]:
            for hp in [1,2,3]:
                with Image.open(ART / 'sprites' / f'crate_tintable_{hp}hp.png') as original, Image.open(ART / 'sprites' / f'material_crate_{color}_{hp}.png') as rendered:
                    self.assertEqual(original.getchannel('A').tobytes(), rendered.getchannel('A').tobytes())
        manifest = json.loads((ART / 'sprites.json').read_text())
        self.assertLess(manifest['portal_exit']['placement']['top'], 0)
        self.assertGreater(manifest['portal_entrance']['placement']['top'], .5)


if __name__ == '__main__':
    unittest.main()
