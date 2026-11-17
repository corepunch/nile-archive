#!/usr/bin/env python3
"""Audit a locally owned Tropicats app and its manifest-referenced level bundles.

Requires UnityPy 1.25.4. Reads only; writes a compact factual JSON report to stdout.
No network requests, executable loading, game changes, or asset exports.
See docs/TROPICATS_ANALYSIS.md for acquisition and evidence limitations.
"""

import argparse
import collections
import hashlib
import json
from pathlib import Path
import plistlib
import re

import UnityPy


def require(condition, message):
    if not condition:
        raise ValueError(message)


def text_assets(path):
    result = {}
    for obj in UnityPy.load(str(path)).objects:
        if obj.type.name == "TextAsset":
            data = obj.read()
            require(data.m_Name not in result, f"Duplicate asset: {data.m_Name}")
            result[data.m_Name] = data.m_Script
    return result


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("app", type=Path)
    parser.add_argument("bundles", type=Path,
                        help="Directory containing config.bundle and levels_area_N")
    args = parser.parse_args()
    with (args.app / "Info.plist").open("rb") as stream:
        info = plistlib.load(stream)
    source = args.app / "Data/resources.assets"
    resources = text_assets(source)
    config = text_assets(args.bundles / "config.bundle")
    quests = json.loads(resources["questconfig"])["quests"]
    chapters = json.loads(config["chapterconfig.json"])["chapters"]
    areas = json.loads(config["areasconfig.json"])["areas"]
    levels = [level for area in areas for level in area["levels"]]
    numbers = [level["level"] for level in levels]
    require(numbers == list(range(1, max(numbers) + 1)), "Non-contiguous campaign")
    manifest = json.loads(resources["assetbundles_hd"])
    entries = [item for group in manifest["all"] for item in group["manifest"]["i"]
               if item["n"] == "config" or re.fullmatch(r"levels_area_\d+", item["n"])]
    cdn = json.loads(resources["CDNConfig.json"])
    root = f"https://cdn.wooga.com/{cdn['SBSAccount']}/{cdn['Environment']}/iOS/hd/"
    provenance = []
    variants = {}
    for entry in entries:
        name = entry["n"]
        path = args.bundles / ("config.bundle" if name == "config" else name)
        provenance.append({"name": name, "url": root + entry["u"],
                           "manifest_bytes": entry["s"], "actual_bytes": path.stat().st_size,
                           "sha256": digest(path)})
        if name == "config":
            continue
        for key, content in text_assets(path).items():
            require(key not in variants, f"Duplicate level: {key}")
            variants[key] = json.loads(content)
    expected = {f"{number:04d}{tier}" for number in numbers for tier in "abc"}
    require(expected <= variants.keys(), "Missing tier assets")
    tiers = {name: variants[name] for name in sorted(expected)}
    references = [ref for quest in quests for group in quest["task_levels"]
                  for ref in group.split(",") if ref != "none"]
    normalized = [f"{int(ref[:-1]):04d}{ref[-1]}" for ref in references]
    require(set(normalized) <= expected, "Quest references a missing tier")
    require(sorted(int(ref[:-1]) for ref in references) == numbers,
            "Quest coverage is not exactly one tier per numbered level")
    eoc = json.loads(resources["endofcontentlevelsconfig"])["levels"]
    require(all(f"{row['level']:04d}{row['tier']}" in tiers for row in eoc),
            "End-of-content table references a missing tier")
    task_counts = collections.Counter(task for quest in quests for task in quest["task_type"])
    story = json.loads(config["storydialogueconfig.json"])
    examples = {}
    for name in ["0001a", "0001b", "0001c", "2730a", "2730b", "2730c"]:
        if name in tiers:
            data = tiers[name]
            examples[name] = {"moves": data["data"]["moves"],
                              "objectives": data["data"]["objectives"],
                              "occupied_layer_cells": {
                                  key: sum(value != 0 for value in data["layout"][key])
                                  for key in ["fields", "stones", "chains"]}}
    report = {
        "app_version": info["CFBundleShortVersionString"],
        "app_build": info["CFBundleVersion"],
        "resources_sha256": digest(source),
        "chapters": chapters,
        "quest_count": len(quests),
        "task_counts": task_counts,
        "story_level_count": len(numbers),
        "configured_tier_count": sum(len(level["tiers"]) for level in levels),
        "decoded_tier_count": len(tiers),
        "additional_assets": sorted(variants.keys() - expected),
        "field_array_lengths": collections.Counter(len(v["layout"]["fields"])
                                                   for v in variants.values()),
        "primary_objectives": collections.Counter(level["objective"] for level in levels),
        "quest_required_tiers": collections.Counter(ref[-1] for ref in references),
        "end_of_content_entries": len(eoc),
        "end_of_content_unique_entries": len({(r["level"], r["tier"]) for r in eoc}),
        "dialogue_setup_rows": len(story["dialogue_setup"]),
        "dialogue_detail_rows": len(story["dialogue_details"]),
        "dialogue_rows_with_sentence": sum("sentence" in r for r in story["dialogue_details"]),
        "dialogue_triggers": collections.Counter(r.get("trigger_condition", "unspecified")
                                                for r in story["dialogue_setup"]),
        "single_tiers_default": json.loads(resources["feature_switches"])["single_tiers"],
        "examples": examples,
        "bundles": provenance,
    }
    print(json.dumps(report, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
