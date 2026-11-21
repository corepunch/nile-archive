"""Register the two building residents from their shared transparent portrait sheet."""
import argparse
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SHEET = ROOT / 'art/match3-residents/source.png'
CAST = [('relic-rush', 'lio', (0, 0, 768, 880)),
        ('christmas-market', 'ada', (768, 0, 1536, 880))]


def prepare(check):
    with Image.open(SHEET) as sheet:
        assert sheet.mode == 'RGBA' and sheet.size == (1536, 1024)
        for game, speaker, crop in CAST:
            bust = sheet.crop(crop)
            bust = bust.crop(bust.getchannel('A').getbbox())
            bust.thumbnail((320, 480), Image.Resampling.LANCZOS)
            canvas = Image.new('RGBA', (320, 480))
            canvas.paste(bust, ((320 - bust.width) // 2, 480 - bust.height))
            path = ROOT / 'games' / game / 'data/story/characters' / (speaker + '.png')
            if check:
                with Image.open(path) as saved:
                    assert saved.mode == canvas.mode and saved.size == canvas.size and saved.tobytes() == canvas.tobytes(), path
            else:
                canvas.save(path)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    prepare(parser.parse_args().check)
