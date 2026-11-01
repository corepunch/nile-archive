"""Register authored artwork (crop, rotate, resize); never synthesize states.

python3 games/relic-rush/tools/board_assets.py [--check]
"""
import argparse
import json
from pathlib import Path

from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    manifest = json.loads((ROOT / "art/board-states/manifest.json").read_text())
    source = Image.open(ROOT / manifest["source"]).convert("RGBA")
    sources = {manifest["source"]: source}
    for atlas in (manifest.get("tool_buttons"),):
        if atlas:
            sources[atlas["source"]] = Image.open(ROOT / atlas["source"]).convert("RGBA")
            assert list(sources[atlas["source"]].size) == atlas["source_size"]
    for asset in manifest["assets"].values():
        path = asset.get("source")
        if path and path not in sources:
            sources[path] = Image.open(ROOT / path).convert("RGBA")
    mask = Image.open(ROOT / manifest["cell_mask"]["source"]).convert("L")
    assert list(source.size) == manifest["source_size"]
    for name, asset in manifest["assets"].items():
        im = sources[asset.get("source", manifest["source"])].crop(asset["box"])
        if asset.get("rotation_degrees"):
            # Align authored directional artwork with its board axis.
            # Rotation changes registration, never the authored state.
            im = im.rotate(asset["rotation_degrees"], Image.Resampling.BICUBIC, expand=True)
            im = im.crop(im.getchannel("A").point(lambda a: 255 if a > 30 else 0).getbbox())
        # Keep the authored alpha and every component (fuses, glints, chains).
        out = Image.new("RGBA", (128, 128))
        if asset.get("fit") == "hex-slot":
            # Registration is spatial fitting of authored art, not a new state.
            # All hex layers share the actual flat-top slot's width/height.
            slot = manifest["hex_slot"]
            im = im.resize(tuple(slot["art_size"]), Image.Resampling.LANCZOS)
            out.alpha_composite(im, tuple(slot["offset"]))
            # Extend the authored rim slightly past the cell and cut it with
            # the renderer's own mask. No green slot rim can protrude beneath it.
            extent = manifest["hex_slot"]["overscan"]
            larger = out.resize((extent, extent), Image.Resampling.LANCZOS)
            margin = (extent - 128) // 2
            out = larger.crop((margin, margin, margin + 128, margin + 128))
            out.putalpha(ImageChops.multiply(out.getchannel("A"), mask))
        elif asset.get("fit") == "square-button":
            # Normalize the measured button body to the same square footprint
            # in every authored state; never manufacture state artwork.
            registration = manifest["tool_buttons"]["registration"]
            im = im.resize(tuple(registration["art_size"]), Image.Resampling.LANCZOS)
            out.alpha_composite(im, tuple(registration["offset"]))
        else:
            im.thumbnail((120, 120), Image.Resampling.LANCZOS)
            out.alpha_composite(im, ((128 - im.width) // 2, (128 - im.height) // 2))
        path = ROOT / asset["runtime"]
        if args.check:
            with Image.open(path) as current:
                assert current.mode == "RGBA" and current.size == out.size, name
                assert current.tobytes() == out.tobytes(), f"Stale asset: {path}"
                if asset.get("fit") == "square-button":
                    body = current.getchannel("A").point(lambda a: 255 if a > 128 else 0).getbbox()
                    assert abs((body[2] - body[0]) - (body[3] - body[1])) <= 2, f"Non-square button: {name}"
                if asset.get("fit") == "hex-slot":
                    alpha = current.getchannel("A")
                    assert not ImageChops.subtract(alpha, mask).getbbox(), f"Outside cell mask: {name}"
                    # A flat-top hex has a broad upper edge and widest middle.
                    # This catches accidental point-up export or extra padding.
                    upper = [x for x in range(128) if alpha.getpixel((x, 18)) > 128]
                    middle = [x for x in range(128) if alpha.getpixel((x, 64)) > 128]
                    assert upper and 15 <= min(upper) and max(upper) <= 112, f"Hex orientation: {name}"
                    assert 55 <= max(upper) - min(upper) <= 95, f"Hex upper edge: {name}"
                    assert middle and max(middle) - min(middle) >= 110, f"Hex footprint: {name}"
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            out.save(path, optimize=True)
    # Normal cells and state panels use this same alpha, so pixel coverage agrees.
    mask_path = ROOT / manifest["cell_mask"]["runtime"]
    mask_rgba = Image.new("RGBA", (128, 128), (255, 255, 255, 255))
    mask_rgba.putalpha(mask)
    if args.check:
        assert Image.open(mask_path).tobytes() == mask_rgba.tobytes(), "Stale cell mask"
    else:
        mask_rgba.save(mask_path, optimize=True)
    print("Relic Rush authored atlas: 27 crops verified" if args.check else "Relic Rush atlas imported")


if __name__ == "__main__":
    main()
