# Each epoch tells one chapter in four purchases

**Design proposal for Relic Rush and Christmas Market.** The purchase ladders and scenes already exist. The four-purchase story grouping below is proposed. The epoch strip, build card and keepsake box are proposed UI. Nile Archive keeps its June's Journey structure.

## The epoch is the chapter

Keep the rhythm of Cradle of Rome. The player matches pieces, banks resources and spends them on the next building. A purchase has a practical consequence worth showing on the build card. The Spring Well puts water buckets on future boards. Repairing the Quay Steps opens a route the crew could see from camp but couldn't reach. [Rome's twenty purchases](cradle-of-rome-reference/GAME_DESIGN.md#5-every-building-in-the-original-20-purchase-ladder)

- **Tell one story in four required purchases.** Give the epoch a question or wish. The first purchase sets it up, the middle two move it forward, and confirming the fourth pays it off. Twenty required purchases give each game five story epochs. Optional buildings, decorations and citizen arrivals do not fill a slot. [Relic Rush ladder](../games/relic-rush/lua/economy.lua) · [Christmas Market ladder](../games/christmas-market/lua/economy.lua)
- **Let citizens add scenes between purchases.** Use the building and play conditions that already bring someone to town. Their arrival gives the writer an occasion for an exchange with another character. The player can finish the epoch whether or not an optional resident has arrived.
- **The next level funds the next purchase.** Design prices around forward play and reserve the resources needed for required purchases before offering optional spending. In Relic Rush Chapter 1, Claim banks only the resources actually matched. A first clear can make a purchase available. The story moves when the player confirms a build or repair, or a citizen arrives. Use this rule when revising later Relic Rush chapters, which still have first-clear scenes. [Relic Rush campaign milestones](../games/relic-rush/docs/story.md#campaign-milestones)

## Worked example · Relic Rush Epoch 1, A Light Below

**Is someone answering Mara’s lamp?** Keep the four existing story scenes and make their buildings the first four required purchases. The live ladder puts the Trapper’s Cabin before the Workshop and the Water Mill before the Quay Steps. In this proposal both move to the start of epoch two, with their upgrades and citizen events. [Current purchase order](../games/relic-rush/lua/economy.lua) · [Chapter 1 script](../games/relic-rush/docs/story.md#chapter-1-a-light-below)

| Purchase | Eligible after clear | What the player does | What follows |
| --- | --- | --- | --- |
| 1 · Expedition Camp | 1 | Choose a site for the camp. | Hammer gems become available. Mara signals from the lookout and gets two flashes back. It could be a reflection. |
| 2 · Spring Well | 4 | Restore the well on its original site. | Water buckets enter the board. Tomas accepts a place at camp and tells Mara the electric relay is dead. |
| 3 · Artisan Workshop | 7 | Choose a site for the workshop. | Cut blocks enter the board. Tomas shows Mara how to size a replacement tread to fit the old cuts. The carpenter can now join if the player makes a match of five. |
| 4 · Quay Steps | 10 | Restore the steps where they stood. | The new tread fits the notch. Cut to the ancient keeper setting that height for dry footing at high tide. Back in the present, the crew opens the viewing shutter and sees the signal change to three flashes. Someone is working the far shutter by hand. The player chooses who answers, and the epoch closes. |

The keeper appears at the instant the player can understand his decision by looking at their own repair. His scene belongs to the past. The crew learns what it can observe from the newly accessible shutter. Future repairs should likewise open a route, enable someone's work or bring people together. The present-day town is the one the player builds.

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

1. **One build card shows the next required purchase.** Show its picture, name, price and practical effect. For a story landmark, add one line from the person who needs it. While funding, show the shortfall and the next level. When affordable, Build starts placement or Restore previews the original site. Confirm spends the resources and applies the change. The card can use the existing next-restoration slot. [Relic Rush results screen](../games/relic-rush/lua/screens.lua)
2. **Four slots show the current epoch.** Fill a slot for each confirmed required purchase, outline the current one and show the rest as silhouettes. Later epochs stay hidden. The epoch title names the story. Filling the fourth slot triggers its closing scene.
3. **The decoration shop holds the keepsake box and items for sale.** In Christmas Market the gift button can show the number of unplaced gifts.
4. **A chapter-end card follows the closing scene.** Show what has changed on the island and, when the occasion brings a keepsake, offer Place now and Later.

### Mockup

The [Christmas Market wireframe](mockups/chapter-progression.svg) illustrates the build card's ready and funding states, placement with Confirm and Cancel, a candle-lighting scene, and the gift box. The four slots track purchases within one Advent story. The candle marks its conclusion.

![Christmas Market build, placement, Advent and decoration wireframes](mockups/chapter-progression.svg)

## Implementation sketch

- Derive the epoch and its four slots from the ordered required purchases. Preserve waived ladder positions in existing saves. Use confirmation of the fourth purchase to trigger the closing scene once. For the proposed Relic Rush reorder, check funding, Dynamite’s later introduction and the trapper’s early arrival window. Verify that the Quay Steps close epoch one with or without the carpenter.
- Use shared engine forms for the card and strip with each game's skin. Verify funding, placement, fixed-site repair and chapter-end states at 480 × 900 and 390 × 844. [Engine skins](UI_ENGINE.md#skins)
- Keep arrivals and scenes in each game's campaign data. Record an arrival once, resume an unread scene on reload, and condition optional exchanges on the residents present. Track who takes part and what changes in the game's story sheet. [Story writing guide](STORY_WRITING.md)
- Record dressing sets in the building catalogue and the wreath and strip states in the asset catalogue. [Building art](BUILDING_ART.md) · [Building registration](BUILDINGS.md)

## Open questions

- Which market occasion should light each Advent candle, including the last one?
- Which pieces of a landmark's dressing can the player move or store?
- Which optional purchases should compete for coins left after the next required building is funded?
