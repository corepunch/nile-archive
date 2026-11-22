# June's Journey: how the story sits beside the island

Collected 2026-11-22 from the local app bundle (`reference/junesjourney.app`, git-ignored) and three public pages. It complements [the opening analysis](../JUNES_JOURNEY_OPENING.md) and [the bundle inventory](../JUNES_JOURNEY_ANALYSIS.md). Game text is paraphrased.

## What the bundle holds

Only chapter 1 ships with the app; later chapters are downloaded. The bundle has:

- **The prologue captions** (`Data/Raw/iOS/locale/en-US/jj-funnel-captions-*.json`): five first-person sentences from June. Her sister and brother-in-law were shot two weeks ago, the police called it a murder-suicide, she doubts it, she is sailing to New York to look after her niece Virginia, and she means to find the truth. The question is set in the first five lines, before any play.
- **The first scene's four lines** (`jj-funnel-001`): the housekeeper, Mrs. Talbot, greets June and sends her to the grieving niece.
- **Chapter 1 staging** (`chapters/001/chapter-001-dialogue-v2-*.json`): 84 rows with speaker, positions and moods. The text for these rows is not in the bundle.
- **The loop, as the game explains it** (a tip string in `Data/level288`): find clues in scenes to earn currency; decorate the island to earn flowers; flowers raise your level and unlock new scenes.
- **No island dialogue in the bundle.** Searching every `level*` and `.assets` file for English sentences turned up shop, event and tutorial text only. The game does have character-voiced island tutorials, downloaded with the chapters: by the user's recollection, Mrs. Talbot says she wanted to plant some flowers, and that walks the player through planting. Neither that line nor any chapter 1 dialogue is in the app. A full search on 2026-11-22 covered every one of the 807 Unity files (including the 188 text and behaviour objects inside the compressed `.hd` bundles, read with UnityPy), all locale JSON in 18 languages, and raw strings in every file: no flower, plant or island tutorial line, and no text for the 84 chapter 1 rows. The game is not installed on this Mac, so there is no download cache either. The code does name the island tutorial's text keys: `tutorial.funnel_island1` and `tutorial.funnel_island2`, `ftue_on_rails.tutorial.building_tutorial`, two timer steps, and twelve `ftue_on_rails.scene_browser.character_comment_N` lines. Its classes include a seven-step decorations tutorial (`BeautificationsTutorialStep0`–`6`). The bundled manifests list only four locale files per language (bundled texts, the prologue captions, the first four lines and peer names), so these keys' text comes from a downloaded table. The chapter 1 staging is tabulated, without text, in the git-ignored `reference/junes-journey-analysis/story/chapter-001-staging.md`.

## Chapter 1 in numbers

| | |
| --- | --- |
| Hidden-object scenes | 5, plus a closing adventure scene (6) |
| Clues per scene | 2 |
| Dialogue blocks | one **before** and one **after** each clue |
| Lines per block | 2–5 (mean 3.8) |
| Lines per scene | 13–17 for scenes 1–5 |
| Speakers | June 43, Virginia 27, caption 8, Mrs. Talbot 6 |
| Cast | three people, and after scene 1 only two: June and Virginia |
| Moods | sad 49, concerned 28, thinking 25, surprised 12, shocked 10, angry 10, crying 5 |

Every scene play advances the story. The **before** block says what June is looking for and why; the **after** block says what the found object means. Clue art in the bundle is the object itself: a family picture, a crime photo, whiskey glasses, a footprint, a broken lock, a carafe, a bloody handkerchief, a window.

## The island carries no story

It carries guidance in a character's voice instead. Mrs. Talbot's flowers line is a tutorial shaped as a small personal wish: she wanted to plant some flowers. It is not a need, it isn't story, and nothing follows from it but the planting.

- Wooga's own help page describes Orchid Island (June's family estate) as placing, upgrading and restoring buildings and decorations, which earn flowers that unlock chapters and scenes. It mentions no dialogue. [Wooga: Orchid Island](https://wooga.theymes.com/hc/en/junes-journey/articles/what-do-i-do-on-orchid-island-413)
- A 2020 Game Developer breakdown calls the island and the scenes a dependency loop: scene rewards build the island, and island currency unlocks scenes. Its one criticism is that the island has no narration. [Game Developer breakdown](https://gamedeveloper.com/design/june-s-journey-breakdown)
- Sources disagree on what gates a chapter (stars in 2020, flowers now). Either way the island is the gate, not the storyteller.

## How the chapters move

A fan list of 355 chapter titles, each with its closing adventure scene, shows the pattern. [Mobi.gg chapter list](https://mobi.gg/en/tips/how-many-chapters-junes-journey/) The first chapters:

| # | Chapter | Closing scene |
| --- | --- | --- |
| 1 | Arrival in New York | Gatehouse |
| 2 | Speak Easy | Belmont Park |
| 3 | Eddie Daggett | Hidden Distillery |
| 4 | Clare's Secret | Roosevelt Field |
| 5 | Havana | Juliana's Terrace |
| 6 | Finding Virginia | Village Harbor |
| 7 | June and Virginia | Ferris Wheel |
| 8 | A Trip to Paris | River Seine |
| 9 | Death on the Seine | Boarding House |
| 10 | To Catch a Thief | Bell Tower |

- **Chapter titles are events or people, never chores:** a secret, a person, a death, a trip.
- **Each chapter is a place:** New York, Havana, Paris, Cortona. The scenes are rooms in that place.
- **The cast stays small and recurs:** June, Virginia, Mrs. Talbot (whose son becomes a case in chapters 13–14), and later Jack. People come back, so the player knows them.
- **Later, cases change, but the family stays.** The story runs as a sequence of mysteries around one family. Late chapter titles include a wedding (100), a homecoming (210) and a new baby (261).

## What it means for Relic Rush

| June's Journey | Relic Rush equivalent |
| --- | --- |
| Hidden-object scene | Match-3 level |
| Clue (the object found) | A find buried under the board's plaques (`reveal`) |
| Before / after blocks | A line before the board (what we're digging for) and a reaction after (what it means) |
| Adventure scene closing a chapter | The boss level every tenth board |
| Orchid Island decorating | The town: purchases and placement, with no dialogue |
| Flowers gating scenes | Building income feeding what appears on the boards |

Two things differ from [the finds plan](../../games/relic-rush/docs/finds-plan.md):

1. **Density.** June's Journey tells story on every scene, with about 15 lines per scene. The finds plan has 12 finds across 100 levels. Matching June's Journey would mean a small find, or at least a before/after pair, on most levels, with the big finds on the bosses.
2. **The before block.** It's the "I need something" line the town couldn't carry: it asks for a clue, not a building. "What's under the old steps?" before the board is natural in a way "let's build a cabin" never was.
