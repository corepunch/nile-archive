"""Fail CI for uncatalogued runtime files, rule kinds, or authored states."""
import json
import re
import struct
from PIL import Image
from pathlib import Path
from prepare_bonus_gems import pack

ROOT = Path(__file__).resolve().parents[1]
manifest = json.loads((ROOT / "art/board-states/manifest.json").read_text())
doc = (ROOT / "docs/asset-catalogue.md").read_text()
rules = (ROOT / "lua/rules.lua").read_text()
art = (ROOT / "lua/art.lua").read_text()
for field, key in [("states", "tool_states")]:
    declaration = re.search(r"A\." + field + r" = \{([^}]+)\}", art).group(1)
    assert re.findall(r'"([^"]+)"', declaration) == manifest[key], f"Runtime {field} need catalogue coverage"
actual = sorted(str(p.relative_to(ROOT)) for p in (ROOT / "data").rglob("*") if p.is_file())
assert actual == manifest["runtime_inventory"], "Runtime inventory changed: update manifest AND asset catalogue"
# Registered sprites ship packed in the typed atlases (data/board/<kind>.png).
atlas = json.loads((ROOT / "art/match3-atlas.json").read_text())
registered = sorted(str(p.relative_to(ROOT)) for p in (ROOT / "art/registered").rglob("*") if p.is_file())
shipped = set(actual) | set(registered)
resources = manifest["resource_pieces"]
declaration = re.search(r"A\.resource_pieces = \{([^}]+)\}", art).group(1)
pieces = [*resources["slots"], *resources["from_campaign"]]
assert re.findall(r'"([^"]+)"', declaration) == pieces
assert all((ROOT / resources[key]).is_file() for key in ("source", "prompt"))
for name in pieces:
    path = f"art/registered/resource-pieces/{name}.png"
    assert path in shipped and f"`{name}`" in doc
wallet = manifest["wallet_icons"]
assert all((ROOT / wallet[key]).is_file() for key in ("source", "prompt", "review"))
declaration = re.search(r"A\.wallet_icons\s*=\s*\{([^}]+)\}", art).group(1)
assert {name: f"art/registered/resource-pieces/{key}.png" for name, key in re.findall(r'(\w+)="([^"]+)"', declaration)} == wallet["runtime"]
for path in wallet["runtime"].values():
    assert path in shipped and f"`{Path(path).stem}`" in doc
campaign = manifest["campaign_pieces"]
for name, unlock in (manifest["resource_unlocks"] | manifest["featured_pieces"]).items():
    assert unlock["runtime"] in shipped and f"`{name}`" in doc
    assert all((ROOT / unlock[key]).is_file() for key in ("source", "registration") if key in unlock)
declaration = re.search(r"A\.resource_upgrades = \{([^}]+)\}", art).group(1)
def registered_tile(frame):
    pack, kind = frame.rsplit("-", 1)
    assert atlas["frames"][frame]["atlas"] == "pieces", frame
    return f"art/registered/tile-sets/{pack}/{kind}.png"
upgrades = {quoted or bare: registered_tile(frame) for quoted, bare, frame in
            re.findall(r'(?:\["([^"]+)"\]|(\w+))\s*=\s*"([^"]+)"', declaration)}
assert upgrades == {name: item["runtime"] for name, item in manifest["resource_unlocks"].items()
                    if name not in pieces and item["runtime"] != campaign["runtime"]}, "Runtime upgrades need catalogue coverage"
declaration = re.search(r"A\.campaign_resources = \{([^}]+)\}", art).group(1)
campaign_resources = set(re.findall(r'"([^"]+)"', declaration))
assert campaign_resources == {"apple"} | {name for name, item in
    (manifest["resource_unlocks"] | manifest["featured_pieces"]).items() if item["runtime"] == campaign["runtime"]}
assert campaign["runtime"] in shipped
assert all((ROOT / campaign[key]).is_file() for key in ("source", "edit_target", "prompt", "review"))
revised_pieces = set()
for revision in campaign["revisions"]:
    assert all((ROOT / revision[key]).is_file() for key in ("source", "prompt"))
    if "review" in revision:
        assert (ROOT / revision["review"]).is_file()
    assert not revised_pieces.intersection(revision["boxes"]), "Overlapping campaign revisions"
    revised_pieces.update(revision["boxes"])
