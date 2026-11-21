-- game_config.lua — the words and options of the shared match-3 screens, merged
-- over the engine's defaults (match3.game DEFAULTS): tables merge field by
-- field, lists replace.
return {
    app = {title = "Relic Rush - The Lost Valley", id = "relic-rush", clear = "#09211F"},
    menu = {title = {"RELIC RUSH"}, subtitle = "THE LOST VALLEY", town = "VISIT ISLAND"},
    corner_close = true,
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
    region_speaker = "mara",
    board = {
        kudos = {"Brilliant!", "Magnificent!", "Legendary!", "Sunstorm!"},
        pieces = {
            campaign_prefix = "campaign-",
            story_prefix = "story-",
            resource_prefix = "resource-",
            crops = {["campaign-leaf"] = 7},   -- trim the transparent gutter for live pieces
        },
        background = {opacity=220, shade={5, 30, 29, 35}, motes={255, 228, 139, 70}},
    },
    notices = {
        reward_building = "Resources banked. Tap Build for the next restoration.",
        reward_story = "Resources banked. Tap Build for the next restoration.",
        reward_replay = "Resources banked. Tap Build for the next restoration.",
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
    failed = {title = "One more adventure?", subtitle = "THE RUINS WILL WAIT FOR YOU.", town = "VISIT ISLAND"},
    zone = {
        subtitle = "A NEW PLACE TO DISCOVER",
        cleared = "EXPEDITIONS CLEARED  %d / %d",
        earn = "CLEAR NEW EXPEDITIONS TO OPEN IT",
    },
    finale = {
        title = "To be continued...",
        lines = {
            {"THE QUAY IS SAFE. OTHER LIGHTS ARE WAITING.", 16},
            {"Your island stays open to build and explore.", 16},
        },
        button = "BACK TO MY ISLAND",
    },
    complete = {
        title = "You won!",
        lines = {
            {"YOU COMPLETED ALL %d EXPEDITIONS.", 16},
            {"Your island stays open to build and explore.", 16},
        },
        button = "BACK TO MY ISLAND",
    },
    card = {
        back = "BACK TO ISLAND",
        moving = "HOLD AND DRAG ON THE ISLAND TO MOVE",
        locked = "COMPLETE MORE LEVELS TO RESTORE THIS WONDER",
    },
    catalogue = {
        title = "Build your valley",
        close = "BACK TO ISLAND",
        categories = {
            {"all", "All treasures"},
            {"wonder", "Story wonders"},
            {"building", "Buildings"},
            {"tree", "Trees"},
            {"bush", "Shrubs"},
            {"flower", "Flowers"},
            {"statue", "Monuments"},
            {"water", "Water gardens"},
            {"garden", "Garden furniture"},
            {"camp", "Expedition supplies"},
            {"animal", "Wildlife"},
            {"rock", "Rocks & crystals"},
        },
        category = "building",
        built = "RESTORED",
        complete = "COMPLETE EXPEDITION %d",
        earlier = "RESTORE EARLIER WONDERS",
        poor = "MORE RESOURCES NEEDED",
        reserved = "RESOURCES RESERVED FOR RESTORATION",
        full = "ISLAND IS FULL",
    },
    debug = {victory = 1, catalogue_card = 37, narrator = "tomas"},
}
