# Relic Rush · Finds plan (draft)

**Status:** a proposal for review. Nothing here is in the game yet, and it has no dialogue on purpose. The lines get written only once the thread below holds up.

## The split

- **Levels carry the story.** They play in the same order for everyone, so the story can't arrive out of order. A few levels are *find levels*: the board's plaques cover a buried object, the player uncovers it by playing, and the people react to what they see.
- **Buildings carry the montage.** A building changes what turns up on the boards (water buckets, timber, tools, and later rings, scarabs and harps). Placing one plays no scene and nobody announces it. The Build button already shows the next purchase and its price.
- **Ordinary levels are silent.** The silence between finds is what makes the finds land.

## The mystery

**The question, asked on level 1:** somebody lived here. Who were they, and where did they go?

**The answer, which the player can piece together before it's said:** the people of Callira didn't vanish. Over generations the land rose and the reef closed their harbour. Their boats couldn't get in or out, so they carried what they could up into the hills and became farmers. The hill people who trade with the settlers from level 21 are their grandchildren's grandchildren. They have forgotten the harbour, but they kept some of its things.

Why this answer:

- **It's warm.** Nobody died, nobody was a villain, nobody hid a secret. It suits the tone rule for Relic Rush (a warm adventure about founding a town).
- **It's fair.** The answer is planted on level 20, when smoke rises over the hills, 70 levels before anyone says it. A player can guess it.
- **It has a turn.** The strangers in the hills turn out to be the people we were looking for.
- **It's physical.** Every clue is something you can paint and bury on a board: a cup, steps, a mooring ring, tide marks, a slate chart, a wall painting.
- **It reuses what's already there.** The cup, the harbour steps, the tide marks, the Callira stones, the wreck, the hill people, Tavi's reef and the museum all stay; they finally point at one answer. The current script leaves "why they left" open for good, and an unanswered mystery doesn't hook anyone.

**Each find answers one thing and raises the next question.** A wrong guess along the way (they drowned in a storm) gives the players something to correct.

## The finds

Bosses (every tenth level) carry the big finds as a reward for the hardest board. Board names change to suit the find.

| # | Level (current board) | Buried find | What it establishes | New question | Who reacts and how |
| --- | --- | --- | --- | --- | --- |
| 1 | 1 The Landing (tutorial) | A clay cup with a wave pattern | Somebody lived here | Who? | Sela finds it and keeps it, which pays off at the fountain (96) |
| 2 | 10 Tide Chamber (boss) | A carved stone of a boat under sail | They were sailors | So this was a harbour? | Tavi reads it as a sailor would |
| 3 | 16 The Overlook | Worn harbour steps leading down to dry sand | Boats tied up here, but the steps end in sand, not water | Why is there no sea at the bottom? | Oren asks where they went. Tavi notices the sand |
| — | 20 Heart of the Temple (boss) | *No find: an event.* Smoke over the hills | We are not alone | Who are they? | The plant for the answer. The market (21) follows |
| 4 | 30 Sun Altar (boss) | A hill-people pot with the same wave pattern as the cup | The hill people and Callira share something | Did they trade with Callira? | Sela matches the pattern. The hill people only know it as "how pots are made" |
| 5 | 36 Moss Well | Tide marks cut in the cliff, far above today's high water | The sea used to come up much higher | The sea left them? | Tavi works it out. It explains the dry steps (3) |
| 6 | 40 Serpent Throne (boss) | Bronze mooring rings set in rock, high and dry | Big ships used to moor where it is now land | How did they get out? | The wrong guess: Oren thinks a storm took them |
| 7 | 58 Wreck of the Gull | An old Callira boat hauled up the beach, rolled on logs, not wrecked | They pulled their own boats out of the water on purpose | Why give up the sea? | Corrects the storm guess. Tavi: someone did this carefully |
| 8 | 60 Disc of Noon (boss) | A stone carved with a word, the same as on other stones | The town's name: Callira | — | They were proud of it. The archive (61) keeps the stones |
| 9 | 70 Maw of the Jaguar (boss) | A chart scratched on slate showing a channel through the reef | Callira had a way in; it's closed now | Can it be opened again? | Tavi compares it with her own chart: the reef has grown over their channel |
| 10 | 80 Sunken Vault (boss) | A wall painting: people carrying pots and boats uphill | They walked up into the hills | Where in the hills? | Oren connects it with the smoke (20) |
| 11 | 90 The Light Below (boss) | A hill grandmother's heirloom cup, the twin of Sela's | **The answer:** the hill people are Callira's descendants | — | Brought down by the hill people, not dug up. Sela puts the two cups together |
| 12 | 100 The Sunken Sanctum (boss) | Callira's founding stone: people coming ashore from boats | Callira began the way the settlers' town did | — | The circle closes. The town takes the old name with the hill people's blessing |

About one find every eight levels, with the gap from 40 to 58 filled by ordinary play and the hill-people trades.

## How each find level works

The engine already has buried finds (`reveal`, [docs/MATCH3_ELEMENTS.md](../../../docs/MATCH3_ELEMENTS.md)); Christmas Market uses them and an earlier Relic Rush campaign did too:

- `reveal = {picture=…, icon=…, object=true, bark=…}` draws the find across the board's plaques. Each cleared plaque shows its part of the object.
- `bark` is one line spoken when half the plaques are clear. It's the tease ("there's something carved under here"), and it's the only line that plays during the board.
- On the first clear the pieces fade, the whole object holds on screen, and then the scene plays. Replays show the picture without the hold.
- The plaques form the object's silhouette: a cup shape for the cup, a stair for the steps, a ring for the mooring ring. The board must still pass the plaque coverage and move budgets in [board-progression.md](board-progression.md). Check with `python3 tools/balance_plaques.py relic-rush`.
- Review a find with `--level N --reveal 1`.

## What it costs

- **Art:** 11 buried-object pictures (12 finds minus the event at 20), each painted to fit its board's plaques, plus 12 plaque goal icons. Catalogue them in [asset-catalogue.md](asset-catalogue.md).
- **Boards:** 11 find levels redrawn so the plaques trace the object. Their difficulty tier stays the same.
- **Script:** 12 short reactions and 11 barks. Placement scenes, request scenes and the "let's build X" lines go.

## Still open

- **The families thread.** The mystery doesn't need the ship going back for the families. If it stays, it fits: the reef that closed Callira's harbour is the reef Tavi has to get across. If it goes, the finale is the hill people coming down to the harbour.
- **The museum (87).** It could display the finds so far. That would be the only building that shows story.
- **Town talk.** Tapping a building could repeat the last find's question, so a returning player remembers where the story is.
