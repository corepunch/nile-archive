# Relic Rush · Landfall

Captain Tavi's ship puts a dozen settlers and their builder, the player, ashore on an empty green island. There's no town, only a spring, a beach and a reef. Tavi will send the ship back for the rest of the families once there's a town worth bringing them to. While they build, the settlers keep digging up traces of an older harbour town. By the end the families are home, and the town takes the old harbour's name.

**Feeling:** the excitement of a new home. Warm, funny, a little adventurous. No villains and no dark secrets.

**Goal everyone shares:** build a town, send the ship for the families, bring them in safely over the reef.

## Cast

| Person | Who | Voice |
| --- | --- | --- |
| Tavi | Captain of the ship. Older, sure of herself. Charts the reef and stays to pilot the families in. | Short, dry, teasing. Calls the player "builder". |
| Sela | A potter. Young and curious. Finds the old cup on the first day and every relic after it. | Eager, quick, full of questions. |
| Oren | A farmer who brought seed wheat and later keeps homing birds. | Easy-going, always thinking about bread. |

## What happened

1. Long ago a harbour town called Callira stood here. Its people cut harbour steps, tide marks and carved stones, and then left. Nobody remembers why, and the story never says.
2. Tavi lands the first settlers. They build a well, roofs, a workshop and a camp, and dig up the harbour steps.
3. The hill people inland come to trade. Nobody there remembers who built the old harbour either.
4. Tavi charts the reef. Once the lighthouse is lit, her mate sails the ship home for the families. Tavi stays, because only she can pilot a big ship over the reef.
5. Oren's homing birds give the town news. When the ship's sails appear, Tavi rows out with Oren's grey bird, sends back a head count, and brings fifty-two people in.
6. The families land. Sela leaves the old cup at the new fountain, and the town votes for the old name, Callira, over Oren's "Breadhaven".

## Plants and payoffs

| First mention | Payoff |
| --- | --- |
| Tavi will sail back for the families (before level 1). | The families land (92–100). |
| Sela digs up an old cup (1). | She keeps using it (87), then leaves it at the fountain for everyone (96). |
| Old harbour steps: "Where did they all go?" (16, 21). | The carved stones give the harbour's name (61). Why they left stays open. |
| Oren wants "Breadhaven" (52, 55). | Callira wins; Breadhaven comes second (100). |
| Oren's birds can fly home from a ship (81, 85). | The grey bird brings the head count (92). |

## Campaign

**In the game only the opening plays** (`story_intro` in `lua/game_config.lua`), before the first board, and Settings → Story turns it off. The rest of this script is archived: the engine's story tests still run it, but the campaign does not.

The numbered scenes play once, on the first clear. Levels between them have no scene. Building scenes play when the building is placed. The player can ask Tavi and Oren more in town.

**Before level 1**

- **Tavi:** Everyone ashore! Builder, welcome to our new home. When there's a town, I'll send for the families.
- **Oren:** Lovely beach. Where's the town?
- **Sela:** There's a spring up in the rocks, Oren. Fresh water! That's a start.

**Level 1**

- **Sela:** Look what I dug up by the spring. A cup! Somebody lived here before us.
- **Oren:** Then somebody else knew where the water was. That's a good sign.

**After restoration 1 · Spring well**

- **Sela:** Clean water from our own well. No more ship's barrels!
- **Oren:** I'm going to fill every pot we own. Just because I can.
- **Tavi:** Good work, builder. Now we need roofs before the rain finds us.

**Level 7**

- **Oren:** Builder, it rained straight into my soup last night.
- **Tavi:** Then let's get a roof up. A cabin next?

**Level 10**

- **Sela:** Tavi, can we take planks from the ship?
- **Tavi:** Take the spares, not the hull. She has to fetch the families.

**Level 12**

- **Oren:** Sela, where are you going to put your potter's wheel?
- **Sela:** Somewhere dry, with a big door. A workshop.

**Level 16**

- **Tavi:** Builder, the crew needs a camp. Tents, a cook fire, somewhere for the tools.
- **Oren:** And a cook. Ideally me.

**After restoration 16 · Expedition camp**

- **Sela:** Tavi, the camp crew dug up old stone steps. Cut by hand and worn smooth.
- **Tavi:** Harbour steps. Somebody tied up their boats here long before us.
- **Oren:** Then where did they all go?

Choice prompt: What should we do with the old steps?

### Choice: clear | Clear them for the boats

- **Sela:** Let's clear them. The boats could tie up right at the bottom.
- **Tavi:** Good. My crew is tired of wading ashore.

### Choice: wait | Leave them for now

