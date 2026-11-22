"""Register building residents from their shared transparent portrait sheets."""
import argparse
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SHEETS = {
    'source.png': [('christmas-market', 'ada', (768, 0, 1536, 880))],
    'chart-and-clock.png': [('christmas-market', 'otis', (768, 0, 1536, 1024))],
}


def prepare(check):
    for source, cast in SHEETS.items():
        with Image.open(ROOT / 'art/match3-residents' / source) as sheet:
            assert sheet.mode == 'RGBA' and sheet.size == (1536, 1024)
            for game, speaker, crop in cast:
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
