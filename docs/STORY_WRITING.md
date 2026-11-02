# Writing game stories

How to write the story of a city or match-3 game in this repository. A game's script lives in `games/<game>/docs/story.md`. [Relic Rush](../games/relic-rush/docs/story.md) and [Christmas Market](../games/christmas-market/docs/story.md) are worked examples.

The craft rules come from Infocom's practice, as collected in the [zilscript](https://github.com/corepunch/zilscript) writing guide (`docs/WRITING_ADVENTURES.md`, `skills/source_design_lessons.md`, `PROSE.md`). The pacing comes from [June's Journey and Tropicats](../reports/Прогрессия%20June%20Journey%20и%20Tropicats.md). Those games have parsers and transcripts; ours has short dialogue between levels, so the rules below are the part that survives the move.

## Order of work

Do these in order, and keep each one in the script document.

1. **One sentence of play fantasy.** What is the player doing and why does it feel good? "A text adventure" or "a match-3 with a story" is not an answer. "I am relighting a town that gave up on Christmas, and someone is secretly helping me" is.
2. **What is broken in this world.** List what is wrong, before any plot. Blockers, buildings and clues should come from this list, so that they feel as if they were always true. Ice in the tropics is a clue because the world explains it; ice as a difficulty step is only a mechanic.
3. **What really happened.** Write the full truth in time order, including what the player never sees. Clues come from this, not the other way round.
4. **The question.** One question the whole game answers, asked by a character in the first few levels. Each episode should move it forward and end by raising a bigger one.
5. **Working materials** (below).
6. **The script**, line by line.
7. **Checks** (below), then the implementation notes.

## Working materials

The world is bigger than working memory, so keep these sheets in the script document and reconcile the lines against them. Do not write 180 lines in one pass and hope.

| Sheet | Holds | Catches |
| --- | --- | --- |
| **Truth timeline** | What happened, in order | Contradictions, and motives that do not add up |
| **Knowledge ledger** | What the player and each character know, level by level | A character acting on what they cannot know yet, a reveal that lands twice |
| **Plant and payoff** | Each planted thing, where it pays off | Payoffs with no plant, plants nobody collects |
| **Clue chain** | Which clue leads to which conclusion | Conclusions that need a guess |
| **Cast arcs** | Start, end, voice, and what each character does | A character who only talks |
| **Beat and wonder table** | Level, wonder, speakers, line count | Budget overruns, speakers absent from the story at that moment |
| **Changelog** | Dated list of what changed and what is still owed | Lost decisions between sessions |

## Fair mysteries

- **The answer must already be in the world.** A player should think "of course", never "how could I have known". Every reveal needs at least one clue, planted well before it, and the best ones need two facts from different places, which the player connects. That moment is the point of the game.
- **Put the clue and its meaning in different beats.** Say what a glance takes in, and let the conclusion arrive later. "A chimney, standing alone" is a clue. "A fire destroyed this row" in the same line is a summary.
- **Voice the player's wrong theory.** Infocom wrote responses for the plausible wrong answers to a puzzle. Our version: a main character states the theory the player is likely to hold, in full, and the evidence breaks it. Do this about once per episode, and have the character admit it. It rewards a player who was ahead and redirects one who was not.
- **A small cast cannot hide who.** With three or four speakers, the suspect is obvious by the middle of an episode. Make the surprise why, or what it cost, and keep the character's motive unguessable even when the name is not.
- **One tell is enough.** A joke such as "I've never liked candles" can give away a reveal thirteen levels early. Give a clue a plain everyday excuse, so that it only looks like a clue afterwards.
- **Keep some mystery alive.** Do not answer everything. End each episode with a question the player could not have asked before it.
- **Twists from the Infocom list:** the reversal (the goal changes), the revelation (one fact rearranges everything before it), the callback (an early joke turns out to matter). Each must survive a re-read.

## Characters

- **Behaviour, not just dialogue.** Memorable characters change the state of the game: they leave, steal, hide, arrive, give, refuse. Each main character must do at least one thing that changes the plot, and go through at least three visible states over the game (for example suspicious, exposed, trusted).
- **Each voice has a job.** A reader should be able to name the speaker with the name plate covered.
- **Objects with two roles.** Every important object has at least two of: practical use, clue, joke, worldbuilding, risk, reward, memory marker. A chisel that is a clue and a tool, or a joke about peaches that becomes evidence, will be remembered. A generic key will not.
- **What is on the portrait counts.** The player stares at the bust for the whole game. If a character is holding something, it should matter.