assert set(resources["from_campaign"]) <= revised_pieces
declaration = re.search(r"A\.campaign_pieces = \{([^}]+)\}", art).group(1)
slots = [key for row in campaign["rows"] for key in row]
assert re.findall(r'"([^"]+)"', declaration) == slots, "Campaign piece atlas order"
story_pieces = re.search(r"A\.story_pieces = \{([^}]+)\}", art).group(1)
expected_pieces = set(pieces) | set(upgrades) | campaign_resources | set(re.findall(r'"([^"]+)"', story_pieces))
expected_pieces |= {"amphora", *revised_pieces}
assert set(slots) == expected_pieces and len(slots) == len(expected_pieces), "Campaign piece atlas coverage"
gems = manifest["bonus_gems"]
assert all((ROOT / gems[key]).is_file() for key in ("source", "prompt", "button_base", "review"))
assert (ROOT / gems["runtime"]).read_bytes() == pack(gems), "Bonus gem atlas registration is stale"
assert gems["rows"] == ["board", *manifest["tool_states"]]
assert set(gems["button_states"]) == set(manifest["tool_states"])
declaration = re.search(r"A\.bonus_atlas_order = \{([^}]+)\}", art).group(1)
assert re.findall(r'"bonus-([^"]+)"', declaration) == gems["columns"]
economy = (ROOT / "lua/economy.lua").read_text()
variants = re.findall(r'\{key="([^"]+)", name="[^"]+", action="[^"]+"(?:, art="([^"]+)")?', economy)
variant_art = {key: art_key or key for key, art_key in variants}
assert variant_art == {key: bonus["art"] for key, bonus in gems["bonuses"].items()}
assert set(variant_art.values()) == set(gems["columns"])
assert gems["toolbar"]["slots"] == re.findall(r'\{key="([^"]+)", levels=\{', economy)
match3 = (ROOT.parent.parent / "engine/match3.lua").read_text()
assert gems["toolbar"]["button_size"] == int(re.search(r'E.TOOL_SIZE = (\d+)', match3).group(1))
kinds = re.findall(r"M\.RELIC_([A-Z]+)", re.search(r"M\.RELIC_IDOL[^\n]+", rules).group())
assert kinds == manifest["kinds"], "Rule kinds need artwork and catalogue entries"
expected = {"chain", "ice-2", "ice-1", "selected", "hint", "guide"}
assert expected == set(manifest["assets"]), "Missing or uncatalogued atlas state"
for name, asset in manifest["assets"].items():
    assert "`" + name + "`" in doc, f"Undocumented atlas state: {name}"
    assert len(asset["box"]) == 4
    if asset.get("atlas_frame"):
        assert asset["atlas_frame"] in atlas[asset.get("atlas_section", "board_theme")]
        assert asset["runtime"] == "data/board/" + atlas["frames"][asset["atlas_frame"]]["atlas"] + ".png"
        continue
    data = (ROOT / asset["runtime"]).read_bytes()
    assert data[:8] == b"\x89PNG\r\n\x1a\n"
    assert struct.unpack(">II", data[16:24]) == (128, 128)
    assert data[25] == 6, f"Expected RGBA authored state: {name}"
    if name in {"ice-1", "ice-2"}:
        alpha = Image.open(ROOT / asset["runtime"]).getchannel("A")
        assert all(alpha.getpixel((x, y)) > 128 for x in range(40, 89, 8)
                   for y in range(40, 89, 8)), f"Ice must cover the whole face: {name}"
for name in [manifest["source"], manifest["prompt"]]:
    assert (ROOT / name).is_file()
# The square tool buttons are retired: every board has bonus slots.
retired = manifest["retired_tool_buttons"]
assert (ROOT / retired["source"]).is_file() and (ROOT / retired["prompt"]).is_file()
assert not any(name.startswith(("pickaxe-", "dynamite-", "sunburst-")) for name in atlas["frames"]), "Retired tool buttons packed"
assert (ROOT / manifest["cell_mask"]["source"]).is_file(), "Missing renderer-authored cell mask"
assert (ROOT / manifest["cell_mask"]["runtime"]).is_file(), "Missing runtime cell mask"
for pack in manifest["packs"]:
    for kind in range(len(kinds)):
        assert (ROOT / f"art/registered/tile-sets/{pack}/{kind}.png").is_file()
hud = json.loads((ROOT / manifest["expedition_hud"]).read_text())
assert set(hud["icons"]) == {"pause-" + state for state in manifest["tool_states"]} | {"score", "complete", "life"}
for asset in [hud["controls"], hud["retired_portrait"]]:
    assert (ROOT / asset["source"]).is_file() and (ROOT / asset["prompt"]).is_file()
for name, asset in hud["icons"].items():
    assert "`" + name + "`" in doc
    assert (ROOT / asset["runtime"]).is_file()
