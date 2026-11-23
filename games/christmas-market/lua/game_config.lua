-- game_config.lua — the words and options of the shared match-3 screens, merged
-- over the engine's defaults (match3.game DEFAULTS): tables merge field by
-- field, lists replace.
return {
    app = {title = "Christmas at Bellmere", id = "christmas-market", clear = "#09211F",
        privacy_url = "https://github.com/corepunch/nile-archive/blob/main/docs/APP_PRIVACY.md"},
    menu = {title = {"CHRISTMAS"}, title_em = 68, subtitle = "AT BELLMERE", subtitle_em = 40, play = "PLAY",
        town = "VISIT MARKET", continue_in_town = true},
    campaign_dialogue = true,
    epochs = {"First Advent", "Second Advent", "Third Advent", "Fourth Advent", "Christmas"},
    epoch_title = "Advent & Christmas",
    result = {visit = "COLLECT & VISIT MARKET"},
    transitions = {
        style = "wipe",
        theme = {
            motif = "snow",
            face = {"#C62F35", "#7A1420"},
            face_alt = {"#2E8B4F", "#15532D"},
            rim = "#F2C14E",
            accent = "#FFFFFF",
            bands = {"#F2C14E", "#FFF8EE", "#1E6B3E", "#B3202A"},
            lights = {"#FF4A4A", "#4FE06A", "#FFD25A", "#59B8FF"},
            drift = "#F4F8FF",
            drift_shade = "#C6D5EA",
            drift_light = "#FFFFFF",
            badge = "#8E1A22",
        },
    },
    packs = {"festive"},
    speech = {scale = 1, name = 15},
    region_speaker = "pip",
    board = {
        tutorial_chain = "Match through the tied treat. Match that cell again to light its pane.",
        tutorial_goal = {"noelle", "To finish, clear all the blue tiles. Make matches over them."},
        kudos = {"Jolly!", "Merry!", "Magical!", "Christmas Magic!"},
        locked = "Match the tied piece to untangle the tinsel.",
        pieces = {kind_prefix="market-", scale=1.06},
        background = {min_height=900, align_y=.35, motes={245, 250, 255, 130}},
        review_replaces_tools = true,
    },
    notices = {
        reward_building = "Select a project to see its cost.",
        reward_replay = "Resources collected.",
        all_open = "The whole market is open.",
        quit = "Your board is saved. Tap Play to continue wish %d.",
    },
    capsules = {show = {"tokens", "treats", "materials"}},
    pause = {
        guide = "MARKET GUIDE",
        quit = "QUIT TO MARKET",
        leaderboard = "LEADERBOARD",
    },
    leaderboard = {
        board = "stars",
        title = "Merriest markets",
    },
    confirm = {title = "Restart this winter wish?"},
    failed = {town = "VISIT MARKET"},
    zone = {
        epoch_hint = function(epoch)
            return epoch == 5 and "Unlocked at Christmas" or ("Unlocked in Advent %d"):format(epoch)
        end,
        subtitle = "MORE ROOM FOR CHRISTMAS CHEER",
        cleared = "WISHES GRANTED  %d / %d",
        earn = "GRANT NEW WISHES TO OPEN IT",
    },
    finale = {
        title = "To be continued",
        lines = {
            {"There's a light in Noelle's window.", 16},
            {"Fernhollow has asked for a few lights of its own.", 16},
            {"THE ROAD TO FERNHOLLOW", 13, "cream"},
        },
    },
    complete = {
        title = "You did it!",
        lines = {
            {"ALL %d WINTER WISHES CAME TRUE.", 16},
        },
    },
    card = {
        every_wish = "EVERY WISH", moves = "MOVES",
    },
    catalogue = {
        title = "Build your market",
        poor = "MORE RESOURCES NEEDED",
    },
    debug = {victory = 3, catalogue_card = 10, narrator = "noelle"},
}
