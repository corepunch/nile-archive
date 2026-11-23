-- game_config.lua — the words and options of the shared match-3 screens, merged
-- over the engine's defaults (match3.game DEFAULTS): tables merge field by
-- field, lists replace.
local l10n = require("l10n")
local tr = l10n.tr

return {
    app = {title = "Christmas at Bellmere", id = "christmas-market", clear = "#09211F",
        privacy_url = "https://github.com/corepunch/nile-archive/blob/main/docs/APP_PRIVACY.md"},
    -- TRANSLATORS: the title screen reads CHRISTMAS / AT BELLMERE (Bellmere is the town)
    menu = {title = {tr("CHRISTMAS")}, title_em = 68, subtitle = tr("AT BELLMERE"), subtitle_em = 40, play = tr("PLAY"),
        town = tr("VISIT MARKET"), continue_in_town = true},
    campaign_dialogue = true,
    epochs = {tr("First Advent"), tr("Second Advent"), tr("Third Advent"), tr("Fourth Advent"), tr("Christmas")},
    epoch_title = tr("Advent & Christmas"),
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
    town_tip = {
        {"noelle", tr("Look at that, we have enough to build!")},
        {"noelle", tr("This Advent’s stalls are listed at the top left. Tap one that says Ready to build.")},
    },
    board = {
        tutorial_chain = tr("Match through the tied treat. Match that cell again to light its pane."),
        tutorial_goal = {"noelle", tr("To finish, clear all the blue tiles. Make matches over them.")},
        kudos = {tr("Jolly!"), tr("Merry!"), tr("Magical!"), tr("Christmas Magic!")},
        locked = tr("Match the tied piece to untangle the tinsel."),
        pieces = {kind_prefix="market-", scale=1.06},
        background = {min_height=900, align_y=.35, motes={245, 250, 255, 130}},
        review_replaces_tools = true,
    },
    notices = {
        reward_building = tr("Select a project to see its cost."),
        reward_replay = tr("Resources collected."),
        all_open = tr("The whole market is open."),
        -- TRANSLATORS: %d is the number of the wish (level) in progress
        quit = tr("Your board is saved. Tap Play to continue wish %d."),
    },
    capsules = {show = {"tokens", "treats", "materials"}},
    pause = {
        guide = tr("MARKET GUIDE"),
        quit = tr("QUIT TO MARKET"),
        leaderboard = tr("LEADERBOARD"),
    },
    leaderboard = {
        board = "stars",
        title = tr("Merriest markets"),
    },
    confirm = {title = tr("Restart this winter wish?")},
    failed = {town = tr("VISIT MARKET")},
    zone = {
        epoch_hint = function(epoch)
            return epoch == 5 and tr("Unlocked at Christmas") or tr("Unlocked in Advent %d"):format(epoch)
        end,
        subtitle = tr("MORE ROOM FOR CHRISTMAS CHEER"),
        -- TRANSLATORS: wishes granted so far / wishes needed to open this part of the market
        cleared = tr("WISHES GRANTED  %d / %d"),
        earn = tr("GRANT NEW WISHES TO OPEN IT"),
    },
    finale = {
        title = tr("To be continued"),
        lines = {
            {tr("There's a light in Noelle's window."), 16},
            {tr("Fernhollow has asked for a few lights of its own."), 16},
            {tr("THE ROAD TO FERNHOLLOW"), 13, "cream"},
        },
    },
    complete = {
        title = tr("You did it!"),
        lines = {
            -- TRANSLATORS: %d is the number of wishes in the campaign (100)
            {tr("ALL %d WINTER WISHES CAME TRUE."), 16},
        },
    },
    card = {
        every_wish = tr("EVERY WISH"), moves = tr("MOVES"),
    },
    catalogue = {
        title = tr("Build your market"),
        poor = tr("MORE RESOURCES NEEDED"),
    },
    debug = {victory = 3, catalogue_card = 10, narrator = "noelle"},
}
