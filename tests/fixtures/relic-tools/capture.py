"""Capture square tools in the actual game, plus native-input edge checks.

python3 tests/fixtures/relic-tools/capture.py --before-ref 3120b70
"""
import argparse
import json
from pathlib import Path
import subprocess
import tempfile

from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--before-ref", default="3120b70")
args = parser.parse_args()
out = ROOT / "games/relic-rush/docs/review/square-tools"
out.mkdir(parents=True, exist_ok=True)
manifest = json.loads((ROOT / "games/relic-rush/art/board-states/manifest.json").read_text())

with tempfile.TemporaryDirectory(prefix="relic-tools-") as directory:
    temporary = Path(directory)
    scripts, data = temporary / "lua", temporary / "data"
    scripts.mkdir()
    data.mkdir()
    for source in (ROOT / "games/relic-rush/lua").glob("*.lua"):
        (scripts / ("game.lua" if source.name == "main.lua" else source.name)).symlink_to(source)
    (scripts / "main.lua").symlink_to(Path(__file__).with_name("main.lua"))
    for source in (ROOT / "games/relic-rush/data").iterdir():
        if source.name != "board-states":
            (data / source.name).symlink_to(source)
    board_art = data / "board-states"
    board_art.mkdir()
    for source in (ROOT / "games/relic-rush/data/board-states").iterdir():
        (board_art / source.name).symlink_to(source)
    tools = [f"{tool}-{state}.png" for tool in manifest["tools"] for state in manifest["tool_states"]]
    for revision in ("before", "after"):
        for name in ("board", "art"):
            target = scripts / f"{name}.lua"
            target.unlink()
            if revision == "before":
                target.write_bytes(subprocess.check_output(
                    ["git", "show", f"{args.before_ref}:games/relic-rush/lua/{name}.lua"], cwd=ROOT))
            else:
                target.symlink_to(ROOT / f"games/relic-rush/lua/{name}.lua")
        for name in tools:
            target = board_art / name
            target.unlink()
            if revision == "before":
                target.write_bytes(subprocess.check_output(
                    ["git", "show", f"{args.before_ref}:games/relic-rush/data/board-states/{name}"], cwd=ROOT))
            else:
                target.symlink_to(ROOT / f"games/relic-rush/data/board-states/{name}")
        states = ("normal", "disabled") if revision == "before" else (
            "normal", "selected", "pressed", "hover", "disabled", "catalogue")
        for size in ("480x900", "390x844"):
            base = [str(ROOT / "build/relic-rush"), "--headless", "--mute", "--fresh",
                    "--lua", str(scripts), "--data", str(data), "--size", size]
            if size == "390x844":
                base += ["--safe-area", "0,47,0,34"]
            for state in states:
                shot = temporary / "shot.png"
                command = base + ["--tool-state", state, "--frames", "2", "--shot", str(shot)]
                if state == "catalogue":
                    command += ["--art-states"]
                subprocess.run(command, cwd=ROOT, check=True)
                with Image.open(shot) as image:
                    image = image.convert("RGB")
                    image.thumbnail((480, 1100))
                    image.save(out / f"{revision}-{state}-{size}.jpg", quality=90)
            if revision == "after":
                subprocess.run(base + ["--tool-smoke", "--frames", "120", "--shot", str(temporary / "smoke.png")],
                               cwd=ROOT, check=True)
    print("Square-tool captures and input checks complete")
