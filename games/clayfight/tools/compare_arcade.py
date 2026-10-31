#!/usr/bin/env python3
"""Extract the supplied Primal Rage 2.3 arcade ROMs and compare their DOS art.

Requires Pillow. From the repository root:
  python3 games/clayfight/tools/compare_arcade.py

No emulator, downloaded art, inferred colours, or runtime changes. Outputs stay
in ignored art/reference/arcade-comparison. Raw PNGs retain indices and transparency;
their greyscale palette is diagnostic, not the game's palette. Coloured core
frames use the original CPU-ROM palette. See docs/primal-rage-arcade.md.

RLE format reference: MAME src/mame/atari/atarirle.cpp, BSD-3-Clause,
Aaron Giles. ROM layout: MAME src/mame/atari/atarigt.cpp (primrageo).
This is an independent Python implementation of the documented format.
"""
from array import array
from collections import Counter
from functools import lru_cache
from hashlib import sha256
from io import BytesIO
from pathlib import Path
import argparse
import json
import struct
import sys
import zipfile
import zlib

from PIL import Image, ImageChops, ImageDraw, ImageFont, ImageStat

import grasheet as G

GAME = Path(__file__).resolve().parents[1]
NAMES = ('sauron', 'blizzard', 'talon', 'vertigo', 'armadon', 'diablo', 'chaos')
PREFIX = dict(zip(NAMES, ('REX', 'KON', 'TAL', 'COB', 'SPI', 'DIA', 'HAV')))
# These are pointers in the supplied, checksum-verified 68020 program, not
# palettes guessed from sprite smoothness. The pointer table is at 0x6e38c.
CPU_ROMS = (('136102-1044b.29l', 0x35c9c34b),
            ('136102-1043b.28l', 0x86322829),
            ('136102-1042b.27l', 0x750e8095),
            ('136102-1041b.25l', 0x6a90d283))
BG, FG, MUTED, ACCENT = '#171e2b', '#edf1f8', '#a9b6c9', '#78dac5'


class Arcade:
    def __init__(self, root):
        self.inputs = {}

        def read(name, crc=None):
            data = (root / name).read_bytes()
            if crc is not None and zlib.crc32(data) != crc:
                raise ValueError(f'{name}: unsupported ROM revision/checksum')
            self.inputs[name] = dict(bytes=len(data), sha256=sha256(data).hexdigest())
            return data

        cpu = bytearray(0x200000)
        for lane, (name, crc) in enumerate(CPU_ROMS):
            data = read(name, crc)
            if len(data) != 0x80000:
                raise ValueError(f'{name}: unexpected program ROM size')
            cpu[lane::4] = data
        self.cpu = cpu
        self.palettes, self.palette_addresses = {}, {}
        for i, name in enumerate(NAMES):
            address = struct.unpack_from('>I', cpu, 0x6e38c + 4 * i)[0]
            self.palette_addresses[name] = address
            values = struct.unpack_from('>64H', cpu, address)
            self.palettes[name] = [tuple(((v >> shift) & 31) * 255 // 31
                                        for shift in (10, 5, 0)) for v in values]

        data = bytearray(0x2000000)

        def pair(lo, hi, offset, crc_lo=None, crc_hi=None):
            low, high = read(lo, crc_lo), read(hi, crc_hi)
            if len(low) != len(high) or len(low) not in (0x80000, 0x100000):
                raise ValueError(f'{lo}, {hi}: unexpected graphics ROM size')
            data[offset:offset + 2 * len(low):2] = high
            data[offset + 1:offset + 2 * len(low):2] = low

        pair('136102-1100a.2v', '136102-1101a.2w', 0, 0x6e9c80b5, 0xbb7ee624)
        for i in range(4):
            pair(f'136102-{332 + 2*i:04d}.mol1.{i}',
                 f'136102-{333 + 2*i:04d}.moh1.{i}', 0x800000 + i * 0x200000)
        for i in range(8):
            pair(f'136102-{316 + 2*i:04d}.mol0.{i}',
                 f'136102-{317 + 2*i:04d}.moh0.{i}', 0x1000000 + i * 0x200000)
        self.words = array('H')
        self.words.frombytes(data)
        if sys.byteorder == 'little':
            self.words.byteswap()
        lowest, offset = len(self.words), 0
        while offset < lowest:
            start = ((self.words[offset + 2] & 255) << 16) | self.words[offset + 3]
            if offset < start < lowest:
                lowest = start
            offset += 4
        self.count = lowest // 4

    @lru_cache(maxsize=256)
    def decode(self, fid):
        if not 0 <= fid < self.count:
            return None
        words = self.words
        x, y, flags, start = words[fid * 4:fid * 4 + 4]
        start |= (flags & 255) << 16
        if start < fid * 4 or start >= len(words):
            return None
        mode, pos, rows = (flags >> 8) & 7, start, []
        for _ in range(1024):
            if pos >= len(words):
                raise ValueError(f'Object {fid}: missing row terminator')
            entries = words[pos]
            pos += 1
            if entries & 0x8000:
                entries ^= 0xffff
            if not entries:
                break
            if pos + entries > len(words):
                raise ValueError(f'Object {fid}: row exceeds ROM')
            row = bytearray()
            for word in words[pos:pos + entries]:
                for value in (word & 255, word >> 8):
                    if mode == 0 or (mode in (1, 4, 6) and value & 15 == 0):
                        count, pixel = (value >> 4) + 1, value & 15
                    elif mode in (1, 2, 3):
                        count, pixel = (value >> 5) + 1, value & 31
                    else:
                        count, pixel = (value >> 6) + 1, value & 63
                    row.extend(bytes([pixel]) * count)
            if len(row) > 4096:
                raise ValueError(f'Object {fid}: unreasonable row width')
            rows.append(row)
            pos += entries
        else:
            raise ValueError(f'Object {fid}: more than 1023 rows')
        if not rows:
            return None
        w, h = max(map(len, rows)), len(rows)
        pixels = b''.join(bytes(row).ljust(w, b'\0') for row in rows)
        im = Image.frombytes('L', (w, h), pixels)
        meta = dict(id=fid, width=w, height=h,
                    pivot=[x if x < 32768 else x - 65536,
                           y if y < 32768 else y - 65536],
                    flags=flags, mode=mode, word_offset=start,
                    visible_indices=len(set(pixels) - {0}), sha256=sha256(pixels).hexdigest())
        return im, meta