nav=json.loads((ROOT / manifest["navigation"]).read_text())
assert (ROOT/nav["source"]).is_file() and (ROOT/nav["prompt"]).is_file()
assert set(nav["icons"])=={kind+"-"+state for kind in ("build","play","levels") for state in manifest["tool_states"]}
for name,asset in nav["icons"].items():
    assert "`"+name+"`" in doc
    assert (ROOT/asset["runtime"]).is_file()
assert not (ROOT / "data/story/characters/elena-investigating.png").exists(), "retired portrait must not ship"
buildings = json.loads((ROOT / manifest['buildings']).read_text())
assert (ROOT / buildings['source']).is_file()
assert (ROOT / buildings['registration']).is_file()
assert len(buildings['items']) == 96
assert len({b['key'] for b in buildings['items']}) == 96
definitions = (ROOT / 'lua/buildings.lua').read_text()
building_doc = (ROOT / 'docs/building-catalogue.md').read_text()
for i, b in enumerate(buildings['items']):
    assert b['id'] == i and b['runtime'] in shipped
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
assert set(manifest['island_layers']) == {'cloud-fog', 'building-shadows', 'placement-guides'}
for name in manifest['island_layers']:
    assert '"'+name+'"' in art and '`'+name+'`' in doc
print(f"Relic Rush catalogue: {len(actual)} runtime files, {len(slots)} campaign pieces, 26 board states, 7 HUD icons, 96 buildings covered")

# Compare actual piece silhouettes with the renderer-authored cell. The sun
# face remains upright: geometry is authored, not a runtime sprite rotation.
mask = Image.open(ROOT / manifest['cell_mask']['runtime']).getchannel('A')
def silhouette(alpha):
    bounds = alpha.point(lambda value: 255 if value > 128 else 0).getbbox()
    left, top, right, bottom = bounds
    width, height = right - left, bottom - top
    spans = []
    for fraction in [.1, .25, .4, .5, .6, .75, .9]:
        y = min(bottom - 1, top + round(height * fraction))
        xs = [x for x in range(left, right) if alpha.getpixel((x, y)) > 128]
        spans.append((max(xs) - min(xs) + 1) / width)
    return width / height, spans
board_ratio, board_spans = silhouette(mask)
for pack in ['relics', 'jewels']:
    image = Image.open(ROOT / f'art/registered/tile-sets/{pack}/0.png').convert('RGBA')
    ratio, spans = silhouette(image.getchannel('A'))
    assert abs(ratio / board_ratio - 1) < .08, f'{pack}: hex must match board aspect'
    assert all(abs(a - b) < .14 for a, b in zip(spans, board_spans)), f'{pack}: six-sided flat-top contour must match board'
    assert spans[3] - spans[2] > .04 and spans[3] - spans[4] > .04, f'{pack}: side vertices must be points, not octagon edges'
print('Hex pieces: sun idol and yellow gemstone match the actual flat-top board mask')

# Script, identities and presentation mapping must ship together.
import subprocess
import sys
tiles = manifest["tiles"]
spec = json.loads((ROOT.parents[1] / tiles["spec"]).read_text())
declaration = re.search(r"A\.floor_tiles = \{([^}]+)\}", art).group(1)
assert re.findall(r'"([^"]+)"', declaration) == tiles["frames"] == list(spec["tiles"])
assert "games/relic-rush/art/registered/board-tiles" in spec["outputs"]
for name in spec["tiles"]:
    assert f"art/registered/board-tiles/{name}.png" in shipped and f"`tile-{name}`" in doc, name
subprocess.run([sys.executable, str(ROOT.parents[1] / tiles["generator"]), "--check"], check=True)
frame = manifest["board_frame"]
for review in ("review", "decoration_review", "reference", "decorations"):
    assert (ROOT.parents[1] / frame[review]).is_file()
assert frame["stone"] in shipped and (ROOT / frame["layout"]).is_file()
assert 'require("board_frame_atlas")' in art
subprocess.run([sys.executable, str(ROOT.parents[1] / frame["generator"]),
                "--game", ROOT.name, "--check", str(ROOT / frame["stone"])], check=True)
finale = manifest["finale"]
for name, item in finale["assets"].items():
    assert f'`{name}`' in doc and f'"{name}"' in art
    assert item["runtime"] in shipped
    assert all((ROOT / item[key]).is_file() for key in ("source", "prompt"))
subprocess.run([sys.executable, str(ROOT / finale["registration"]), "--check"], check=True)

