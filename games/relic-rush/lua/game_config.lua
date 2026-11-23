-- game_config.lua — the words and options of the shared match-3 screens, merged
-- over the engine's defaults (match3.game DEFAULTS): tables merge field by
-- field, lists replace.
return {
    app = {title = "Relic Rush - The Lost Valley", id = "relic-rush", clear = "#09211F",
        privacy_url = "https://github.com/corepunch/nile-archive/blob/main/docs/APP_PRIVACY.md"},
    menu = {title = {"RELIC RUSH"}, subtitle = "THE LOST VALLEY", town = "VISIT ISLAND"},
    campaign_dialogue = false,
    epochs = {"Epoch I", "Epoch II", "Epoch III", "Epoch IV", "Epoch V"},
    epoch_title = "Epochs",
    epoch_medal_names = {"Spring Camp", "Mill and Market", "Harbour Town", "Coastal Watch", "Sun Temple"},
    result = {visit = "COLLECT & VISIT ISLAND"},
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
    board = {
        tutorial_chain = "Match through the chained piece. Match that cell again to clear its plaque.",
        kudos = {"Brilliant!", "Magnificent!", "Legendary!", "Sunstorm!"},
        pieces = {
            campaign_prefix = "campaign-",
            story_prefix = "story-",
            resource_prefix = "resource-",
            crops = {["campaign-leaf"] = 7},   -- trim the transparent gutter for live pieces
        },
        background = {min_height=900, align_y=.35, motes={255, 228, 139, 70}},
    },
    notices = {
        reward_building = "Select a project to see its cost.",
        reward_replay = "Resources collected.",
        all_open = "Your whole island is open to explore.",
        quit = "Your board is saved. Tap Play to continue expedition %d.",
    },
    capsules = {show = {"coins", "supplies", "food"}},
    pause = {guide = "EXPLORER'S GUIDE", quit = "QUIT TO ISLAND", leaderboard = "LEADERBOARD"},
    leaderboard = {
        board = "stars",
        title = "Top explorers",
    },
    confirm = {title = "Restart this expedition?"},
    failed = {town = "VISIT ISLAND"},
    zone = {
        subtitle = "A NEW PLACE TO DISCOVER",
        cleared = "EXPEDITIONS CLEARED  %d / %d",
        earn = "CLEAR NEW EXPEDITIONS TO OPEN IT",
    },
    finale = {
        title = "Breakfast at the quay",
        lines = {
            {"THE SPRING RUNS TO THE QUAY AGAIN.", 16},
        },
    },
    complete = {
        title = "You won!",
        lines = {
            {"YOU COMPLETED ALL %d EXPEDITIONS.", 16},
        },
    },
    catalogue = {
        earlier = "RESTORE EARLIER WONDERS",
        poor = "MORE RESOURCES NEEDED",
    },
    debug = {victory = 1, catalogue_card = 37, narrator = "oren"},
}
