"""Native-pose alpha, LUT mask resolution, charge and format regressions."""
from pathlib import Path
import unittest
try:
    from PIL import Image, ImageChops
    from mechanics import chameleon_atlas
    from skeleton import read_setup
except ImportError:
    Image = None

ART = Path(__file__).resolve().parents[2] / 'reference/tropicats-analysis/art'


@unittest.skipIf(Image is None, 'Run in the UnityPy extraction environment for material checks')
class MechanicsTests(unittest.TestCase):
    def test_two_color_mask_uses_uvs_when_texture_resolutions_differ(self):
        source = Image.new('RGBA',(8,4),(128,80,40,173))
        lut = Image.new('RGBA',(10,1))
        lut.putpixel((1,0),(255,0,0,255))
        lut.putpixel((2,0),(0,255,0,255))
        for mask_color, expected in [((255,255,0,255),(255,0,0,173)),
                                     ((0,255,0,255),(0,255,0,173)),
                                     ((255,0,0,255),(128,80,40,173))]:
            mask = Image.new('RGBA',(4,2),mask_color)
            result = chameleon_atlas(source,mask,lut,1,2)
            self.assertEqual(set(result.getdata()),{expected})

    @unittest.skipUnless((ART/'shader-evidence/chameleon.skel').exists(),'Native assets unavailable')
    def test_native_skeleton_pose_and_all_color_pairs_keep_the_alpha(self):
        evidence = ART/'shader-evidence'
        layers = read_setup((evidence/'chameleon.skel').read_bytes())
        self.assertEqual(len(layers),25)
        # All 49 material variants must preserve the same complete authored pose.
        reference = Image.open(ART/'sprites/material_chameleon_1_2.png').getchannel('A')
        self.assertGreater(sum(v>128 for v in reference.getdata()),25000)
        self.assertLess(sum(v>128 for v in reference.getdata()),55000)
        for current in [1,2,3,4,5,6,9]:
            for next_color in [1,2,3,4,5,6,9]:
                with Image.open(ART/f'sprites/material_chameleon_{current}_{next_color}.png') as image:
                    self.assertEqual(image.getchannel('A').tobytes(),reference.tobytes())
        # Unknown versions must not quietly produce malformed characters.
        data=(evidence/'chameleon.skel').read_bytes().replace(b'3.2.01',b'3.8.01',1)
        with self.assertRaises(ValueError):read_setup(data)

    @unittest.skipUnless((ART/'sprites/material_cannon_1_0.png').exists(),'Native assets unavailable')
    def test_cannon_gauge_changes_only_inside_the_mouth(self):
        images=[Image.open(ART/f'sprites/material_cannon_1_{q}.png').convert('RGBA') for q in [0,15,30,45]]
        red_counts=[sum(r>150 and g<70 and b<70 and a>128 for r,g,b,a in im.getdata()) for im in images]
        self.assertEqual(red_counts,sorted(set(red_counts)))
        for image in images[1:]:
            self.assertEqual(image.getchannel('A').tobytes(),images[0].getchannel('A').tobytes())
            box=ImageChops.difference(image.convert('RGB'),images[0].convert('RGB')).getbbox()
            self.assertGreater(box[0],40);self.assertLess(box[2],205)
            self.assertGreater(box[1],60);self.assertLess(box[3],215)


if __name__ == '__main__':
    unittest.main()
