# Story: three episodes to "To be continued"

**Status: script for review, not implemented.** The game still plays Noelle's short lines. The structure matches [Relic Rush](../../relic-rush/docs/story.md): 30 levels, wonders split 4+3+3, one beat per level, a hook at each episode's end. It was written by the [story guide](../../../docs/STORY_WRITING.md). The plot, cast and setting are original.

**Fantasy of play:** I am relighting a town that gave up on Christmas, and someone is secretly helping me.

**Tone:** warm, funny, for all ages. Nobody is hurt, nobody is a villain, and every secret was kept out of love. It is the opposite of Relic Rush, where the threat is real and people lie for gain.

## What is broken in Bellmere

Everything the player fights on the board comes from this list.

- **Snow** has lain on the square for 25 years, since nobody clears it. This is the powder snow blocker.
- **Tinsel** from the last market was never taken down and has knotted itself around everything. This is the tangled tinsel blocker.
- **The wish fountain froze** with the town's ribbons locked inside. This is the ice blocker, first seen in level 6.
- **Soot** lies under the snow at one end of the square, and nobody will say why.
- **The town** stays indoors and changes the subject.

## The question

**Why did Bellmere stop Christmas, and who is still answering the letters?** Noelle asks the first half in level 3, and the hook of level 10 raises the second. Episode 2 answers the first half and turns it on her. Episode 3 settles it, then the last letter asks something nobody expected.

## What really happened

1. **25 years ago, Christmas Eve, the last market.** Henrik Strand, the toymaker, has carved a wooden horse for six-year-old Noelle. She slips into his shop after dark with a candle, to see it. The candle falls into the shavings. Henrik gets her out and tells her to run. The fire takes the lane, the old carousel and the star from the tree. Nobody is hurt.
2. **That night.** Noelle writes to Santa: it was me, please tell him sorry. Her grandmother, Rosa, finds the letter and never posts it. Henrik stands in the square and says he left a candle by the shavings. Only Rosa, Agnes and Henrik know. Noelle stops speaking, so Rosa takes her to the city. In time she forgets.
3. **The 25 years since.** Henrik lives up the mountain, one light in the dark, with the star he carried out of the fire. Nobody holds a market again. He answers every child's letter to Santa in tidy black ink. Rosa carries them up until her knees give out, then he comes down at night himself.
4. **Something else, nobody knows.** A few replies over the years are in silver ink, and know things no one could. Agnes assumes they are Henrik's, and he assumes they are Rosa's. Rosa never said. They are neither's.
5. **Five years ago, Rosa dies**, leaving Noelle the market and a parcel: the wooden horse, which six-year-old Noelle wrapped herself to give back, before she stopped speaking. Rosa kept it and added a tag: "For the one who answers." Her instructions: light the tree by Christmas Eve. It takes Noelle time to come.
6. **Now.** Noelle arrives. Henrik sees lights in the square for the first time in 25 years, and starts leaving parcels at night.

## Cast

Noelle exists. The other three are **new busts** in the same painted style, generated from a new prompt in `art/character-and-icon-prompts.json`.

| Character | Role | Arc | Voice | What she or he does |
| --- | --- | --- | --- | --- |
| **Noelle** | Rosa's granddaughter, market keeper | Cheerful outsider → finds she caused it → tells the town herself | Warm, quick, jokes when nervous | Rebuilds, accuses wrongly twice, confesses, lights the candles |
| **Agnes Holt** | Baker, Rosa's oldest friend. *Flour on her apron, sixty-odd, arms crossed* | Obstructive → exposed as a protector → lights her oven again | Gruff, deflects with food and weather. "Drink your cocoa" | Blocks questions, reopens the bakery, finally tells the truth |
| **Pip Larkin** | Ten years old, the town's post runner. *Big satchel, one bell on a string* | Bored kid → keeper of the mail → carries the news | Blunt, asks what nobody else will | Sets the bell trap, finds the box, finds the sled, spots the hoofprints |
| **Henrik Strand** | The toymaker, seventy-odd. *White whiskers, leather apron, a carving knife in the pocket* | A rumour → a helper → a man who comes home | Tidy, dry, always correcting someone's workmanship | Leaves parcels, comes down through the storm with the star |

Henrik does not speak until level 28. Until then he is only his handwriting, and the speaker budget accounts for that.

