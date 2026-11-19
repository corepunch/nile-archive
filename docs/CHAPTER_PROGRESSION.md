# Each epoch tells one chapter in four purchases

**Design proposal for Relic Rush and Christmas Market.** Relic Rush implements the four opening building quests and their next-building card. The epoch strip and keepsake box are proposed UI. Nile Archive keeps its June's Journey structure.

## The epoch is the chapter

Keep the rhythm of Cradle of Rome. The player matches pieces, banks resources and spends them on the next building. A purchase has a practical consequence worth showing on the build card. The Spring Well puts water buckets on future boards. The Sawmill supplies timber for Tomas’s cable reel. [Rome's twenty purchases](cradle-of-rome-reference/GAME_DESIGN.md#5-every-building-in-the-original-20-purchase-ladder)

- **Tell one story in four required purchases.** Give the epoch a question or wish. The first purchase sets it up, the middle two move it forward, and confirming the fourth pays it off. Twenty required purchases give each game five story epochs. Optional buildings, decorations and citizen arrivals do not fill a slot. [Relic Rush ladder](../games/relic-rush/lua/economy.lua) · [Christmas Market ladder](../games/christmas-market/lua/economy.lua)
- **Let citizens add scenes between purchases.** Use the building and play conditions that already bring someone to town. Their arrival gives the writer an occasion for an exchange with another character. The player can finish the epoch whether or not an optional resident has arrived.
- **Requests run beside the purchases.** Relic Rush's crew asks for smaller things between two purchases. A request has a piece of its own on the boards and a scene when it is handed in, and it never holds a purchase. Two can be open at once, beside the next building. The broken cable opens a hands-on shutter investigation. The Village still opens the long-flash reply choice. [Crew requests](../games/relic-rush/docs/story.md#crew-requests)
- **The next level funds the next purchase.** Design prices around forward play and reserve the resources needed for required purchases before offering optional spending. In Relic Rush Chapter 1, Claim banks only the resources actually matched. A first clear can make a purchase available. The story moves when the player confirms a build or repair, or a citizen arrives. Use this rule when revising later Relic Rush chapters, which still have first-clear scenes. [Relic Rush campaign milestones](../games/relic-rush/docs/story.md#campaign-milestones)

`python3 tools/scenario_overview.py --epoch 1 --capture` renders an epoch of both games as they are now: its four purchases, prices, board changes, levels, scenes and town. [Scenario overview](STORY_WRITING.md#scenario-overview)

## Worked example · Relic Rush Epoch 1, A Light Below

For the shipped Well, Hunter’s Hut, Sawmill and Village order and the cable investigation, use the [first-epoch playtest](../games/relic-rush/docs/epoch-one-quests.md).

| Confirmed purchase | Board reward | What the player hears |
| --- | --- | --- |
| Well | Water buckets earn Food | Mara draws fresh water. Elena sees a light flash and takes the scrap from the wet rope. |
| Hunter’s Hut | Hammer | Tomas reaches for his father’s hammer. Mara asks him about the light, and he tells her the relay was cut. |
| Sawmill | Timber earns Supplies | Tomas makes a reel from the offcuts and points Mara toward the loose cable. |
| Village | Bomb replaces Hammer | The village takes up the night watch. The keeper’s orders give Mara a reason to signal again. The reply changes from two flashes to three. |

The cable hand-in opens a separate experiment with a spare shutter. [Story and choices](../games/relic-rush/docs/story.md#chapter-1-a-light-below)

## Citizens are characters

Give each citizen a name, a workplace, a reason to stay and someone they have business with. Introduce them doing their job. Bring them back when another resident or a later purchase gives them something new to do. A short exchange at a stall or a detail the player can tap on a return visit can carry a relationship between the larger scenes.

- **People the chapter depends on arrive reliably.** Restoring the well brings Tomas into camp. At the Sawmill, Tomas tells Mara where to look for the cable. By the quay, the player can choose him to answer the signal. His citizen event belongs to the Well. The Hunter’s Hut introduces him in dialogue.
- **Give Rome-style citizen feats a scene.** Rome pairs an owned building with a feat such as a five-piece match, two successive combos, or collecting a resource in one level. Relic Rush already uses these conditions at its own scale. With the Sawmill built, a match of five brings the carpenter and raises matched timber from five Supplies to six. Let Mara welcome the carpenter at the bench when the player returns to town. With the Water Mill built, a two-stage cascade brings the miller. Use the same arrival event for the exchange and the existing perk. [Rome’s citizen challenges](cradle-of-rome-reference/GAME_DESIGN.md#7-citizen-challenges-buildings-can-have-a-second-payoff) · [Relic Rush citizen events](../games/relic-rush/lua/user_events.lua)
- **Christmas Market already shows how this can feel.** When Agnes opens the bakery, Henrik sends Pip with a penny for a bun he insists he doesn't want. Agnes saves one at the back of the tray. Later, Henrik's workshop gives him a window facing hers. Still later, a tap at the bakery reveals two cups on the sill. The player gets to see a relationship change through the ordinary business of running the market. Use the existing cast, stalls and tap bubbles for more of these encounters. [Christmas Market script](../games/christmas-market/docs/story.md)

For Christmas Market, group the existing wishes and scenes into five four-purchase stories. Four Advent Sundays followed by Christmas Eve give those five epochs a natural shape. Each Sunday’s fourth purchase can bring the neighbours together to light a candle. The fifth epoch pays off their preparations on Christmas Eve.

## Decorations

1. **Landmarks bring their own dressing.** On confirmation, matching pieces appear in the clearance ring, such as lamps by the bakery or palms at the well. Players who never open the decoration shop still get a lived-in town.
2. **Keepsakes have an occasion.** A new resident or a chapter-closing build can bring something specific to that event, such as lanterns for the market. Keep movable gifts in a box until the player wants to place them. Relic Rush levels award matched resources only.
3. **Extra decorations are optional purchases.** Players can spend spare Coins or Bells and move or store the pieces. Decoration counts add neither a campaign requirement nor a level payout.

## UI

1. **One build card shows the next required purchase.** Give the card a short quest title, one or two sentences of narration saying who needs the building and why, the building name and picture, its wallet cost and its practical effect. Characters speak in the scenes, which play once. The card never quotes them, so a player who reopens it reads the task and no repeated dialogue. Tropicats writes its quest setups the same way. [The Guard’s Breakfast](tropicats-reference/story/chapter-03.md#chp3_q2-the-guards-breakfast) While funding, show the shortfall as resource amounts and the next level. When affordable, Build starts placement or Restore previews the original site. Confirm spends the resources and applies the change. The results card says one thing about that purchase: the amounts it still needs after the win, or that it is ready to build. The quest and its narration stay on the build card. [Relic Rush results screen](../games/relic-rush/lua/screens.lua)
2. **Four slots show the current epoch.** Fill a slot for each confirmed required purchase, outline the current one and show the rest as silhouettes. Later epochs stay hidden. The epoch title names the story. Filling the fourth slot triggers its closing scene.
3. **The decoration shop holds the keepsake box and items for sale.** In Christmas Market the gift button can show the number of unplaced gifts.
4. **A chapter-end card follows the closing scene.** Show what has changed on the island and, when the occasion brings a keepsake, offer Place now and Later.

### Mockup

The [Christmas Market wireframe](mockups/chapter-progression.svg) illustrates the build card's ready and funding states, placement with Confirm and Cancel, a candle-lighting scene, and the gift box. The four slots track purchases within one Advent story. The candle marks its conclusion.

![Christmas Market build, placement, Advent and decoration wireframes](mockups/chapter-progression.svg)

## Implementation sketch

- Derive the epoch and its four slots from the ordered required purchases. Preserve waived ladder positions in existing saves. Use confirmation of the fourth purchase to trigger the closing scene once. Keep the first four Relic Rush purchases in their current order. The Sawmill adds timber to the boards. The Village opens the reply choice once.
- Use shared engine forms for the card and strip with each game's skin. Verify funding, placement and chapter-end states at 480 × 900 and 390 × 844. [Engine skins](UI_ENGINE.md#skins)
- Keep arrivals and scenes in each game's campaign data. Record an arrival once, resume an unread scene on reload, and condition optional exchanges on the residents present. Track who takes part and what changes in the game's story sheet. [Story writing guide](STORY_WRITING.md)
- Record dressing sets in the building catalogue and the wreath and strip states in the asset catalogue. [Building art](BUILDING_ART.md) · [Building registration](BUILDINGS.md)

## Open questions

- Which market occasion should light each Advent candle, including the last one?
- Which pieces of a landmark's dressing can the player move or store?
- Which optional purchases should compete for coins left after the next required building is funded?