subprocess.run([sys.executable, str(ROOT / 'tools/prepare_story.py'), '--check'], check=True)
assert set(manifest['story']['cast']) == {'elena','mara','tomas','adrian'}
assert all(path in shipped for path in manifest['story']['cast'].values())
assert manifest['story']['states'] == ['speaking','listening','thought','shout']
assert 'A.story=' in art and '31.5' in doc

quest = manifest["quest_objects"]
assert quest["runtime"] in shipped
declaration = re.search(r"A\.quest_objects = \{([^}]+)\}", art).group(1)
assert re.findall(r'"([^"]+)"', declaration) == quest["slots"]
for key in quest["slots"]:
    assert "`" + key + "`" in doc
    path = quest["shared_rewards"].get(key, f"data/story/finds/{key}.png")
    assert path in shipped
for key in ["source", "prompt", "registration"]:
    assert (ROOT / quest[key]).is_file()
assert all((ROOT / quest["gear_reward"][key]).is_file() for key in ("source", "prompt"))
for name, reward in quest["reward_sources"].items():
    assert name in quest["slots"] and all((ROOT / reward[key]).is_file() for key in ("source", "prompt"))
rewards = quest["separate_rewards"]
declaration = re.search(r"A\.separate_rewards = \{([^}]+)\}", art).group(1)
assert re.findall(r'"([^"]+)"', declaration) == list(rewards)
for name, reward in rewards.items():
    assert reward["runtime"] == f"data/story/finds/{name}.png" and reward["runtime"] in shipped
    assert all((ROOT / reward[key]).is_file() for key in ("source", "prompt"))
campaign = (ROOT / "lua/campaign.lua").read_text()
sheets = quest["story_pieces"]["atlases"]
declaration = re.search(r"A\.story_pieces = \{([^}]+)\}", art).group(1)
assert re.findall(r'"([^"]+)"', declaration) == [name for sheet in sheets for name in sheet["items"]]
board_slots = {}
for sheet in sheets:
    assert all((ROOT / sheet[key]).is_file() for key in ("source", "prompt"))
    for name, item in sheet["items"].items():
        assert item["runtime"] == f"art/registered/story-pieces/{name}.png" and item["runtime"] in shipped
        for board in item["boards"]:
            assert board not in board_slots, f"Multiple story pieces on board {board}"
            board_slots[board] = name, item["kind"]
atlas_pieces = quest["atlas_pieces"]
declaration = re.search(r"A\.atlas_quest_pieces = \{([^}]+)\}", art).group(1)
assert re.findall(r'"([^"]+)"', declaration) == list(atlas_pieces)
for name, item in atlas_pieces.items():
    assert name in slots and f"`{name}`" in doc
    for board in item["boards"]:
        assert board not in board_slots, f"Multiple story pieces on board {board}"
        board_slots[board] = name, item["kind"]
declarations = re.findall(r'levels\[(\d+)\]\.story_piece, levels\[\1\]\.goal_kind = "([^"]+)", (\d+)', campaign)
assert {int(board): (name, int(kind)) for board, name, kind in declarations} == board_slots
subprocess.run([sys.executable, str(ROOT / quest["registration"]), "--check"], check=True)
subprocess.run([sys.executable, str(ROOT / "tools/prepare_resource_pieces.py"), "--check"], check=True)

result_icons = manifest["result_icons"]
assert result_icons["runtime"] in shipped
declaration = re.search(r"A\.result_icons = \{([^}]+)\}", art).group(1)
assert re.findall(r'"([^"]+)"', declaration) == list(result_icons["icons"])
for key in result_icons["icons"]:
    assert "`" + key + "`" in doc
assert (ROOT / result_icons["source"]).is_file() and (ROOT / result_icons["prompt"]).is_file()
subprocess.run([sys.executable, str(ROOT / result_icons["registration"]), "--check"], check=True)

# Kenney particle sprites: retained CC0 sources, a fresh atlas and documented frames.
for particles in (manifest['particle_sprites'], manifest['smoke_sprites']):
    assert (ROOT / particles['license']).is_file(), 'Particle sprites need their licence'
    for name, source in particles['frames'].items():
        path = (Path(particles['source']) / f'{source}.png').as_posix()
        assert (ROOT / path).is_file(), f'Missing particle source: {source}'
        assert atlas['effects'][f'fx-{name}'] == path
        assert '`' + name + '`' in doc, f'Undocumented particle sprite: {name}'

# Exact crop freshness for the changed town controls, without re-exporting the board HUD.
subprocess.run([sys.executable, str(ROOT/"tools/prepare_hud.py"), "--navigation-only", "--check"], check=True)
subprocess.run([sys.executable, str(ROOT.parents[1]/"tools/match3_buttons.py"), "--check"], check=True)