## Working sheets

**The parcel.** Noelle's only portrait already holds a red gift in both mittens, so the player sees it in every line of the game without a word about it. That is why it became the central object. It is a mystery, a promise and the payoff.

| Planted | Paid off |
| --- | --- |
| The red parcel, "For the one who answers" (opening) | Noelle hands it to Henrik: her horse (level 29) |
| "Keep going" on the gift tags (level 1) | Henrik says it in person (level 29) |
| "Candles in a timber market? Not while I'm in charge." (level 7), hiding as common sense | Cold hands at the candle shop (level 19), the letter (level 20). She lights the candles herself (level 27) |
| Soot under the snow (level 3) | The fire (level 5), and whose it was (level 20) |
| Chimney and half a horse (levels 5, 8) | The town kept the pieces (level 23) |
| The one light on the mountain (level 9) | It goes out (level 25). Town's lights answer it (level 27) |
| Child's knot on the parcel (level 16) | Noelle tied it herself, age six (level 29) |
| Silver ink, the custard reply (levels 10, 12) | "I've only ever had black" (level 30) |
| Bell on a string (level 4) | With her handwriting, clears Agnes (level 7) |

**Clue chain for the big reveal.** Noelle left suddenly at six (6) + she keeps candles out (7) + a horse ordered for her that last week (14) + a child's knot (16) + Gran did not do it (17) + candle smell brings back a memory (19) → her letter (20). A sharp player gets there around level 16 to 19, which is the aim.

**Wrong theories, all voiced and broken.** Agnes sends the parcels (7, broken by the bell). Rosa started the fire (17, broken by three hundred witnesses).

**Who knows what.** Agnes and Henrik know the whole truth throughout. Pip knows nothing and asks everything, so the player learns with him. Noelle learns at 20. The town learns at 21.

**Knock-on check.** The story counts time in events, down to Christmas Eve, so neither lives nor replays contradict it. Beats never say where a building stands, because the player chooses. Henrik never speaks at a wonder before level 29.

## How beats play

Order: result → market → place the wonder → beat → next goal. A level without a wonder plays its beat on returning to the market. Beats play once per save, on the first clear. Lines are speech unless marked *(thought)* or *(shout)*. Mechanic lessons stay separate.

## Episode 1: The Dark Square

**Before level 1 · opening** · *Panel: Noelle under a snowed-in arch at dusk, holding the red parcel. A dark square, and one lit window.*

- **Noelle (thought):** Snow on the rooftops, and not one light in the trees. Gran said this was the finest market in the north.
- **Agnes:** Square's shut, love. Has been for twenty-five years. If you're after a bun, so's the bakery.
- **Noelle:** I'm Rosa's granddaughter. She left me the market. And this parcel: "For the one who answers."
- **Agnes:** Answers what?
- **Noelle:** No idea. There was one more thing. "Light the tree by Christmas Eve."
- **Agnes:** Rosa always did give her orders from a distance.
- **Pip (shout):** Are you opening the market? Can I help? I'm Pip! I do the post! There's not much post!
- **Noelle:** Then we start with one little wish, Pip. And a shovel.

**Level 1 · Welcome Lights · builds Welcome arch**

- **Pip:** The arch is up! That's the first new thing in this square since before I was born.
- **Agnes:** It's crooked.
- **Noelle:** It's perfectly straight.
- **Pip:** Hey. Who left a present on it? There's a tag. "Keep going."

**Level 2 · Lumber Lane**

- **Noelle:** Timber, fresh-cut and stacked under a tarp. Who's felling trees for a closed market?
- **Pip:** Nobody goes up that road. It only goes to the mountain.
- **Noelle:** Then who made those sled tracks?
- **Agnes:** Deer.
- **Pip:** Deer with a sled?

**Level 3 · Gingerbread Swirl**

- **Noelle:** Look at these cobbles under the drift. They're black, all down that end.
- **Pip:** Everything's black down that end. Nobody'll say why.
- **Noelle:** Agnes? Why did Bellmere stop having Christmas?
- **Agnes:** Ask me something else, love. Ask me about buns.

**Level 4 · Cocoa Corner · builds Lumber workshop**

