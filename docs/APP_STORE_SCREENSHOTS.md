# App Store screenshots

| Listing | iPhone, 1320 × 2868 | iPad, 2064 × 2752 |
| --- | --- | --- |
| Christmas at Bellmere | [Five screenshots](../games/christmas-market/docs/screenshots/app-store/iphone/) | [Five screenshots](../games/christmas-market/docs/screenshots/app-store/ipad/) |
| Relic Rush - Uncover Mysteries | [Five screenshots](../games/relic-rush/docs/screenshots/app-store/iphone/) | |

Both galleries open on the built town, then show two line gems clearing a row and column. Bellmere also shows the market streets, the letter puzzle and a rainbow-and-line-gem combo. Relic Rush shows the jewel pack, the rainbow-and-line-gem combo and a tablet shattering.

## Capture and export

From the repository root on a Mac with a 2× display, run the opt-in capture jobs. They render the game at the App Store pixel sizes and use the target device's safe-area proportions.

```sh
make build/test/all
APP_STORE_SHOTS=1 build/test/all --suite=christmas-market --suite=relic-rush 'shot app-store-'
```

Convert the captures to RGB JPEGs. The numbered filenames set the gallery order.

```sh
python3 - <<'PY'
from pathlib import Path
from PIL import Image

sizes = {"iphone": (1320, 2868), "ipad": (2064, 2752)}
for game in ("christmas-market", "relic-rush"):
    for path in sorted(Path("build/shots", game).glob("app-store-*-??-*.png")):
        _, _, device, name = path.stem.split("-", 3)
        destination = Path("games", game, "docs/screenshots/app-store", device)
        destination.mkdir(parents=True, exist_ok=True)
        with Image.open(path) as capture:
            if capture.size != sizes[device]:
                raise ValueError(f"{path} is {capture.size}, expected {sizes[device]}")
            capture.convert("RGB").save(destination / f"{name}.jpg",
                                        quality=95, subsampling=0, optimize=True)
PY
```

Inspect the exported images, then use `asc screenshots validate --path <gallery> --device-type <type>` with `IPHONE_69` or `IPAD_PRO_3GEN_129`. Check the editable version and its existing sets before uploading to the `en-US` localization. Use `asc screenshots list` to verify the order and delivery status after upload.