- **Oren:** Leave them for now. We need houses more than stairs.
- **Tavi:** Fair enough. They've waited this long.

**Level 20**

- **Oren:** Tavi, there's smoke over the hills. We're not alone here.
- **Tavi:** Then let's be good neighbours. Builder, how about a market?

**Before level 21**

- **Oren:** Sela, are you sure the hill people want pots?
- **Sela:** Everybody wants pots, Oren. They just don't know it yet.

**After restoration 21 · Jungle market**

- **Sela:** The hill people came! Three baskets of mangoes for two of my pots.
- **Oren:** An old woman asked me who built the harbour steps. She thought we did.
- **Tavi:** So nobody remembers. Whoever they were, they left a long time ago.

**Level 25**

- **Oren:** My wheat's in the ground. Now I need a mill, or it's porridge forever.
- **Sela:** I like porridge.
- **Oren:** You would.

**Level 28**

- **Tavi:** The hill people want stone for their houses. We've got a whole cliff of it.
- **Sela:** Then let's sell it. We'll need a trading post.

**Level 33**

- **Oren:** The wheat's ripe, and I'm still grinding it between two rocks.
- **Sela:** Builder, can he have that mill now? Before his arms fall off.

**Level 35**

- **Tavi:** I lost a net on the reef last night. I need to know when the tide's high.
- **Sela:** There are old lines cut in the rock by the steps. Could they be tide marks?

**After restoration 36 · Tide clock tower**

- **Tavi:** The old marks were right. They show high water to the inch.
- **Sela:** So whoever lived here were sailors too.
- **Tavi:** Good ones. Now I can bring a ship in without scraping her.

**Level 40**

- **Oren:** Tavi, when will you send the ship for the families?
- **Tavi:** When the town has a harbour. A ship that size needs one.

**After restoration 41 · Harbour plaza**

- **Sela:** A harbour square! Somebody's already selling fish on it.
- **Tavi:** Then it's a harbour. Builder, my crew needs a lodge, and I need a chart of the reef.

**Level 46**

- **Tavi:** My crew has lived on that ship for months. They'd like a floor that doesn't rock.
- **Oren:** Give them a lodge with a big table. Sailors eat like I do.

**After restoration 46 · Harbour lodge**

- **Tavi:** Look at them, builder. Sitting down without holding on to anything.
- **Oren:** Give them an hour. They'll be telling sea stories to anyone who sits still.

**Level 50**

- **Sela:** The hill families are asking if they can move down to the harbour.
- **Tavi:** Tell them yes. A town needs more than a dozen people.

**Level 52**

- **Sela:** Everyone's arguing about what to call this place.
- **Oren:** My vote's for Breadhaven.

**Level 55**

- **Oren:** Four people want Breadhaven. Me, and three people I gave bread to.
- **Sela:** That's not a vote, Oren. That's a bribe.

**Level 56**

- **Tavi:** Builder, I need a house with a big table and good light. For my charts.
- **Sela:** Are you getting ready to send the ship?
- **Tavi:** Nearly. I won't bring the families over that reef without a chart.

**Level 58**

- **Oren:** Sela, why is Tavi rowing in circles out by the reef?
- **Sela:** She's measuring how deep it is. Every circle is a line on her chart.

**Level 60**

- **Sela:** More old stones keep turning up. Some of them have writing on.
- **Oren:** Let's keep them somewhere dry before someone builds a wall with them.

**After restoration 61 · Keeper's archive**

- **Sela:** The same word is carved on every stone we've found. Callira.
- **Tavi:** It must be the harbour's name. You don't carve a word that often unless you're proud of it.
- **Oren:** All right, it's better than Breadhaven. Let's put it to a vote.

**Level 65**

- **Tavi:** The chart's done. Now I need a light, so the ship can find her way back.
- **Sela:** Aren't you sailing with her?
- **Tavi:** Somebody has to pilot the families over the reef. That's me. My mate will sail her.

**After restoration 66 · Lighthouse**

- **Tavi:** The ship sails tonight. Keep that fire lit every night, builder, so she can find us.
- **Sela:** Every night. Tell your mate to hurry.
- **Oren:** And to bring flour.

**Level 67**

- **Oren:** How long until the ship comes back?
- **Sela:** Two months, Tavi says, if the wind is fair.

**Level 70**

- **Sela:** Builder, there's an old wreck on the rocks. Can we haul her up the beach?
- **Tavi:** Gently. She's older than my grandmother.

**Level 76**

- **Tavi:** Out at sea, my mate steers by the stars. I'd like to watch them too.
- **Sela:** Then we'll build somewhere to watch them from.