- **Pip:** Second parcel! Same tag. "Keep going." Very tidy writing.
- **Noelle:** Brass hinges. The exact size we ran out of yesterday.
- **Agnes:** Someone's been watching your carpentry and despairing.
- **Noelle:** Someone who wants us to finish, and doesn't want to be seen helping.
- **Pip:** I'll catch him. I've got a bell on a string.

**Level 5 · Toymaker Lane**

- **Noelle:** A whole row of shops, and one chimney still standing.
- **Pip:** Old Henrik's. People say "Henrik's fire" and then they talk about the weather.
- **Noelle:** Who's Henrik?
- **Agnes:** A careless man who left a candle by the shavings. Mind the snow, it's slippery.

**Level 6 · Ribbon Wishes**

- **Noelle:** The fountain's frozen solid, and there are ribbons in the ice. Hundreds of them.
- **Pip:** Wish ribbons! You tied one on and told it your wish. I've only heard about it.
- **Noelle:** I tied one. I remember the cold on my hands. I must have been small.
- **Agnes:** Six. You'd have been six when Rosa took you off to the city.
- **Noelle:** In the middle of winter? Why so suddenly?
- **Agnes:** Rosa had work in the city. Drink your cocoa.

**Level 7 · Candlelight Circle · builds Gingerbread bakery**

- **Pip:** Can we put candles in all the windows? Like in the old pictures?
- **Noelle:** Lanterns, Pip. Candles in a timber market? Not while I'm in charge.
- **Noelle:** Now then, Agnes. There was flour on that last gift tag. It's you, isn't it?
- **Agnes:** There's flour on everything, girl. There's flour on the cat.
- **Pip:** My bell rang at midnight, and she was here arguing with the oven. You could hear it from the lane.
- **Noelle:** And Agnes writes like a hen fell in the ink. So who's out there, and why won't he knock?

**Level 8 · Carousel Stars** *(easier level)*

- **Noelle:** A carousel horse. Half of one. Burned clean through the saddle.
- **Agnes:** That fire took the lane, the carousel and the tree's star. Then Henrik took himself up the mountain.
- **Noelle:** And nobody ever asked him back?
- **Agnes:** It's going to be a long winter, love. Eat something.

**Level 9 · Skating Evening · builds Hot cocoa kiosk**

- **Pip:** Cocoa! First customer's me. Second customer's also me.
- **Noelle:** Look up the hill, Pip. There's a light on the mountain. Just the one.
- **Pip:** That's always been there. I thought it was a star that got stuck.
- **Agnes:** Drink your cocoa.
- **Noelle:** You keep saying that.

**Before level 10**

- **Pip:** The snow's deepest round the old tree. I bet there's stuff under it.
- **Noelle:** Gran said to finish at the tree. One last dig.
- **Agnes:** Go gently. That tree's had twenty-five years' rest.

**Level 10 · Under the Old Tree · hook** · *Panel: a bare tree, a hollow dug at its foot, an iron mailbox bursting with paper.*

- **Pip (shout):** The old mailbox! It's jammed full!
- **Noelle:** Letters to Santa. Every child in Bellmere. And every one has been opened.
- **Noelle:** They've got replies pinned to them. "Dear Hannah. The kitten will come home when it's hungry."
- **Noelle:** Oh! This one's mine. I was five. "Dear Noelle. No, reindeer don't like custard. I've asked."
- **Pip:** Twenty-five years of letters! Who's been answering them?
- **Noelle:** Same tidy writing as the gift tags. All of them.
- **Noelle:** But Gran's been gone five years. It can't be her.
- **Pip:** Wait, that's mine on top! I dropped it down the snow hole last week, for a laugh. I asked for a shovel.
- **Noelle:** "Dear Pip. Look behind the arch." Pip, this is dated yesterday.
- **Agnes (thought):** Oh, Henrik. You stubborn old fool.
- **Noelle:** "For the one who answers." Agnes, I think this parcel has an address.

## Episode 2: The Last Market

**Before level 11 · opening** · *Panel: the three of them on the mailbox's snowbank, letters in their laps, Agnes finally sitting down.*

- **Agnes:** Sit down, the pair of you, and don't interrupt. Henrik Strand, toymaker. The whole town loved him.
- **Agnes:** Last market, Christmas Eve, his shop went up. He stood in this square and said it was his candle.
- **Agnes:** By morning he'd gone up the mountain. Nobody had the heart for a market after that.
- **Noelle:** And he's been answering children's letters ever since?
- **Agnes:** Rosa carried them up to him, till her knees gave out. Now he comes down for them himself.
- **Noelle:** Then I'll go up. I've got his parcel.
- **Agnes:** Through that? The road's shut till spring. He can come down. You can't go up.
- **Noelle:** Then we'll give him something to come down for.