def indexed(im, palette):
    out = Image.frombytes('P', im.size, im.tobytes())
    out.putpalette([v for colour in palette for v in colour]
                   + [0] * (768 - len(palette) * 3))
    out.info['transparency'] = 0
    return out


def rgba(im, palette):
    return indexed(im, palette).convert('RGBA')


def png(im):
    buf = BytesIO()
    im.save(buf, format='PNG')
    return buf.getvalue()


@lru_cache(maxsize=64)
def dos_archive(filename):
    return G.load(filename)


def dos_frame(ref, name):
    archive, k = ref.split('#')
    data, frames, _ = dos_archive('S04' + archive + '.GRA')
    frame = frames[int(k)]
    rows = G.decode(data, frame)
    im = Image.frombytes('L', frame[:2], b''.join(bytes(row) for row in rows))
    palette = dos_archive('S04' + PREFIX[name] + '.GRA')[2][1 if name == 'vertigo' else 3]
    return im, [(0, 0, 0)] + palette, frame


def animations(name, creatures):
    out, current = {}, None
    for line in (creatures / (name + '.txt')).read_text().splitlines():
        fields = line.split()
        if not fields or fields[0].startswith('#'):
            continue
        if fields[0] == 'anim':
            current = fields[1]
            out[current] = []
        elif fields[0] == 'end':
            current = None
        elif current and '#' in fields[0]:
            out[current].append(fields[0])
    return out


def font(size, bold=False):
    path = '/System/Library/Fonts/Supplemental/Arial' + (' Bold' if bold else '') + '.ttf'
    try:
        return ImageFont.truetype(path, size)
    except OSError:
        return ImageFont.truetype('DejaVuSans.ttf', size)


def text(draw, xy, value, size=20, colour=FG, bold=False):
    draw.text(xy, value, font=font(size, bold), fill=colour)


def paste(canvas, im, center, bottom, scale):
    im = im.resize((round(im.width * scale), round(im.height * scale)), Image.Resampling.NEAREST)
    canvas.paste(im, (round(center - im.width / 2), round(bottom - im.height)), im)


