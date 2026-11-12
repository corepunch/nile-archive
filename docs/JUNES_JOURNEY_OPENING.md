# June's Journey: opening scene, clues and progression

This analysis combines the bundled iPhone app 4.17.7 / build 120 with Wooga's
current player guides. Bundled data establishes what was authored into this app;
the guides describe the general game. The first scene has not been played for
this analysis, and the full chapter dialogue and progression configuration were
not recovered. [Extraction and source inventory](JUNES_JOURNEY_ANALYSIS.md)

## The opening premise

The English opening captions introduce June Parker. Her sister Clare and
Clare's husband Harry have been shot at their estate. The police believe Harry
shot Clare and then himself, but June doubts that conclusion. She travels to
New York to care for her niece Virginia and investigate. Two bundled versions
of this introduction disagree on whether the deaths were days or two weeks
earlier, and the files do not establish which version is displayed.

In a separate four-line opening dialogue, Mrs. Talbot tells June that Virginia
is inconsolable and directs her to the parlor. This establishes a personal
responsibility and an unresolved murder before the investigation develops.
The relative playback order of the two bundled sequences has not been verified.

Sources are the extracted `story/locale/en-US/jj-funnel-captions-*.json`, the
`ftue_on_rails.intro_subtitle_*` entries in `bundled_texts-*.json`, and
`story/funnel-dialogue-en-US.json` under `reference/junes-journey-analysis/`.

## A hidden-object scene

Wooga describes a scene as a picture with an item list along the bottom. The
player taps the pictured items until the list is empty. Faster finds improve
score and wrong taps cost points. A rechargeable hint highlights an item;
some finds produce a suitcase bonus revealed when the score is calculated.
These are general rules and the extracted tutorial does not establish whether
every rule is active immediately in scene 001-01. [Hidden Object Scene guide](https://wooga.theymes.com/hc/en/junes-journey/articles/what-is-a-hidden-object-scene-439)

The bundled scene 001-01 is the estate exterior, with a mansion, car, luggage
and fountain. Its extracted background is 2048×1170 pixels. The scene includes
75 regular object definitions with authored transforms, references to item,
cover and cast layers, and polygon colliders. The definitions contain five
serialized difficulty values, each assigned to 15 objects. Two additional
clue-prefixed definitions also have colliders. The data supports individual
placed targets and interaction regions; it does not establish the selection
algorithm, target list for a particular run, or the meaning of the difficulty
values during play.

The scene bundle exports 173 sprites, including the background and item, cover
and cast artwork. Those layers and `scene-001-01/objects.json` are in
`reference/junes-journey-analysis/scenes/`. The background is an artwork layer,
not a capture of the fully assembled interactive screen.

## How clues carry the story

The chapter 001 dialogue file has 84 staging rows. It assigns `before` and
`after` blocks to two numbered clues for each of scenes 1–5, plus one numbered
block for scene 6. Each row may specify a speaker, character positions and
moods. Scene 2, clue 1, for example, stages June and Virginia together before
the clue. Its after block places a family-picture clue between them, then
continues with dialogue from both characters. This is authored presentation
around a clue; the localized lines for these chapter blocks are absent.

For scenes 2–5, the staged after blocks name these clue images:

| Scene | Clue 1 | Clue 2 |
| --- | --- | --- |
| 2 | Family picture | Crime photo |
| 3 | Whiskey glasses | Footprint |
| 4 | Broken lock | Carafe |
| 5 | Bloody handkerchief | Window |

The chapter clue bundle contains matching named artwork, along with Mrs Talbot
and a placeholder for scene 1. These names identify the staged objects but do
not reveal what the missing dialogue says or what conclusion June draws from
any clue. Scene 1's staging does not bind its clue numbers to specific artwork.
The chapter data is
`story/chapters/001/chapter-001-dialogue-v2-*.json`; extracted artwork is in
`scenes/clues/`.

## Replay, chapter gates and the island

Wooga describes a general scene as having two clues. The first is found on the
first play, and the second on a play after the player earns the scene's third
Mastery Star. Replaying adds score toward up to five Stars, each harder to earn
than the previous one. The extracted chapter staging is consistent with two
numbered clue blocks for scenes 1–5, but it does not itself establish when
those blocks fire or whether the opening tutorial changes the general rule.
[Hidden Object Scene guide](https://wooga.theymes.com/hc/en/junes-journey/articles/what-is-a-hidden-object-scene-439)
[How to play](https://wooga.theymes.com/hc/en/junes-journey/articles/how-do-i-play-junes-journey-394)

Wooga says that opening the next hidden-object scene requires the previous
scene's two clues and enough Flowers. Decorating Orchid Island earns Flowers;
the bundled loading tips also describe that connection. Thus scene replay and
island decoration both feed access to the next piece of the investigation.
The extracted files do not provide chapter-one Flower thresholds, scores or
precise post-scene screen order. [Hidden Object Scene guide](https://wooga.theymes.com/hc/en/junes-journey/articles/what-is-a-hidden-object-scene-439)

Each chapter has five hidden-object scenes followed by an Adventure Scene.
Wooga says the Adventure Scene requires all chapter clues and a specified
number of Stars. It is an untimed object-use puzzle. In the official chapter-one
walkthrough, a key found under a plant opens a drawer, a note gives a safe
combination, and a painting conceals the safe. Completing the Adventure Scene
makes the next chapter available when the Flower requirement is met. The
walkthrough establishes this puzzle sequence; the extracted sixth dialogue
block does not establish its exact timing relative to each puzzle action.
[Adventure Scene guide and chapter-one walkthrough](https://wooga.theymes.com/hc/en/junes-journey/articles/what-is-an-adventure-scene-483)

The resulting general structure is a sequence of item searches and clue-linked
story beats, with replays building mastery, island Flowers gating access, and
a chapter-ending interactive puzzle. The exact ordering of dialogue, clue
reveal, score tally and reward screens in this opening remains unverified.
