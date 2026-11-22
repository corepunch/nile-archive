# Writing game stories

A game's script lives in `games/<game>/docs/story.md`; each game's tools compile it into its runtime story table. The story is short dialogue between levels, read on a phone, often a day apart. Most players will skim it. Write so that skimming still works and reading closely is a pleasure.

These rules replace an earlier, much longer guide. That guide rewarded lines for passing checks (a listener, an intention, a concrete detail), and produced lines that passed every check and that no person would say. The test now is simpler: would a player who just watched the screen believe this line?

## The rules

1. **Read it as the player.** Every scene follows something the player just did: cleared a board, placed a building. A line must be true to that moment. If the player built the well a second ago, nobody remembers drinking from it. If the building is new, people react to something new.
2. **Would a person say this, here, out loud?** Read it aloud. If it sounds like a riddle, a craft manual or a line written to tick a box, cut it. Don't invent an errand ("Lend me your bucket", "Hold this while I…") just so the line has someone to talk to.
3. **Plain, ordinary details.** People drink water; they don't taste buckets. Prefer the obvious word. A detail must be one a real person would mention.
4. **Say something the screen doesn't.** What the new building means to someone, what they want next, a joke, a worry. Don't caption what the player can see.
5. **Talk to the player.** The player is the builder. Characters can speak to "you" (thank you, ask you, tease you), as well as to each other. That is usually more natural than two people describing their work to each other.
6. **Check how it could be misread.** Sleeping arrangements, beds, undressing, who stays with whom: avoid them unless the scene is about that. State a relationship ("my brother", "the captain") before a line depends on it.
7. **Short.** Two to four lines per scene, each under about 100 characters. Many levels need no scene at all. Silence is better than filler.
8. **Few people, each recognisable.** Three or four speakers carry a game. Each has a different way of talking, so you can tell who speaks with the name plate covered.
9. **The story has somewhere to go.** One goal the whole game moves towards, said early by someone who wants it, and reached at the end. Each chapter moves it on.
10. **No mechanics in dialogue.** Moves, tiles and boosters go in the level's `lesson` line.
11. **Match the game's feeling.** Christmas Market is joyful: no tragedy, guilt or dark secrets. Relic Rush is a warm adventure about founding a town.

## Speech only, no narration

Every line sits in a speech bubble under a portrait. There is no narrator, so every line is something that character says. That doesn't mean every line must give someone an order. A character can simply react: "Look at that. A real roof."

## Before calling it done

- Read the whole script aloud, start to finish, in one sitting. Fix every line where you wince.
- Ask a separate reader, a person if possible, to read it cold and mark any line that is confusing, unnatural or open to a wrong reading.
- `python3 tools/story_lines.py <game>` lists lines that may be captions. It's a hint, not a test.
- Look at the longest lines in the game on a phone-sized capture.

## Scenario overview

`python3 tools/scenario_overview.py --capture` writes `build/scenarios/index.html`, one page for Relic Rush, Christmas Market and Nile Archive. It shows each game's cast with portraits, then every level or search in order, with its board capture or scene painting, the building it funds, any story picture, and each story beat as dialogue. Without `--capture` the page reuses the boards already in `build/shots/frames`.

`python3 tools/scenario_overview.py --epoch 1 --capture` writes `build/scenarios/epoch-1.html` instead: one [epoch](CHAPTER_PROGRESSION.md) of Relic Rush and Christmas Market, with its four purchases, the town once the fourth is placed, and every scene in it.
