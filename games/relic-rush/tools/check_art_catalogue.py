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
buttons = manifest["tool_buttons"]
assert (ROOT / buttons["source"]).is_file() and (ROOT / buttons["prompt"]).is_file()
assert buttons["runtime_button_size"] == [int(re.search(r"A\.tool_size = (\d+)", art).group(1))] * 2
for tool in manifest["tools"]:
    for state in manifest["tool_states"]:
        asset = manifest["assets"][tool + "-" + state]
        assert asset["source"] == buttons["source"] and asset["fit"] == "square-button"
assert (ROOT / manifest["cell_mask"]["source"]).is_file(), "Missing renderer-authored cell mask"
assert (ROOT / manifest["cell_mask"]["runtime"]).is_file(), "Missing runtime cell mask"
for pack in manifest["packs"]:
    for kind in range(len(kinds)):
        assert (ROOT / f"data/tile-sets/{pack}/{kind}.png").is_file()
hud = json.loads((ROOT / manifest["expedition_hud"]).read_text())
assert set(hud["icons"]) == {"pause-" + state for state in manifest["tool_states"]} | {"score", "complete"}
for asset in [hud["controls"], hud["retired_portrait"]]:
    assert (ROOT / asset["source"]).is_file() and (ROOT / asset["prompt"]).is_file()
for name, asset in hud["icons"].items():
    assert "`" + name + "`" in doc
    assert (ROOT / asset["runtime"]).is_file()
assert not (ROOT / "data/characters/elena-investigating.png").exists(), "retired portrait must not ship"
buildings = json.loads((ROOT / manifest['buildings']).read_text())
assert (ROOT / buildings['source']).is_file()
assert (ROOT / buildings['registration']).is_file()
assert len(buildings['items']) == 96
assert len({b['key'] for b in buildings['items']}) == 96
definitions = (ROOT / 'lua/buildings.lua').read_text()
building_doc = (ROOT / 'docs/building-catalogue.md').read_text()
for i, b in enumerate(buildings['items']):
    assert b['id'] == i and b['runtime'] in actual
    assert (ROOT / b['source']).is_file(), b['key']
    assert all(n > 0 and n % 1 == 0 for n in b['size'])
    assert b['base_width'] > 0 and len(b['pivot']) == 2
    data = (ROOT / b['runtime']).read_bytes()
    assert data[:8] == b'\x89PNG\r\n\x1a\n' and data[25] == 6, b['key']
    assert list(struct.unpack('>II',data[16:24])) == b['image'], b['key']
    assert (ROOT / b['shadow']['runtime']).is_file(), b['key']
    assert 'key="'+b['key']+'"' in definitions and '`'+b['key']+'`' in building_doc
    assert (ROOT / f'docs/review/building-catalogue/footprints-{i//4+1:02d}.jpg').is_file()
assert '96' in doc and 'building-catalogue.md' in doc
assert set(manifest['island_layers']) == {'cloud-fog', 'building-shadows'}
for name in manifest['island_layers']:
    assert '"'+name+'"' in art and '`'+name+'`' in doc
print(f"Relic Rush catalogue: {len(actual)} runtime files, 18 pieces, 27 board states, 7 HUD icons, 96 buildings covered")
