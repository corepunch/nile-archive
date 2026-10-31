"""Capture both pause menus at both phone sizes without copying game assets.

Run under Xvfb on Linux; macOS uses its native renderer.
"""
import argparse
from pathlib import Path
import subprocess
import tempfile

from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--before-ref", default="HEAD^")
args = parser.parse_args()
out = ROOT / "games/relic-rush/docs/review/pause-actions"
out.mkdir(parents=True, exist_ok=True)

with tempfile.TemporaryDirectory(prefix="relic-pause-") as directory:
    scripts = Path(directory)
    for source in (ROOT / "games/relic-rush/lua").glob("*.lua"):
        if source.name != "screens.lua":
            (scripts / source.name).symlink_to(source)
    for revision in ("before", "after"):
        screen = scripts / "screens.lua"
        if screen.exists():
            screen.unlink()
        if revision == "before":
            screen.write_bytes(subprocess.check_output(
                ["git", "show", f"{args.before_ref}:games/relic-rush/lua/screens.lua"], cwd=ROOT))
        else:
            screen.symlink_to(ROOT / "games/relic-rush/lua/screens.lua")
        for size in ("480x900", "390x844"):
            for context, extra in (("board", ["--level", "7"]), ("island", ["--city", "3"])):
                shot = scripts / "shot.png"
                command = [str(ROOT / "build/relic-rush"), "--headless", "--mute", "--fresh",
                           "--lua", str(scripts), "--size", size, "--dialog", "pause",
                           "--frames", "4", "--shot", str(shot)] + extra
                if size == "390x844":
                    command += ["--safe-area", "0,47,0,34"]
                subprocess.run(command, cwd=ROOT, check=True)
                with Image.open(shot) as image:
                    image = image.convert("RGB")
                    image.thumbnail((480, 1100))
                    image.save(out / f"{revision}-{context}-{size}.jpg", quality=88)

print("Pause review: both contexts captured at both phone sizes")
