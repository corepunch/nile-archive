"""Render the real dead-board update loop at both phone sizes, before/after a fix.

    python3 tests/fixtures/relic-dead-board/capture.py --before-ref origin/main

Uses existing build/dependencies; creates temporary script links, no asset copies.
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
out = ROOT / "games/relic-rush/docs/review/dead-board"
out.mkdir(parents=True, exist_ok=True)

with tempfile.TemporaryDirectory(prefix="relic-dead-board-") as directory:
    scripts = Path(directory)
    for source in (ROOT / "games/relic-rush/lua").glob("*.lua"):
        (scripts / ("game.lua" if source.name == "main.lua" else source.name)).symlink_to(source)
    (scripts / "main.lua").symlink_to(Path(__file__).with_name("main.lua"))
    (scripts / "setup.lua").symlink_to(ROOT / "tests/lua/fixtures/dead_board.lua")
    for state in ("before", "after"):
        for name in ("board", "rules"):
            target = scripts / f"{name}.lua"
            target.unlink()
            if state == "before":
                source = subprocess.check_output(
                    ["git", "show", f"{args.before_ref}:games/relic-rush/lua/{name}.lua"], cwd=ROOT
                )
                target.write_bytes(source)
            else:
                target.symlink_to(ROOT / f"games/relic-rush/lua/{name}.lua")
        for size in ("480x900", "390x844"):
            shot = scripts / "shot.png"
            command = [str(ROOT / "build/relic-rush"), "--headless", "--mute", "--fresh",
                       "--lua", str(scripts), "--size", size, "--frames", "1", "--shot", str(shot)]
            if size == "390x844":
                command += ["--safe-area", "0,47,0,34"]
            subprocess.run(command, cwd=ROOT, check=True)
            destination = out / f"{state}-{size}.jpg"
            with Image.open(shot) as image:
                image.convert("RGB").save(destination, quality=90)
            print(destination.relative_to(ROOT))
