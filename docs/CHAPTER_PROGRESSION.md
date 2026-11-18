# Each epoch tells one chapter in four purchases

**Design proposal for Relic Rush and Christmas Market.** Relic Rush implements the four opening building quests and their next-building card. The epoch strip and keepsake box are proposed UI. Nile Archive keeps its June's Journey structure.

## The epoch is the chapter

Keep the rhythm of Cradle of Rome. The player matches pieces, banks resources and spends them on the next building. A purchase has a practical consequence worth showing on the build card. The Spring Well puts water buckets on future boards. The Artisan Workshop lets the crew cut a tread to reach the viewing shutter on the quay. [Rome's twenty purchases](cradle-of-rome-reference/GAME_DESIGN.md#5-every-building-in-the-original-20-purchase-ladder)

- **Tell one story in four required purchases.** Give the epoch a question or wish. The first purchase sets it up, the middle two move it forward, and confirming the fourth pays it off. Twenty required purchases give each game five story epochs. Optional buildings, decorations and citizen arrivals do not fill a slot. [Relic Rush ladder](../games/relic-rush/lua/economy.lua) · [Christmas Market ladder](../games/christmas-market/lua/economy.lua)
- **Let citizens add scenes between purchases.** Use the building and play conditions that already bring someone to town. Their arrival gives the writer an occasion for an exchange with another character. The player can finish the epoch whether or not an optional resident has arrived.
- **The next level funds the next purchase.** Design prices around forward play and reserve the resources needed for required purchases before offering optional spending. In Relic Rush Chapter 1, Claim banks only the resources actually matched. A first clear can make a purchase available. The story moves when the player confirms a build or repair, or a citizen arrives. Use this rule when revising later Relic Rush chapters, which still have first-clear scenes. [Relic Rush campaign milestones](../games/relic-rush/docs/story.md#campaign-milestones)

`python3 tools/scenario_overview.py --epoch 1 --capture` renders an epoch of both games as they are now: its four purchases, prices, board changes, levels, scenes and town. [Scenario overview](STORY_WRITING.md#scenario-overview)

## Worked example · Relic Rush Epoch 1, A Light Below

**Is someone answering Mara’s lamp?** The next building on the card is the quest. Before the player builds, someone asks for something they need. After confirmation, show that person using it. Cubby’s breakfast in Tropicats works because fixing his grill gets a hungry guard back on duty. In Relic Rush the pieces the player matches already pay the price on the card. Several expeditions can contribute, and resources already in the wallet count. [The Guard’s Breakfast](tropicats-reference/story/chapter-03.md#chp3_q2-the-guards-breakfast) · [Building prices](../games/relic-rush/lua/buildings.lua) · [Piece yields and purchase order](../games/relic-rush/lua/economy.lua)

### 1. Bring the crew ashore · Expedition Camp

**Mara asks** for tents and a meal. The others are still on the boat, and she wants supper ready when they land.

**Match** sun and silver coins for **60 Coins**. Board 1 has no fruit, timber or stone yet.

**On placement**, the player chooses the camp site. The crew comes ashore and eats. Hammer gems unlock. At dusk Elena spots a lamp bracket at the lookout. Mara flashes twice and sees two flashes come back. A reflection could do that. At breakfast, Mara tips the last water from the boat’s cask.

### 2. Get the pump running · Spring Well

**Mara asks** for the cost of a new pump seal. The island has a freshwater spring. With the old well working, the crew can refill its casks right here.

**Match** coin pieces for **125 Coins**.

**On restoration**, the crew fills the first cask at the original well site. Water buckets begin to earn Food on expeditions. Tomas Reed comes to try the pump he remembers and accepts Mara’s offer of a bedroll. When she asks about the flashes, he tells her the electric relay is dead. The viewing shutter on the lower quay faces the old warning station across the inlet. He offers to take her down at low tide.

### 3. Be there for low tide · Trapper’s Cabin

**Tomas asks** for a dry place where he and Mara can unroll their bedrolls. Low tide comes before dawn. They can leave the rest of the camp asleep and walk down to inspect the exposed steps.

**Match** coins for **65 Coins**, dressed stone for **45 Supplies**, and water buckets or fruit for **40 Food**. The crew needs a roof and provisions for an early start.

**On placement**, Mara unrolls two bedrolls in the cabin. The Cabin upgrades Hammer to Dynamite on the board. At low tide Tomas takes Mara to the foot of the steps. One tread is missing. Tomas holds a line between the two sockets while Mara knots it to length. They take it back to camp.

### 4. Cut a tread to fit · Artisan Workshop

**Tomas asks** Mara for a stone bench. He holds the knotted line between his hands. They have stone at camp and the measure of the gap. What they need now is somewhere to cut a tread square.

**Match** coins for **120 Coins**, dressed stone for **90 Supplies**, and water buckets or fruit for **80 Food**. The gathered stone supplies the bench and its first job. Cut blocks start appearing on boards after the Workshop opens.

**On placement**, Tomas lays out the line on the finished bench. The crew cuts its first tread and seats both ends in the old sockets at the quay. Elena runs her thumb over one notch. Cut to that same notch freshly carved. The ancient keeper sets the tread at that height so the night watch has dry footing at high tide. That evening in the present, Mara climbs the repaired steps. Tomas opens the viewing shutter and Mara flashes twice. Three flashes come back from the warning station across the inlet. Someone is answering. The player chooses whether Mara or Tomas replies, and the epoch ends. [Existing keeper scene and reply choice](../games/relic-rush/docs/story.md#chapter-1-a-light-below)

Confirming the Workshop pays for this whole outcome, including the repair at the original quay site. The next build card belongs to epoch two. The carpenter’s match-of-five arrival stays available as a later character beat.

## Citizens are characters

Give each citizen a name, a workplace, a reason to stay and someone they have business with. Introduce them doing their job. Bring them back when another resident or a later purchase gives them something new to do. A short exchange at a stall or a detail the player can tap on a return visit can carry a relationship between the larger scenes.

- **People the chapter depends on arrive reliably.** Restoring the well brings Tomas into camp. At the workshop, Mara needs his knowledge of the old cuts. By the quay, the player can choose him to answer the signal. His arrival and the well repair share one scene.
- **Give Rome-style citizen feats a scene.** Rome pairs an owned building with a feat such as a five-piece match, two successive combos, or collecting a resource in one level. Relic Rush already uses these conditions at its own scale. With the Workshop built, a match of five brings the carpenter and raises matched cut blocks from five Supplies to six. Let Mara welcome the carpenter at the bench when the player returns to town. With the Water Mill built, a two-stage cascade brings the miller. Use the same arrival event for the exchange and the existing perk. [Rome’s citizen challenges](cradle-of-rome-reference/GAME_DESIGN.md#7-citizen-challenges-buildings-can-have-a-second-payoff) · [Relic Rush citizen events](../games/relic-rush/lua/user_events.lua)
- **Christmas Market already shows how this can feel.** When Agnes opens the bakery, Henrik sends Pip with a penny for a bun he insists he doesn't want. Agnes saves one at the back of the tray. Later, Henrik's workshop gives him a window facing hers. Still later, a tap at the bakery reveals two cups on the sill. The player gets to see a relationship change through the ordinary business of running the market. Use the existing cast, stalls and tap bubbles for more of these encounters. [Christmas Market script](../games/christmas-market/docs/story.md)

For Christmas Market, group the existing wishes and scenes into five four-purchase stories. Four Advent Sundays followed by Christmas Eve give those five epochs a natural shape. Each Sunday’s fourth purchase can bring the neighbours together to light a candle. The fifth epoch pays off their preparations on Christmas Eve.

## Decorations

1. **Landmarks bring their own dressing.** On confirmation, matching pieces appear in the clearance ring, such as lamps by the bakery or palms at the well. Players who never open the decoration shop still get a lived-in town.
2. **Keepsakes have an occasion.** A new resident or a chapter-closing build can bring something specific to that event, such as lanterns for the market. Keep movable gifts in a box until the player wants to place them. Relic Rush levels award matched resources only.
3. **Extra decorations are optional purchases.** Players can spend spare Coins or Bells and move or store the pieces. Decoration counts add neither a campaign requirement nor a level payout.

## UI

1. **One build card shows the next required purchase.** Give the card a short quest title, one or two sentences of narration saying who needs the building and why, the building name and picture, its wallet cost and its practical effect. Characters speak in the scenes, which play once. The card never quotes them, so a player who reopens it reads the task and no repeated dialogue. Tropicats writes its quest setups the same way. [The Guard’s Breakfast](tropicats-reference/story/chapter-03.md#chp3_q2-the-guards-breakfast) While funding, show the shortfall and the next level. When affordable, Build starts placement or Restore previews the original site. Confirm spends the resources and applies the change. The card can use the existing next-restoration slot. [Relic Rush results screen](../games/relic-rush/lua/screens.lua)
2. **Four slots show the current epoch.** Fill a slot for each confirmed required purchase, outline the current one and show the rest as silhouettes. Later epochs stay hidden. The epoch title names the story. Filling the fourth slot triggers its closing scene.
3. **The decoration shop holds the keepsake box and items for sale.** In Christmas Market the gift button can show the number of unplaced gifts.
4. **A chapter-end card follows the closing scene.** Show what has changed on the island and, when the occasion brings a keepsake, offer Place now and Later.

### Mockup

The [Christmas Market wireframe](mockups/chapter-progression.svg) illustrates the build card's ready and funding states, placement with Confirm and Cancel, a candle-lighting scene, and the gift box. The four slots track purchases within one Advent story. The candle marks its conclusion.

![Christmas Market build, placement, Advent and decoration wireframes](mockups/chapter-progression.svg)

## Implementation sketch

- Derive the epoch and its four slots from the ordered required purchases. Preserve waived ladder positions in existing saves. Use confirmation of the fourth purchase to trigger the closing scene once. Keep the first four Relic Rush purchases in their current order. On Workshop confirmation, resolve the quay repair and reply choice once for the same purchase. Retire the later paid Quay Steps gate and preserve access for existing saves. When laying out the later epochs, account for the purchase slot this frees.
- Use shared engine forms for the card and strip with each game's skin. Verify funding, placement, fixed-site repair and chapter-end states at 480 × 900 and 390 × 844. [Engine skins](UI_ENGINE.md#skins)
- Keep arrivals and scenes in each game's campaign data. Record an arrival once, resume an unread scene on reload, and condition optional exchanges on the residents present. Track who takes part and what changes in the game's story sheet. [Story writing guide](STORY_WRITING.md)
- Record dressing sets in the building catalogue and the wreath and strip states in the asset catalogue. [Building art](BUILDING_ART.md) · [Building registration](BUILDINGS.md)

## Open questions

- Which market occasion should light each Advent candle, including the last one?
- Which pieces of a landmark's dressing can the player move or store?
- Which optional purchases should compete for coins left after the next required building is funded?
