# Epoch one outline · A Light Below

> This page records the 100-level campaign's predecessor: a ten-expedition first epoch with crew requests, which were removed from the game in commit f98aedd2. The current campaign is in [the script](story.md) and [square-match3.md](square-match3.md).

The first epoch is Chapter 1 of the [script](story.md#chapter-1-a-light-below): expeditions 1–10, four restorations, five crew requests and the field test that follows the cable. It ends when the Village's watch gets an answer from across the gap and the player chooses who replies. This page puts the pieces in play order. The sources it summarizes stay authoritative: [script](story.md), [requests](../lua/quests.lua), [buildings and prices](../lua/buildings.lua), [unlock ladder](../lua/economy.lua), [move budgets](level-moves.md) and the [playtest plan](epoch-one-quests.md).

## Premise

- **Where we start.** An expedition crew lands at an abandoned harbor camp. The well is fouled, the quay wall is failing, and a severed relay cable has left the reef without its warning lamp.
- **Hook.** When Mara flashes her lamp at the cliff, two flashes come back.
- **Epoch question.** Is it a reflection, or is someone signalling? By the end, three flashes answer two, so it is a person.
- **Hidden truth (not revealed yet).** Ines, Tomas's former partner, has come back by another shore. She is working the old hand shutter. Tomas thinks she never returned.
- **Cast on stage:** Mara, the pilot; Elena, the scholar; Tomas Reed, the harbor keeper, from restoration 4; and the Ancient keeper's voice, read from the watch book at restoration 10. Adrian and Ines stay off stage.

## Play order

| Stretch | Expeditions (board, tier) | Restoration and price | What it unlocks on the board | Scene after placement |
| --- | --- | --- | --- | --- |
| 1 | 1 The Landing (tutorial) | **Well**: 35 Coins | Water buckets: +3 Food each, from expedition 2 | Mara draws the first bucket. Two flashes answer her lamp. A scrap of a harbor chart is caught in the rope. |
| 2 | 2 Temple Steps, 3 Sunken Courtyard, 4 Overgrown Terraces (tutorial) | **Hunter's Hut**: 225 Coins + 80 Food | Hammer, from expedition 5 | Tomas wedges the hammer and introduces himself. He and Ines wired a warning lamp below the cliff, and the storm cut its cable. |
| 3 | 5 Vault Door (easy), 6 Vine-Bound Terraces (normal), 7 Jaguar Court (easy) | **Sawmill**: 420 Coins + 150 Food | Timber bundles: +5 Supplies each, from expedition 8 | Tomas turns offcuts into a cable reel and says where the coils lie. |
| 4 | 8 Overgrown Arches (normal), 9 Twin Terraces (hard), 10 Jaguar Throne (boss) | **Village**: 585 Coins + 225 Food + 325 Supplies | Bomb, from expedition 11 | The watch book's orders. Mara takes first watch, and three flashes come back. Tomas names Ines. **Choice:** Mara or Tomas replies. |

Each restoration becomes available after the clear before its first board (1, 4, 7, 10). Its scene plays after the player confirms placement. The Village scene opens Chapter 2: expedition 11 follows the reply.

## Crew requests

Requests sit between purchases. Each puts its own piece on the boards and banks nothing in the wallet. Its marker on the island's left edge shows the giver's portrait and a progress gauge. Handing it in pays 2 Coins per piece and plays its scene. There are two lines, and a request opens once its building stands and the previous request on its line has been handed in.

| Request | Giver | Line | Piece × need | Opens with | Written for | Pays | What the scene adds |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Piece the harbor chart together | Elena | Search | Chart pages × 25 | Well | 2–4 | 50 | The chart shows a reef across the harbor mouth and a warning station on the far side. |
| Fill the supper pot | Mara | Crew | Berries × 25 | Well | 2–4 | 50 | Elena writes down what they saw, restating the two flashes. |
| Uncover the painted arrows | Tomas | Search | Trail arrows × 45 | Hut + chart | 5–7 | 90 | Tomas kept the cliff path marked after the boats stopped coming. The arrows lead to the lower quay. |
| Dig out the keeper's tools | Tomas | Crew | Tool rolls × 45 | Hut + supper | 5–7 | 90 | An empty loop in the tool roll: Tomas left his pliers at the break. |
| Haul up the relay cable | Tomas | Search | Relay cable × 60 | Sawmill + trail | 8–10 | 120 | His pliers are rusted onto the cut cable, and the wire is dead. This opens the field test. |
| Test the hand shutter | Tomas | Search | (no pieces; lift the brass ring) | Cable handed in | any time | — | Mara rows the skiff: the lamp shows red over the reef and white in clear water. Elena marks the bearing on the chart. |

- **Optional by design.** No request blocks a purchase or an expedition. After the Sawmill, the search line takes the last free piece slot, so leaving supper unfinished can never strand the cable.
- **Any order.** A request can be handed in long after its stretch. So each scene names nothing that only a later restoration establishes, and no restoration scene depends on one.

## Clue chain

| Plant | Payoff |
| --- | --- |
| Two flashes answer Mara's lamp (Well) | Three answer at the Village; Ines repeats the pattern at the finale (30). |
| A reef and a far warning station on the chart | The watch book tells the village when to open the shutter. |
| Tomas: the relay cable is severed (Hut) | The cable request, then the hand-shutter test. |
| Tomas makes a reel from Sawmill timber | The cable request asks for the loose coils. |
| Pliers missing from the tool roll | Pliers rusted onto the break (either scene may come first). |
| Elena writes down what they saw (supper) | She marks the red sector after Mara's skiff test. |
| Tomas names Ines (Village) | He recognizes her handwriting in the port register (13). |

## Knowledge at the end of the epoch

- **Player and crew:** the relay is dead, and someone across the gap is working a shutter by hand and counting replies.
- **Tomas:** remembers that Ines worked the far shutter, and still believes she is gone.
- **Adrian:** the secret claim stays unspoken until Chapter 2.

## Open questions for tuning

- Do players open the first request card unprompted, and can they find its piece on the board? See the [playtest plan](epoch-one-quests.md#iterate-in-two-short-sessions).
- Does the chart (25) or the cable (60) outlast interest? Tune the quota before adding content to epoch two.
- After the skiff scene, do players understand why the light changed? If they say "the wire was repaired", revisit the staging.

## Review commands

```sh
./build/relic-rush --fresh --city 1 --quest-offer chart          # first request offer
./build/relic-rush --fresh --city 3 --quest-have 60 --quest-card cable   # cable ready
./build/relic-rush --fresh --city 3 --dive                        # Play: town dives into the board
```
