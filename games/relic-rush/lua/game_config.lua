-- game_config.lua — the words and options of the shared match-3 screens, merged
-- over the engine's defaults (match3.game DEFAULTS): tables merge field by
-- field, lists replace.
local l10n = require("l10n")
local tr = l10n.tr

return {
    app = {title = "Relic Rush - The Lost Valley", id = "relic-rush", clear = "#09211F",
        privacy_url = "https://github.com/corepunch/nile-archive/blob/main/docs/APP_PRIVACY.md"},
    menu = {title = {tr("RELIC RUSH")}, subtitle = tr("THE LOST VALLEY"), town = tr("VISIT ISLAND")},
    campaign_dialogue = false,
    epochs = {tr("Epoch I"), tr("Epoch II"), tr("Epoch III"), tr("Epoch IV"), tr("Epoch V")},
    epoch_title = tr("Epochs"),
    -- TRANSLATORS: the medal won for finishing each epoch, named for what the town built in it
    epoch_medal_names = {tr("Spring Camp"), tr("Mill and Market"), tr("Harbour Town"), tr("Coastal Watch"), tr("Sun Temple")},
    packs = {"relics", "jewels", "resources"},
    transitions = {
        style = "wipe",
        theme = {
            motif = "leaves",
            face = {"#3F7D5C", "#163A2C"},
            face_alt = {"#2F6E73", "#123A3E"},
            rim = "#E5B24A",
            accent = "#FFE7A3",
            bands = {"#E5B24A", "#EBD9A8", "#3F7D5C", "#163A2C"},
            lights = {"#FFE7A3", "#C8452E"},
            drift = "#4E9A4F",
            drift_shade = "#1F5132",
            drift_light = "#7CC35E",
            badge = "#163A2C",
        },
    },
    speech = {scale = 1.5, name = 22.5},
    region_speaker = "sela",
    town_tip = {
        {"sela", tr("Look, we have enough to build!")},
        {"sela", tr("This epoch’s projects are listed at the top left. Tap one that says Ready to build.")},
    },
    board = {
        tutorial_chain = tr("Match through the chained piece. Match that cell again to clear its plaque."),
        -- TRANSLATORS: praise over the board for ever bigger cascades; "Sunstorm" is a made-up word
        kudos = {tr("Brilliant!"), tr("Magnificent!"), tr("Legendary!"), tr("Sunstorm!")},
        pieces = {
            campaign_prefix = "campaign-",
            story_prefix = "story-",
            resource_prefix = "resource-",
            crops = {["campaign-leaf"] = 7},   -- trim the transparent gutter for live pieces
        },
        background = {min_height=900, align_y=.35, motes={255, 228, 139, 70}},
    },
    notices = {
        reward_building = tr("Select a project to see its cost."),
        reward_replay = tr("Resources collected."),
        all_open = tr("Your whole island is open to explore."),
        quit = tr("Your board is saved. Tap Play to continue expedition %d."),
    },
    capsules = {show = {"coins", "supplies", "food"}},
    pause = {guide = tr("EXPLORER'S GUIDE"), quit = tr("QUIT TO ISLAND"), leaderboard = tr("LEADERBOARD")},
    leaderboard = {
        board = "stars",
        title = tr("Top explorers"),
    },
    confirm = {title = tr("Restart this expedition?")},
    failed = {town = tr("VISIT ISLAND")},
    zone = {
        subtitle = tr("A NEW PLACE TO DISCOVER"),
        cleared = tr("EXPEDITIONS CLEARED  %d / %d"),
        earn = tr("CLEAR NEW EXPEDITIONS TO OPEN IT"),
    },
    finale = {
        title = tr("Breakfast at the quay"),
        lines = {
            {tr("THE SPRING RUNS TO THE QUAY AGAIN."), 16},
        },
    },
    complete = {
        title = tr("You won!"),
        lines = {
            {tr("YOU COMPLETED ALL %d EXPEDITIONS."), 16},
        },
    },
    catalogue = {
        title = tr("Build your valley"),
        earlier = tr("RESTORE EARLIER WONDERS"),
        poor = tr("MORE RESOURCES NEEDED"),
    },
    debug = {victory = 1, catalogue_card = 37, narrator = "oren"},
}
