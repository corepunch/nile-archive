"""Actual-game header/modal review and queued-input checks; no asset copies.

python3 tests/fixtures/expedition-header/capture.py --before-ref a47431a
"""
import argparse
from pathlib import Path
import subprocess
import tempfile
from PIL import Image

ROOT=Path(__file__).resolve().parents[3]
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument("--before-ref",default="a47431a")
args=parser.parse_args()
out=ROOT/"games/relic-rush/docs/review/expedition-header"
out.mkdir(parents=True,exist_ok=True)
cases={"first":[],"late":["--level","7"],"pause":["--dialog","pause"],
       "guide":["--dialog","guide"],"island":["--city","3"],
       "shop":["--catalogue","bush"],"browser":["--expeditions"],
       "details":["--card","1"],"zone":["--city","3","--zone","1"]}
with tempfile.TemporaryDirectory(prefix="relic-header-") as directory:
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
        main.symlink_to(Path(__file__).with_name("main.lua"))
        selected=dict(cases)
        if revision=="after":
            selected.update({"complete":["--level","7","--goals-complete"],"states":["--hud-states"]})
        for size in ("480x900","390x844"):
            base=[str(ROOT/"build/relic-rush"),"--headless","--mute","--fresh","--lua",str(scripts),"--size",size]
            if size=="390x844":base += ["--safe-area","0,47,0,34"]
            for name,extra in selected.items():
                shot=scripts/"shot.png"
                subprocess.run(base+["--frames","4","--shot",str(shot)]+extra,cwd=ROOT,check=True)
                with Image.open(shot) as image:
                    image=image.convert("RGB");image.thumbnail((480,1100))
                    image.save(out/f"{revision}-{name}-{size}.jpg",quality=88)
            if revision=="after":
                subprocess.run(base+["--header-smoke","--frames","700","--shot",str(scripts/"smoke.png")],cwd=ROOT,check=True)
print("Header/modal review and native input checks complete")