def nearest(arcade, ref, name, ids):
    pc, pal, _ = dos_frame(ref, name)
    pc = rgba(pc, pal)
    pc = pc.crop(pc.getbbox()).resize((64, 64), Image.Resampling.BILINEAR)
    scores = []
    for fid in ids:
        decoded = arcade.decode(fid)
        if decoded is None:
            continue
        im = rgba(decoded[0], arcade.palettes[name])
        if not im.getbbox():
            continue
        im = im.crop(im.getbbox()).resize((64, 64), Image.Resampling.BILINEAR)
        score = sum(ImageStat.Stat(ImageChops.difference(pc, im)).mean)
        scores.append((score, fid))
    return min(scores)[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--roms', type=Path, default=GAME / 'data/primrage')
    parser.add_argument('--dos', type=Path, required=True, help='external DOS installation for historical comparison only')
    parser.add_argument('--creatures', type=Path, required=True, help='external DOS definitions from pr2creature.py')
    parser.add_argument('--out', type=Path, default=GAME / 'art/reference/arcade-comparison')
    parser.add_argument('--review-only', action='store_true', help='reuse extracted ZIPs; regenerate comparison images/report')
    args = parser.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)
    G.DATA = str(args.dos)
    arcade = Arcade(args.roms)
    print(f'Arcade table: {arcade.count} object slots', flush=True)
    all_anims = {name: animations(name, args.creatures) for name in NAMES}
    report = dict(rom_set='primrageo / version 2.3',
                  object_slots=arcade.count, inputs=arcade.inputs,
                  palette_addresses=arcade.palette_addresses, comparisons=[], idle_counts={})

    # Complete lossless index extraction, including objects whose palette/use is
    # unknown. Do not present diagnostic greyscale as original coloured artwork.
    metadata, modes = [], Counter()
    grey = [(i * 255 // 63, i * 255 // 63, i * 255 // 63) for i in range(64)]
    if args.review_only:
        with zipfile.ZipFile(args.out / 'arcade-raw-indexed.zip') as pack:
            metadata = json.loads(pack.read('manifest.json'))
            modes.update(item['mode'] for item in metadata)
    else:
        with zipfile.ZipFile(args.out / 'arcade-raw-indexed.zip', 'w', zipfile.ZIP_STORED) as pack:
            for fid in range(arcade.count):
                decoded = arcade.decode(fid)
                if decoded is None:
                    continue
                im, meta = decoded
                pack.writestr(f'raw/{fid:05d}.png', png(indexed(im, grey)))
                metadata.append(meta)
                modes[meta['mode']] += 1
            pack.writestr('manifest.json', json.dumps(metadata, indent=2))
            pack.writestr('palettes.json', json.dumps(arcade.palettes, indent=2))
    report['decoded_objects'] = len(metadata)
    report['modes'] = dict(modes)
    print(f'Extracted {len(metadata)} raw objects', flush=True)

    # Use the arcade script table, never the DOS global frame-ID aliases.
    known = NAMES
    standing = {}
    for character, name in enumerate(known):
        script = struct.unpack_from('>I', arcade.cpu, 0x6d964 + character * 4)[0]
        base = struct.unpack_from('>H', arcade.cpu, script)[0]
        standing[name] = list(range(base, base + 30))
        hashes = {arcade.decode(fid)[1]['sha256'] for fid in standing[name]}
        report['idle_counts'][name] = dict(dos_images=len(set(all_anims[name]['stand'])),
            arcade_ids=30, unique_arcade_pixels=len(hashes), script_address=script)
    core_count = 0
    with zipfile.ZipFile(args.out / 'arcade-standing-coloured.zip', 'w', zipfile.ZIP_STORED) as pack:
        manifest = {}
        for name in known:
            entries = []
            for fid in standing[name]:
                im, meta = arcade.decode(fid)
                pack.writestr(f'{name}/{fid:05d}.png', png(indexed(im, arcade.palettes[name])))
                entries.append(meta)
            manifest[name] = entries
            core_count += len(entries)
        pack.writestr('manifest.json', json.dumps(manifest, indent=2))
        pack.writestr('palettes.json', json.dumps(arcade.palettes, indent=2))
    report['coloured_standing_frames'] = core_count

    def pair(name, anim):
        ref = all_anims[name][anim][0]
        fid = nearest(arcade, ref, name, standing[name])
        pc, pal, frame = dos_frame(ref, name)
        ac, meta = arcade.decode(fid)
        entry = dict(character=name, animation=anim, dos_ref=ref, arcade_id=fid,
                     dos_size=list(pc.size), arcade_size=list(ac.size),
                     dos_visible_indices=len(set(pc.tobytes()) - {0}),
                     arcade_visible_indices=meta['visible_indices'])
        report['comparisons'].append(entry)
        for version, im in [('dos', rgba(pc, pal)), ('arcade', rgba(ac, arcade.palettes[name]))]:
            im.save(args.out / f'{name}-{anim}-{version}.png')
        return rgba(pc, pal), rgba(ac, arcade.palettes[name]), entry

    sheet = Image.new('RGB', (1120, 2360), BG)
    draw = ImageDraw.Draw(sheet)
    text(draw, (32, 20), 'PRIMAL RAGE  /  DOS vs ARCADE', 29, bold=True)
    text(draw, (32, 63), 'Original pixels at 2x nearest-neighbour. Transparent margins retained.', 19, MUTED)
    text(draw, (270, 110), 'DOS', 24, bold=True)
    text(draw, (780, 110), 'ARCADE', 24, ACCENT, True)
    for j, name in enumerate(known):
        pc, ac, entry = pair(name, 'stand')
        top, bottom = 158 + j * 310, 432 + j * 310
        draw.line((32, top - 8, 1088, top - 8), fill='#344155')
        text(draw, (32, top), name.title(), 22, bold=True)
        paste(sheet, pc, 330, bottom, 2)
        paste(sheet, ac, 850, bottom, 2)
        text(draw, (195, bottom + 9), f"{pc.width} x {pc.height}  |  {entry['dos_visible_indices']} colours", 18, MUTED)
        text(draw, (710, bottom + 9), f"{ac.width} x {ac.height}  |  {entry['arcade_visible_indices']} colours", 18, ACCENT)
    sheet.save(args.out / 'native-comparison.png')

    # Same display height exposes extra detail without the native-size difference.
    detail = Image.new('RGB', (1200, 1000), BG)
    draw = ImageDraw.Draw(detail)
    text(draw, (32, 22), 'DETAIL  /  SAME DISPLAY HEIGHT', 29, bold=True)
    text(draw, (32, 65), 'Nearest-neighbour enlargement of matched poses; no smoothing or recolouring.', 20, MUTED)
    for j, (name, anim) in enumerate([('sauron', 'stand'), ('blizzard', 'stand'), ('armadon', 'stand')]):
        pc, ac, entry = pair(name, anim)
        pc, ac = pc.crop(pc.getbbox()), ac.crop(ac.getbbox())
        top, bottom = 120 + j * 285, 365 + j * 285
        text(draw, (32, top), f'{name.title()}  /  {anim}', 22, bold=True)
        paste(detail, pc, 310, bottom, min(190 / pc.height, 540 / pc.width))
        paste(detail, ac, 900, bottom, min(190 / ac.height, 540 / ac.width))
        text(draw, (55, bottom + 15), f"DOS: {entry['dos_ref']}  /  {entry['dos_visible_indices']} colours", 19, MUTED)
        text(draw, (650, bottom + 15), f"Arcade: object {entry['arcade_id']}  /  {entry['arcade_visible_indices']} colours", 19, ACCENT)
    detail.save(args.out / 'detail-comparison.png')

    strip = Image.new('RGB', (1200, 440), BG)
    draw = ImageDraw.Draw(strip)
    text(draw, (28, 20), 'ANIMATION  /  NATIVE ARCADE BREATHING CYCLE', 26, bold=True)
    ref = all_anims['sauron']['stand'][0]
    pc, pal, _ = dos_frame(ref, 'sauron')
    paste(strip, rgba(pc, pal), 180, 340, 2)
    text(draw, (60, 370), f'DOS: {ref}', 21, MUTED)
    for j, fid in enumerate(standing['sauron'][:3]):
        im, _ = arcade.decode(fid)
        paste(strip, rgba(im, arcade.palettes['sauron']), 460 + j * 280, 340, 1.35)
        text(draw, (370 + j * 280, 370), f'Arcade: {fid}', 21, ACCENT)
    text(draw, (28, 74), '30 native breathing frames, recovered from the arcade script and native cycle length.', 20, MUTED)
    strip.save(args.out / 'animation-comparison.png')
    (args.out / 'report.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({k: report[k] for k in ('decoded_objects', 'coloured_standing_frames', 'idle_counts', 'comparisons')}, indent=2))
    print(f'Output: {args.out}')


if __name__ == '__main__':
    main()
