# Shop and expedition status icons

The building catalogue shows the new emerald checkmark for restored buildings
and the new gold padlock for locked buildings. The expedition list uses the
same padlock for locked levels. In each comparison, the original is on the left
and the updated screen is on the right.

| Screen | 480 × 900 | 390 × 844 |
| --- | --- | --- |
| Building catalogue | [Before and after](shop-status.jpg) | [Before and after](phone-shop-status.jpg) |
| Expedition list | [Before and after](expeditions.jpg) | [Before and after](phone-expeditions.jpg) |

```sh
build/test/relic-rush "shot shop-status" "shot phone-shop-status" "shot expeditions" "shot phone-expeditions"
```
