#!/usr/bin/env python3
"""Export Cradle of Rome 2's authored economy from the unpacked Windows data."""

import argparse
import json
from pathlib import Path

from analyze import legacy_xml, pieces, prices


def read_economy(root):
    game = root / "settings/scenes/game"
    shop = root / "settings/scenes/shop/epochs.xml"
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
            assert unlock in tiles, building.attrib["id"]
            buildings.append({
                "id": building.attrib["id"],
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
