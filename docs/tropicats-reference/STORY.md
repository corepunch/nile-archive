# Tropicats: the serialized story, step by step

This is a navigable reference to the **bundled authored campaign**, not a playthrough or proof of the behavior of the live service. It records 70 chapters, 274 quests and 1,217 configured tasks. Start with a chapter below; each page lists every quest and task in serialized order, the associated scene triggers and the attributed localized quest setup and journal outcome. These entries preserve evidence but are not complete dialogue or a substitute for reading the linked source keys.

## How to read a chapter

- Chapter first levels and quest `level` fields come from `chapterconfig` and `questconfig`; each task lists its individual level/tier tokens exactly as serialized. A suffix such as `b` is a tier identifier. A `reach_rank` task has `none` for level tokens and its count is the rank gate. Do not infer a strict runtime sequence from array order, especially where `visual_order` is present.
- The action, item and target are distinct fields. `none` is the literal target and does not establish that the world never changes. A repair target identifies an encoded target, not independently verified on-screen behavior. Quest journal outcomes express the authored story; the runtime sequence and delivery are unverified.
- Task IDs in the tables use `quest ID`.`one-based index`, matching the configured dialogue `trigger_value`; these are a convenient address, not a separate questconfig field. Scene trigger entries may be stale or belong to an earlier task version. In particular `t5chp3_q3` and `t5chp5_q3` refer to task 5 although the current arrays have four tasks; do not count them as additional configured tasks.
- `loca_override` chooses the matching localized action when present. The config also contains localization keys and dialogue scenes not addressed by current arrays; their existence alone does not prove they are used. The `visual_order` strings are retained verbatim; their exact runtime interpretation is unverified.
- The quest file has a single top-level default reward of **10 diamonds**; it has no per-task reward fields. It does not prove identical live rewards, building income, or bonuses. A rank gate, item and repair target are reported only where encoded.

## Story arc map

The opening begins with rebuilding the fallen protective totem. Ava identifies deliberate sabotage, the tribe pursues a suspected dog, and Ragnaruff earns trust by rescuing the kittens. The elder’s deception and the ancestors’ conflict resolve the first mystery. Later, Cubby and Olivia marry and become parents; opening a harbor brings Blacktail and the Duchess.

The middle arcs move across islands and change focus repeatedly: inventors and Felicity’s farm lead to the Nordogs and family histories, then Furrenze, a crash and Blacktail’s capture. On Nordog Island, school and a cat–dog hockey rivalry lead into a rescue expedition. Alternate-world counterparts and crystals complicate the rescue; a hostile Sylvia is exposed. The final confrontation restores Blacktail, Elsie briefly inherits the crown, and the Chief takes it before a farewell with friends. See the individual quest outcomes for the evidence and exact placements; the index is a compressed orientation, not a replacement for them.

## Chapter index

Chapter names come from `quest.chapter.name_<N>`. Level ranges run from each configured chapter start through the level before the next; the final range ends at the highest quest tier referenced in chapter 70. They are an index, not proof of runtime unlock or display order.

