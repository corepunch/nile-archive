#!/usr/bin/env python3
"""Inspect the board, piece and construction tables of Cradle of Rome Beta."""

import argparse
from collections import Counter
import json
from pathlib import Path
import re
from xml.etree import ElementTree as ET


DEFAULT_ROOT = Path(__file__).resolve().parents[2] / "reference/cradle-of-rome/resources"


def legacy_xml(path):
    # Some tables contain legacy comments or use dash sequences forbidden by XML.
    return ET.fromstring(re.sub(rb"<!--.*?-->", b"", path.read_bytes(), flags=re.DOTALL))


def components(cells):
    unvisited = set(cells)
    groups = []
    while unvisited:
        pending = [unvisited.pop()]
        area = generators = plaques = 0
        while pending:
            x, y = pending.pop()
            plaque, ball = cells[x, y]
            area += 1
            plaques += int(plaque > 0)
            generators += int(ball.get("generator") == "1")
            for neighbor in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if neighbor in unvisited:
                    unvisited.remove(neighbor)
                    pending.append(neighbor)
        groups.append((area, plaques, generators))
    return sorted(groups, reverse=True)


def read_board(path):
    root = ET.parse(path).getroot()
    field = root.find("Field")
    width, height = (int(field.attrib[k]) for k in ("width", "height"))
    positions = set()
    cells = {}
    for cell in field.findall("Cell"):
        x, y = (int(cell.attrib[k]) for k in ("x", "y"))
        if (x, y) in positions or not (0 <= x < width and 0 <= y < height):
            raise ValueError(f"{path}: invalid cell {(x, y)}")
        positions.add((x, y))
        ball = cell.find("Ball").attrib
        tile = cell.find("Tile").attrib
        if ball.get("active") == "1":
            cells[x, y] = int(tile["puzzle_count"]), ball
        elif int(tile["puzzle_count"]):
            raise ValueError(f"{path}: inactive plaque at {(x, y)}")
    values = list(cells.values())
    return {
        "settings": {key: int(value) for key, value in root.find("Settings").attrib.items()},
        "envelope": [width, height],
        "serialized_cells": len(positions),
        "active": len(cells),
        "plaques": sum(plaque > 0 for plaque, _ in values),
        "double_plaques": sum(plaque == 2 for plaque, _ in values),
        "generators": sum(ball.get("generator") == "1" for _, ball in values),
        "single_locks": sum(ball.get("lock") == "1" for _, ball in values),
        "double_locks": sum(ball.get("lock") == "2" for _, ball in values),
        "locked_plaques": sum(plaque > 0 and "lock" in ball for plaque, ball in values),
        "frozen": sum(ball.get("freeze") == "1" for _, ball in values),
        "disabled": sum(ball.get("disable") == "1" for _, ball in values),
        "fixed_types": dict(sorted(Counter(int(ball["type"]) for _, ball in values if "type" in ball).items())),
        "components": components(cells),  # (active cells, plaques, generators)
    }, cells


def summary(boards, first, last):
    rows = range(first, last + 1)
    active = [boards[n]["active"] for n in rows]
    plaques = [boards[n]["plaques"] for n in rows]
    return {
        "range": [first, last],
        "active_min_max": [min(active), max(active)],
        "active_mean": round(sum(active) / len(active), 2),
        "plaque_min_max": [min(plaques), max(plaques)],
        "time_counts": dict(sorted(Counter(boards[n]["settings"]["play_time"] for n in rows).items())),
        "levels_with_feature": {
            field: [n for n in rows if boards[n][field]]
            for field in ("double_plaques", "single_locks", "double_locks", "locked_plaques", "frozen", "disabled")
        },
        "multiple_components": [n for n in rows if len(boards[n]["components"]) > 1],
    }


def pieces(game):
    rows = {}
    for piece in legacy_xml(game / "game_balls.xml"):
        credit = piece.find("ResCredit")
        rows[int(piece.attrib["type"])] = {
            "kind": piece.tag,
            "initially_available": piece.attrib["available"] == "1",
            "base_score": int(piece.attrib["score"]),
            "credit": {k: int(v) for k, v in credit.attrib.items()} if credit is not None else None,
        }
    return rows


def prices(building, field):
    amounts = {int(item.attrib["type"]): int(item.attrib["amount"]) for item in building.findall(f"{field}/Resource")}
    return [amounts[k] for k in (1, 2, 3)]  # gold, supplies, food


def city(settings):
    scenes = settings / "scenes"
    epochs = ET.parse(scenes / "shop/epochs.xml").getroot()
    info = legacy_xml(scenes / "city/city_info_dialog.xml")
    locale = ET.parse(settings / "locale.xml")
    labels = {n.attrib["alias"]: n.text for n in locale.iter("String")}
    titles = {}
    for page in info.iter("Page"):
        for control in page.findall("Control"):
            alias = control.get("string", "")
            if alias.startswith("Text00") and alias in labels:
                titles[page.attrib["id"]] = labels[alias]
                break
    result = []
    for i, epoch in enumerate(epochs.findall("Epoch")):
        buildings = []
        for building in epoch.findall("Construction"):
            ident = building.attrib["id"]
            plan = building.find("PlanAccess/Puzzle")
            buildings.append({
                "id": ident,
                "title": titles[ident + "_0"],
                "ball": int(building.find("Ball").attrib["type"]),
                "price": prices(building, "Price"),
                "plan_access": prices(building, "PlanAccess"),
                "plan_type": plan.get("type"),
                "plan_score": int(plan.attrib["score"]),
            })
        result.append({"title": labels[f"Episode_title_{i}"], "buildings": buildings})
    return result, epochs.find("GameComplete/Construction").attrib["id"]


def print_board(board, cells):
    print(json.dumps(board, indent=2))
    print("Terrain: . plain, p plaque, P double plaque")
    print("Pieces: . open, + generator, 1/2 lock, f frozen, x disabled")
    left, right = min(x for x, _ in cells), max(x for x, _ in cells)
    top, bottom = min(y for _, y in cells), max(y for _, y in cells)
    print(f"Origin ({left}, {top})")
    for y in range(top, bottom + 1):
        terrain, pieces = [], []
        for x in range(left, right + 1):
            if (x, y) not in cells:
                terrain.append(" ")
                pieces.append(" ")
                continue
            plaque, ball = cells[x, y]
            terrain.append(".pP"[plaque])
            mark = "+" if ball.get("generator") == "1" else "."
            if ball.get("freeze") == "1":
                mark = "f"
            if ball.get("disable") == "1":
                mark = "x"
            pieces.append(ball.get("lock", mark))
        print("".join(terrain) + " | " + "".join(pieces))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=DEFAULT_ROOT, help="extracted resources directory")
    parser.add_argument("--level", choices=[str(n) for n in range(1, 116)] + ["empty"], metavar="NUMBER")
    args = parser.parse_args()
    settings = args.root / "settings"
    game = settings / "scenes/game"
    levels = game / "levels"
    if args.level:
        print_board(*read_board(levels / f"level_{args.level}.xml"))
        return
    boards = {n: read_board(levels / f"level_{n}.xml")[0] for n in range(1, 116)}
    epochs, finale = city(settings)
    print(json.dumps({
        "groups": {
            "beta": summary(boards, 1, 40),
            "adventure": summary(boards, 1, 100),
            "extras": summary(boards, 101, 115),
        },
        "boards": boards,
        "template": read_board(levels / "level_empty.xml")[0],
        "pieces": pieces(game),
        "epochs": epochs,
        "completion_construction": finale,
    }, indent=2))


if __name__ == "__main__":
    main()