**Level 11 · Soot and Snow**

- **Pip:** Lane's clear to the chimney. There's a tin sign. "No flame past this door. H. Strand."
- **Noelle:** That's a strict rule, for a man who left a candle by the shavings.
- **Agnes:** People get careless at Christmas.
- **Noelle (thought):** Not people who paint signs.

**Level 12 · Silver Ink**

- **Pip:** I've sorted the replies. Some are in silver. Very fancy.
- **Noelle:** My custard one's silver! Who actually asks a reindeer?
- **Agnes:** Rosa never would say about those. Put them back in order, there's a good lad.

**Level 13 · Sawdust Row · builds Toymaker's workshop**

- **Noelle:** The workshop's standing again. It even smells right.
- **Pip:** Parcel on the bench! A chisel set, oiled. Tag says "Your joints are a disgrace. Keep going."
- **Noelle:** He's been inside. Last night, while we slept.
- **Pip:** My bell went. By the time I got my boots on, there was just a sled track.
- **Noelle:** Next time, leave a note on the bench. Tell him the cocoa's hot.

**Level 14 · The Order Book**

- **Pip:** Found his order book, in the iron safe. Burnt round the edge. Last week before the fire.
- **Noelle:** Sled for the Finch boys. Skates for Hannah. "Wooden horse, painted red. For Noelle."
- **Noelle:** He made me a horse. I don't remember any horse.
- **Agnes:** You were very small. Leave that, love, you'll get soot on your mittens.

**Level 15 · Tangled Tinsel**

- **Pip:** Mrs Alder's on the green untangling tinsel. Mrs Alder hasn't left her house since before I was born!
- **Noelle:** Nobody asked her to, either.
- **Agnes:** Well. She always did like a bit of tinsel. Hmph.

**Level 16 · Paper and String · builds Gift wrapping pavilion**

- **Pip:** Let me do your parcel properly. That bow's terrible.
- **Noelle:** Don't touch it! Gran wrapped this.
- **Pip:** Then your gran couldn't tie a knot. That's how little kids do it, look. Two loops.
- **Noelle:** Gran could tie anything. Gran tied up a whole goose once.
- **Agnes:** Leave the parcel be, Pip.

**Level 17 · Three Hundred Witnesses**

- **Noelle:** I've worked it out. No flame past the door, and he took the blame anyway. He was protecting someone.
- **Noelle:** Gran. It was Gran's candle. That's why she ran, and why she carried his letters all those years.
- **Agnes:** Rosa was serving cocoa all night, in front of three hundred people. I was next to her.
- **Noelle:** Oh. ...Not Gran. I'm sorry. I was so sure.
- **Agnes:** Yes. Well. You're warm, girl. Now leave it.

**Level 18 · Fairy Lights** *(easier level)*

- **Agnes:** You've got your market. Light your tree and let the rest lie. Please.
- **Noelle:** You've never said please in your life. Who are you protecting?
- **Agnes:** Not me, love. Not me.

**Level 19 · A Hundred Flames · builds Candlelight shop**

- **Pip:** Finished! A hundred candles! Come and see, it's the best smell in the whole market!
- **Noelle:** I'll stay out here, Pip. It's just... wax, and hot wood. My hands have gone cold.
- **Noelle (thought):** It was dark. Somebody big was shouting at me to run.
- **Pip:** Noelle? You've gone a funny colour.
- **Noelle:** Pip. Did Gran's house have a box of letters? One that never went in the mailbox?
- **Pip:** There's a tin in her attic. I saw it when I did the post. Why?

**Before level 20**

- **Agnes:** Don't go up to that attic, love.
- **Noelle:** You've been telling me that since the day I came.
- **Agnes:** I know. Take a lantern, then. It's dark up there.

**Level 20 · The Letter in the Tin · hook** · *Panel: an attic, one lantern, a tin box, a small sheet of paper in a child's big letters.*

