-- match3_game.lua — the portrait match-3 city game around the board, shared by
-- Relic Rush and Christmas Market (`require("match3.game")`): progress and
-- saving, the level flow and lives, the frame, the paint helpers and every
-- dialog (pause and its Restart confirmation, failed, region card, building
-- card, finale), the build shop, the level list, the town hooks, story
-- delivery, the journey's bookkeeping and the debug entry points.
--
-- A game is data: words in data/game.json (merged over DEFAULTS below), its
-- campaign and story, its skin and art tables. Its own Lua paints only what is
-- art: the board's cells and pieces (board.lua), the results card and guide
-- rows (screens.lua), the cast (narrative.lua).
--
--   -- screens.lua, first:   local R = require("match3.game").bind(require("state"))
--   -- main.lua, last:       return require("match3.game").app(R)
--
-- Game hooks the shared code calls (set on R by the game's modules):
--   R.dialogs[R.OV_RESULT], R.dialogs[R.OV_GUIDE]   the results card and guide
--   R.wallet_icons()        three icons for lives, gold and stars capsules
--   R.town_middle_icon(at)  the round middle button's icon in the town
--   R.cast                  the story cast (narrative.lua)
--   R.smoke(), R.campaign_smoke()   the --smoke runs
--   data/game.json "leaderboard" {board, title, level_board, level_title}   Game Center boards (below)
-- See docs/PORTRAIT_GAMES.md.
local json = require("json")
local G = {}

------------------------------------------------------------------- words

G.DEFAULTS = {
    app = {title = "Match-3 town", id = "match3-game", clear = "#09211F"},
    start_on_town = false,   -- a new launch opens on the town, not the board
    packs = {"kind"},        -- piece packs; the first is the default, --tiles picks another
    speech = {scale = 1, name = 15},
    region_speaker = "",
    board = {},
    notices = {
        build_first = "Build your earned building before the next level.",
        story_waiting = "Something is happening in town.",
        no_lives = "A life returns every 30 minutes. Explore the town meanwhile.",
        reward_building = "Building funded! Spare gold is yours to decorate.",
        reward_story = "Something is happening in town.",
        reward_replay = "Replay gold collected. Choose something in the shop.",
        relocate = "Some buildings need a new spot. Hold one to move it.",
        all_open = "The whole town is open.",
        quit = "Your board is saved. Tap LEVEL %d or the level list to continue.",
    },
    capsules = {
        lives_full = "5 FULL",
        notes = {"A life returns every 30 minutes, up to five.", "Gold buys buildings.", "Stars unlock shop items and land."},
    },
    pause = {guide = "GUIDE", quit = "QUIT", town = "Your town", leaderboard = "LEADERBOARD"},
    confirm = {title = "Restart this level?", body = "The board starts over: moves, goals and tools reset. Retrying is always free.",
               restart = "RESTART", cancel = "KEEP PLAYING"},
    failed = {title = "One more try?", subtitle = "THE TOWN WILL WAIT FOR YOU.", hint = "Try a special combo or use a tool.",
              no_lives = "A life returns every 30 minutes.", retry = "TRY AGAIN", town = "VISIT TOWN"},
    zone = {subtitle = "A NEW PLACE TO DISCOVER", stars = "STARS  %d / %d", earn = "EARN STARS IN NEW LEVELS",
            open = "OPEN THIS AREA", wait = "KEEP EXPLORING", keep = "STARS STAY WITH YOU.", close = "CLOSE"},
    finale = {title = "To be continued", lines = {}, button = "BACK TO TOWN"},
    card = {move = "MOVE THIS BUILDING", build = "CHOOSE A LOCATION", back = "BACK TO TOWN",
            moving = "HOLD AND DRAG IN TOWN TO MOVE", locked = "COMPLETE MORE LEVELS TO BUILD THIS", close = "CLOSE"},
    catalogue = {
        title = "Build your town", hint = "Choose a building, then place it.", close = "BACK TO TOWN",
        categories = {{"all", "Everything"}, {"wonder", "Story buildings"}, {"building", "Buildings"}},
        category = "all",
        choose = "CHOOSE LOCATION", tap = "Tap to build", built = "BUILT", complete = "COMPLETE LEVEL %d", earlier = "BUILD EARLIER BUILDINGS",
        stars = "REQUIRES %d STARS", poor = "MORE GOLD NEEDED", reserved = "GOLD RESERVED FOR BUILDINGS", full = "TOWN IS FULL",
        price = "%d gold", unlock = "  /  %d stars to unlock",
        details = "%d x %d tiles  /  Owned %d\n%s",
    },
    expeditions = {
        title = "Levels", intro = "First clear: the story, Stars and building funding.\nReplay: gold.", close = "BACK TO TOWN",
        locked = "LOCKED", resume = "RESUME", replay = "REPLAY", pending = "BUILD FIRST", new = "NEW LEVEL", earlier = "COMPLETE EARLIER LEVELS",
        resume_note = "Continue the unfinished board. Rewards come with a win.",
        replay_note = "Gold only.", building_note = "First clear: building funded.", story_note = "First clear: the next scene.",
    },
    debug = {victory = 1, catalogue_card = 10, narrator = ""},
}

local function merge(base, over)
    if type(over) ~= "table" or over == json.null then return base end
    if #over > 0 or type(base) ~= "table" then return over end   -- arrays replace
    local out = {}
    for k, v in pairs(base) do out[k] = v end
    for k, v in pairs(over) do
        if v == json.null then out[k] = nil
        elseif type(v) == "table" and type(base[k]) == "table" and #v == 0 then out[k] = merge(base[k], v)
        else out[k] = v end
    end
    return out
end
G.merge = merge

-- data/game.json over the defaults; nil or a table also works (tests).
function G.config(over)
    if over == nil then
        local text = app.read_text("game.json")
        over = text and json.decode(text) or {}
    end
    return merge(G.DEFAULTS, over)
end

local function hex(s)
    local h = s:gsub("^#", "")
    local function byte(i) return tonumber(h:sub(i, i + 1), 16) or 255 end
    return color(byte(1), byte(3), byte(5), #h >= 8 and byte(7) or 255)
end

-- The state the game's modules share, and their namespace: every module
-- attaches its public functions here (R.notice, R.cell_pos, ...) so they can
-- call each other without import cycles. A game's lua/state.lua returns it.
function G.state()
    return require("match3").view{
        hit_dy = 0,          -- where the open dialog's buttons sit below their layout

        intro = nil,

        -- overlays and board phases
        OV_NONE = 0, OV_GUIDE = 1, OV_PAUSE = 2, OV_RESULT = 3, OV_FAILED = 4, OV_WONDER = 5, OV_FINALE = 6, OV_ZONE = 7, OV_SHOP = 8, OV_EXPEDITIONS = 9, OV_CONFIRM = 10, OV_STORY_CHOICE = 11,
        PAL_GOLD = "gold", PAL_CREAM = "cream", PAL_GREEN = "green", PAL_WHITE = "white",   -- text styles in skin.lua

        backdrop = nil, scenes = {}, relics = {}, glow = nil,
        font = nil,
        prog = nil,          -- {level, seed, wallet}
        island = nil,        -- the engine city

        -- screens
        on_island = false,
        overlay = 0, modal_for = 0,   -- modal_for: the dialog whose entrance is playing
        dialog = nil,        -- the open dialog's motion (screens.lua: R.open_dialog)
        modal_closing = false,
        inspect = -1, inspect_item = -1, zone_card = -1,
        reduced_motion = false, sound = true, test_mode = false,
        toast = nil,
        toast_time = 0, now = 0,
        quiet = false,       -- no story (stills for the docs)

        -- animated readouts
        score_display = 0, score_pulse = 0, goal_display = 0, goal_pulse = 0,
        fx_combo = 0, fx_origin = -1,
    }
end

----------------------------------------------------------------- journey

-- The story's bookkeeping. `content` is the game's: beats (story_content),
-- wonder_levels, recap(level), regions, building lines and save version.
-- Checkpoints are stable keys, acknowledged after a whole beat ends.
function G.journey(content)
    local M = content
    M.about = M.about or {}

    function M.earned(level)
        local n = 0
        for _, at in ipairs(M.wonder_levels) do if level >= at then n = n + 1 end end
        return n
    end

    function M.wonder_at(level)
        for i, at in ipairs(M.wonder_levels) do if level == at then return i end end
    end

    function M.find(key)
        for _, beat in ipairs(M.beats) do if beat.key == key then return beat end end
    end

    -- Legacy clears remain clears; already-owned buildings stay. A recap
    -- bridges the old abbreviated dialogue without replaying rewards.
    function M.migrate(p, version)
        p.story_seen = p.story_seen or {}
        if version < M.version then
            for _, b in ipairs(M.beats) do
                if b.level <= p.level then p.story_seen[b.key] = true end
            end
            p.story_recap = p.level > 0
        end
    end

    function M.serialize(s, p)
        p.story_seen = p.story_seen or {}
        p.story_choices = p.story_choices or {}
        for _, b in ipairs(M.beats) do
            p.story_seen[b.key] = s:int("narrative.v1." .. b.key, p.story_seen[b.key] and 1 or 0) == 1
            if b.choices then
                local choice = s:int("narrative.choice." .. b.key, p.story_choices[b.key] or 0)
                p.story_choices[b.key] = b.choices[choice] and choice or nil
            end
        end
        p.story_recap = s:int("narrative.recap", p.story_recap and 1 or 0) == 1
    end

    function M.result_beat(p, g)
        if not M.clear_before_result or not g.won or g.level ~= p.level then return end
        local beat = M.find(("after-%02d"):format(p.level + 1))
        if beat and not beat.choices and not p.story_seen[beat.key] and g.story_clear ~= beat.key then return beat end
    end

    function M.next(p, owns, before_level)
        for _, b in ipairs(M.beats) do
            if not (p.story_seen or {})[b.key] then
                if b.phase == "before" then
                    if before_level == b.level - 1 and p.level >= b.level - 1 then return b end
                elseif p.level >= b.level then
                    local wonder = M.wonder_at(b.level)
                    if (b.phase == "after" and M.clear_before_result) or not wonder or owns(wonder - 1) then return b end
                end
                return nil
            end
        end
    end

    function M.awaiting_return(p)
        for _, b in ipairs(M.beats) do
            if not (p.story_seen or {})[b.key] then return b.phase ~= "before" and p.level >= b.level end
        end
        return false
    end

    -- The scene that bridges an old save: the opening line, then the lines of
    -- the first {level, line...} step the player has reached.
    local recap = M.recap or {}
    function M.recap(level)
        local lines = {recap[1]}
        for i = 2, #recap do
            if level >= recap[i][1] then
                for k = 2, #recap[i] do lines[#lines + 1] = recap[i][k] end
                break
            end
        end
        return lines
    end

    -- A building's tap line for this point in the story: the last authored
    -- {kind, level, text} the player has reached, or the catalogue line.
    function M.building_about(kind, level, fallback)
        local best
        for _, line in ipairs(M.about) do
            if line[1] == kind and level >= line[2] and (not best or line[2] >= best[2]) then best = line end
        end
        return best and best[3] or fallback
    end

    return M
end

--------------------------------------------------------------------- bind

-- Everything around the board, attached to the game's state table R.
-- Idempotent: rule tests may load screens.lua more than once.
function G.bind(R, over)
    if R.game_bound then return R end
    R.game_bound = true
    local W = G.config(over)
    R.words = W
    local rules = require("rules")
    local island = require("island")
    local journey = require("journey")
    local match3 = require("match3")
    local LEVELS = rules.LEVELS
    local rgba = color
    R.dialogs = R.dialogs or {}

    -------------------------------------------------------------- paint

    -- Dialogs animate through a paint transform (scale, offset, opacity);
    -- hit testing always uses the untransformed layout, so a dialog is
    -- clickable where it comes to rest.
    local P = {scale = 1, offset = vec2(0, 0), alpha = 1}
    R.P = P
    local function reset_paint() P.scale, P.offset, P.alpha = 1, vec2(0, 0), 1 end
    local function copy_paint() return {scale = P.scale, offset = P.offset, alpha = P.alpha} end
    local function set_paint(k) P.scale, P.offset, P.alpha = k.scale, k.offset, k.alpha end
    R.copy_paint, R.set_paint = copy_paint, set_paint

    local function pp(p) return P.offset + p:scale(P.scale) end
    local function pr(r) return rect.make(pp(r:pos()), r:size():scale(P.scale)) end
    local function pc(c) return color.alpha(c, P.alpha) end
    R.pp, R.pr, R.pc = pp, pr, pc

    function R.fill(r, c) gfx.rect(pr(r), pc(c)) end
    function R.rrect(r, radius, c) gfx.round_rect(pr(r), radius * P.scale, pc(c)) end
    function R.disc(center, radius, c) gfx.circle(pp(center), radius * P.scale, pc(c)) end
    function R.seg(a, b, width, c) gfx.line(pp(a), pp(b), width * P.scale, pc(c)) end
    function R.picture(t, r, alpha) gfx.image(t, pr(r), rgba(255, 255, 255, alpha * P.alpha)) end
    function R.picture_fit(t, box, alpha)
        if t.w > 0 then R.picture(t, box:fit(texture.size(t)), alpha) end
    end

    -- The look lives in the game's skin.lua; the engine paints it through the
    -- dialog's current transform. A palette is one of its text styles (R.PAL_*).
    local skin = require("skin")
    skin.transform = function() return P.scale, P.offset, P.alpha end
    R.skin, R.form_skin = skin, skin
    function R.pal(palette, em) return skin:text(palette, em) end
    local pal = R.pal
    function R.say(s, box, em, palette) return text.inside(pal(palette, em), pr(box), vec2(.5, .5), s) end
    function R.say_left(s, box, em, palette) return text.inside(pal(palette, em), pr(box), vec2(0, .5), s) end
    function R.say_at(s, center, em, palette, max_width)
        local w = max_width > 0 and max_width or 2000
        return R.say(s, rect.centered(center, size2(w, em * 2)), em, palette)
    end
    function R.paragraph(s, box, em, palette) text.box(pal(palette, em), pr(box), vec2(.5, .5), s) end
    local say_at = R.say_at
    function R.panel(r) skin:paint("panel", r) end
    function R.tapped(r) return ui.hit(r:offset(vec2(0, R.hit_dy)), 0).clicked end
    -- Buttons respond even when drawn disabled, so the game can explain why not.
    function R.paint_button(r, st, enabled)
        skin:paint("button", r, {hot = st.hot, held = st.held, disabled = not enabled})
    end
    function R.button(r, label, enabled)
        local st = ui.hit(r:offset(vec2(0, R.hit_dy)), 0)
        R.paint_button(r, st, enabled)
        R.say(label, (st.held and r:offset(vec2(0, 2)) or r):inflate(-12), 25, R.PAL_CREAM)
        return st.clicked
    end
    local panel, button, tapped = R.panel, R.button, R.tapped
    local PAL_GOLD, PAL_CREAM, PAL_WHITE = R.PAL_GOLD, R.PAL_CREAM, R.PAL_WHITE

    -- Dialogue text: the skin's font, scaled by speech.scale, in dark ink.
    function R.speech_style(size) return style{font = R.font, size = size * W.speech.scale, fill = rgba(74, 50, 28)} end
    function R.notice(message)
        R.toast = message
        R.toast_time = 3.6
    end
    function R.tone(hz)
        if R.sound then sfx.tone(hz, .17) end
    end

    function R.draw_toast()
        if R.toast_time <= 0 or R.overlay ~= R.OV_NONE then return end
        if R.on_island then   -- above the map buttons
            R.rrect(rect(18, 710 + R.drop, 444, 30), 11, rgba(10, 37, 31, 235))
            say_at(R.toast, vec2(240, 724 + R.drop), 14, PAL_CREAM, 424)
        else   -- just below the HUD, above the board
            local bounds = R.board_toast
            R.rrect(bounds, 11, rgba(10, 37, 31, 235))
            say_at(R.toast, bounds:center(), 14, PAL_CREAM, bounds.w - 16)
        end
    end

    -- The town's wallet capsules: lives, gold, stars (engine/town.lua lays them out).
    function R.header_capsules()
        local remaining = math.max(0, math.ceil((R.prog.life_at or 0) - app.clock()))
        local lives = (R.prog.lives or rules.LIVES) == rules.LIVES and W.capsules.lives_full
            or ("%d %d:%02d"):format(R.prog.lives, remaining // 60, remaining % 60)
        local values = {lives, tostring(R.prog.wallet[rules.GOLD]), tostring(R.prog.wallet[rules.STARS])}
        local icons = R.wallet_icons()
        local out = {}
        for k = 1, 3 do out[k] = {icon = icons[k], value = values[k], note = W.capsules.notes[k]} end
        return out
    end

    ------------------------------------------------------------ dialogs

    -- The open dialog's motion, on the engine's tween module. Popups appear
    -- and close at once, with no entrance or exit motion: they must never
    -- wait on the frame clock to become visible (a stalled clock on device
    -- left a dim with no panel), and the backdrop blur already costs the
    -- opening frame. A dialog's parts (the results card) still arrive on one
    -- timeline in reels (--reel); a tap skips to its end.
    local function new_dialog()
        return {entry = 0, exit = 0, parts = {}, n = 0, tl = nil, fresh = true}
    end

    function R.open_dialog(settled)
        local old = R.dialog
        if old then
            tween.kill(old)
            if old.tl then old.tl:kill() end
        end
        local d = new_dialog()
        R.dialog = d
        R.modal_closing = false
        d.settled = settled or not app.arg("reel")
        d.entry = 1
    end

    -- Bank the reward and leave the dialog immediately.
    function R.close_dialog()
        R.modal_closing = false
        R.claim_reward()
        R.modal_for = R.overlay
    end

    -- Has the entrance, parts included, finished?
    function R.dialog_settled()
        local d = R.dialog
        return d ~= nil and d.entry >= 1 and (d.tl == nil or d.tl:is_done())
    end

    -- Jump the parts to their places, as the first tap on a result does.
    function R.dialog_skip()
        local d = R.dialog
        if d.tl and not d.tl:is_done() then d.tl:complete() end
    end

    -- A part of the dialog arriving `delay` seconds after it opened: `f` is its
    -- eased progress and `u` its linear one. Parts are keyed by draw order and
    -- join the dialog's timeline the first time they are drawn.
    function R.dialog_part(delay, duration)
        local d = R.dialog
        d.n = d.n + 1
        local part = d.parts[d.n]
        if not part then
            part = {f = 0, u = 0}
            d.parts[d.n] = part
            d.tl = d.tl or tween.timeline()
            d.tl:to(part, duration, {f = 1}, delay)
            d.tl:to(part, duration, {u = 1}, delay):ease("linear")
            if d.settled then d.tl:complete() end
        end
        return part
    end

    -- Fade and lift a part of a dialog in after `delay`; returns the paint to restore.
    function R.section(delay, duration, rise)
        local old = copy_paint()
        local part = R.dialog_part(delay, duration)
        local f = part.f
        P.alpha = P.alpha * f
        P.offset = P.offset + vec2(0, rise * (1 - f) * P.scale)
        return old, part
    end

    -- The building card: a story building or a shop item, to build or move.
    local wonder_form = ui.form{
        root = {kind="column", panel=true, padding={24,20,24,13}, children={
            {kind="label", id="name", height=44, em=34},
            {kind="spacer", height=19},
            {kind="image", id="sprite", height=205},
            {kind="spacer", height=18},
            {kind="label", id="about", height=62, wrap=true, em=22, text_style=PAL_CREAM},
            {kind="spacer", height=14},
            {kind="row", height=78, padding={16,0,16,0}, gap=10, visible_field="can_build", children={
                {kind="column", grow=1, gap=9, children={{kind="image",id="gold_icon",height=34},{kind="label",id="gold",height=28}}},
            }},
            {kind="label",id="notice",height=78,wrap=true,em=15,text_style=PAL_CREAM,visible_field="show_notice"},
            {kind="spacer",height=18},
            {kind="button",id="action",height=56},
            {kind="spacer",height=17},
            {kind="button",id="close",text=W.card.close,height=28,flat=true,em=16},
        }},
        bindings={
            {id="name",field="name",readonly=true},{id="sprite",field="sprite",type="texture",readonly=true},
            {id="about",field="about",readonly=true},{id="action",field="action",readonly=true},
            {id="gold",field="cost.1",type="integer",readonly=true},
        },
    }
    R.wonder_form = wonder_form
    R.dialogs[R.OV_WONDER] = function()
        local i = R.inspect >= 0 and R.inspect or island.wonder_count(R.island)
        if i < 0 or i >= #R.buildings then return end
        local w = R.buildings[i + 1]
        local can_build, built = island.can_buy(R.island, R.prog.wallet, R.prog.level, i), R.inspect_item and R.inspect_item >= 0
        local ok, message = wonder_form:push{name=w.name, sprite=w.sprite, about=journey.building_about(i, R.prog.level, w.about),
            cost={w.cost[1]}, action=built and W.card.move or can_build and W.card.build or W.card.back}
        assert(ok, message)
        wonder_form:set("gold_icon", R.wallet_icons()[2])
        wonder_form.values.can_build, wonder_form.values.show_notice = can_build and not built, built or not can_build
        wonder_form:set("notice", built and W.card.moving or W.card.locked)
        local bounds = rect.centered(vec2(240, 450), size2(math.min(420, R.SCREEN_W - 48), 592))
        R.modal_bounds = pr(bounds)
        local event = wonder_form:draw(bounds, skin, {hit_offset=vec2(0, R.hit_dy)})
        if event and event.id == "action" then
            if can_build or built then R.island_begin(i, true, built and R.inspect_item or nil) else R.overlay = R.OV_NONE end
        elseif event and event.id == "close" then R.overlay = R.OV_NONE end
    end

    -- Pause: the settings grouped in one well, then Resume and the secondary
    -- actions. Restart asks first; Quit keeps the board, which LEVEL or the
    -- level list resume later. From the town only Resume applies.
    local pause_form = match3.pause_form(W.pause.guide, W.pause.quit, W.leaderboard and W.pause.leaderboard)
    R.pause_form = pause_form
    R.dialogs[R.OV_PAUSE] = function()
        local level = R.on_island and W.pause.town or ("%d. %s"):format(R.g.level + 1, rules.level_of(R.g).name)
        local action = match3.draw_pause(R, pause_form, level)
        if action == "restart" then R.overlay = R.OV_CONFIRM
        elseif action == "leaderboard" then R.open_leaderboard()
        elseif action == "quit" then   -- the unfinished board waits in town
            R.on_island, R.overlay = true, R.OV_NONE
            R.notice(W.notices.quit:format(R.g.level + 1))
        end
    end

    -- Restart throws the board away, so it asks first. Retrying is always free.
    local confirm_form = ui.form{
        root={kind="column",panel=true,padding={36,22,36,18},gap=14,children={
            {kind="label",text=W.confirm.title,height=40,em=28},
            {kind="label",text=W.confirm.body,height=56,wrap=true,em=18,text_style=PAL_CREAM},
            {kind="button",id="confirm",text=W.confirm.restart,height=50},
            {kind="button",id="cancel",text=W.confirm.cancel,height=32,role="link",em=20},
        }},
    }
    R.confirm_form = confirm_form
    R.dialogs[R.OV_CONFIRM] = function()
        local _, height = confirm_form:measure(396, skin)
        local bounds = rect.centered(vec2(240, 450), size2(396, height))
        R.modal_bounds = pr(bounds)
        local event = confirm_form:draw(bounds, skin, {hit_offset=vec2(0, R.hit_dy)})
        if event and event.id == "confirm" then R.start_level(R.g.level); R.overlay = R.OV_NONE
        elseif event and event.id == "cancel" then R.overlay = R.OV_PAUSE end
    end

    -- Out of moves. With no lives left, Try Again waits and says why.
    R.dialogs[R.OV_FAILED] = function()
        local f = W.failed
        panel(rect(38, 272, 404, 333))
        say_at(f.title, vec2(240, 317), 32, PAL_GOLD, 0)
        say_at(f.subtitle, vec2(240, 366), 16, PAL_WHITE, 0)
        local can_retry = (R.prog.lives or rules.LIVES) > 0
        say_at(can_retry and f.hint or f.no_lives, vec2(240, 404), 17, PAL_CREAM, 0)
        if button(rect(83, 448, 314, 50), f.retry, can_retry) and can_retry then R.start_level(R.g.level) end
        if button(rect(115, 520, 250, 42), f.town, true) then R.on_island, R.overlay = true, R.OV_NONE end
    end

    -- A closed region: what it needs, and the button to open it.
    R.dialogs[R.OV_ZONE] = function()
        local z, t = R.zone_card, W.zone
        local zone = R.island.zones[z + 1]
        local ready = R.island:zone_available(z, R.prog.wallet)
        R.modal_bounds = pr(rect(30, 263, 420, 365))
        panel(rect(30, 263, 420, 365))
        say_at(zone.name, vec2(240, 304), 34, PAL_GOLD, 380)
        say_at(t.subtitle, vec2(240, 349), 16, PAL_CREAM, 0)
        say_at(t.stars:format(R.prog.wallet[rules.STARS], zone.needs[rules.STARS]), vec2(240, 397), 24, PAL_GOLD, 0)
        say_at(t.earn, vec2(240, 441), 19, PAL_CREAM, 0)
        if button(rect(72, 487, 336, 47), ready and t.open or t.wait, true) then
            if R.island:unlock(z, R.prog.wallet) then
                R.island_focus(zone.marker, R.island.cam.zoom)
                R.save_progress()
                story.add({W.region_speaker, journey.regions[z], story.SHOUT})
                R.tone(820)
            end
            R.overlay = R.OV_NONE
        end
        say_at(t.keep, vec2(240, 559), 12, PAL_WHITE, 0)
        say_at(t.close, vec2(240, 592), 15, PAL_WHITE, 0)
        if tapped(rect(180, 575, 120, 38)) then R.overlay = R.OV_NONE end
    end

    -- The end of the campaign. Lines are {text, y, em, style}.
    R.dialogs[R.OV_FINALE] = function()
        panel(rect(32, 285, 416, 305))
        say_at(W.finale.title, vec2(240, 330), 31, PAL_GOLD, 0)
        for _, line in ipairs(W.finale.lines) do say_at(line[1], vec2(240, line[2]), line[3], line[4] or PAL_WHITE, 0) end
        if button(rect(82, 489, 316, 50), W.finale.button, true) then R.overlay = R.OV_NONE end
    end

    -- Draws the open dialog over everything; it alone receives input.
    function R.overlays(dt)
        if R.overlay ~= R.modal_for then   -- a new dialog opens
            R.modal_for = R.overlay
            R.open_dialog()
        end
        if R.overlay == R.OV_NONE then return end
        if R.overlay == R.OV_SHOP then R.draw_catalogue(dt); return end
        if R.overlay == R.OV_EXPEDITIONS then R.draw_expeditions(dt); return end
        if R.overlay == R.OV_STORY_CHOICE then R.draw_story_choice(dt); return end
        local d = R.dialog
        d.n = 0
        local entry, exit = d.entry, d.exit
        ui.modal_layer(7, rgba(5, 22, 22, 185))
        local scale = .96 + .04 * entry
        -- dialogs are laid out on the 900-tall design: centre them on a taller screen
        R.hit_dy = R.drop / 2
        P.scale, P.offset, P.alpha = scale, vec2(240 * (1 - scale), 450 * (1 - scale) + 22 * (1 - entry) + 18 * exit + R.hit_dy), entry * (1 - exit)
        local before = R.overlay
        R.modal_bounds = nil
        local draw = R.dialogs[R.overlay]
        local covered = R.leaderboard_active()   -- a board above this dialog owns the input
        if covered then ui.set_enabled(false) end
        if draw then draw() end
        if covered then ui.set_enabled(true) end
        if R.overlay == before and R.modal_bounds and not R.modal_closing and not covered
                and ui.modal_dismiss(R.modal_bounds, {fresh=d.fresh}) then R.overlay = R.OV_NONE end
        d.fresh = false
        reset_paint()
        R.hit_dy = 0
    end

    ----------------------------------------------------- shop and levels

    -- Modal lists: the engine owns measured rows, focus, hit testing and
    -- input capture. Backdrops snap in, like every popup.
    local MODAL = {width=448, snap_backdrop=true, blur=7, dim=color(5, 22, 22, 185), cancel="close"}
    local C = W.catalogue
    local categories, category = C.categories, 1
    for i, cat in ipairs(categories) do if cat[1] == C.category then category = i end end
    local shop = ui.modals(skin)
    local function paint_tile(box, record)
        local locked = record.state == "locked"
        R.rrect(box:offset(vec2(0, 3)), 13, rgba(201, 164, 100))
        R.rrect(box, 13, record.selected and rgba(184, 60, 60) or locked and rgba(243, 229, 192) or rgba(255, 246, 214))
        if record.selected then R.rrect(box:inflate(-3), 11, rgba(255, 246, 214)) end
        R.picture_fit(record.sprite, rect(box.x + 4, box.y + 4, box.w - 8, box.h - 34), locked and 110 or 255)
        local line = rect(box.x, box.y + box.h - 28, box.w, 24)
        if record.state == "built" or locked then   -- icons from the game's atlas
            R.picture_fit(record.state == "built" and R.shop_built_art or R.shop_locked_art, rect.centered(line:center(), size2(30, 30)), 255)
        else
            R.picture_fit(R.wallet_icons()[2], rect(box.x + box.w / 2 - 34, line.y + 1, 22, 22), 255)
            R.say_left(tostring(record.cost), rect(box.x + box.w / 2 - 9, line.y, box.w / 2, 24), 19, record.state == "ready" and PAL_GOLD or PAL_CREAM)
        end
    end
    local catalogue_form = match3.catalogue_form(C.title, C.hint, C.close, PAL_CREAM, paint_tile)
    R.catalogue_form = catalogue_form

    local tiles = {}   -- building key -> its tile record
    local selected   -- the tile the footer explains
    local function refresh_catalogue()
        local records, rows = {}, {}
        local cat = categories[category][1]
        local wallet = R.prog.wallet
        for i, meta in ipairs(island.catalogue) do
            if cat == "all" or meta.category == cat then
                local def = R.buildings[i]
                local owned = island.owned(R.island, i - 1)
                local available = island.can_buy(R.island, wallet, R.prog.level, i - 1)
                local action, state = C.choose, "ready"
                if i <= island.WONDERS then
                    local reason = owned > 0 and C.built or journey.wonder_levels[i] > R.prog.level and C.complete:format(journey.wonder_levels[i]) or
                        i - 1 ~= island.wonder_count(R.island) and C.earlier
                    if reason then action, state = reason, owned > 0 and "built" or "locked" end
                elseif wallet[rules.STARS] < meta.stars then action, state = C.stars:format(meta.stars), "locked"
                elseif not wallet:covers(def.cost) then action, state = C.poor, "poor"
                elseif wallet[rules.GOLD] - island.reserved_gold(R.island, R.prog.level) < def.cost[1] then action, state = C.reserved, "poor"
                elseif R.island.count >= 160 then action, state = C.full, "poor" end
                local price = C.price:format(def.cost[1])
                if i > island.WONDERS then price = price .. C.unlock:format(meta.stars) end
                local details = C.details:format(meta.size.w, meta.size.h, owned, price):gsub("\n", "  /  ")
                if R.quest_build_points then details = details .. ("  /  +%d decoration points"):format(R.quest_build_points(i - 1)) end
                local record = {id=meta.key, kind=i - 1, name=def.name, sprite=def.sprite, cost=def.cost[1], state=state,
                    details=details, available=available, action=action}
                records[#records + 1], tiles[meta.key] = record, record
            end
        end
        local in_category = false
        for _, record in ipairs(records) do if record.id == selected then in_category = true end end
        if not in_category then
            selected = records[1] and records[1].id
            for _, record in ipairs(records) do if record.available then selected = record.id; break end end
        end
        for n, record in ipairs(records) do
            record.selected = record.id == selected
            local r = (n - 1) // match3.CATALOGUE_COLUMNS + 1
            rows[r] = rows[r] or {id="r" .. r, cells={}}
            rows[r].cells[#rows[r].cells + 1] = record
        end
        assert(catalogue_form:set_items("stock", rows))
        catalogue_form:set("category", categories[category][2])
        local record = tiles[selected]
        catalogue_form:set("info_name", record and record.name or "")
        catalogue_form:set("info_note", record and (record.details .. "\n" .. (record.available and C.tap or record.action)) or "")
        return #rows
    end

    -- The tile node and record for a building key, for smoke tests that press it.
    function R.catalogue_tile(key)
        for _, node in pairs(catalogue_form.nodes) do
            if node.local_id and node.local_id:find("^pick") then
                local row = catalogue_form:get_item("stock", node.item_key)
                local record = row and row.cells[tonumber(node.local_id:sub(5))]
                if record and record.id == key then return node, record end
            end
        end
    end

    function R.open_catalogue(filter, review_page)
        local old_category = category
        if filter then
            for i, cat in ipairs(categories) do if cat[1] == filter then category = i end end
        end
        if shop:active() then shop:close() end
        local row_count = refresh_catalogue()
        if review_page and row_count > 0 then
            local row = num.clampi(math.floor(review_page), 1, row_count)
            catalogue_form:scroll_to("stock", "r" .. row)
        elseif category ~= old_category then catalogue_form:scroll_to("stock") end
        assert(shop:open("catalogue", catalogue_form, {}, MODAL))
        R.overlay = R.OV_SHOP
    end

    function R.draw_catalogue(dt)
        local event = shop:draw(dt, {reduced_motion=R.reduced_motion})
        if not event then return end
        if event.id == "close" or event.kind == "cancel" then shop:close(); R.overlay = R.OV_NONE
        elseif event.id == "category_prev" or event.id == "category_next" then
            category = (category - 1 + (event.id == "category_next" and 1 or -1)) % #categories + 1
            refresh_catalogue()
            catalogue_form:scroll_to("stock")
        elseif event.source == "stock" then
            local row = catalogue_form:get_item("stock", event.key)
            local record = row and row.cells[tonumber(tostring(event.id):sub(5)) or 0]
            if record and record.available then shop:close(); R.island_begin(record.kind, true)
            elseif record then selected = record.id; refresh_catalogue() end   -- the footer says why it cannot be built
        end
    end

    -- Repeatable earning and the one-time story track share one level list.
    local E = W.expeditions
    local levels = ui.modals(skin)
    local function paint_level(box, e)
        local current = e.state == "current"
        R.rrect(box:offset(vec2(0, 2)), 13, rgba(201, 164, 100))
        R.rrect(box, 13, current and rgba(255, 228, 150) or e.state == "locked" and rgba(243, 229, 192) or rgba(255, 246, 214))
        local c = vec2(box.x + 30, box.y + (current and 33 or box.h / 2))
        gfx.circle(c, 19, rgba(77, 58, 31))
        gfx.circle(c, 17, current and rgba(184, 60, 60) or e.state == "locked" and rgba(140, 150, 136) or rgba(44, 108, 84))
        R.say(tostring(e.number), rect.centered(c, size2(34, 24)), 17, PAL_CREAM)
        local title = rect(box.x + 58, box.y + (current and 7 or 0), box.w - 168, current and 26 or box.h)
        R.say_left(e.name, title, 18, e.state == "locked" and PAL_CREAM or PAL_GOLD)
        if current then R.say_left(e.note, rect(box.x + 58, box.y + 34, box.w - 70, 24), 12, PAL_CREAM) end
        local right = rect(box.x + box.w - 106, box.y + (current and 7 or (box.h - 28) / 2), 96, 28)
        if e.state == "current" or e.resume then
            R.rrect(right:offset(vec2(0, 2)), 14, rgba(120, 36, 36))
            R.rrect(right, 14, e.available and rgba(184, 60, 60) or rgba(125, 140, 126))
            R.say(e.action, right, 14, PAL_CREAM)
        elseif e.state == "done" then R.say(e.action, right, 13, PAL_CREAM)
        else R.say(E.locked, right, 13, PAL_CREAM) end
    end
    local expedition_form = match3.expedition_form(E.title, E.intro, E.close, PAL_CREAM, paint_level)
    R.expedition_form = expedition_form

    local function refresh_levels()
        local entries = {}
        local pending = island.wonder_count(R.island) < journey.earned(R.prog.level)
        for i = 0, LEVELS - 1 do
            local done = i < R.prog.level
            local current = i == R.prog.level
            local available = done or (current and not pending)
            local active = R.g and R.g.level == i and not R.g.won and not R.g.lost
            entries[#entries + 1] = {id=tostring(i), level=i, number=i + 1, name=rules.levels[i + 1].name, available=available,
                state=done and "done" or current and "current" or "locked", resume=active and available,
                action=active and available and E.resume or done and E.replay or current and (pending and E.pending or E.new) or E.earlier,
                note=active and available and E.resume_note or done and E.replay_note or
                    (journey.wonder_at(i + 1) and E.building_note or E.story_note)}
        end
        assert(expedition_form:set_items("levels", entries))
    end

    -- Opens at the current level (or a review page of three).
    function R.open_expeditions(review_page)
        refresh_levels()
        local level = review_page and (math.floor(review_page) - 1) * 3 or math.min(R.prog.level, LEVELS - 1) // 3 * 3
        expedition_form:scroll_to("levels", tostring(num.clampi(level, 0, LEVELS - 1)))
        if levels:active() then levels:close() end
        assert(levels:open("expeditions", expedition_form, {}, MODAL))
        R.overlay = R.OV_EXPEDITIONS
    end

    function R.draw_expeditions(dt)
        local ev = levels:draw(dt, {reduced_motion=R.reduced_motion})
        if not ev then return end
        if ev.id == "close" or ev.kind == "cancel" then levels:close(); R.overlay = R.OV_NONE
        elseif ev.source == "levels" then
            local entry = expedition_form:get_item("levels", ev.key)
            if entry and entry.available then
                levels:close()
                R.overlay = R.OV_NONE   -- a refused start must not leave the list's overlay behind
                R.play_level(entry.level)
            end
        end
    end

    ------------------------------------------------------------- town

    local town = require("town")
    function R.island_focus(world, zoom) R.town:focus(world, zoom) end
    function R.island_begin(kind, focus, item)
        if not R.town:begin(kind, focus, item) then return false end
        R.overlay, R.inspect = R.OV_NONE, -1   -- placement happens on the open map
        return true
    end

    function R.expand()
        local z = R.island:next_zone(R.prog.wallet)
        if z < 0 then R.notice(W.notices.all_open)
        else R.zone_card, R.overlay = z, R.OV_ZONE end
    end

    -- The building's name and its line for this point in the story.
    function R.building_words(item)
        local kind = R.island.items[item + 1].type
        local definition = R.buildings[kind + 1]
        return definition.name .. "\n" .. journey.building_about(kind, R.prog.level, definition.about)
    end

    local function owes_building() return island.wonder_count(R.island) < journey.earned(R.prog.level) end

    function R.town_setup()
        R.town = town.new(R.island, town.load("town.json"), {
            skin = skin,
            wallet = function() return R.prog.wallet end,
            notice = R.notice,
            capsules = R.header_capsules,
            menu = function(bounds) if match3.pause_button(R, bounds) then R.overlay = R.OV_PAUSE end end,
            middle = R.open_expeditions,
            middle_icon = function(at) R.town_middle_icon(at) end,
            build = function() R.open_catalogue(owes_building() and "wonder" or "building") end,
            play = function()
                if owes_building() then R.notice(W.notices.build_first); R.open_catalogue("wonder")
                elseif R.prog.level >= LEVELS then R.open_expeditions()
                else R.play_level(R.prog.level) end
            end,
            about = R.building_words,
            zone = function(z) R.zone_card, R.overlay = z, R.OV_ZONE end,
            can_buy = function(kind) return island.can_buy(R.island, R.prog.wallet, R.prog.level, kind) end,
            suggest = function(kind) return island.island_suggestion(math.min(kind, island.WONDERS - 1)) end,
            placed = function(ev)
                for k = 0, 23 do R.vfx_emit(ev.screen - vec2(0, 30), k % 6, false) end
                R.tone(740)
                R.save_progress()   -- the building's story beat follows from R.story_tick
            end,
            bubble_text = function() return R.speech_style(15) end,
            reduced_motion = function() return R.reduced_motion end,
            overlay = R.vfx_particles,
            extras = R.draw_quest,
        })
        R.placement_form = R.town.placement_form
    end

    function R.island_screen(inp, dt)
        R.town:frame(inp, dt, R.overlay == R.OV_NONE)
    end

    ------------------------------------------------------------ story

    R.intro_lines = journey.beats[1].lines              -- the opening scene
    R.finale = journey.beats[#journey.beats].lines      -- its end opens the finale

    function R.queue_story(beat, preview, before_result)
        R.story_current = beat
        R.story_preview = preview
        R.story_before_result = before_result
        for _, line in ipairs(beat.lines) do story.add(line) end
    end

    local choices = ui.modals(skin)

    local function choice_reply(beat, index, preview)
        R.queue_story({key=beat.key, lines=beat.choices[index].lines}, preview)
    end

    function R.open_story_choice(beat, preview)
        local children = {{kind="label", text=beat.prompt, wrap=true, em=27}}
        for index, option in ipairs(beat.choices) do
            children[#children + 1] = {kind="button", id=tostring(index), text=option.label, height=54}
        end
        R.choice_form = ui.form{root={kind="column", panel=true, padding=22, gap=14, children=children}}
        if choices:active() then choices:close() end
        assert(choices:open(beat.key, R.choice_form, {}, {width=416, snap_backdrop=true, close_on_background=false}))
        R.story_choice_beat, R.story_choice_preview = beat, preview
        R.overlay = R.OV_STORY_CHOICE
    end

    function R.choose_story_option(index)
        local beat, preview = R.story_choice_beat, R.story_choice_preview
        if not beat or not beat.choices[index] then return false end
        choices:close()
        R.story_choice_beat, R.story_choice_preview = nil, nil
        R.overlay = R.OV_NONE
        if not preview then
            R.prog.story_choices = R.prog.story_choices or {}
            R.prog.story_choices[beat.key] = index
            R.save_progress()
        end
        choice_reply(beat, index, preview)
        return true
    end

    function R.draw_story_choice(dt)
        local event = choices:draw(dt, {reduced_motion=R.reduced_motion})
        if event and event.kind == "click" then R.choose_story_option(tonumber(event.id)) end
    end

    -- Acknowledge a finished beat, then start the next one that is due. The
    -- opening plays at once, even over the town a new game may start on.
    function R.story_tick()
        if R.story_current then
            if story.active() then return end
            local b = R.story_current
            R.story_current = nil
            if R.story_preview then R.story_preview = false; return end
            if R.story_before_result then
                R.story_before_result = false
                R.g.story_clear = b.key
                return
            end
            if b.choices then R.open_story_choice(b); return end
            if b.key == "recap" then R.prog.story_recap = false
            else R.prog.story_seen[b.key] = true end
            R.save_progress()
            if b.key == journey.beats[#journey.beats].key then R.overlay = R.OV_FINALE; return end
        end
        if R.quiet or story.active() then return end
        if R.overlay == R.OV_RESULT and R.g then
            local b = journey.result_beat(R.prog, R.g)
            if b then R.queue_story(b, false, true) end
            return
        end
        if R.overlay ~= R.OV_NONE or R.island.placing >= 0 then return end
        if R.prog.story_recap then
            R.on_island = true
            R.queue_story({key="recap", lines=journey.recap(R.prog.level)})
            return
        end
        local before = not R.on_island and R.g and R.g.level or (R.prog.level == 0 and 0 or nil)
        local b = journey.next(R.prog, function(kind) return island.owned(R.island, kind) > 0 end, before)
        if b then
            if b.phase ~= "before" then R.on_island = true end
            local reply = R.prog.story_choices and R.prog.story_choices[b.key]
            if reply then choice_reply(b, reply)
            else R.queue_story(b) end
        end
    end

    ------------------------------------------------------------- flow

    local function serialize(s)
        local version = s:int("version", journey.version)
        R.prog.level = s:int("level", R.prog.level)
        R.prog.seed = s:int("seed", R.prog.seed) & 0xFFFFFFFF
        R.prog.wallet = s:ints("wallet", R.prog.wallet)
        R.prog.lives = s:int("lives", R.prog.lives or rules.LIVES)
        R.prog.life_at = s:int("life_at", R.prog.life_at or 0)
        R.island:serialize(s)
        story.serialize(s)
        journey.serialize(s, R.prog)
        if save.is_reading(s) then
            R.prog.level = num.clampi(R.prog.level, 0, LEVELS)
            journey.migrate(R.prog, version)
            R.needs_relocation = island.restore_saved(R.island, R.prog.level)
        end
    end
    R.serialize = serialize

    local function progress_slot()
        return app.arg("debug-walkthrough") and "walkthrough" or "progress"
    end
    R.progress_slot = progress_slot

    function R.save_progress()
        if not R.test_mode then save.write(progress_slot(), serialize) end
    end

    function R.start_level(chosen)
        local lvl = num.clampi(chosen or R.prog.level, 0, LEVELS - 1)
        if lvl > R.prog.level then return false end
        if lvl == R.prog.level and owes_building() then R.notice(W.notices.build_first); return false end
        if lvl == R.prog.level and journey.awaiting_return(R.prog) then R.notice(W.notices.story_waiting); return false end
        if lvl == R.prog.level and R.quest_allows_board and not R.quest_allows_board(lvl + 1) then return false end
        rules.refill_lives(R.prog, app.clock())
        if R.prog.lives <= 0 then R.on_island = true; R.notice(W.notices.no_lives); return false end
        R.reset_board(rules.game_start(lvl, (R.prog.seed + lvl * 7919) & 0xFFFFFFFF))
        R.on_island = false
        R.overlay = R.OV_NONE
        R.intro = nil
        R.vfx_reset()
        -- Mechanics stay in the board lesson, apart from the story dialogue.
        if not R.quiet then
            local l = rules.level_of(R.g)
            R.mission(l.lesson, ("%d. %s"):format(lvl + 1, l.name)); R.present_board()
        end
        return true
    end

    function R.play_level(level)
        if R.g and R.g.level == level and not R.g.won and not R.g.lost then
            if level == R.prog.level and (owes_building() or journey.awaiting_return(R.prog)) then return false end
            if level == R.prog.level and R.quest_allows_board and not R.quest_allows_board(level + 1) then return false end
            R.on_island = false; R.overlay = R.OV_NONE
            if R.phase == R.PH_IDLE or R.phase == R.PH_PRESENT then R.present_board() end
            return true
        end
        return R.start_level(level)
    end

    -- After the results dialog closes: bank the reward and go build.
    function R.claim_reward()
        local paid, first = rules.progress_reward(R.prog, R.g, R.wonders)
        if not paid then return end
        if first and R.g.story_clear then R.prog.story_seen[R.g.story_clear] = true end
        if not app.arg("debug-walkthrough") then R.submit_scores() end
        R.save_progress()
        R.on_island = true
        R.overlay = first and R.g.story_clear == journey.beats[#journey.beats].key and R.OV_FINALE or R.OV_NONE
        R.notice(first and (journey.wonder_at(R.prog.level) and W.notices.reward_building or W.notices.reward_story) or W.notices.reward_replay)
    end

    -- Opt-in walkthrough controls use the same result and placement paths as play.
    function R.debug_skip_level()
        if R.on_island or not R.g or R.g.won or R.g.lost or R.overlay ~= R.OV_NONE then return false end
        local g = R.g
        g.score = math.max(g.score, rules.level_of(g).score)
        g.delivered, g.carpeted = g.delivery_total, g.carpet_total
        g.won = true
        R.overlay = R.OV_RESULT
        return true
    end

    function R.debug_complete_task()
        if not R.on_island or R.overlay ~= R.OV_NONE then return false end
        if R.island.placing >= 0 then return R.town:confirm() ~= nil end
        if owes_building() then
            local kind = island.wonder_count(R.island)
            if not R.town:begin(kind, false) then
                local zone = R.island:next_zone(R.prog.wallet)
                if zone >= 0 and R.island:zone_available(zone, R.prog.wallet) then R.expand() end
                return false
            end
            return R.town:confirm() ~= nil
        end
        if R.prog.level < LEVELS then return R.play_level(R.prog.level) end
        return false
    end

    -- Game Center (engine/gamecenter.lua docs: docs/GAMECENTER.md). game.json's
    -- "leaderboard" block turns it on: `board` holds the lifetime Discovery Stars,
    -- `level_board` (a format with the level number, e.g. "level_%02d") each
    -- expedition's best score. Scores are reported when a reward is claimed.
    local boards = require("leaderboard").boards{skin = skin, width = 400, texts = W.leaderboard and W.leaderboard.texts}
    function R.submit_scores()
        local c = W.leaderboard
        if not c then return end
        gamecenter.submit(c.board, R.prog.wallet[rules.STARS])
        if c.level_board and R.g then gamecenter.submit(c.level_board:format(R.g.level + 1), R.g.score) end
    end
    -- The board of the whole game, or of one expedition (0-based level).
    function R.open_leaderboard(level)
        local c = W.leaderboard
        if not c then return end
        if level and c.level_board then boards:open(c.level_board:format(level + 1), c.level_title:format(level + 1))
        elseif not level then boards:open(c.board, c.title) end
    end
    function R.leaderboard_active() return boards:active() end
    function R.draw_leaderboard(dt) boards:draw(dt, {reduced_motion = R.reduced_motion}) end

    require("match3.debug").bind(R, W)
    require("match3.vfx").bind(R, rules)
    return R
end

---------------------------------------------------------------------- app

-- The game's app description: the frame and init around the bound state.
function G.app(R)
    local W = R.words
    local rules = require("rules")
    local island = require("island")
    local journey = require("journey")
    local LEVELS = rules.LEVELS

    -- Town <-> board: the screen being left is covered (the town's camera dives
    -- into its newest building), then the other screen is uncovered while the
    -- board's pieces start to fall. engine/match3_dive.lua holds the styles.
    -- Game state switches at once; only drawing and input wait for the dive.
    local dive_styles = require("match3.dive")
    local dive, shown_island
    local function dive_focus()   -- the screen point the town zooms about
        local c, screen = R.island, app.screen()
        if c.count > 0 then
            local at = c.cam:rect_to_screen(c:sprite_rect(c.items[c.count])):center()
            if screen:inflate(-40):contains(at) then return at end
        end
        return screen:center()
    end
    function R.diving() return dive ~= nil end
    local function dive_watch()
        if shown_island ~= nil and shown_island ~= R.on_island and not R.reduced_motion
           and (not R.quiet or app.arg("dive")) then
            local label = R.on_island and nil or ("%d. %s"):format(R.g.level + 1, rules.level_of(R.g).name)
            dive = {t = 0, from_island = shown_island, town = dive_focus(), board = R.BOARD_CLIP:center(),
                    style = dive_styles.get(app.arg("dive-style") or (W.dive and W.dive.style)),
                    theme = dive_styles.theme(W.dive), label = label, say = R.say}
        end
        shown_island = R.on_island
    end
    local function dive_screen(world, dt)
        local s = dive.style
        local leaving = dive.t < s.out
        local u = leaving and dive.t / s.out or num.saturate((dive.t - s.out) / s.inn)
        local island_view = leaving == dive.from_island
        dive.focus = island_view and dive.town or dive.board
        if island_view then
            local cam = R.island.cam
            local zoom, pan = s.look(dive, leaving, u)
            local view = zoom ~= 1 and cam:zoom_at(zoom, dive.focus) or cam
            R.island.cam = pan and view:pan(pan) or view
            R.island_screen(world, dt)
            R.island.cam = cam
        else
            R.board_screen(world, dt)
            R.vfx_draw()
            R.vfx_particles()
        end
        gfx.bleed(true)
        s.draw(dive, leaving, u)
        gfx.bleed(false)
        dive.t = dive.t + dt
        if dive.t >= s.out + s.inn then dive = nil end
    end

    local function frame(dt)
        if app.arg("cell-mask") then
            -- Same flat-top polygon as a cell, captured at texture resolution.
            gfx.rect(rect(0, 0, R.SCREEN_W, R.SCREEN_H), color(0, 0, 0))
            gfx.ngon(vec2(R.SCREEN_W / 2, R.SCREEN_H / 2), 64, 6, 0, color.WHITE)
            return
        end
        local inp = input.get()
        R.story_tick()
        local talking = story.active()
        local board = R.leaderboard_active()
        R.layout()
        dive_watch()
        local world = (R.overlay ~= R.OV_NONE or talking or board or dive) and input{pos = inp.pos, pinch = 1} or input.world()
        tween.instant(R.reduced_motion)   -- reduced motion: every tween settles on its next frame
        if app.arg("smoke") then (app.arg("campaign") and R.campaign_smoke or R.smoke)() end
        R.debug_frame()
        R.now = R.now + dt
        if not talking then R.toast_time = R.toast_time - dt end
        if inp.back and not talking and R.overlay == R.OV_NONE then R.overlay = R.OV_PAUSE end

        if not (dive and dive.t < dive.style.out) then R.board_update(dt) end   -- the board waits behind the dive
        local now = app.clock()   -- lives return on the clock; a lost board costs one at once
        rules.refill_lives(R.prog, now)
        if rules.lose_life(R.prog, R.g, now) then R.save_progress() end
        R.vfx_update(dt)
        ui.set_enabled(R.overlay == R.OV_NONE and not talking and not board and not dive)
        if dive then dive_screen(world, dt)
        elseif R.on_island then R.island_screen(world, dt) else R.board_screen(world, dt) end
        if not R.on_island and not dive then
            R.vfx_draw()
            R.vfx_particles()
            R.draw_board_banners(dt)
        end
        if app.arg("debug-walkthrough") and not talking and not board and not dive
            and R.overlay == R.OV_NONE then
            local label = R.on_island and "Complete task" or "Skip level"
            local bounds = rect(318, R.on_island and 116 or R.hud_rect.y - 50, 152, 40)
            local state = ui.hit(bounds, 0)
            R.paint_button(bounds, state, true)
            R.say(label, bounds:inflate(-8), 18, R.PAL_CREAM)
            if state.clicked then
                if R.on_island then R.debug_complete_task() else R.debug_skip_level() end
            end
        end
        R.draw_toast()
        ui.set_enabled(true)
        local clear_due = not R.quiet and R.overlay == R.OV_RESULT and journey.result_beat(R.prog, R.g)
        if not talking and not clear_due then R.overlays(dt) end   -- the first-clear beat precedes the result
        if not talking then R.draw_leaderboard(dt) end   -- above every dialog, closing returns to it
        story.frame(dt)
        if story.active() and R.draw_story_item then R.draw_story_item() end
        -- Keep the HUD above ordinary dialogs. Results, the guide and
        -- leaderboard own the whole foreground.
        local hud_above = R.overlay ~= R.OV_RESULT and R.overlay ~= R.OV_GUIDE and not board
        if hud_above and (R.overlay ~= R.OV_NONE or talking) then
            ui.set_enabled(false)
            if R.on_island then R.town:header() else R.draw_board_hud() end
            ui.set_enabled(true)
        end
    end

    local function init()
        if app.arg("cell-mask") then return end
        R.font = R.skin:font("lilita")
        story.setup(R.cast, story_style{text = R.speech_style(21), name = R.pal(R.PAL_CREAM, W.speech.name), bubble = color(255, 246, 222, 252),
                                      edge = color(102, 68, 39), dim = color(5, 22, 22, 150), backdrop_blur = 7,
                                      portrait_height = .34, centered = true, inward = true,
                                      edge_to_edge = true, skip = "SKIP"})
        local art = require("art")
        local board_skin = art.skin()
        R.backdrop = board_skin.background
        R.scenes[1], R.scenes[2] = board_skin["scene-1"] or R.backdrop, board_skin["scene-2"] or R.backdrop
        -- match pieces: the first pack, or another (--tiles / ?tiles=)
        local function pack_kinds(pack)
            local kinds = {}
            for k = 0, rules.COLORS - 1 do kinds[k + 1] = board_skin[(app.arg("default-match3") and "kind-" or pack .. "-") .. k] end
            return kinds
        end
        local tiles = W.packs[1]
        for _, pack in ipairs(W.packs) do if app.arg("tiles") == pack then tiles = pack end end
        for i, t in ipairs(pack_kinds(tiles)) do R.relics[i] = t end
        R.board_art = art.load()
        R.shop_built_art, R.shop_locked_art = board_skin["shop-built"], board_skin["shop-locked"]   -- in the game's match3 atlas
        R.hud_art = art.load_hud()
        R.life_art = texture.load("expedition-hud/life.png")
        if app.arg("art-states") then
            R.art_packs = {}
            for _, pack in ipairs(W.packs) do R.art_packs[pack] = pack_kinds(pack) end
        end
        R.vfx_init()
        R.island = city.new()
        island.island_setup(R.island)
        R.buildings = R.island.defs   -- with the sprites loaded
        R.town_setup()
        R.wonders = {}
        for i = 1, island.WONDERS do R.wonders[i] = R.buildings[i] end

        R.sound = true
        R.inspect, R.zone_card = -1, -1
        R.test_mode = app.arg("smoke") ~= nil or app.arg("shot") ~= nil or app.arg("fresh") ~= nil
        R.quiet = app.arg("shot") ~= nil   -- stills skip the story unless asked for (--dialog)
        R.prog = {level = 0, seed = 782341, wallet = purse(), lives = rules.LIVES, life_at = 0, story_seen = {}}
        if not app.arg("smoke") then save.read(R.progress_slot(), R.serialize) end
        if app.arg("empty-lives") then R.prog.lives, R.prog.life_at, R.quiet = 0, app.clock() + rules.LIFE_INTERVAL, true end
        rules.refill_lives(R.prog, app.clock())
        if W.leaderboard and not app.arg("smoke") and not app.arg("debug-walkthrough") then
            gamecenter.submit(W.leaderboard.board, R.prog.wallet[rules.STARS])
        end
        R.story_current, R.story_preview, R.story_before_result = nil, false, false
        R.story_choice_beat, R.story_choice_preview = nil, nil
        R.layout()
        if not R.start_level() then
            -- A loaded zero-life wallet still needs an inert board for shared view
            -- updates. It cannot be resumed as an unfinished level.
            R.reset_board(rules.game_start(math.min(R.prog.level, LEVELS - 1), R.prog.seed))
            R.g.lost, R.g.life_paid = true, true
            R.on_island = true
        end
        if R.prog.level >= LEVELS then R.g.won = true end -- no unfinished attempt is created at campaign completion
        if journey.earned(R.prog.level) > island.wonder_count(R.island) or R.prog.level >= LEVELS then R.on_island = true end
        if R.needs_relocation then R.on_island = true; R.notice(W.notices.relocate) end
        if W.start_on_town and not app.arg("smoke") then R.on_island = true end
        R.debug_screens()
    end

    return {
        title = W.app.title,
        id = W.app.id,
        design = size2(R.SCREEN_W, R.SCREEN_H),
        fixed = true,
        max_aspect = 2.2,   -- tall phones (19.5:9) get a taller screen, not bars
        clear = hex(W.app.clear),
        init = init,
        frame = frame,
    }
end

return G