| Chapter | Campaign levels | Quest titles in configured order |
| --- | ---: | --- |
| [Chapter 1: Totem Troubles](story/chapter-01.md) | 1–5 | The Great Totem |
| [Chapter 2: A Mew Beginning](story/chapter-02.md) | 6–10 | Home Is Where The Hut Is |
| [Chapter 3: The Totem Cutter](story/chapter-03.md) | 11–50 | Finding The Guard; The Guard's Breakfast; The Investigation!; Get To The Point |
| [Chapter 4: On The Prowl](story/chapter-04.md) | 51–90 | To Catch A "Monster"; The Wildlife Expert; The Book Thief!; Keep Calm And Take Catnip! |
| [Chapter 5: Eternal Enemies?](story/chapter-05.md) | 91–130 | Meowgic Matters; Partying With The Enemy; Where's The Shaman?; Spell Crafting |
| [Chapter 6: Heating Up](story/chapter-06.md) | 131–170 | The Sun Ritual; No Shrine? No Ritual!; Ancestor Apology; Well, Well, Well... |
| [Chapter 7: A Fair Trial](story/chapter-07.md) | 171–210 | Prisoner Pup; Bath Time; Message In A Bottle; Dog Gone |
| [Chapter 8: Who's A Good Boy?](story/chapter-08.md) | 211–250 | Kitten Rescue; In The Dog House; The Tropidogs?; Shooting Stars |
| [Chapter 9: The Great Kikuna](story/chapter-09.md) | 251–290 | The Elder's Prophecy; The Birth Of A Village; Village Life Or Wild Life?; The Revelation |
| [Chapter 10: Taming Tika](story/chapter-10.md) | 291–330 | Where Cats Belong; The Founder's Return; The Big Apawlogy; A Purrfect Purrposal |
| [Chapter 11: I Do, I Mew](story/chapter-11.md) | 331–370 | The House Cat; Love Birds; Pagoda Of Purrs; Cat Cruise |
| [Chapter 12: Purrenthood](story/chapter-12.md) | 371–410 | Kitten Shower; Housewarming; Cold Paws; Welcome To Kittengarden |
| [Chapter 13: The Beacon](story/chapter-13.md) | 411–450 | Tropikittens!; Attracting Attention; Let There Be Light; Safe Harbor |
| [Chapter 14: Pirates of the Sea of Slobber](story/chapter-14.md) | 451–490 | Black Sails; Shiver Me Timbers!; Tavern Fever; Watchers In The Night |
| [Chapter 15: Mummy's Boy](story/chapter-15.md) | 491–530 | The Dreaded Duchess; Tea For Mew; Meeting Mummy; Impurrial Pride |
| [Chapter 16: Bad Romance](story/chapter-16.md) | 531–570 | Split Purrsonality; Garden Of Love; The Blacktail Agenda; Setting Up Home |
| [Chapter 17: Enter The Inventor](story/chapter-17.md) | 571–610 | Shipwrecked; Age Of Purrgress; A Miracle Cure; Mass Purrduction |
| [Chapter 18: Age Of Purrgress](story/chapter-18.md) | 611–650 | Pigeon Post; Cat Me If You Can; Mee Li's Market; A Mew Adventure |
| [Chapter 19: Felicity's Farm](story/chapter-19.md) | 651–690 | Lay Of The Land; Farmhouse Warming; Running Water; Soil 'N Trouble |
| [Chapter 20: Fowl Play](story/chapter-20.md) | 691–730 | Cooped Up; Are You Chicken?; Ghost Hunt; Body Purrsession |
| [Chapter 21: A Way Home?](story/chapter-21.md) | 731–770 | It's Alive!; The Allure Of Lures; Seeing Redd; Self Belief |
| [Chapter 22: The Dream Harvest](story/chapter-22.md) | 771–810 | V Is For Veggies; Reap What You Sow; Farewell, Felicity; Northward Bound |
| [Chapter 23: A Hero's Welcome](story/chapter-23.md) | 811–850 | Ashes To Ashes; Tea For Talk; Ain't Nothing But A Howldog; Return Of The King |
| [Chapter 24: Dogs Of War](story/chapter-24.md) | 851–890 | Wolf Food; The Hall of Honor; Give Peace A Chance?; The Summit |
| [Chapter 25: A Trial Of Guts](story/chapter-25.md) | 891–930 | Hero Or Zero?; The Trial Of Guts; Fenrir’s Favor; One Sick Doggy |
| [Chapter 26: Hail To The King](story/chapter-26.md) | 931–970 | Who Poisoned The King?; Repair The Nordog Throne; Mother Knows Best; An Ancient Truth |
| [Chapter 27: The Mother's Truth](story/chapter-27.md) | 971–1010 | The Mother's Truth; The Return Of Kata; The Family Reunion; Secrets Of The Elder |
| [Chapter 28: Toil And Trouble](story/chapter-28.md) | 1011–1050 | A Mixed Up Mind; Toil And Trouble; The Trial Of The Century; The Doomed Groom |
| [Chapter 29: Trouble In Paradise](story/chapter-29.md) | 1051–1090 | The Big Wedding; The Wedding Site; The Missing Groom; The Long-Delayed Wedding |
| [Chapter 30: The Truth About Chief](story/chapter-30.md) | 1091–1130 | The Tropicat Parents; Family Secrets; The Ceremony; Journey To Catton Abbey |
| [Chapter 31: The Shabby Abbey](story/chapter-31.md) | 1131–1170 | Homecoming; Catton Abbey Reborn; The Legend Of Ava; Of Duchesses And Toms |
| [Chapter 32: Unfortunate Son](story/chapter-32.md) | 1171–1210 | From The Highlands; Lairds And Ladies; Battle Of The Butlers; Where's That Pirate? |
| [Chapter 33: Courting Disaster](story/chapter-33.md) | 1211–1250 | Down On The Farm; No Party Like A Tropicat Party; The Club Conspiracy; A Tropicat Party Don't Stop |
| [Chapter 34: Ode To A Highland Cat](story/chapter-34.md) | 1251–1290 | Dial "M" For Meowrder; Ode To A Highland Cat; McYowler Is Missing; Pigeon Practice |
| [Chapter 35: Whodunit?!](story/chapter-35.md) | 1291–1330 | The Unsent Letter; What's Up With Blacktail?; A Meowtive To Kill; The Butler Did It? |
| [Chapter 36: The Ham Of The Whiskervilles](story/chapter-36.md) | 1331–1370 | The Hamster From Hell; Lair Of The Hamster; Pirate Training; Ham's End |
| [Chapter 37: Night Of The Living Cat](story/chapter-37.md) | 1371–1410 | Trail Of The Highland Cat; A Second Chance; Getting To Know Mew; McYowler's Wish |
| [Chapter 38: The Highlander And The Duchess](story/chapter-38.md) | 1411–1450 | The Big Question; The Wedding Planner; Highland Love; Elsie Of The Bells |
| [Chapter 39: Artistic Differences](story/chapter-39.md) | 1451–1490 | De-Composition; La Gatta Bianca; The Prima Donna; The Play's The Thing |
| [Chapter 40: Purrformance Of A Lifetime](story/chapter-40.md) | 1491–1530 | The Dueling Divas; Setting The Scene; Three's Company; Worked To Purrfection |
| [Chapter 41: Of Art And Memory](story/chapter-41.md) | 1531–1570 | On With The Show; Papa Knows Best... ish; Memory Refresher; The Producers |
| [Chapter 42: The Worst Show On Earth](story/chapter-42.md) | 1571–1610 | An Actor's Life For Me; Public Relations; Getting Worse All The Time; Le Due Farfalle |
| [Chapter 43: Renaissance Cat](story/chapter-43.md) | 1611–1650 | The Gathering Storm; Oh Ship!; Renaissance Cat; Ava's Wish |
| [Chapter 44: Dubious Parentage](story/chapter-44.md) | 1651–1690 | How Ava Got Her Groove Back; The Meowna Lisa; A Bigger Boat; Rapid Transit |
| [Chapter 45: The Mother Of Invention](story/chapter-45.md) | 1691–1730 | The Flight Plan; Total Recall; Daddy Knows Worst; Moving On |
| [Chapter 46: Flight Of The Tropicats](story/chapter-46.md) | 1731–1770 | The Tower of Hissa; Flight School; Flappy Cats; Flight Of The Tropicats |
| [Chapter 47: Unhappy Landings](story/chapter-47.md) | 1771–1810 | Crash Course; The Two Meowsters; Felicity's Secret; The Dreams Of Cats |
| [Chapter 48: Captains Of Industry](story/chapter-48.md) | 1811–1850 | Eureka!; Business Boom; Scaling Up; Anything For Love |
| [Chapter 49: Felicity's Feast](story/chapter-49.md) | 1851–1890 | Cookin' Up Somethin' Good; Supply And Demand; Yes, Chef!; Purrnout |
| [Chapter 50: All Work And No Play](story/chapter-50.md) | 1891–1930 | The Customer Is King; Union Dues; I Quit!; Felicity's Choice |
| [Chapter 51: New Purrspectives](story/chapter-51.md) | 1931–1970 | Transcendental Meowditation; The Therapist Is In; Slow Business; Chilling Out |
| [Chapter 52: Furgive And Furget](story/chapter-52.md) | 1971–2010 | A Second Chance; The Second First Date; Mo' Kittens, Mo' Problems; Anchors Aweigh |
| [Chapter 53: Purrcini's Cannon March](story/chapter-53.md) | 2011–2050 | Purrcini's Revenge; Meows In The Time Of War; The Rescue; The Last Option |
| [Chapter 54: A Meow For Help](story/chapter-54.md) | 2051–2090 | Spreading The Word; The Duchess's Vow; Taka's Peril; Sylvia's Scheme |
| [Chapter 55: Herding Kittens](story/chapter-55.md) | 2091–2130 | Kitty It's Cold Outside; Adventures In Kittensitting; Return Of The King; School's In For Winter |
| [Chapter 56: Too Mewl For School](story/chapter-56.md) | 2131–2170 | School Kittens; A Place To Learn; Neither Dog Nor Cat; One Bad Kitty |
| [Chapter 57: Ain't Misbehavin'](story/chapter-57.md) | 2171–2210 | Leapin' Libraries!; Class Disruption; Escape From Detention; Way Of The Dog |
| [Chapter 58: To Furgive Is Divine](story/chapter-58.md) | 2211–2250 | Hiss And Make Up; Cat For Teacher; Catwatching; Of Canines And Codes |
| [Chapter 59: A Song Of Ice And Felines](story/chapter-59.md) | 2251–2290 | The Madness Of Dean Gruffgar; Teaching The Unteachable; Meowgical Deeds; The Meowgic Of Learning |
| [Chapter 60: Cats Rule, Dogs Drool](story/chapter-60.md) | 2291–2330 | The Big Event; Taka Taka; Tourist Season; Cats Vs. Dogs |
| [Chapter 61: Sylvia's Scheme](story/chapter-61.md) | 2331–2370 | No Winners, No Losers; Winter's End; Potential Energy; Forming A Plan |
| [Chapter 62: Lily The Learned](story/chapter-62.md) | 2371–2410 | The King's Support; School's Out For Winter; The Journey Begins; Playing Hooky |
| [Chapter 63: Yarn Theory](story/chapter-63.md) | 2411–2450 | Into The Takaverse; The New Tropicats; A New Totem; A Message From Beyond |
| [Chapter 64: Hisstaken Identity](story/chapter-64.md) | 2451–2490 | Never Too Many Friends; Three's Company; The Trials Of Olivia; Problem Child |
| [Chapter 65: Be Mine](story/chapter-65.md) | 2491–2530 | The Source Of Meowgick; Be Mine; The Case Of The Missing Cubbies; The Last Temptation Of Cubby |
| [Chapter 66: The Return Of Blacktail](story/chapter-66.md) | 2531–2570 | Crystal Collection; Do It For Blacktail; A Pirate's Life For She; Elsie Envy |
| [Chapter 67: Tropicruel Cats](story/chapter-67.md) | 2571–2610 | Karate Cat; Claws Out; Nibblesby's Task; The Royal Lie |
| [Chapter 68: Cat Scratch Fever](story/chapter-68.md) | 2611–2650 | There's Something About Sylvia; Good Riddance To Bad Cats; The Cat Came Back; Another Totem, Another Axe |
| [Chapter 69: Impurrial Interference](story/chapter-69.md) | 2651–2690 | Rulers And Mewlers; Sylvia's Second Chance; A Dog's Life; Hairball To The Throne |
| [Chapter 70: The Fate of the Crown](story/chapter-70.md) | 2691–2730 | In With The Mew; Queen Elsie I; Hail To The Chief; A Farewell To Paws |

## Story-design observations

- **Let a repair change the question.** Rebuilding the totem resolves an immediate need, then the cut marks turn the same object into evidence. Later, the restored observatory helps Ragnaruff navigate and also introduces a new ancestral mystery. These are useful patterns for Relic Rush: give an artifact a practical result and a separate evidentiary meaning.
- **Make construction answer a character's immediate problem.** Cubby's grill supplies breakfast before investigation; Olivia's study holds the encyclopedia needed to identify tracks. For Christmas Market, a stall or decoration could similarly satisfy a person's wish and make the next interaction possible, without needing a villain.
- **Let social consequences generate the next quest.** Ava's attempted trap damages Lily's trust, so the tribe must repair that relationship before approaching Taka. The setup, individual task actions and outcome in chapter 5 show a practical way to carry one choice into a new objective.
- **Give long arcs local endings.** Ragnaruff's rescue changes his standing with the tribe in chapter 8; the elder's scheme resolves in chapter 10. Subsequent family and travel stories supply new aims. These are observations about the authored quest text, not measurements of pacing in live play.

## Sources and scope

- [Chapter configuration](../../reference/tropicats-analysis/config/chapterconfig.json): `chapters[]`, including first levels and opening quest IDs.
- [Quest configuration](../../reference/tropicats-analysis/bundled/157_questconfig): `quests[]` arrays, order, character, targets and default `reward`. Each quest heading names its exact source ID.
- [English localization](../../reference/tropicats-analysis/bundled/english.json): `quest.chapter.name_<N>`, `quest.title.<quest>`, `quest.description.<quest>`, `quest.roundup.<quest>`, `quest.task<N>.action.<quest>[.<override>]`, and `dialogue.story.<scene>.<sentence>`. Localized setup and outcome entries are explicitly attributed; braces are source placeholders.
- [Story dialogue configuration](../../reference/tropicats-analysis/config/storydialogueconfig.json): `dialogue_setup` supplies scene IDs, triggers and values; `dialogue_details` contains staging and draft text. The localization is the stronger source for final wording. Search the listed scene ID in both files to inspect a scene.
- [Existing extraction analysis](../TROPICATS_ANALYSIS.md) explains inventory, tiers, evidence limits and extraction. [Earlier research](../../research_notes/Прогрессия%20June%20Journey%20и%20Tropicats/tropicats_story.md) is secondary context and should not override the bundled tables.

The last configured chapter starts at level 2691; its final quest includes tier `2730c` and rank 137. The inspected campaign tables have no chapter 71. This establishes the bundle endpoint, not the absence of events, post-story level rotation, server content or alternate releases. Collection events and post-story level selection have separate bundled configuration and are outside this quest-by-quest campaign reference. The extracted configuration establishes authored data, not what an encrypted client or live account actually showed.

## Reproduce and verify

Run `python3 tools/tropicats_story_reference.py --check` from the repository root. It recomputes the pages, checks every source quest appears once, verifies parallel task arrays, compares generated files and checks the chapter-file count. It does not validate narrative truth against a playthrough or prove that every localization and scene is used. Remove `--check` to regenerate.