- **Pip:** There's only one in here. Big wobbly letters, all downhill.
- **Noelle:** That's my writing. It's dated Christmas Eve, the last market.
- **Noelle:** "Dear Santa. I went to see my horse. I took a candle so I could see it. It fell down."
- **Noelle:** "Mr Henrik said run and I ran. Please tell him sorry. Noelle, age 6."
- **Pip:** ...You?
- **Noelle:** He stood in the square and said it was him. For me.
- **Agnes:** You were six, love. You stopped talking for a month. Rosa took you away so you could forget.
- **Noelle:** You all knew.
- **Agnes:** Rosa, me and him. Nobody else, ever.
- **Noelle:** Every letter in that mailbox got an answer, and this is the only one he never saw.
- **Noelle:** Get your satchel, Pip. It's twenty-five years late, and I'm going to deliver it.

## Episode 3: The Star on the Mountain

**Before level 21 · opening** · *Panel: the attic window at first light, Noelle with the letter and the parcel, snow clouds piling over the mountain.*

- **Noelle:** First I'm telling the town. Tonight, at the cocoa kiosk.
- **Agnes:** Nobody's asking you to. He's carried it twenty-five years so you wouldn't have to.
- **Noelle:** That's why.
- **Pip:** Parcel on the doorstep! Tag says "Weather coming. Stay off the road. Nearly done."
- **Noelle:** Nearly done with what?
- **Pip:** Also it's five days to Christmas Eve, and the tree's still got no star.
- **Agnes:** I'll get the big pot on. If you're breaking hearts, you'll do it with something warm in them.
- **Noelle (thought):** Keep going, he said.

**Level 21 · Carolers Court**

- **Noelle:** Well, I said it. All of it. Nobody said a thing. They just went home.
- **Agnes:** Give them a minute. It's been twenty-five years.
- **Pip:** Um. Noelle? Old Mr Finch went home and came back with a ladder.

**Level 22 · Ladders and Lamps**

- **Pip:** Now there's nine ladders. And Hannah's brought her old skates, and her kids!
- **Noelle:** Nine ladders? Pip, I told them I burned down their town.
- **Agnes:** They've been waiting for someone to go first, you daft girl. Cocoa's on.

**Level 23 · Painted Horses · builds Reindeer carousel**

- **Pip:** They keep bringing horses! Everyone's got one. In attics, under beds, all scorched!
- **Noelle:** They pulled them out of the fire. And they've kept them all this time?
- **Agnes:** Couldn't look at them. Couldn't throw them out. That's Bellmere for you.
- **Noelle:** Twelve horses. That's the full set. All but one saddle.
- **Agnes:** It'll do. Things can be mended and still show it.

**Level 24 · Frozen Fountain**

- **Noelle:** We got the fountain running. The ribbons are coming out, every one.
- **Pip:** This one's yours. It's got your name. What did you wish?
- **Noelle:** I've no idea. I expect it was a horse.

**Level 25 · The Light Goes Out**

- **Pip:** No parcel today. None yesterday, either. There's always a parcel.
- **Noelle:** And the wind's come round from the north. I can barely see the mountain.
- **Agnes:** Noelle. Look up. His light's gone out.
- **Pip:** It's never gone out. Not once, not in my whole life.

**Level 26 · Lantern Ice · builds Winter skating rink**

- **Pip (shout):** Noelle! On the far side of the lake! There's a sled!
- **Noelle:** It's his. Empty, with one runner smashed. And a note tied to the rail.
- **Noelle:** "Should have brought this down years ago. Road's gone, I'm on foot. Keep the cocoa hot."
- **Pip:** Brought what down? What's he carrying?
- **Agnes:** Oh, I know what. I've wondered for twenty-five years where it got to.
- **Agnes:** He went back in for the star, girl. He's bringing you the star. In this.

**Level 27 · Every Light in Bellmere**

- **Noelle:** I'll take the ladders and go up with Mr Finch's boys.
- **Agnes:** You'll be lost in ten yards, and I'll have two of you to find. He knows the mountain. He just can't see.
- **Noelle:** Then we'll let him see. Every lamp, every lantern, every stall. Light the whole market.
- **Pip:** We've run out of lanterns. There's only the candle shop.
- **Noelle:** I know. Give me the matches. I'll do the first one.

**Level 28 · The Last Hill** *(easier level)*

