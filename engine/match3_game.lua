-- match3_game.lua — the portrait match-3 city game around the board, shared by
-- Relic Rush and Christmas Market (`require("match3.game")`): progress and
-- saving, the level flow, the frame, the paint helpers and every
-- dialog (pause and its Restart confirmation, failed, region card, building
-- card, finale), the build shop, the level list, the town hooks, story
-- delivery, the journey's bookkeeping and the debug entry points.
--
-- A game is data: words in lua/game_config.lua (merged over DEFAULTS below), its
-- campaign and story, its skin and art tables. Its own Lua paints only what is
-- art: the board's cells and pieces (board.lua), the results card and guide
-- rows (screens.lua), the cast (narrative.lua).
--
--   -- screens.lua, first:   local R = require("match3.game").bind(require("state"))
--   -- main.lua, last:       return require("match3.game").app(R)
--
-- Game hooks the shared code calls (set on R by the game's modules):
--   R.register_result, R.register_guide   the results data and guide form
--   R.clear_scene(), R.draw_clear_scene(scene, inp)   optional presentation before the first-clear beat
--   R.wallet_icons()        three icons: unused, gold, unused (the gold capsule's is the second)
--   R.town_middle_icon(at)  the round middle button's icon in the town
--   R.cast                  the story cast (narrative.lua)
--   R.smoke(), R.campaign_smoke()   the --smoke runs
--   game_config.lua "leaderboard" {board, title, level_board, level_title}   Game Center boards (below)
-- See docs/PORTRAIT_GAMES.md.
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
        reward_building = "Building funded! Spare gold is yours to decorate.",
        reward_story = "Something is happening in town.",
        reward_replay = "Replay gold collected. Choose something in the shop.",
        relocate = "Some buildings need a new spot. Hold one to move it.",
        all_open = "The whole town is open.",
        quit = "Your board is saved. Tap LEVEL %d or the level list to continue.",
    },
    capsules = {
        notes = {"", "Gold buys buildings.", ""},
    },
    pause = {guide = "GUIDE", quit = "QUIT", leaderboard = "LEADERBOARD"},
    confirm = {title = "Restart this level?", body = "Restarting discards the resources you matched on this board.",
               restart = "RESTART", cancel = "KEEP PLAYING"},
    failed = {title = "One more try?", subtitle = "THE TOWN WILL WAIT FOR YOU.", hint = "Look for longer lines or use a tool.",
              retry = "TRY AGAIN", town = "VISIT TOWN"},
    zone = {subtitle = "A NEW PLACE TO DISCOVER", cleared = "LEVELS CLEARED  %d / %d", earn = "CLEAR NEW LEVELS TO OPEN IT",
            open = "OPEN THIS AREA", wait = "KEEP EXPLORING", close = "CLOSE"},
    finale = {title = "To be continued", lines = {}, button = "BACK TO TOWN"},
    card = {move = "MOVE THIS BUILDING", build = "CHOOSE A LOCATION", repair = "RESTORE ON SITE", back = "BACK TO TOWN",
            moving = "HOLD AND DRAG IN TOWN TO MOVE", locked = "COMPLETE MORE LEVELS TO BUILD THIS", close = "CLOSE"},
    catalogue = {
        title = "Build your town", close = "BACK TO TOWN",
        categories = {{"all", "Everything"}, {"wonder", "Story buildings"}, {"building", "Buildings"}},
        category = "all",
        build = "BUILD", built = "BUILT", complete = "COMPLETE LEVEL %d", earlier = "BUILD EARLIER BUILDINGS",
        cleared = "CLEAR %d LEVELS", poor = "MORE GOLD NEEDED", reserved = "GOLD RESERVED FOR BUILDINGS", full = "TOWN IS FULL",
        row = "%d x %d tiles  ·  Owned %d",
    },
    expeditions = {
        title = "Levels", close = "BACK TO TOWN",
        locked = "LOCKED", resume = "RESUME", replay = "REPLAY", pending = "BUILD FIRST", new = "NEW LEVEL", earlier = "COMPLETE EARLIER LEVELS",
        resume_note = "Continue the unfinished board. Rewards come with a win.",
        replay_note = "Gold only.", building_note = "First clear: building funded.", story_note = "First clear: the next scene.",
    },
    debug = {victory = 1, catalogue_card = 10, narrator = ""},
}

local function merge(base, over)
    if type(over) ~= "table" then return base end
    if #over > 0 or type(base) ~= "table" then return over end   -- arrays replace
    local out = {}
    for k, v in pairs(base) do out[k] = v end
    for k, v in pairs(over) do
        if type(v) == "table" and type(base[k]) == "table" and #v == 0 then out[k] = merge(base[k], v)
        else out[k] = v end
    end
    return out
end
G.merge = merge

-- The game's lua/game_config.lua over the defaults; a table also works (tests).
function G.config(over) return merge(G.DEFAULTS, over or require("game_config")) end

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
        -- A 9 x 12 board between the HUD and the bonus tray on a 480 x 900
        -- screen; the cell art is painted at a 26.5 px radius.
        HEX_R = 30,
        hit_dy = 0,          -- where the open dialog's buttons sit below their layout

        intro = nil,

        -- overlays and board phases
        OV_NONE = 0, OV_GUIDE = 1, OV_PAUSE = 2, OV_RESULT = 3, OV_FAILED = 4, OV_WONDER = 5, OV_FINALE = 6, OV_ZONE = 7, OV_SHOP = 8, OV_EXPEDITIONS = 9, OV_CONFIRM = 10, OV_STORY_CHOICE = 11,
        PAL_GOLD = "gold", PAL_CREAM = "cream", PAL_GREEN = "green", PAL_WHITE = "white", PAL_SHORT = "short",   -- text styles in skin.lua

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
    }
end

----------------------------------------------------------------- ladder

