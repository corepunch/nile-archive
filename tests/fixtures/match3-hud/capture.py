"""Before/after captures of the match-3 HUD from the actual game.

python3 tests/fixtures/match3-hud/capture.py --before-ref 6a56346

Reuses the expedition-header fixture (goal completion, move count, a real tool
tap and native popup input checks) against the old and the current Lua.
"""
import argparse
from pathlib import Path
import subprocess
import tempfile
from PIL import Image

ROOT=Path(__file__).resolve().parents[3]
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument("--before-ref",default="6a56346")
args=parser.parse_args()
out=ROOT/"games/relic-rush/docs/review/match3-hud"
out.mkdir(parents=True,exist_ok=True)
cases={"first":(["--level","1"],60),"late":(["--level","7"],60),"temple":(["--level","10"],60),
       "complete":(["--level","7","--goals-complete"],60),"last-moves":(["--level","4","--moves","3"],60),
       "tool":(["--level","4","--tap-tool"],30),"pause":(["--dialog","pause"],30),
       "guide":(["--dialog","guide"],40),"island":(["--city","3"],30)}
fixture=ROOT/"tests/fixtures/expedition-header/main.lua"
with tempfile.TemporaryDirectory(prefix="relic-hud-") as directory:
    scripts=Path(directory)
    for revision in ("before","after"):
        for source in (ROOT/"games/relic-rush/lua").glob("*.lua"):
            target=scripts/("game.lua" if source.name=="main.lua" else source.name)
            if target.exists():target.unlink()
            if revision=="before":
                target.write_bytes(subprocess.check_output(["git","show",f"{args.before_ref}:games/relic-rush/lua/{source.name}"],cwd=ROOT))
            else:target.symlink_to(source)
        main=scripts/"main.lua"
        if main.exists():main.unlink()
        main.symlink_to(fixture)
        data=ROOT/"games/relic-rush/data"
        if revision=="before":   # the old Lua also needs the since-retired portrait
            data=scripts/"data";data.mkdir(exist_ok=True)
            for entry in (ROOT/"games/relic-rush/data").iterdir():
                if entry.name!="characters" and not (data/entry.name).exists():(data/entry.name).symlink_to(entry)
            (data/"characters").mkdir(exist_ok=True)
            for entry in (ROOT/"games/relic-rush/data/characters").iterdir():
                if not (data/"characters"/entry.name).exists():(data/"characters"/entry.name).symlink_to(entry)
            (data/"characters/elena-investigating.png").write_bytes(subprocess.check_output(
                ["git","show",f"{args.before_ref}:games/relic-rush/data/characters/elena-investigating.png"],cwd=ROOT))
        for size in ("480x900","390x844"):
            base=[str(ROOT/"build/relic-rush"),"--headless","--mute","--fresh","--lua",str(scripts),"--data",str(data),"--size",size]
            if size=="390x844":base += ["--safe-area","0,47,0,34"]
            for name,(extra,frames) in cases.items():
                if revision=="before" and "--tap-tool" in extra:extra=extra+["175"]   # old Dynamite centre
                shot=scripts/"shot.png"
                subprocess.run(base+["--frames",str(frames),"--shot",str(shot)]+extra,cwd=ROOT,check=True,
                               stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
                with Image.open(shot) as image:
                    image=image.convert("RGB");image.thumbnail((480,1100))
                    image.save(out/f"{revision}-{name}-{size}.jpg",quality=88)
            if revision=="after":
                subprocess.run(base+["--header-smoke","--frames","700","--shot",str(scripts/"smoke.png")],cwd=ROOT,check=True,
                               stdout=subprocess.DEVNULL)
print("Match-3 HUD review captures and native input checks complete")