**Level 77**

- **Oren:** Tavi's been up every night this week.
- **Sela:** She's counting the days.

**Level 81**

- **Oren:** A month without news of the ship. I hate waiting.
- **Sela:** Then keep homing birds. They could carry news.
- **Oren:** A loft of my own. I've always wanted one.

**Level 85**

- **Sela:** Tavi, have you seen Oren today?
- **Tavi:** He's teaching his birds to find a ship. Don't interrupt him.

**Level 87**

- **Sela:** We've got shelves of old things from Callira now. Coins, lamps, a carved comb.
- **Tavi:** Put them where the families can see them when they land.

**Level 91**

- **Sela:** When the families land, they'll need a feast. And somewhere to hold it.
- **Oren:** I'll do the bread. Somebody else can do everything else.

**After restoration 91 · Temple of the Sun**

- **Sela:** The hill people say Callira had a sun temple that baked bread for strangers.
- **Oren:** Then I approve of Callira.
- **Tavi:** Then we're ready. All we need now is the ship.

**Level 92**

- **Sela:** Sails on the horizon! Tavi, is that her?
- **Tavi:** That's her. I'm rowing out to bring her over the reef.
- **Oren:** Bring them in hungry. I've been baking all week.

**Level 95**

- **Tavi:** They're all ashore, builder. Fifty-two people, and every one of them wants water.
- **Sela:** Then let's give them a fountain. With cups for everyone.

**After restoration 96 · Jade fountain**

- **Sela:** I'm leaving the old cup by the spout. It was the first thing I found here.
- **Oren:** Somebody from Callira drank from it. Now all of us can.

**Level 100**

- **Tavi:** Fifty-two new neighbours, a harbour and a light. Not bad for a beach, builder.
- **Oren:** And the vote's in. It's Callira. Breadhaven came second.
- **Sela:** Welcome home, everyone. Welcome to Callira.

## Town dialogue

**Placed log_cabin**

- **Oren:** A roof that doesn't flap in the wind. I may never come out.
- **Sela:** You'll come out for supper.

**Placed workshop**

- **Sela:** My wheel fits! Oren, the first pot is yours.
- **Oren:** Make it a big one. I'm planning soup.

**Placed trading_post**

- **Sela:** My first customer was a girl with a goat. She wanted a grindstone.
- **Oren:** Did you sell her one?
- **Sela:** Two. She's coming back with another goat.

**Placed water_mill**

- **Oren:** Hear that? That's the sound of bread.
- **Sela:** That's the sound of you talking about bread again.

**Placed amphitheater**

- **Sela:** Can you hear me up there, Oren?
- **Oren:** Every word. Even the ones about me.

**Placed map_room introduces Tavi after-56**

- **Tavi:** Good light and a big table. I'll have the reef drawn in a month.
- **Sela:** Can I watch? I've never seen anyone make a chart.
- **Tavi:** Watch quietly, then.

**Placed beached_ship**

- **Tavi:** Look at those timbers. I'd bet she was built in Callira.
- **Oren:** Will she ever sail again?
- **Tavi:** No. But children will climb on her for a hundred years.

**Placed observatory**

- **Sela:** Which star is your mate steering by?
- **Tavi:** That bright one, low in the south. When it's overhead, she'll be home.

**Placed aviary introduces Oren after-81**

- **Oren:** Twelve birds, and every one of them knows this loft is home.
- **Tavi:** Teach them to find a ship and I'll be impressed.

**Placed museum**

- **Sela:** Everything we've dug up, on shelves. Except my cup. I still use that.
- **Oren:** A potter with a hundred cups, drinking from someone else's.

**With log_cabin after-07 2**

- **Sela:** Then eat in the cabin tonight. That's what the roof is for.

**With workshop after-12 2**

- **Sela:** In the new workshop. I've already claimed the corner by the window.

**With trading_post after-28 2**

- **Sela:** Then let's sell it. The trading post is ready for them.

**With water_mill after-33 2**

- **Sela:** Take it to the mill. The wheel's already turning.

**With amphitheater after-52 1**

- **Sela:** Everyone's arguing about the town's name. Let's settle it at the amphitheatre.

**With map_room after-58 2**

- **Tavi:** I'm measuring the depth, Oren. Every circle is a line on my chart.

**With beached_ship after-76 1**

- **Tavi:** I sat on the old wreck last night, looking at the stars my mate steers by.

**With observatory after-77 2**

- **Tavi:** Counting stars, Oren. It's quicker than counting days.

**With aviary after-85 2**