-- A Cradle of Rome campaign ladder: catalogue buildings bought in order, each
-- adding one piece or bonus. `island` is the game's map module with
-- `buildings`, `WONDERS`, `owned` and `wonder_count`. `unlocks` lists the
-- steps in purchase order: {building=key, after=clear, ...}. Story buildings
-- are types 0..WONDERS-1 and keep the journey's schedule; they hold the next
-- new level. The others open after their clear and must be placed before the
-- next story building. A save from before the ladder waives the ones it had
-- passed: those stay on sale and never block. Installs on `island`: ladder,
-- ladder_position, catalogue_order, next_step, next_build, ladder_blocked,
-- campaign_count, reserved_cost, can_spend, can_buy, waived, set_waived and
-- waive_passed. `slots` is the number of spendable wallet slots.
local function wonder_kind(island, index)
    if island.wonder_kinds then return island.wonder_kinds[index] end
    return index - 1
end

function G.campaign_ladder(island, unlocks, journey, slots)
    local M, WONDERS = island, island.WONDERS
    M.ladder, M.ladder_position = {}, {}
    local type_of = {}
    for i, d in ipairs(M.buildings) do type_of[d.key] = i - 1 end
    local story_index, optional = {}, {}
    for i = 1, WONDERS do story_index[wonder_kind(island, i)] = i end
    for _, unlock in ipairs(unlocks) do
        local kind = assert(type_of[unlock.building], unlock.building)
        local index = story_index[kind]
        assert(not index or unlock.after == journey.wonder_levels[index], unlock.building .. " follows the story schedule")
        if unlock.optional then
            optional[kind] = unlock.after
        else
            local n = #M.ladder + 1
            M.ladder[n] = {kind=kind, unlock=unlock, after=unlock.after, story=index ~= nil}
            M.ladder_position[kind] = n
        end
    end
    -- The shop lists the ladder in purchase order, then everything else.
    M.catalogue_order = {}
    for _, step in ipairs(M.ladder) do M.catalogue_order[#M.catalogue_order + 1] = step.kind + 1 end
    for i in ipairs(M.buildings) do
        if not M.ladder_position[i - 1] then M.catalogue_order[#M.catalogue_order + 1] = i end
    end

    -- Waived positions, {[position]=true}, per city (a city takes no new fields).
    local waivers = setmetatable({}, {__mode = "k"})
    local function waived(c, n) return waivers[c] and waivers[c][n] end
    function M.waived(c) return waivers[c] or {} end
    function M.set_waived(c, positions) waivers[c] = positions end

    -- The next building to place and its position. The type is nil while that
    -- one waits for a later clear.
    function M.next_step(c, level)
        for n, step in ipairs(M.ladder) do
            if not waived(c, n) and M.owned(c, step.kind) == 0 then
                if step.after <= level then return step.kind, n end
                return nil, n
            end
        end
    end

    function M.next_build(c, level) return M.next_step(c, level) or wonder_kind(island, M.wonder_count(c) + 1) end

    -- Why a ladder building cannot be placed now: "built", "later" (with the
    -- clear it waits for) or "earlier" (another comes first). False when it
    -- can, nil for shop items.
    function M.ladder_blocked(c, level, kind)
        local n = M.ladder_position[kind]
        if not n then
            if optional[kind] then
                if M.owned(c, kind) > 0 then return "built" end
                if optional[kind] > level then return "later", optional[kind] end
            end
            return nil
        end
        local step = M.ladder[n]
        if M.owned(c, kind) > 0 then return "built" end
        if step.after > level then return "later", step.after end
        if not waived(c, n) and M.next_step(c, level) ~= kind then return "earlier" end
        return false
    end

    -- Ladder positions the story requires by `level`: everything up to the
    -- latest story building it has earned.
    local function required_through(level)
        local earned, last = journey.earned(level), 0
        for n, step in ipairs(M.ladder) do
            if step.story and story_index[step.kind] <= earned then last = n end
        end
        return last
    end

    function M.campaign_count(c)
        local n = 0
        for _, b in ipairs(c.items) do if M.ladder_position[b.type] then n = n + 1 end end
        return n
    end

    -- Keep the buildings the story requires affordable in the finite economy.
    function M.reserved_cost(c, level)
        local cost = purse()
        for n = 1, required_through(level) do
            local step = M.ladder[n]
            if not waived(c, n) and M.owned(c, step.kind) == 0 then cost = cost + M.buildings[step.kind + 1].cost end
        end
        return cost
    end

    function M.can_spend(c, wallet, level, cost)
        local reserved = M.reserved_cost(c, level)
        for slot = 1, slots do
            if cost[slot] > 0 and wallet[slot] - reserved[slot] < cost[slot] then return false end
        end
        return true
    end

    function M.can_buy(c, wallet, level, kind)
        if kind < 0 or kind >= #M.buildings or c.count >= 160 then return false end
        local d = M.buildings[kind + 1]
        local blocked = M.ladder_blocked(c, level, kind)
        if blocked then return false end
        if blocked == nil and not M.can_spend(c, wallet, level, d.cost) then return false end
        return wallet:covers(d.needs) and wallet:covers(d.cost)
    end

    -- Waive the non-story steps before the latest earned story building.
    function M.waive_passed(c, level)
        local positions = waivers[c] or {}
        for n = 1, required_through(level) do
            local step = M.ladder[n]
            if not step.story and M.owned(c, step.kind) == 0 then positions[n] = true end
        end
        waivers[c] = positions
    end

    -- Save the waivers as a bit mask beside the game's campaign data. A read
    -- from a save older than the ladder (`predates`) waives what it passed.
    function M.serialize_waivers(s, c, level, predates)
        local mask = 0
        for n in pairs(M.waived(c)) do mask = mask | (1 << (n - 1)) end
        mask = s:int("ladder_waived", mask)
        if not save.is_reading(s) then return end
        local positions = {}
        for n in ipairs(M.ladder) do
            if mask & (1 << (n - 1)) ~= 0 then positions[n] = true end
        end
        M.set_waived(c, positions)
        if predates then M.waive_passed(c, level) end
    end
    return M
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

    function M.result_beat(p, g, level)
        if not g.won or g.level ~= p.level or not (M.clear_before_result or level and level.reveal) then return end
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
                    if ((b.phase == "after" and M.clear_before_result) or not wonder or owns(wonder - 1))
                        and (not M.ready or M.ready(p, b)) then return b end
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
    function R.paint_button(r, st, enabled)
        skin:paint("button", r, {hot = st.hot, held = st.held, disabled = not enabled})
    end
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

    -- The wallet row. capsules.show in game_config.lua lists what it holds, in order:
    -- a currency's id (its capsule's `id`; "gold" when the
    -- game has one currency). Without the list it holds them all. A board with
    -- several currencies shows only those, at the shared row's width.
    function R.header_capsules(board)
        local currencies = R.currency_capsules and R.currency_capsules(R.prog.wallet)
        local icons, notes = R.wallet_icons(), W.capsules.notes
        local all, by_id = {}, {}
        local function add(id, capsule)
            capsule.id = id
            all[#all + 1], by_id[id] = capsule, capsule
        end
        if currencies then
            for i, capsule in ipairs(currencies) do
                capsule.slot = capsule.slot or i
                if board then capsule.width = nil end
                add(capsule.id or tostring(capsule.slot), capsule)
            end
        else add("gold", {icon=icons[2], value=tostring(R.prog.wallet[rules.GOLD]), note=notes[2]}) end
        local show = W.capsules.show
        if not show then return all end
        local out = {}
        for _, id in ipairs(show) do
            assert(by_id[id], "capsules.show names no capsule: " .. id)
            out[#out + 1] = by_id[id]
        end
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

    local function price_parts(cost)
        if R.currency_prices then return R.currency_prices(cost) end
        return {{id="gold", amount=cost[rules.GOLD], icon=R.wallet_icons()[2]}}
    end

    -- The campaign building to place next. A game whose campaign is more than
    -- types 0..WONDERS-1 in order supplies island.next_build.
    local function next_build()
        if island.next_build then return island.next_build(R.island, R.prog.level) end
        return island.wonder_count(R.island)
    end
    -- Why a campaign building cannot be placed now ("built", "later" with the
    -- clear it waits for, "earlier"), false when it can, nil for shop items.
    local function ladder_blocked(kind, owned)
        if island.ladder_blocked then return island.ladder_blocked(R.island, R.prog.level, kind) end
        if kind >= island.WONDERS then return nil end
        if owned > 0 then return "built" end
        local at = journey.wonder_levels[kind + 1]
        if at > R.prog.level then return "later", at end
        if kind ~= island.wonder_count(R.island) then return "earlier" end
        return false
    end

    local popups = {}
    local function popup(id, form, config)
        assert(form.root.kind == "column" and not popups[id], "popup requires a unique vertical form")
        assert(form.root.children[1] and form.root.children[1].role == "popup_header", "popup requires a shared header")
        popups[id] = config
        config.form = form
    end

    function R.register_result(model)
        local form = ui.form{kind="column",panel=true,padding={21,20,21,23},gap=15,children={
            match3.popup_header("Results"),
            {kind="column",gap=1,paint_group={.24,.32,9},children={
                {kind="label",text="SCORE",em=13,text_style="cream"},
                {kind="label",id="score",em=44,text_style="gold"},
            }},
            {kind="column",gap=7,paint_group={.62,.28,10},children={
                {kind="label",text="RESOURCES TO BANK",em=13,text_style="cream"},
                {kind="list",id="resources",direction="row",gap=9,item=function(entry)
                    return {kind="column",grow=1,panel=true,role="result_resource",padding={4,5,4,7},gap=1,children={
                        {kind="image",image=entry.icon,height=36},
                        {kind="label",text=entry.amount,em=25,text_style="gold"},
                        {kind="label",text=entry.name,em=13,text_style="cream"},
                    }}
                end},
            }},
            {kind="row",id="next_step",visible_field="show_next",panel=true,role="group",
                padding={9,8,10,8},gap=10,align="center",paint_group={.9,.26,8},children={
                    {kind="image",id="next_icon",width=58,height=58,visible_field="show_next_icon"},
                    {kind="column",grow=1,gap=2,children={
                        {kind="label",id="next_heading",wrap=true,text_align="start",em=12,text_style="cream"},
                        {kind="label",id="next_title",wrap=true,text_align="start",em=21,text_style="gold"},
                        {kind="label",id="next_detail",visible_field="show_next_detail",
                            wrap=true,text_align="start",em=12,text_style="gold"},
                    }},
                }},
            {kind="button",id="claim",height=54,paint_group={1.02,.22,8}},
        }}
        R.result_form = form
        popup(R.OV_RESULT, form, {width=408, dismiss=false, prepare=function(d)
            local count = R.dialog_part(.43, .65).f
            form:set("score", tostring(math.floor(R.g.score * count + .5)))
            if not d.fresh then return end
            local data = model()
            local next_step = data.next_step
            match3.set_popup_header(form, data.title, data.subtitle)
            form:set("claim", data.action)
            assert(form:set_items("resources", data.resources))
            form.values.show_next = next_step ~= nil
            form.values.show_next_icon = next_step and next_step.icon ~= nil
            form.values.show_next_detail = next_step and next_step.detail ~= nil
            if next_step then
                form:set("next_icon", next_step.icon):set("next_heading", next_step.heading)
                    :set("next_title", next_step.title):set("next_detail", next_step.detail)
            end
        end, handle=function(event)
            if event.id ~= "claim" or R.modal_closing then return end
            if R.dialog_settled() then R.close_dialog() else R.dialog_skip() end
        end})
    end

    function R.register_guide(form)
        popup(R.OV_GUIDE, form, {width=432, shift=10, handle=function() R.overlay = R.OV_NONE end})
    end

    -- The building card: a story building or a shop item, to build or move.
    local wonder_form = ui.form{
        root = {kind="column", panel=true, padding={24,20,24,18}, gap=14, children={
            match3.popup_header("Building details"),
            {kind="image", id="sprite", height=205},
            {kind="label", id="about", wrap=true, em=22, text_style=PAL_CREAM},
            {kind="label", id="unlock", wrap=true, em=17, text_style=PAL_GOLD, visible_field="show_unlock"},
            {kind="row", height=78, align="center", visible_field="show_price", children={
                {kind="spacer",grow=1},
                {kind="list",id="price",direction="row",gap=10,item=function(entry)
                    return {kind="column",width=90,gap=4,children={
                        {kind="image",image=entry.icon,height=33},
                        {kind="label",text=tostring(entry.amount),height=25,em=23},
                        {kind="label",text=entry.name or "",height=12,em=11,text_style=PAL_CREAM},
                    }}
                end},
                {kind="spacer",grow=1},
            }},
            {kind="label",id="notice",wrap=true,em=15,text_style=PAL_CREAM,visible_field="show_notice"},
            {kind="button",id="action",height=56},
            {kind="button",id="close",text=W.card.close,height=28,flat=true,em=16},
        }},
        bindings={
            {id="sprite",field="sprite",type="texture",readonly=true},
            {id="about",field="about",readonly=true},{id="action",field="action",readonly=true},
        },
    }
    R.wonder_form = wonder_form
    local wonder_action
    popup(R.OV_WONDER, wonder_form, {width=420, prepare=function()
        local i = R.inspect >= 0 and R.inspect or next_build()
        if not i or i < 0 or i >= #R.buildings then return false end
        local w = R.buildings[i + 1]
        local unlock_text = island.buildings[i + 1].unlock_text
        local can_build, built = island.can_buy(R.island, R.prog.wallet, R.prog.level, i), R.inspect_item and R.inspect_item >= 0
        local fixed = w.fixed_site and (w.fixed_site.x ~= 0 or w.fixed_site.y ~= 0)
        local movable = built and not fixed
        match3.set_popup_header(wonder_form, w.name)
        local ok, message = wonder_form:push{sprite=w.sprite, about=journey.building_about(i, R.prog.level, w.about),
            action=movable and W.card.move or can_build and (fixed and W.card.repair or W.card.build) or W.card.back}
        assert(ok, message)
        local show_price = not built and (can_build or R.currency_prices and w.needs and
            R.prog.wallet:covers(w.needs) and (i >= island.WONDERS or i < journey.earned(R.prog.level)))
        wonder_form.values.show_price, wonder_form.values.show_notice = show_price, not show_price
        wonder_form.values.show_unlock = unlock_text ~= nil
        wonder_form:set("unlock", unlock_text or "")
        assert(wonder_form:set_items("price", price_parts(w.cost)))
        wonder_form:set("notice", built and (fixed and "RESTORED AT ITS ORIGINAL SITE" or W.card.moving) or W.card.locked)
        wonder_action = (can_build or movable) and {kind=i, item=movable and R.inspect_item or nil} or nil
    end, handle=function(event)
        local action = wonder_action
        if event.id == "action" and action then R.island_begin(action.kind, true, action.item)
        else R.overlay = R.OV_NONE end
    end})

    local pause_form = match3.pause_form(W.pause.guide, W.pause.quit, W.leaderboard and W.pause.leaderboard)
    R.pause_form = pause_form
    popup(R.OV_PAUSE, pause_form, {width=396, shift=W.leaderboard and 24 or 0, prepare=function()
        local level
        if not R.on_island then level = ("%d. %s"):format(R.g.level + 1, rules.level_of(R.g).name) end
        assert(pause_form:push(R))
        pause_form.values.expedition = not R.on_island
        match3.set_popup_header(pause_form, "Settings", level)
    end, handle=function(event)
        local action = event.id
        if event.kind == "change" then
            assert(pause_form:pull(R))
            sfx.enable(R.sound)
        elseif action == "resume" then R.overlay = R.OV_NONE
        elseif action == "guide" then R.overlay = R.OV_GUIDE
        elseif action == "restart" then R.overlay = R.OV_CONFIRM
        elseif action == "leaderboard" then R.open_leaderboard()
        elseif action == "quit" then   -- the unfinished board waits in town
            R.on_island, R.overlay = true, R.OV_NONE
            R.notice(W.notices.quit:format(R.g.level + 1))
        end
    end})

    local confirm_form = ui.form{kind="column",panel=true,padding={36,22,36,18},gap=14,children={
        match3.popup_header(W.confirm.title, W.confirm.body),
        {kind="button",id="confirm",text=W.confirm.restart,height=50},
        {kind="button",id="cancel",text=W.confirm.cancel,height=32,role="link",em=20},
    }}
    R.confirm_form = confirm_form
    popup(R.OV_CONFIRM, confirm_form, {width=396, handle=function(event)
        if event.id == "confirm" then R.start_level(R.g.level); R.overlay = R.OV_NONE
        else R.overlay = R.OV_PAUSE end
    end})

    local failed = W.failed
    popup(R.OV_FAILED, ui.form{kind="column",panel=true,padding={32,24,32,22},gap=14,children={
        match3.popup_header(failed.title, failed.subtitle),
        {kind="label",text=failed.hint,wrap=true,em=17,text_style=PAL_CREAM},
        {kind="button",id="retry",text=failed.retry,height=50},
        {kind="button",id="town",text=failed.town,height=42,role="secondary"},
    }}, {width=404, dismiss=false, handle=function(event)
        if event.id == "retry" then R.start_level(R.g.level) else R.on_island, R.overlay = true, R.OV_NONE end
    end})

    local region = W.zone
    local zone_form = ui.form{kind="column",panel=true,padding={32,24,32,20},gap=14,children={
        match3.popup_header("Region"),
        {kind="label",id="cleared",wrap=true,em=24,text_style=PAL_GOLD},
        {kind="label",text=region.earn,wrap=true,em=19,text_style=PAL_CREAM},
        {kind="button",id="open",height=47},
        {kind="button",id="close",text=region.close,height=32,role="link",em=16},
    }}
    popup(R.OV_ZONE, zone_form, {width=420, prepare=function()
        local z = R.zone_card
        local zone = R.island.zones[z + 1]
        match3.set_popup_header(zone_form, zone.name, region.subtitle)
        zone_form:set("cleared", region.cleared:format(R.prog.wallet[rules.CLEARED], zone.needs[rules.CLEARED]))
            :set("open", R.island:zone_available(z, R.prog.wallet) and region.open or region.wait)
    end, handle=function(event)
        local z = R.zone_card
        if event.id == "open" and R.island:unlock(z, R.prog.wallet) then
            R.island_focus(R.island.zones[z + 1].marker, R.island.cam.zoom)
            R.save_progress()
            if journey.regions[z] then story.add({W.region_speaker, journey.regions[z], story.SHOUT}) end
            R.tone(820)
        end
        R.overlay = R.OV_NONE
    end})

    local finale = {match3.popup_header(W.finale.title)}
    for _, line in ipairs(W.finale.lines) do
        finale[#finale+1] = {kind="label",text=line[1],wrap=true,em=line[2],text_style=line[3] or PAL_WHITE}
    end
    finale[#finale+1] = {kind="button",id="back",text=W.finale.button,height=50}
    popup(R.OV_FINALE, ui.form{kind="column",panel=true,padding=24,gap=14,children=finale},
        {width=416, dismiss=false, handle=function() R.overlay = R.OV_NONE end})

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
        local modal = assert(popups[before], "overlay has no vertical popup form")
        if modal.prepare and modal.prepare(d) == false then R.overlay = R.OV_NONE; reset_paint(); R.hit_dy = 0; return end
        local width = math.min(modal.width, R.SCREEN_W - 32)
        local _, height = modal.form:measure(width, skin)
        local bounds = rect.centered(vec2(240, 450 + (modal.shift or 0)), size2(width, height))
        R.modal_bounds = pr(bounds)
        local covered = R.leaderboard_active()   -- a board above this dialog owns the input
        local event = modal.form:draw(bounds, skin, {hit_offset=vec2(0, R.hit_dy), interactive=not covered and not d.fresh, dt=dt,
            paint_scope=function(group, draw)
                local previous = R.section(table.unpack(group))
                local action = draw()
                set_paint(previous)
                return action
            end})
        if event then modal.handle(event) end
        if R.overlay == before and modal.dismiss ~= false and not R.modal_closing and not covered
                and ui.modal_dismiss(R.modal_bounds, {fresh=d.fresh}) then R.overlay = R.OV_NONE end
        d.fresh = false
        reset_paint()
        R.hit_dy = 0
    end

    ----------------------------------------------------- shop and levels

    -- Modal lists: the engine owns measured rows, focus, hit testing and
    -- input capture. Backdrops snap in, like every popup.
    -- Both lists are full-screen sheets from under the wallet row to the
    -- bottom of the safe screen; a tap on the strip around them closes.
    local function sheet(screen)
        local header = R.town.cfg.header
        local top = screen.y + header.y + (header.band_height or header.height)
        return rect(screen.x + 8, top, screen.w - 16, screen:max().y - 10 - top)
    end
    local MODAL = {bounds=sheet, snap_backdrop=true, blur=7, dim=color(5, 22, 22, 185), cancel="close"}
    local C = W.catalogue
    local categories, category = C.categories, 1
    for i, cat in ipairs(categories) do if cat[1] == C.category then category = i end end
    local shop = ui.modals(skin)
    local ACTION_W = 100   -- the right-hand column: the action pill or why it waits
    local function row_card(box, face)
        R.rrect(box:offset(vec2(0, 2)), 13, rgba(201, 164, 100))
        R.rrect(box, 13, face)
    end
    local ROW_FACE, ROW_DIM, ROW_CURRENT = rgba(255, 246, 214), rgba(243, 229, 192), rgba(255, 228, 150)
    -- The row's action in the skin's own button, so each game keeps its colours.
    local function action_pill(box, label, on)
        skin:paint("button", box, {disabled = not on})
        R.say(label, box, 14, PAL_CREAM)
    end
    -- One building: art, name, what it brings, the whole price (an amount the
    -- wallet cannot cover is in the skin's "short" style) and the action.
    local function paint_row(box, record)
        local locked = record.state == "locked"
        row_card(box, record.state == "ready" and ROW_FACE or ROW_DIM)
        local right = rect(box.x + box.w - ACTION_W - 6, box.y, ACTION_W, box.h)
        local side = box.h - 12
        R.picture_fit(record.sprite, rect(box.x + 6 + (72 - side) / 2, box.y + 6, side, side), locked and 130 or 255)
        local x = box.x + 88   -- every row's text starts after the tall rows' art
        if record.slim then   -- built: its art, its name and a tick
            R.say_left(record.name, rect(x, box.y, right.x - x - 4, box.h), 17, PAL_CREAM)
            R.picture_fit(R.shop_built_art, rect(right.x + 2, box.y + (box.h - 26) / 2, 26, 26), 255)
            R.say_left(record.action, rect(right.x + 32, box.y, right.w - 32, box.h), 12, PAL_CREAM)
            return
        end
        local w = right.x - x - 4
        R.say_left(record.name, rect(x, box.y + 6, w, 24), 18, PAL_GOLD)
        R.say_left(record.note, rect(x, box.y + 31, w, 16), 12, PAL_CREAM)
        local step = math.min(64, w / #record.prices)
        for k, part in ipairs(record.prices) do
            local px = x + (k - 1) * step
            R.picture_fit(part.icon, rect(px, box.y + 52, 22, 22), 255)
            R.say_left(tostring(part.amount), rect(px + 25, box.y + 51, step - 25, 24), 16, part.short and R.PAL_SHORT or PAL_CREAM)
        end
        if record.available then action_pill(rect.centered(right:center(), size2(ACTION_W - 8, 34)), C.build, true)
        elseif locked then
            R.picture_fit(R.shop_locked_art, rect.centered(vec2(right:center().x, box.y + 22), size2(26, 26)), 255)
            R.paragraph(record.action, rect(right.x, box.y + 36, right.w, box.h - 42), 11, PAL_CREAM)
        else R.paragraph(record.action, right:inflate(-2), 11, PAL_CREAM) end
    end
    local catalogue_form = match3.catalogue_form(C.title, C.close, paint_row)
    R.catalogue_form = catalogue_form

    local tiles = {}   -- building key -> its row record
    local catalogue_rows = {}
    for i in ipairs(island.catalogue) do catalogue_rows[i] = i end
    local function refresh_catalogue()
        local records = {}
        local cat = categories[category][1]
        local wallet = R.prog.wallet
        -- A game may list its catalogue in another order (rows stay save data).
        for _, i in ipairs(island.catalogue_order or catalogue_rows) do
            local meta = island.catalogue[i]
            if cat == "all" or meta.category == cat then
                local def = R.buildings[i]
                local owned = island.owned(R.island, i - 1)
                local available = island.can_buy(R.island, wallet, R.prog.level, i - 1)
                local action, state = C.build, "ready"
                local blocked, at = ladder_blocked(i - 1, owned)
                if blocked ~= nil then
                    local reason = blocked == "built" and C.built or blocked == "later" and C.complete:format(at) or
                        blocked == "earlier" and C.earlier
                    if reason then action, state = reason, owned > 0 and "built" or "locked" end
                    if not reason and not wallet:covers(def.cost) then action, state = C.poor, "poor" end
                elseif wallet[rules.CLEARED] < meta.cleared then action, state = C.cleared:format(meta.cleared), "locked"
                elseif not wallet:covers(def.cost) then action, state = C.poor, "poor"
                elseif island.can_spend and not island.can_spend(R.island, wallet, R.prog.level, def.cost)
                    or not island.can_spend and wallet[rules.GOLD] - island.reserved_gold(R.island, R.prog.level) < def.cost[1] then
                    action, state = C.reserved, "poor"
                elseif R.island.count >= 160 then action, state = C.full, "poor" end
                local parts = price_parts(def.cost)
                for _, part in ipairs(parts) do part.short = wallet[part.slot or rules.GOLD] < part.amount end
                local note = meta.unlock_text or C.row:format(meta.size.w, meta.size.h, owned)
                local record = {id=meta.key, kind=i - 1, name=def.name, sprite=def.sprite, prices=parts, state=state,
                    note=note, available=available, action=action, slim=state == "built"}
                records[#records + 1], tiles[meta.key] = record, record
            end
        end
        assert(catalogue_form:set_items("stock", records))
        catalogue_form:set("category", categories[category][2])
        return records
    end

    -- The row's button node and record for a building key, for smoke tests that press it.
    function R.catalogue_tile(key)
        for _, node in pairs(catalogue_form.nodes) do
            if node.local_id == "pick" and node.item_key == key and catalogue_form:get_item("stock", key) then
                return node, tiles[key]
            end
        end
    end

    function R.open_catalogue(filter, review_page)
        local old_category = category
        if filter then
            for i, cat in ipairs(categories) do if cat[1] == filter then category = i end end
        end
        if shop:active() then shop:close() end
        local records = refresh_catalogue()
        if review_page and #records > 0 then   -- review pages are six rows apart
            catalogue_form:scroll_to("stock", records[num.clampi((math.floor(review_page) - 1) * 6 + 1, 1, #records)].id)
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
            local record = catalogue_form:get_item("stock", event.key)
            if record and record.available then shop:close(); R.island_begin(record.kind, true) end
        end
    end

    -- Repeatable earning and the one-time story track share one level list.
    local E = W.expeditions
    local levels = ui.modals(skin)
    local function paint_level(box, e)
        local current, locked = e.state == "current", e.state == "locked"
        row_card(box, current and ROW_CURRENT or locked and ROW_DIM or ROW_FACE)
        local c = vec2(box.x + 30, box:center().y)
        gfx.circle(c, 19, rgba(77, 58, 31))
        gfx.circle(c, 17, current and rgba(184, 60, 60) or locked and rgba(140, 150, 136) or rgba(44, 108, 84))
        R.say(tostring(e.number), rect.centered(c, size2(34, 24)), 17, PAL_CREAM)
        local right = rect(box.x + box.w - ACTION_W - 14, box.y + 6, ACTION_W + 8, 25)
        R.say_left(e.name, rect(box.x + 58, box.y + 7, right.x - box.x - 62, 26), 18, locked and PAL_CREAM or PAL_GOLD)
        R.say_left(e.note, rect(box.x + 58, box.y + 36, box.w - 66, 18), 12, PAL_CREAM)
        if e.available or current then action_pill(right, e.action, e.available)
        else
            R.picture_fit(R.shop_locked_art, rect(right.x, right.y + 1, 26, 26), 255)
            R.say_left(E.locked, rect(right.x + 30, right.y + 1, right.w - 30, 26), 13, PAL_CREAM)
        end
    end
    local expedition_form = match3.expedition_form(E.title, E.close, paint_level)
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

    -- Opens near the current level (or a review page of three).
    function R.open_expeditions(review_page)
        refresh_levels()
        -- The current level opens with the last two clears above it.
        local level = review_page and (math.floor(review_page) - 1) * 3 or math.min(R.prog.level, LEVELS - 1) - 2
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
        R.town = town.new(R.island, require("town_config"), {
            skin = skin,
            wallet = function() return R.prog.wallet end,
            notice = R.notice,
            capsules = R.header_capsules,
            pause = function() R.overlay = R.OV_PAUSE end,
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
            suggest = function(kind) return island.island_suggestion(kind) end,
            placed = function(ev)
                for k = 0, 23 do R.vfx_emit(ev.screen - vec2(0, 30), k % 6, false) end
                R.tone(740)
                R.save_progress()   -- the building's story beat follows from R.story_tick
            end,
            bubble_text = function() return R.speech_style(15) end,
            reduced_motion = function() return R.reduced_motion end,
            overlay = R.vfx_particles,
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
        local children = {match3.popup_header(beat.prompt)}
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
            if require("match3.elements_view").reveal_holding(R, rules) then return end   -- the finished picture first
            if R.clear_scene and R.clear_scene() then return end
            local b = journey.result_beat(R.prog, R.g, rules.level_of(R.g))
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
        local b = journey.next(R.prog, function(index) return island.owned(R.island, wonder_kind(island, index + 1)) > 0 end, before)
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
        -- The fourth slot counts boards cleared. Saves from the star economy
        -- held three stars a board there, so it is always rebuilt from the level.
        if save.is_reading(s) then R.prog.wallet[rules.CLEARED] = R.prog.level end
        R.island:serialize(s)
        story.serialize(s)
        journey.serialize(s, R.prog)
        if save.is_reading(s) then
            R.prog.level = num.clampi(R.prog.level, 0, LEVELS)
            journey.migrate(R.prog, version)
            R.needs_relocation = island.restore_saved(R.island, R.prog.level)
        end
        if R.serialize_campaign then R.serialize_campaign(s) end
    end
    R.serialize = serialize

    local function progress_slot()
        return app.arg("debug-walkthrough") and "walkthrough" or "progress"
    end
    R.progress_slot = progress_slot

    function R.save_progress()
        if not R.test_mode then save.write(progress_slot(), serialize) end
    end

    function R.make_board(level, seed, preview)
        return rules.game_start(level, seed, R.board_context and R.board_context(preview))
    end

    function R.start_level(chosen)
        local lvl = num.clampi(chosen or R.prog.level, 0, LEVELS - 1)
        if lvl > R.prog.level then return false end
        if lvl == R.prog.level and owes_building() then R.notice(W.notices.build_first); return false end
        if lvl == R.prog.level and journey.awaiting_return(R.prog) then R.notice(W.notices.story_waiting); return false end
        R.reset_board(R.make_board(lvl, (R.prog.seed + lvl * 7919) & 0xFFFFFFFF))
        R.on_island = false
        R.overlay = R.OV_NONE
        R.intro = nil
        R.vfx_reset()
        -- Mechanics stay in the board lesson, apart from the story dialogue.
        if not R.quiet then
            local l = rules.level_of(R.g)
            R.mission(R.board_lesson and R.board_lesson(R.g) or l.lesson, ("%d. %s"):format(lvl + 1, l.name)); R.present_board()
        end
        return true
    end

    function R.play_level(level)
        if R.g and R.g.level == level and not R.g.won and not R.g.lost then
            if level == R.prog.level and (owes_building() or journey.awaiting_return(R.prog)) then return false end
            if R.refresh_board_bonuses then R.refresh_board_bonuses() end
            R.on_island = false; R.overlay = R.OV_NONE
            if R.phase == R.PH_IDLE or R.phase == R.PH_PRESENT then R.present_board() end
            return true
        end
        return R.start_level(level)
    end

    -- After the results dialog closes: bank the reward and go build.
    function R.claim_reward()
        local paid, first = rules.progress_reward(R.prog, R.g, R.wonders, R.island)
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
        if R.debug_fill_earnings and app.arg("debug-walkthrough") then R.debug_fill_earnings(g) end
        g.score = math.max(g.score, rules.level_of(g).score)
        for i = 0, rules.CELLS - 1 do g.oil[i] = 0 end
        g.oil_left = 0
        g.won = true
        R.overlay = R.OV_RESULT
        return true
    end

    function R.debug_advance_town()
        if not R.on_island or R.overlay ~= R.OV_NONE then return false end
        if R.island.placing >= 0 then return R.town:confirm() ~= nil end
        -- A game with an ordered ladder may also have an optional building open.
        local open_step = island.next_step and island.next_step(R.island, R.prog.level)
        if owes_building() or open_step then
            local kind = next_build()
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

    -- Game Center (engine/gamecenter.lua docs: docs/GAMECENTER.md). game_config.lua's
    -- "leaderboard" block turns it on: `board` holds the boards cleared,
    -- `level_board` (a format with the level number, e.g. "level_%02d") each
    -- expedition's best score. Scores are reported when a reward is claimed.
    local boards = require("leaderboard").boards{skin = skin, width = 400, header = match3.popup_header, texts = W.leaderboard and W.leaderboard.texts}
    function R.submit_scores()
        local c = W.leaderboard
        if not c then return end
        gamecenter.submit(c.board, R.prog.level)
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
    require("match3.shatter").bind(R, rules)
    return R
end

---------------------------------------------------------------------- app

-- Keep a completed board's unclaimed earnings across a restart.
-- Each game owns its wallet migration and calls the returned serializer.
function G.bind_completed_rewards(R, rules)
    function R.stash_completed()
        local g = R.g
        if not g.earnings then return end
        R.prog.completed = {level=g.level, rng=g.rng, moves=g.moves, score=g.score,
            earnings={table.unpack(g.earnings)}}
        R.save_progress()
    end

    local function serialize(s)
        local reading = save.is_reading(s)
        local completed = R.prog.completed
        local level = s:int("completed_level", completed and completed.level or -1)
        if level < 0 or level > R.prog.level or level >= rules.LEVELS then
            if reading then R.prog.completed = nil end
            return
        end
        local rng = s:int("completed_rng", completed and completed.rng or 1) & 0xFFFFFFFF
        local moves = s:int("completed_moves", completed and completed.moves or 0)
        local score = s:int("completed_score", completed and completed.score or 0)
        local earnings = s:ints("completed_earnings", purse(table.unpack(completed and completed.earnings or {})))
        if reading then
            R.prog.completed = {level=level, rng=rng, moves=moves, score=score,
                earnings={earnings[1],earnings[2],earnings[3]}}
        end
    end

    function R.resume_completed()
        local completed = R.prog.completed
        if not completed then return end
        local g = R.make_board(completed.level,completed.rng)
        g.rng, g.moves, g.score, g.earnings = completed.rng, completed.moves, completed.score, completed.earnings
        local spec = rules.level_of(g)
        g.won, g.relics, g.oil_left = true, spec.relics, 0
        for i = 0, rules.CELLS-1 do g.oil[i] = 0 end
        R.reset_board(g)
        R.on_island, R.overlay, R.intro = false, R.OV_RESULT, nil
    end

    return serialize
end

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
        if s.wipe then   -- both screens at once, the town masked to its side of the edge
            local u = num.saturate(dive.t / s.inn)
            R.board_screen(world, dt)
            R.vfx_draw()
            R.vfx_particles()
            dive.focus = dive.town
            s.mask(dive, u)
            R.island_screen(world, dt)
            gfx.sdf_unmask()
            gfx.bleed(true)
            s.draw(dive, false, u)
            gfx.bleed(false)
            dive.t = dive.t + dt
            if dive.t >= s.inn then dive = nil end
            return
        end
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
            local label = R.on_island and "Advance" or "Skip level"
            local bounds = rect(318, R.on_island and 116 or R.hud_rect.y - 50, 152, 40)
            local state = ui.hit(bounds, 0)
            R.paint_button(bounds, state, true)
            R.say(label, bounds:inflate(-8), 18, R.PAL_CREAM)
            if state.clicked then
                if R.on_island then R.debug_advance_town() else R.debug_skip_level() end
            end
        end
        R.draw_toast()
        ui.set_enabled(true)
        local at_result = R.overlay == R.OV_RESULT
        local revealing = at_result and require("match3.elements_view").reveal_holding(R, rules)
        local scene = at_result and not R.quiet and R.clear_scene and R.clear_scene()
        local clear_due = at_result and not R.quiet and journey.result_beat(R.prog, R.g, rules.level_of(R.g))
        if scene then R.draw_clear_scene(scene, inp) end
        if not talking and not revealing and not scene and not clear_due then R.overlays(dt) end
        if not talking then R.draw_leaderboard(dt) end   -- above every dialog, closing returns to it
        story.frame(dt)
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
        R.hud_art = art.load_hud()
        require("match3").load_action_buttons(R.skin, R.hud_art)
        R.shop_built_art, R.shop_locked_art = R.hud_art["shop-built"], R.hud_art["shop-locked"]
        -- The neutral skin has no life icon: borrow the game's own HUD atlas.
        R.life_art = R.hud_art.life or require("match3").hud(require("match3_hud")).life
        if app.arg("art-states") then
            R.art_packs = {}
            for _, pack in ipairs(W.packs) do R.art_packs[pack] = pack_kinds(pack) end
        end
        R.vfx_init(board_skin)
        R.island = city.new()
        island.island_setup(R.island)
        R.buildings = R.island.defs   -- with the sprites loaded
        R.town_setup()
        R.wonders = {}
        for i = 1, island.WONDERS do R.wonders[i] = R.buildings[wonder_kind(island, i) + 1] end

        R.sound = true
        R.inspect, R.zone_card = -1, -1
        R.test_mode = app.arg("smoke") ~= nil or app.arg("shot") ~= nil or app.arg("fresh") ~= nil
        R.quiet = app.arg("shot") ~= nil   -- stills skip the story unless asked for (--dialog)
        R.prog = {level = 0, seed = 782341, wallet = purse(), story_seen = {}}
        if not app.arg("smoke") then save.read(R.progress_slot(), R.serialize) end
        if W.leaderboard and not app.arg("smoke") and not app.arg("debug-walkthrough") then
            gamecenter.submit(W.leaderboard.board, R.prog.level)
        end
        R.story_current, R.story_preview, R.story_before_result = nil, false, false
        R.story_choice_beat, R.story_choice_preview = nil, nil
        R.layout()
        if not R.start_level() then
            -- A save the story or a building holds on the island still needs an
            -- inert board for shared view updates.
            R.reset_board(R.make_board(math.min(R.prog.level, LEVELS - 1), R.prog.seed))
            R.g.lost = true
            R.on_island = true
        end
        if R.prog.level >= LEVELS then R.g.won = true end -- no unfinished attempt is created at campaign completion
        if journey.earned(R.prog.level) > island.wonder_count(R.island) or R.prog.level >= LEVELS then R.on_island = true end
        if R.needs_relocation then R.on_island = true; R.notice(W.notices.relocate) end
        if W.start_on_town and not app.arg("smoke") then R.on_island = true end
        if R.resume_completed then R.resume_completed() end
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
