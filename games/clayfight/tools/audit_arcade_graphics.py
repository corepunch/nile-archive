#!/usr/bin/env python3
"""Inventory the supplied 2.3 ROM's scene artwork and independent reference pixels.
No emulator or extracted image bundle is needed. Output is a source manifest,
not generated runtime data; the game reads these same source tables directly.
"""
import argparse
import json
from pathlib import Path
import struct

GAME = Path(__file__).resolve().parents[1]
CPU = ('136102-1044b.29l', '136102-1043b.28l',
       '136102-1042b.27l', '136102-1041b.25l')
PLANES = ('136102-0050a.25n', '136102-0051a.27n', '136102-0052a.28n')
CYCLES = ((0x2478c, 0x247a2, 0x247bc), (0x24736, 0x2474c, 0x24766),
          (0x247fa,), (), (), (0x247da,), (), ())


def audit(roms):
    cpu = bytearray(0x200000)
    for lane, name in enumerate(CPU):
        data = (roms / name).read_bytes()
        if len(data) != 0x80000:
            raise ValueError(f'Incorrect program chip size: {name}')
        cpu[lane::4] = data
    u16 = lambda at: struct.unpack_from('>H', cpu, at)[0]
    s16 = lambda at: struct.unpack_from('>h', cpu, at)[0]
    u32 = lambda at: struct.unpack_from('>I', cpu, at)[0]
    s32 = lambda at: struct.unpack_from('>i', cpu, at)[0]
    if u32(0x6d964) != 0x57112:
        raise ValueError('Expected primrageo 2.3 December 1994')
    chips = [(roms / name).read_bytes() for name in PLANES]

    def background(stage, x, y):
        horizon = u16(0x6ba0c + stage * 2)
        far = y < horizon
        table = 0x1e58c4 if far else 0x1e5904
        px = x + (u16(0x6b9fc + stage * 2) // 32 if far else 344)
        at = u32(table + stage * 4 + (32 if px >= 512 else 0))
        px %= 512
        py = y + cpu[at + 1] * 8 - horizon if far else y - horizon
        word = u16(at + 2 + 2 * (py // 8 * cpu[at] + px // 8))
        word |= 0 if far else 0x4000
        tx = 7 - px % 8 if word & 0x8000 else px % 8
        bank = cpu[(0x1e5944 if far else 0x1e594c) + stage]
        offset = (bank * 4096 + (word & 4095)) * 16 + py % 8 * 2 + tx // 4
        lo = chips[1 if tx % 4 < 2 else 0][offset]
        hi = chips[2][offset]
        value = (lo >> (0 if tx % 2 else 4)) & 15
        value |= ((hi >> (4 + tx % 4)) & 1) << 5 | ((hi >> (tx % 4)) & 1) << 4
        color = u16(u32(0x5fea2 + stage * 4) + 2 * ((value + (word >> 12 & 7) * 32) & 255))
        rgb = [((color >> shift) & 31) * 255 // 31 for shift in (10, 5, 0)]
        return dict(x=x, y=y, rgb=rgb, argb=f'ff{rgb[0]:02x}{rgb[1]:02x}{rgb[2]:02x}')

    def object_info(descriptor, x, y, z, flags=0, linked=False):
        source = u32(descriptor)
        return dict(descriptor=hex(descriptor), source=hex(source),
                    direct_frame=bool(u16(descriptor + 8) & 0x800),
                    x_26_6=x, y_26_6=y, z_26_6=z, flags=hex(flags),
                    color=hex(u16(descriptor + 6)), scale=u16(descriptor + 12) / 4096,
                    frame_ticks=cpu[descriptor + 5], linked=linked)

    stages = []
    for stage in range(8):
        objects = []
        p = u32(0x6c418 + stage * 4)
        while u32(p):
            objects.append(object_info(u32(p), s32(p + 4), 0, s16(p + 8)))
            p += 12
        p = u32(0xf2648 + stage * 4)
        count = u16(p)
        for i in range(count):
            at = p + 2 + i * 12
            objects.append(object_info(u32(0x6d724 + cpu[at + 10] * 12),
                                       s32(at), s16(at + 4), s16(at + 6), u16(at + 8)))
        # Only expand the leading spawn operations. Zero-duration scripts hold
        # their first frame and are laid next to unrelated scripts in ROM.
        for obj in objects:
            if obj['direct_frame']:
                continue
            ip = int(obj['source'], 16)
            while u16(ip) & 0x8000:
                word = u16(ip)
                if word in (0xcc00, 0xcc01):
                    factor = 64 if word == 0xcc01 else 1
                    objects.append(object_info(u32(ip + 2), obj['x_26_6'] + s16(ip + 6) * factor,
                                               obj['y_26_6'], obj['z_26_6'] - s16(ip + 8) * factor,
                                               linked=True))
                    ip += 10
                elif word & 0xff00 == 0x9300:
                    ip += 2
                else:
                    break
        nameptr = u32(0x6b884 + stage * 4) if stage < 7 else 0
        name = bytes(cpu[nameptr:]).split(b'\0')[0].decode() if nameptr else 'DINOSAUR GRAVEYARD'
        cycles = []
        for p in CYCLES[stage]:
            if any(u16(p + j * 4) != 0x4878 for j in range(5)):
                raise ValueError('Palette cycle argument block changed')
            cycles.append(dict(length=u16(p + 2), ticks=u16(p + 6),
                               signed_offset=s16(p + 10), group=u16(p + 14)))
        stages.append(dict(index=stage, name=name, sky_maps=[hex(u32(0x1e58c4 + stage * 4)), hex(u32(0x1e58e4 + stage * 4))],
                           floor_maps=[hex(u32(0x1e5904 + stage * 4)), hex(u32(0x1e5924 + stage * 4))],
                           sky_bank=cpu[0x1e5944 + stage], floor_bank=cpu[0x1e594c + stage],
                           horizon=u16(0x6ba0c + stage * 2), palette_cycles=cycles,
                           object_count=len(objects), objects=objects,
                           reference_pixels=[background(stage, 168, 100), background(stage, 168, 230)],
                           capture=f'review/arcade/after/stage-{stage}.png'))
    return dict(revision='primrageo 2.3 Dec 1994', framebuffer=[672, 480],
                character_home_stages=list(cpu[0x69a40:0x69a47]),
                arena_width=336 + 2 * (u16(0x6ba36) // 64), stages=stages,
                shadows=dict(pointer_table='0x6b068', descriptors='0x6d5e0', palette='0x61702'),
                contacts=dict(hit_script='0x56e28', block_script='0x56e36', block_palette='0x61802',
                              hit_palette='0x61822 (descriptor 0x6cf50, colour 0x190)', frame_ticks=3),
                tribes=dict(descriptors='0x6d270 + variant*16', variants=6, team_palettes='0x63382 + character*128',
                            presentation='Four ambient spectators; idle ROM scripts, 0.75 scale. No eating/worship AI.'),
                title=dict(primal_frames=[447, 460], rage_frames=[475, 480], palette='0x652c2'))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--roms', type=Path, default=GAME / 'data/primrage')
    parser.add_argument('--output', type=Path, default=GAME / 'docs/arcade-graphics.json')
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    text = json.dumps(audit(args.roms), indent=2) + '\n'
    if args.check:
        if args.output.read_text() != text:
            raise SystemExit('Arcade graphics source manifest needs regeneration')
        print('Arcade graphics source manifest matches ROM tables')
    else:
        args.output.write_text(text)
        print(args.output)


if __name__ == '__main__':
    main()
