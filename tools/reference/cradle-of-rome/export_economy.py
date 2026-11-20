#!/usr/bin/env python3
"""Export Cradle of Rome 2's authored economy from the unpacked Windows data."""

import argparse
import json
from pathlib import Path

from analyze import legacy_xml, pieces, prices


def read_economy(root):
    game = root / "settings/scenes/game"
    shop = root / "settings/scenes/shop/epochs.xml"
    locale = legacy_xml(root / "settings/locale.xml").find("Locale[@language='en']")
    strings = {node.attrib["alias"]: node.text for node in locale.iter("String")}
    tiles = pieces(game)
    for tile in legacy_xml(game / "field_balls.xml").findall("Ball"):
        number = int(tile.attrib["type"])
        if number in tiles:
            tiles[number]["sprite"] = tile.attrib["default_sprite"]
    epochs = []
    for epoch in legacy_xml(shop).findall("Epoch"):
        buildings = []
        for building in epoch.findall("Construction"):
            unlock = int(building.find("Ball").attrib["type"])
            key = building.attrib["id"]
            short = key.removeprefix("city_")
            name = strings.get(f"ct_tt_{key}") or strings[f"ct_tt_{short}"]
            message = strings.get(f"ct_{key}_you_got") or strings[f"ct_{short}_you_got"]
            reward = message.removeprefix("You have ").removeprefix("a ").removeprefix("an ").removesuffix(".")
            assert unlock in tiles, key
            buildings.append({
                "id": key,
                "name": name.title().replace(" Of ", " of ").replace(" The ", " the ").replace("'S", "'s"),
                "reward": reward[0].upper() + reward[1:],
                "price": prices(building, "Price"),
                "plan_access": prices(building, "PlanAccess"),
                "unlocks_tile": unlock,
            })
        epochs.append({"id": epoch.attrib["title"], "buildings": buildings})
    adventure = legacy_xml(game / "game_settings.xml").find("Adventure")
    return {
        "build": "GameTop Windows",
        "price_order": ["gold", "supplies", "food"],
        "resource_ids": {1: "gold", 2: "supplies", 3: "food"},
        "tiles": dict(sorted(tiles.items())),
        "epochs": epochs,
        "adventure": {
            "match_multipliers": {int(line.attrib["size"]): int(line.attrib["multiplier"])
                                  for line in adventure.findall("Score/Match/Line")},
            "combo_multipliers": {int(line.attrib["count"]): int(line.attrib["multiplier"])
                                  for line in adventure.findall("Score/Combo/Line")},
            "finish_time_multiplier": int(adventure.find("LevelComplete").attrib["time_multiplier"]),
            "finish_level_multiplier": int(adventure.find("LevelComplete").attrib["level_multiplier"]),
        },
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("resources", type=Path)
    args = parser.parse_args()
    print(json.dumps(read_economy(args.resources), indent=2))
