# A light below · first-epoch playtest

**Question for this build.** After the player finds the cable, will they choose to test the lamp? Ask them what prompted that choice and what they learned from the skiff. The first ten expeditions, four purchases and two returning characters give us enough room to try the whole loop.

| When | What the player sees and does | What changes |
| --- | --- | --- |
| Well, after expedition 1 | Mara draws the first bucket. They find a scrap in the rope, and Elena asks for the other pages. **Find chart pages** takes the player to the board. They can choose **Later** and find the same piece on the upper-left rail. Mara has an independent request for supper. | The chart puts a reef between the boats and the warning station. Supper earns a conversation about what Mara actually saw. |
| Hunter's Hut, after 4 | With the chart delivered, Tomas asks the player to uncover his painted trail arrows. If supper was delivered, he can also ask for his father's tools. | The arrows lead to the lower quay. The empty loop in the tool roll plants the pliers for players who took that detour. |
| Sawmill, after 7 | With the trail delivered, Tomas asks for cable coils. Each matched coil fills the counter above the board. A win banks it. The ready card takes the player to the painting of his pliers at the break. | The cable is dead. Mara asks what a sailor could have seen offshore. Tomas has a spare hand shutter and proposes trying it. |
| Cable handed in, even much later | Tomas and the closed shutter appear together. **Lift the shutter** cuts to the skiff facing the red lamp over the reef. Mara rows two strokes while Tomas holds the shutter steady. | The light turns white in clear water. Elena marks that boundary on the chart from the first request. Tapping the Sawmill recalls the finding. |
| Village, after 10 | From the shore, Mara sees three flashes in reply to her two. The player chooses who answers. | The main expedition story continues, including for a player who has deferred every crew request. |

**How the invitation works.** The first eligible card appears automatically after dialogue. It names the giver, shows the portrait and board item, and offers a verb for the next action. A win that fills a request earns a hand-in prompt on the island. Later leaves the marker in place. Introductions and ready prompts are remembered separately. The second request can wait until another island visit. After the Sawmill, the investigation gets the last free piece slot, so leaving supper unfinished cannot strand the cable.

**What informed the design.** Tropicats gives Elsie a specific object to repair, then associates tools gathered on named boards with visible work on the totem. Cradle of Empires puts the requested item on a left-edge marker and routes the player directly to its level. June’s Journey introduces new players to one Island Errand at a time and explicitly announces completion. We use the same identifiable item across the request, board and results, introduce one ask at a time, and give the player a character with a reason to ask. [Tropicats opening](../../../docs/tropicats-reference/story/chapter-01.md) · [Awem’s quest routing](https://support.awem.com/hc/en-gb/articles/4408737335442-How-can-I-reach-the-next-XP-level-faster) · [Wooga’s Island Errands](https://wooga.theymes.com/hc/en/junes-journey/articles/what-are-island-errands-398)

## Iterate in two short sessions

1. **Fresh arrival.** Give a new player the game through the Well. Stay silent after the scene. Watch their first tap, then ask who wanted what. On the board, ask them to point to the piece and predict what happens on a win. If they need to hunt through the circles, change the invitation before tuning a quota.
2. **The decision at the break.** Start with the cable ready. Let the player decide whether to hand it in, lift the shutter or leave. After the skiff scene, ask why the light changed. If they answer “the wire was repaired,” revisit the staging. Have a second player take Later, play an expedition, then return to Tomas unaided.
3. **Tune only the first epoch.** Watch how many won boards each collection took and whether the player deliberately favored a quest match. If the chart or cable outlasts interest, tune that quota before adding content to epoch two. These are human-playtest questions. Automated runs verify reachability and persistence.

For a quick interactive review, run the regular game with a fresh preview profile. The second entry skips collecting the coils and leaves the actual hand-in and unlock to the player.

```sh
./build/relic-rush --fresh --city 1 --quest-offer chart
./build/relic-rush --fresh --city 3 --quest-have 60 --quest-card cable
```

[Phone captures and previous cards](screenshots/review/crew-requests/README.md)