- **Oren:** Up here, Sela! The grey one just beat me home from the harbour.

**With museum after-87 2**

- **Tavi:** Good. The families should know whose harbour this was.

**With map_room after-67 2**

- **Tavi:** Two months, if the wind is fair. Plenty of time to finish the town.

**If asked placed-map_room personal**

- **Tavi:** Two months, if the wind is fair. My mother would have done it in six weeks.

**With aviary after-91 2**

- **Oren:** I'll do the bread. And my birds will watch for the sails.

**If asked after-85 personal**

- **Oren:** I'll do the bread. The grey one will spot the sails before any of us.

**With aviary after-92 3**

- **Oren:** Take my grey bird. Send her back with a head count, so I know how much to bake.

**Visit map_room placed-map_room**

**Ask personal | Why the sea?**

- **Sela:** Why did you go to sea, Tavi?
- **Tavi:** My mother had a fishing boat and nobody else to sail it.

**Ask story | How do you chart a reef?**

- **Sela:** How do you chart a reef you can't see?
- **Tavi:** A rope with a weight. Drop it, count the knots, write it down. A thousand times.

**Visit map_room after-67**

**Ask personal | Do you miss the ship?**

- **Sela:** Do you miss the ship?
- **Tavi:** Like a lost tooth. I keep reaching for it.

**Ask story | Will she find us?**

- **Sela:** What if your mate can't find the island?
- **Tavi:** She'll see our lighthouse from far out at sea.

**Visit map_room after-100**

**Ask personal | Will you sail again?**

- **Sela:** Will you go back to sea?
- **Tavi:** Someday. Right now I want to sit somewhere that doesn't move.

**Ask story | Who pilots the boats now?**

- **Sela:** Who'll pilot the boats over the reef now?
- **Tavi:** I'm teaching two of the hill boys. They're brave. Not careful yet.

**Visit aviary placed-aviary**

**Ask personal | Why birds?**

- **Sela:** Why birds, Oren?
- **Oren:** Since the crossing, I like anything that always finds its way home.

**Ask story | What are they for?**

- **Sela:** What can a bird do that a boat can't?
- **Oren:** Fly a day's sail in an hour and come straight back with a message.

**Visit aviary after-85**

**Ask personal | Has one come back yet?**

- **Sela:** Has a bird come back yet?
- **Oren:** Every one. The grey one beat me home from the harbour.

**Ask story | Could one reach the ship?**

- **Sela:** Could a bird reach the ship at sea?
- **Oren:** Not from here. But Tavi could row one out and let it go.

**Visit aviary restore-91**

**Ask personal | Bread for the feast?**

- **Sela:** How much bread are you making for the feast?
- **Oren:** All of it. Every loaf this island can hold.

**Ask story | Any news from sea?**

- **Sela:** Any news from the ship?
- **Oren:** Not yet. I check the loft every morning before breakfast.

**Visit aviary after-92**

**Ask personal | Did you bake enough?**

- **Sela:** Did you bake enough?
- **Oren:** Three loaves left over. I'm calling that perfect.

**Ask story | Keeping the birds?**

- **Sela:** Will you keep the birds now the ship is home?
- **Oren:** Of course. Tavi wants one on every boat that leaves this harbour.

**Visit aviary restore-96**

**Ask personal | Why the crowd?**

- **Sela:** Why is everyone at the fountain?
- **Oren:** The children found your old cup. They're taking turns with it.

**Ask story | Are they settling in?**

- **Sela:** Are the families settling in?
- **Oren:** Three days here and they're already arguing about bread. They're home.

**Visit aviary after-100**

**Ask personal | Happy, Oren?**

- **Sela:** Is this what you hoped for, Oren?
- **Oren:** A mill, a loft and a whole town to feed. Yes.

**Ask story | What's next?**

- **Sela:** What will you do tomorrow?
- **Oren:** Bake for fifty-two more people. Ask me again the day after.

**Meeting map_room aviary**

- **Oren:** Tavi, my birds can't find a ship at sea. But they can fly home from one.
- **Tavi:** Then when her sails show up, I'll row out with a bird and send it back.
- **Oren:** With a head count. I need to know how much bread to make.

**If asked map_room after-67 personal 2**

- **Tavi:** Any excuse to get back on a boat. I'll row out with a bird and send it back.

**If asked map_room after-67 personal 3**

- **Oren:** You'd row out with or without a bird, Tavi.

**Ask at aviary | Which bird will go?**

- **Sela:** Which bird will Tavi take?
- **Oren:** The grey one. She's never once got lost.

**Ask at map_room | How far will you row?**

