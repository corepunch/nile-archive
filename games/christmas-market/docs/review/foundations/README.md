# Adjacent painted foundations

Lantern Firs and Snowman Bench occupy adjacent 2 × 2 plots. The fixture sets
clearance to zero so the slab edges meet, confirms both plots through the city
placement API, and checks that moving the second toward the first creates a
collision. The before captures show a step
where the painted slabs meet. In the after captures the front edge continues
across the join.

| Phone viewport | Before | After |
| --- | --- | --- |
| 480 × 900 | ![Before at 480 × 900](before-480x900.jpg) | ![After at 480 × 900](after-480x900.jpg) |
| 390 × 844 | ![Before at 390 × 844](before-390x844.jpg) | ![After at 390 × 844](after-390x844.jpg) |

```sh
python3 tools/import_painted_buildings.py christmas-market
python3 games/christmas-market/tools/check_assets.py --update
python3 tools/buildings.py --check
build/test/christmas-market "shot adjacent-foundations" "shot phone-adjacent-foundations"
```

The captures use the two logical phone viewports at 2× pixel density.
Catalogue review pages 1–3 and 8–10 show all 18 slab-based objects with their
footprints overlaid.
