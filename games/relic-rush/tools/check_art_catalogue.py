"""Fail CI for uncatalogued runtime files, rule specials/kinds, or authored states."""
import json
import re
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
manifest = json.loads((ROOT / "art/board-states/manifest.json").read_text())
doc = (ROOT / "docs/asset-catalogue.md").read_text()
rules = (ROOT / "lua/rules.lua").read_text()
art = (ROOT / "lua/art.lua").read_text()
for field, key in [("tools", "tools"), ("states", "tool_states")]:
    declaration = re.search(r"A\." + field + r" = \{([^}]+)\}", art).group(1)
    assert re.findall(r'"([^"]+)"', declaration) == manifest[key], f"Runtime {field} need catalogue coverage"
actual = sorted(str(p.relative_to(ROOT)) for p in (ROOT / "data").rglob("*") if p.is_file())
assert actual == manifest["runtime_inventory"], "Runtime inventory changed: update manifest AND asset catalogue"
special_line = re.search(r"M\.NORMAL[^\n]+", rules).group()
specials = re.findall(r"M\.([A-Z_]+)", special_line)
assert specials == list(manifest["specials"]), "Rule specials need artwork and catalogue entries"
kinds = re.findall(r"M\.RELIC_([A-Z]+)", re.search(r"M\.RELIC_IDOL[^\n]+", rules).group())
assert kinds == manifest["kinds"], "Rule kinds need artwork and catalogue entries"
expected = {v for v in manifest["specials"].values() if v}
expected |= {"sand", "chain", "ice-2", "ice-1", "selected", "hint", "guide"}
for tool in manifest["tools"]:
    for state in manifest["tool_states"]:
        expected.add(tool + "-" + state)
        assert '"' + tool + '"' in art and '"' + state + '"' in art
assert expected == set(manifest["assets"]), "Missing or uncatalogued atlas state"
special_declaration = re.search(r"A\.specials = \{([^}]+)\}", art).group(1)
assert re.findall(r'"([^"]+)"', special_declaration) == [v for v in manifest["specials"].values() if v]
for name, asset in manifest["assets"].items():
    assert "`" + name + "`" in doc, f"Undocumented atlas state: {name}"
    assert len(asset["box"]) == 4
    data = (ROOT / asset["runtime"]).read_bytes()
    assert data[:8] == b"\x89PNG\r\n\x1a\n"
    assert struct.unpack(">II", data[16:24]) == (128, 128)
    assert data[25] == 6, f"Expected RGBA authored state: {name}"
for name in [manifest["source"], manifest["prompt"]]:
    assert (ROOT / name).is_file()
assert (ROOT / manifest["cell_mask"]["source"]).is_file(), "Missing renderer-authored cell mask"
assert (ROOT / manifest["cell_mask"]["runtime"]).is_file(), "Missing runtime cell mask"
for pack in manifest["packs"]:
    for kind in range(len(kinds)):
        assert (ROOT / f"data/tile-sets/{pack}/{kind}.png").is_file()
print(f"Relic Rush catalogue: {len(actual)} runtime files, 18 pieces, 27 authored states covered")