- **Sela:** How far out will you row?
- **Tavi:** Past the reef, where the water's deep. A big ship can't come closer without me.

**Ask at map_room after aviary | The grey bird?**

- **Sela:** Oren's giving you his grey bird.
- **Tavi:** His best one? He really does want that head count.

**Ask at aviary after map_room | Past the reef?**

- **Sela:** Tavi's rowing out past the reef. Isn't that dangerous?
- **Oren:** For anyone else. She drew the chart.

**Recall after-92**

**Heard neither**

- **Tavi:** Is the bird ready, Oren?
- **Oren:** Fed and ready. Count twice before you let her go.

**Heard aviary**

- **Oren:** Here's the grey one. She's never once got lost.
- **Tavi:** Then she'll beat me home. Get the ovens hot.

**Heard map_room**

- **Tavi:** I'll wait past the reef. If it gets dark, light the fire.
- **Oren:** It's the middle of the day, Tavi. Just go.

**Heard both**

- **Oren:** The grey bird, past the reef, a head count. Anything else?
- **Tavi:** Yes. Push the boat, Oren!

**Catch up in town**

- **Tavi:** Push me off, Oren. I'm going out to meet her.
- **Oren:** Go. The bread will be out of the oven before you're back.

**Ask at aviary | Did the bird come back?**

- **Sela:** Did the grey bird come back?
- **Oren:** Within the hour. Fifty-two people aboard. I need more flour.

**If heard map_room**

- **Sela:** Tavi got out past the reef. Did your bird beat her back?
- **Oren:** By an hour. Fifty-two aboard. I need more flour.

**Ask at map_room | How was it out there?**

- **Sela:** How was it out there?
- **Tavi:** They were all at the rail, waving. I took her over the reef myself.

**If heard aviary**

- **Sela:** Fifty-two people, Oren says. Did they all fit?
- **Tavi:** Just. Half of them waved at the town the whole way in.

## Upgrades

**Upgrade man_03 · a second rope and pulley · Spring well**

- **Oren:** Two buckets at once now. The queue for water just got half as long.

**Upgrade man_04 · his father's tools sharpened · Trapper's cabin**

- **Oren:** My father's old axe, sharpened. It cuts like it did when I was a boy.

**Upgrade man_02 · a second saw bench · Carpenter's workshop**

- **Sela:** Two saw benches. Now the planks get cut while I'm at my wheel.

**Upgrade man_01 · a dry tool store · Expedition camp**

- **Sela:** A dry shed for the tools. No more rusty saws after a rainy night.

**Upgrade man_05 · the hill farms send their carts · Jungle market**

- **Tavi:** Carts from the hill farms every week now. Beans, mangoes, and far too many goats.

**Upgrade man_06 · a cart road to the quarry · Stone trading post**

- **Sela:** A proper road to the quarry. The carts don't get stuck any more.

**Upgrade man_07 · a second millstone · Water mill**

- **Oren:** Two millstones! Twice the flour, and still only one of me.

**Upgrade man_08 · a warning chime · Tide clock tower**

- **Tavi:** Now the tower rings at high water. Nobody gets caught on the reef by surprise.

**Upgrade man_09 · a fish market every morning · Harbour plaza**

- **Tavi:** Fresh fish on the plaza every morning. The gulls are delighted.

**Upgrade man_10 · market-day shows · Stone amphitheatre**

- **Oren:** A show every market day now. I never miss the jugglers.

**Upgrade man_11 · storm charts on the wall · Cartographer's house**

- **Tavi:** Storm charts on the wall. Now everyone can see where the bad weather comes from.

**Upgrade man_12 · a bronze reflector · Lighthouse**

- **Tavi:** With bronze behind the fire, ships can see our light twice as far.

**Upgrade man_13 · a ferry to the hill villages · Beached schooner**

- **Tavi:** A ferry up the coast to the hill villages. Cheaper than walking, and drier.

**Upgrade man_14 · the sighting stones aligned · Star observatory**

- **Sela:** Look through both stones. That's the bright star in the south, right in the gap.

**Upgrade man_15 · a reading room open to all · Relic museum**

- **Sela:** Anyone can come and read the old stones now. Bring your children.

**Upgrade man_16 · the keepers' watch roster · Temple of the Sun**

- **Oren:** I've put my name down for the night watch. Somebody has to keep the temple ovens warm.

## Changelog

22 November 2026 · Replaced "A Crust Each Way" with "Landfall": settlers land from Tavi's ship and found a town, and the families arrive at the end. Same cast faces with new roles; Ina is gone. Same scene keys and resident structure, so saves and town visits keep working.