## Writing lines

- **The screen shows only the story.** Dialogue never names moves, amulets, stars or tiles. Mechanics go in the level `lesson`, a separate slot. The simulation stays underneath.
- **Text and picture divide the work.** Over an illustrated panel, do not describe what is drawn: say what it means or what happens next. Busts over a blurred island have no scene behind them, so there a line needs one strong concrete anchor: "Twelve bunks. Plates still on the table."
- **Short and concrete.** Aim for under 100 characters per line, and one idea per line. Name a thing rather than a feeling: not "she looked sad", but a character changing the subject.
- **One beat, one change.** Each beat leaves something different from how it found it: a new fact, a changed relationship or a new problem. If two beats could swap without anyone noticing, one is redundant.
- **Recurring words become memory.** Repeat a few anchors in the same words (a place, an object, a catchphrase), so the player can retell the story in them. Keep names stable.
- **Humour comes from people and from failure.** Keep it dry, and mix it with real stakes. Comedy lands better next to danger than next to more comedy.

## Structure

Starting template for a three-episode game, with 10 levels and 50–70 lines per episode. Tune it per game.

| Position | Role | Lines |
| --- | --- | --- |
| Before level 1 | Opening, panel | 7–8 |
| 1–2 | Setup | 3–4 each |
| 3–6 | Clues | 3–5 each |
| 7 | Wrong theory collapses | 4–6 |
| 8 | Pressure rises, easier level | 3–5 |
| 9 | A building gives the last clue | 4–6 |
| Before 10 | One short reason this level matters | 3 |
| 10 | Turn and hook, panel | 10–14 |

Beat order: result → island → place the wonder → beat → next goal. Wonders are split across episodes, and mechanic `lesson` lines stay separate.

- **The opening is playable at once.** One landmark, one object, one thing that is blocked, and a reward within the first minute. Open on something interesting, never on backstory or "welcome to".
- **Environmental storytelling first.** Prefer a letter, a burn mark or a bricked-up door to a character explaining. Put history in artifacts, and let characters argue about what they mean.
- **The world answers back.** Things change after a reveal. A building's tap bubble can change once the player knows what it means, which is cheap and rewards curiosity. Failure screens and small lines keep the voice too.
- **The ending must:** pay off at least two specific discoveries, include a real decision by a main character, and show what comes next.
- **Walk straight into the sequel.** Zork I's last room is the first room of Zork II, and players remember one continuous journey although nothing carries over. Open each episode at the place and moment the last one stopped. The "To be continued" screen should feel like the next step in that place, not an advertisement.

## Checks

Do these before calling a script done.

- **Count.** Lines per beat and episode against the budget, longest line, and no unknown speakers. A small script over the document will do.
- **Read it cold.** The author of a mystery cannot judge it, as Lebling found when he got his own puzzle wrong. Give a separate agent or person the script one episode at a time, with no notes, and ask: what do you think happened, who is lying, what will happen next? Fix what they could not reach, and what they guessed too early.
- **Cross the story with the systems.** Each piece is usually right on its own, and the bugs live where two meet:
  - **Replays and retries** must not repeat a beat.
  - **Queued beats:** a region opening and a wonder in the same moment must not collide or spoil each other.
  - **Skip:** a player who skips a line must still have what they need, so restate key facts once, later.
  - **Saves from older versions** have beats they will never see, and need migrating or a recap.
  - **Waiting:** a story deadline must not be contradicted by lives, gates or replays. Count time in story events ("two days out", moved on by beats) rather than real time.
  - **Placement order:** a beat tied to a building must fit any place the player can put it, so never say where it stands.
  - **Unavailable characters:** a character who has left the story cannot speak at a wonder.
- **Check in the game** on the primary and alternate phone sizes: longest lines, longest scene, and every new speaker.

## What does not apply

Parsers, verb coverage, mapping, mazes, inventory and unwinnable states are about a form we do not use. Our equivalents are in the checks above. Game-wide hints already exist as the idle hint on the board, so the story needs none.
