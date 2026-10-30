"""Capture the game's real hex geometry. Run under Xvfb on Linux."""
import subprocess
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
shot = ROOT / "build/shots/relic-cell-mask.png"
shot.parent.mkdir(parents=True, exist_ok=True)
subprocess.run([str(ROOT / "build/relic-rush"), "--headless", "--fresh", "--mute",
                "--cell-mask", "--size", "480x900", "--shot", str(shot)], cwd=ROOT, check=True)
im = Image.open(shot).convert("L")
scale = im.width / 480
x, y, r = im.width / 2, im.height / 2, 64 * scale
im = im.crop((round(x-r), round(y-r), round(x+r), round(y+r)))
im.resize((128, 128), Image.Resampling.LANCZOS).save(ROOT / "games/relic-rush/art/board-states/cell-mask.png")