- **Pip (shout):** There's someone on the hill! Somebody's coming down! Noelle!
- **Noelle:** Mr Strand! Over here! Are you hurt?
- **Henrik:** Frozen, seventy-four, and carrying forty pounds of brass. Who hung that carousel?
- **Noelle:** We all did.
- **Henrik:** I can tell. The horses are on backwards. It's beautiful. Is there cocoa?

**Level 29 · The Old Tree Again · builds Christmas tree**

- **Noelle:** Mr Strand, I've a letter for you. It's twenty-five years late. I told the town.
- **Henrik:** "Please tell him sorry." ...Well. This one wants an answer, doesn't it?
- **Henrik:** Dear Noelle. You ran when I said run. That was all I ever needed from you.
- **Noelle:** And this is yours. "For the one who answers." I tied that bow myself, the night we left.
- **Henrik:** Your horse. Rosa kept it? I made this for you, you stubborn child. It was always yours.
- **Henrik:** Now. That tree's a disgrace. Keep going.

**Before level 30**

- **Pip:** It's Christmas Eve! Everyone's in the square. All of them! Even Mr Finch and all his ladders.
- **Henrik:** He's got that one on the wrong side.
- **Noelle:** Then let's light it before he falls off.

**Level 30 · Light the Christmas Tree · hook** · *Panel: the whole town in the square, every window lit, the tree blazing, the old star on top. Far above, a thin silver streak.*

- **Henrik:** Up she goes. Mind the third branch. It sulks.
- **Pip (shout):** It's on! IT'S ON! LOOK AT IT!
- **Agnes:** There you are, you old thing. There you are.
- **Noelle:** A warm bakery, backwards horses and a tree you can see from the mountain. Oh, Gran.
- **Noelle:** We built this together, all of us. Merry Christmas, Bellmere.
- **Pip:** Merry Christmas! Oh! One more post, Mr Strand. It's for you. Silver ink, like your best ones.
- **Henrik:** Silver? I've only ever had black, lad. I wondered who was doing those.
- **Noelle:** Then who asked the reindeer? Read it. Read it!
- **Henrik:** "Thank you for minding my post all these years. We are a toymaker short. Bring the girl."
- **Pip:** What's the stamp say?
- **Noelle:** ...North Pole.
- **Agnes:** Someone's having you on, love.
- **Pip (shout):** Then who's on the bakery roof? There's hoofprints! And sled tracks going north!
- **Henrik:** Get your coat, girl. And bring the cocoa.

## The end screen

Shown once after the level 30 hook, replacing today's "ALL TEN MARKET WISHES CAME TRUE" panel. The market stays open behind it.

> **TO BE CONTINUED**
> Hoofprints on the bakery roof. Who is a toymaker short?
> *Next: Episode 4, The North Road*
> Episodes 3 · Wonders 10 · Rank N
> **[ BACK TO MY MARKET ]**

**Walking into the sequel.** Episode 4 opens on the bakery roof at the moment this one ends, and Pip follows the tracks north. The catalogue already holds the places to go: *North Pole post office*, *Reindeer stable*, *Santa's workshop*, *Santa's sleigh*. So those decorations foreshadow the next map, while the mundane mystery of Bellmere remains fully explained.

## Small lines

**Pip, when a region opens** (replacing today's one repeated line). Levels assume the proposed tripled star gates.

- **Lantern Lane, level 6. Pip:** Lantern Lane's clear! There's a lamp post that still works if you kick it.
- **Gingerbread Green, level 9. Pip:** Gingerbread Green's open! It doesn't smell of gingerbread yet. Give it a week.
- **Carolers Court, level 15. Pip:** Carolers Court's open! Mrs Alder's already in it, singing flat.
- **Starlight Terrace, level 21. Pip:** Starlight Terrace is open! You can see the mountain from here, and the mountain can see you.
- **Evergreen Hill, level 27. Pip:** Evergreen Hill's open! It's the last of the land, and every window's looking your way.

**Episode gates, only if a Rank gate is approved for this game.**

- **Rank goal before episode 2. Agnes:** A market's not a shed and a hope, love. Hang something pretty, then we'll talk.
- **Rank goal before episode 3. Agnes:** He'll want something worth coming down to. Trees, lamps, the lot. Make it glow.

**Tap bubbles that change after a reveal.** The world answers back, at a cost of four strings:

| Building | After | Bubble |
| --- | --- | --- |
| Toymaker's workshop | Level 20 | Red paint on the bench, twenty-five years dry. |
| Candlelight shop | Level 27 | Noelle lit the first one herself. |
| Reindeer carousel | Level 28 | The horses are on backwards. Nobody's fixing them. |
| Christmas tree | Level 30 | The star is scorched on one side. It looks better that way. |

## Levels

Levels 1–9 keep their boards and lessons. **Level 10 is renamed** from *Light the Christmas Tree*, and that name and its finish move to level 30, because the tree is now built at level 29. Levels 11–30 need boards authored and use only existing mechanics. Level lessons stay separate from the story.

| # | Name | Focus | Lesson |
| ---: | --- | --- | --- |
| 10 | Under the Old Tree | All | Clear the snow from the old tree's roots. |
| 11 | Soot and Snow | Snow, gentle restart | Dig out the lane, one drift at a time. |
| 12 | Silver Ink | Snow, tinsel | Unwrap the tangled treats to free the post. |
| 13 | Sawdust Row | Tinsel, specials | Shooting stars reach what your hands can't. |
| 14 | The Order Book | Tinsel, combos | Two specials together clear a whole crossing. |
| 15 | Tangled Tinsel | Tinsel, dense | So much tinsel. Work from the outside in. |
| 16 | Paper and String | Ice returns | Break the ice before you wrap anything. |
| 17 | Three Hundred Witnesses | Ice, candy canes | Candy canes melt every cell around them. |
| 18 | Fairy Lights | Lighter board | Nearly clear. Take a breath. |
| 19 | A Hundred Flames | Double ice | Old ice takes two hits. Plan for both. |
| 20 | The Letter in the Tin | All, ring shape | Everything hidden is in the middle. |
| 21 | Carolers Court | Snow, gentle restart | One drift at a time. People are watching. |
| 22 | Ladders and Lamps | Tinsel, narrow shape | Thread the lights along the narrow path. |
| 23 | Painted Horses | Rainbow stars | A rainbow star clears a whole colour. |
| 24 | Frozen Fountain | Ice, rainbow stars | Free the ribbons from the centre. |
| 25 | The Light Goes Out | Tight moves | Moves are short. Every swap has to count. |
| 26 | Lantern Ice | Ice, snow | Clear the lake edge before the storm. |
| 27 | Every Light in Bellmere | All, wide shape | Light every corner of the board. |
| 28 | The Last Hill | Lighter board | Run. The board is on your side. |
| 29 | The Old Tree Again | All, dense | Every drift in Bellmere stands in your way. |
| 30 | Light the Christmas Tree | All, star shape | Clear the snow and light our Christmas tree! |

## For implementation

- **Wonder order is unchanged:** arch 1, lumber 4, bakery 7, cocoa 9, workshop 13, pavilion 16, candles 19, carousel 23, rink 26, tree 29.
- **Same blocker as Relic Rush:** `reward_breakdown` in `lua/rules.lua` indexes the wonder by level, and `WONDERS` is 10 in `lua/island.lua:10`. An 11th level needs the level-to-wonder map first. Share that fix if possible, rather than writing it twice.
- **Three new busts** (Agnes, Pip, Henrik) and **six panels**, recorded in the [asset catalogue](asset-catalogue.md) and checked by `tools/check_assets.py`, whose inventory count changes. Dialogue can ship before the panels.
- **The cast table** in `lua/main.lua:19` gets three entries, each with a mouth position. The automatic Noelle line at wonders (`lua/island_view.lua:55`) goes away, and `about` stays in the tap bubble.
- **`R.finale` and the end panel** (`lua/screens.lua:450`) move to level 30.
- **Economy is not covered here.** This game still pays and costs wood and stone, unlike Relic Rush. Any Rank gate is a separate decision.
- **Check in the game:** the longest scene is 14 lines, and `story.frame` has not been tried past 3 in a row. The name plate must fit "Henrik Strand" and "Agnes Holt".

## Changelog

- 2026-11-02: First full script. Cast art, boards and code not started.
- 2026-11-02: Cold read done by a separate reader. They guessed the fire at level 7, so "I've never liked candles" became a practical excuse and level 6 gained a cover story. Fixed the bow, the flour alibi, who collects the letters, the silver ink, the road and the finale lines. Noelle's voice is still the least distinct, and a second read should check whether the reveal now holds until level 17.
