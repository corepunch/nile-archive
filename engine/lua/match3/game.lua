-- match3/game.lua — the portrait match-3 city game around the board, shared by
-- Relic Rush and Christmas Market (`require("match3.game")`): progress and
-- saving, the level flow, the frame, the paint helpers and every
-- dialog (pause and its Restart confirmation, failed, region card, building
-- card, finale), the build shop, the town hooks, story
-- delivery and the debug entry points. match3.journey owns the story rules.
--
-- A game is data: words in lua/game_config.lua (merged over DEFAULTS below), its
-- campaign and story, its skin and art tables. The board is painted by
-- match3.screen. The games still supply the results card and guide rows
-- (screens.lua) and the cast (narrative.lua).
--
--   -- screens.lua, first:   local R = require("match3.game").bind(require("state"))
--   -- main.lua, last:       return require("match3.game").app(R)
--
-- Game hooks the shared code calls (set on R by the game's modules):
--   R.register_result, R.register_guide   the results data and guide form
--   R.clear_scene(), R.draw_clear_scene(scene, inp)   optional presentation before the first-clear beat
--   R.wallet_icons()        three icons: unused, gold, unused (the gold capsule's is the second)
--   R.town_middle_icon(at)  the round middle button's icon in the town
--   R.draw_town_world(view)  optional effects above the town and below its HUD
--   R.cast                  the story cast (narrative.lua)
--   R.smoke(), R.campaign_smoke()   the --smoke runs
--   game_config.lua "leaderboard" {board, title}   Game Center leaderboard (below)
-- See docs/PORTRAIT_GAMES.md.
local N = ui.node

local G = {}
local BOARD_OUT = .30

------------------------------------------------------------------- words

G.DEFAULTS = {
    app = {title = "Match-3 town", id = "match3-game", clear = "#09211F"},
    menu = {play = "CONTINUE", settings = "SETTINGS", label = "MAIN MENU"},
    packs = {"kind"},        -- piece packs; the first is the default, --tiles picks another
    speech = {scale = 1, name = 15},
    region_speaker = "",
    board = {},
    notices = {
        reward_building = "Building funded! Spare gold is yours to decorate.",
        reward_story = "Something is happening in town.",
        reward_replay = "Replay gold collected. Choose something in the shop.",
        relocate = "Some buildings need a new spot. Hold one to move it.",
        all_open = "The whole town is open.",
        quit = "Your board is saved. Tap Play to continue level %d.",
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
    -- Every level is cleared: shown after the last win, and by Play from then on.
    -- A line's %d is the number of levels.
    complete = {title = "You won!", lines = {{"YOU COMPLETED ALL %d LEVELS.", 16}, {"Your town stays open to build.", 16}},
        button = "BACK TO TOWN"},
    result = {needs = "%s STILL NEEDS", ready = "READY TO BUILD"},
    card = {move = "MOVE THIS BUILDING", build = "CHOOSE A LOCATION", repair = "RESTORE ON SITE", back = "BACK TO TOWN",
            gets = "YOU GET", price = "PRICE", missing = "STILL NEEDED", play = "PLAY",
            moving = "HOLD AND DRAG IN TOWN TO MOVE", locked = "COMPLETE MORE LEVELS TO BUILD THIS", close = "CLOSE"},
    catalogue = {
        title = "Build your town", close = "BACK TO TOWN",
        categories = {{"all", "Everything"}, {"wonder", "Story buildings"}, {"building", "Buildings"}},
        category = "all",
        build = "BUILD", built = "BUILT", complete = "COMPLETE LEVEL %d", earlier = "BUILD EARLIER BUILDINGS",
        cleared = "CLEAR %d LEVELS", poor = "MORE GOLD NEEDED", reserved = "GOLD RESERVED FOR BUILDINGS", full = "TOWN IS FULL",
        row = "%d x %d tiles  ·  Owned %d",
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
        -- A 9 x 12 board between the HUD and the bonus tray on a 480 x 900 screen.
        HEX_R = 24,
        intro = nil,

        -- overlays and board phases
        OV_NONE = 0, OV_GUIDE = 1, OV_PAUSE = 2, OV_RESULT = 3, OV_FAILED = 4, OV_WONDER = 5, OV_FINALE = 6, OV_ZONE = 7, OV_SHOP = 8, OV_COMPLETE = 9, OV_CONFIRM = 10, OV_STORY_CHOICE = 11,
        PAL_GOLD = "gold", PAL_CREAM = "cream", PAL_GREEN = "green", PAL_WHITE = "white", PAL_SHORT = "short",   -- text styles in skin.lua

        backdrop = nil, scenes = {}, relics = {}, glow = nil,
        font = nil,
        prog = nil,          -- {level, seed, wallet}
        island = nil,        -- the engine city

        -- screens
        on_island = false, on_menu = false,
        overlay = 0, modal_for = 0,
        dialog = nil,
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

G.journey = require("match3.journey")

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

    -- Dialog paint follows the motion without changing the measured layout.
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

    local shop, choices

    function R.open_dialog(settled)
        local old = R.dialog
        if old and old.tl then old.tl:kill() end
        local d = ui.popup_motion(settled or R.reduced_motion)
        d.settled, d.parts, d.n = settled or R.reduced_motion or not app.arg("reel"), {}, 0
        R.dialog = d
    end

    -- Keep the old screen and its input barrier until the card has left.
    local function close_popup(action)
        R.dialog:close(function()
            action()
            if R.overlay == R.modal_for then R.open_dialog() end
        end, R.reduced_motion)
    end

    -- Has the entrance, parts included, finished?
    function R.dialog_settled()
        if R.overlay == R.OV_SHOP then return shop:ready() end
        if R.overlay == R.OV_STORY_CHOICE then return choices:ready() end
        local d = R.dialog
        return R.modal_for == R.overlay and d ~= nil and d.entry >= 1 and not (d.after_exit or d.closed)
            and (d.tl == nil or d.tl:is_done())
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

    -- The results card's line about the next building `w`: what it still
    -- needs after this win (`missing`, resource records), or its picture
    -- once the wallet covers it.
    function R.result_next(w, missing)
        if #missing > 0 then return {needs=missing, needs_caption=W.result.needs:format(w.name:upper())} end
        return {icon=w.sprite, heading=W.result.ready, title=w.name}
    end

    function R.register_result(model)
        local form = ui.form(N.column {panel=true,
            match3.popup_header("Results"),
            N.column {gap=1,paint_group={.24,.32,9},
                N.label {text="SCORE",em=13,text_style="caption"},
                N.label {id="score",em=44,text_style="gold"},
            },
            N.column {gap=7,paint_group={.62,.28,10},
                N.label {text="RESOURCES TO BANK",em=13,text_style="caption"},
                -- One row of equal cells, however many currencies the game banks.
                N.uniform_grid {id="resources",rows=1,gap=9,item=function(entry)
                    return match3.resource_indicator(entry)
                end},
            },
            -- The next purchase, in at most two parts: what it still needs after
            -- this win, as resource amounts, and one captioned picture row.
            N.column {id="next_step",visible_field="show_next",panel=true,role="group",
                padding={9,8,10,9},gap=6,paint_group={.9,.26,8},
                    N.label {id="next_needs_caption",em=13,text_style="caption",visible_field="show_next_needs"},
                    N.row {visible_field="show_next_needs",
                        N.spacer {grow=1},
                        N.list {id="next_needs",direction="row",gap=9,item=function(entry)
                            return match3.resource_indicator(entry, 104)
                        end},
                        N.spacer {grow=1},
                    },
                    N.row {gap=10,align="center",visible_field="show_next_title",
                        N.image {id="next_icon",width=58,height=58,visible_field="show_next_icon"},
                        N.column {grow=1,gap=2,
                            N.label {id="next_heading",wrap=true,text_align="start",em=12,text_style="caption"},
                            N.label {id="next_title",wrap=true,text_align="start",em=21,text_style="gold"},
                        },
                    },
                },
            N.button {id="claim",height=54,paint_group={1.02,.22,8}},
        })
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
            local needs = next_step and next_step.needs or {}
            form.values.show_next = next_step ~= nil
            form.values.show_next_needs = #needs > 0
            form.values.show_next_title = next_step ~= nil and next_step.title ~= nil
            form.values.show_next_icon = next_step ~= nil and next_step.icon ~= nil
            assert(form:set_items("next_needs", needs))
            if next_step then
                form:set("next_needs_caption", next_step.needs_caption or "")
                    :set("next_icon", next_step.icon):set("next_heading", next_step.heading or "")
                    :set("next_title", next_step.title or "")
            end
        end, handle=function(event)
            if event.id ~= "claim" then return end
            if R.dialog_settled() then close_popup(R.claim_reward) else R.dialog_skip() end
        end})
    end

    function R.register_guide(form)
        popup(R.OV_GUIDE, form, {width=432, shift=10, handle=function() R.overlay = R.OV_NONE end})
    end

    -- A captioned group of resource amounts on the building card. The price
    -- and what the building brings sit side by side, after Cradle of Rome,
    -- and the amounts narrow together when five share the row. The list
    -- grows into the row's height, so a group of icons alone stands as tall
    -- as one of figures. A wider gap, with no rule, sets the groups apart.
    local AMOUNT_GAP, GROUP_GAP, CARD_INNER = 9, 20, 372
    local amount_width = 96
    local function amounts(id, caption, visible, width)
        return N.column {gap=5, visible_field=visible,
            N.label {id=id .. "_caption", text=caption, em=13, text_style="caption"},
            N.list {id=id,direction="row",gap=AMOUNT_GAP,grow=1,item=function(entry)
                return match3.resource_indicator(entry, width or amount_width)
            end},
        }
    end
    local function group_gap(visible)
        return N.spacer {width=GROUP_GAP,visible_field=visible}
    end

    -- The building card: a story building or a shop item, to build or move.
    -- R.building_reward(kind) returns the board piece with its payout, if any.
    local wonder_form = ui.form{
        root = N.column {panel=true,
            match3.popup_header("Building details", nil, W.corner_close and "close"),
            N.image {id="sprite", height=205},
            N.label {id="about", wrap=true, em=19, text_style="body"},
            N.label {id="unlock", wrap=true, em=16, text_style="body", visible_field="show_unlock"},
            N.row {visible_field="show_upgrade",
                N.spacer {grow=1},
                amounts("upgrade", "", "show_upgrade", 96),
                N.spacer {grow=1},
            },
            N.row {visible_field="show_amounts",
                N.spacer {grow=1},
                amounts("price", W.card.price, "show_price"),
                group_gap("show_both"),
                amounts("gets", W.card.gets, "show_gets"),
                N.spacer {grow=1},
            },
            N.label {id="notice",wrap=true,em=15,text_style="body",visible_field="show_notice"},
            N.button {id="action",height=56},
            N.button {id="shop",text="OPEN BUILD SHOP",height=30,flat=true,em=16,visible_field="show_shop"},
            not W.corner_close and N.button {id="close",text=W.card.close,height=28,flat=true,em=16} or nil,
        },
        bindings={
            {id="sprite",field="sprite",type="texture",readonly=true},
            {id="about",field="about",readonly=true},{id="action",field="action",readonly=true},
        },
    }
    R.wonder_form = wonder_form
    local wonder_action, funding_play
    popup(R.OV_WONDER, wonder_form, {width=420, prepare=function()
        local i = R.inspect >= 0 and R.inspect or next_build()
        if not i or i < 0 or i >= #R.buildings then return false end
        local w = R.buildings[i + 1]
        local unlock_text = island.buildings[i + 1].unlock_text
        local can_build, built = island.can_buy(R.island, R.prog.wallet, R.prog.level, i), R.inspect_item and R.inspect_item >= 0
        local fixed = w.fixed_site and (w.fixed_site.x ~= 0 or w.fixed_site.y ~= 0)
        local movable = built and not fixed
        local _, position = island.next_step(R.island, R.prog.level)
        local step = not built and island.ladder[position]
        if step and (step.kind ~= i or step.after > rules.LEVELS) then step = nil end
        local needs_funding = step and not can_build
        funding_play = needs_funding and (R.prog.level < rules.LEVELS or step.after <= R.prog.level)
        match3.set_popup_header(wonder_form, w.name)
        local upgrade = R.upgrade_card and R.upgrade_card(i)
        local about = journey.building_about(i, R.prog.level, w.about)
        if upgrade then about = about .. "\n" .. upgrade.about end
        local ok, message = wonder_form:push{sprite=w.sprite, about=about,
            action=movable and W.card.move or can_build and (fixed and W.card.repair or W.card.build) or funding_play and (R.prog.level < rules.LEVELS and W.card.play or "EARN RESOURCES") or W.card.back}
        assert(ok, message)
        local show_price = step ~= nil or not built and (can_build or R.currency_prices and w.needs and
            R.prog.wallet:covers(w.needs) and (i >= island.WONDERS or i < journey.earned(R.prog.level)))
        wonder_form.values.show_price = show_price
        wonder_form.values.show_notice = not show_price or step ~= nil
        wonder_form.values.show_shop = step ~= nil
        local reward = R.building_reward(i)
        local gets = reward and {reward} or {}
        local price = show_price and price_parts(w.cost) or {}
        -- While the building is being funded the card lists what is still
        -- missing, as amounts, in place of the full price.
        local missing = needs_funding and R.funding_shortfall and R.funding_shortfall(w.cost) or {}
        if #missing > 0 then price = missing end
        wonder_form:set("price_caption", #missing > 0 and W.card.missing or W.card.price)
        local count, groups = #gets + #price, (#gets > 0 and 1 or 0) + (#price > 0 and 1 or 0)
        -- An upgrade's feat or perk: its own captioned row under the amounts.
        local upgrade_entries = upgrade and upgrade.entries or {}
        wonder_form.values.show_upgrade = #upgrade_entries > 0
        wonder_form:set("upgrade_caption", upgrade and upgrade.caption or "")
        assert(wonder_form:set_items("upgrade", upgrade_entries))
        amount_width = math.min(96, math.floor((CARD_INNER - GROUP_GAP * (groups - 1) - AMOUNT_GAP * (count - groups)) / math.max(1, count)))
        wonder_form.values.show_gets, wonder_form.values.show_amounts = #gets > 0, count > 0
        wonder_form.values.show_both = groups == 2
        assert(wonder_form:set_items("gets", gets))
        wonder_form.values.show_unlock = unlock_text ~= nil and #gets == 0
        wonder_form:set("unlock", unlock_text or "")
        assert(wonder_form:set_items("price", price))
        local funding
        if needs_funding then
            -- The amounts already say what is missing; a line is only for the level gate.
            if R.prog.level < step.after then funding = W.catalogue.complete:format(step.after)
            elseif #missing == 0 then funding = W.catalogue.poor
            else wonder_form.values.show_notice = false end
        end
        wonder_form:set("notice", funding or step and can_build and W.result.ready or built and (fixed and "RESTORED AT ITS ORIGINAL SITE" or W.card.moving) or W.card.locked)
        wonder_action = (can_build or movable) and {kind=i, item=movable and R.inspect_item or nil} or nil
    end, handle=function(event)
        local action = wonder_action
        if event.id == "action" and action then R.island_begin(action.kind, true, action.item)
        elseif event.id == "action" and funding_play then
            R.overlay = R.OV_NONE
            if R.prog.level < rules.LEVELS then R.play_next()
            else R.play_level(rules.LEVELS - 1) end
        elseif event.id == "shop" then R.open_catalogue("all")
        else R.overlay = R.OV_NONE end
    end})

    local pause_form = match3.pause_form(W.pause.guide, W.pause.quit, W.leaderboard and W.pause.leaderboard, W.corner_close, W.menu.label)
    R.pause_form = pause_form
    popup(R.OV_PAUSE, pause_form, {width=396, shift=W.leaderboard and 24 or 0, prepare=function()
        local level
        if not R.on_island and not R.on_menu then level = ("%d. %s"):format(R.g.level + 1, rules.level_of(R.g).name) end
        assert(pause_form:push(R))
        pause_form.values.in_game = not R.on_menu
        pause_form.values.expedition = not R.on_island and not R.on_menu
        pause_form:set("resume", R.on_menu and "DONE" or "RESUME")
        match3.set_popup_header(pause_form, "Settings", level)
    end, handle=function(event)
        local action = event.id
        if event.kind == "change" then
            assert(pause_form:pull(R))
            sfx.enable(R.sound)
            if not R.test_mode then save.write("settings", R.serialize_settings) end
        elseif action == "resume" or action == "close" then R.overlay = R.OV_NONE
        elseif action == "menu" then
            R.overlay = R.OV_NONE
            R.open_menu()
        elseif action == "guide" then R.overlay = R.OV_GUIDE
        elseif action == "restart" then R.overlay = R.OV_CONFIRM
        elseif action == "leaderboard" then R.open_leaderboard()
        elseif action == "quit" then   -- the unfinished board waits in town
            R.on_island, R.overlay = true, R.OV_NONE
            local replay = R.prog.level >= rules.LEVELS
            R.notice(replay and "Your board is saved. Open Build to continue earning resources."
                or W.notices.quit:format(R.g.level + 1))
        end
    end, live=function(event)
        return event.kind == "change" or event.id == "leaderboard"
    end})

    local confirm_form = ui.form(N.column {panel=true,
        match3.popup_header(W.confirm.title, W.confirm.body, W.corner_close and "close"),
        N.button {id="confirm",text=W.confirm.restart,height=50},
        N.button {id="cancel",text=W.confirm.cancel,height=32,role="link",em=20},
    })
    R.confirm_form = confirm_form
    popup(R.OV_CONFIRM, confirm_form, {width=396, handle=function(event)
        if event.id == "confirm" then R.start_level(R.g.level); R.overlay = R.OV_NONE
        else R.overlay = R.OV_PAUSE end
    end})

    local failed = W.failed
    R.failed_form = ui.form(N.column {panel=true,
        match3.popup_header(failed.title, failed.subtitle),
        N.label {text=failed.hint,wrap=true,em=17,text_style=PAL_CREAM},
        N.button {id="retry",text=failed.retry,height=50},
        N.button {id="town",text=failed.town,height=42,role="secondary"},
    })
    popup(R.OV_FAILED, R.failed_form, {width=404, dismiss=false, handle=function(event)
        if event.id == "retry" then R.start_level(R.g.level) else R.on_island, R.overlay = true, R.OV_NONE end
    end})

    local region = W.zone
    local zone_form = ui.form(N.column {panel=true,
        match3.popup_header("Region", nil, W.corner_close and "close"),
        N.label {id="cleared",wrap=true,em=24,text_style=PAL_GOLD},
        N.label {text=region.earn,wrap=true,em=19,text_style=PAL_CREAM},
        N.button {id="open",height=47},
        not W.corner_close and N.button {id="close",text=region.close,height=32,role="link",em=16} or nil,
    })
    R.zone_form = zone_form   -- the campaign smoke runs press its Open button
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

    -- The story's last scene (finale) and the last level (complete) close on the same card.
    for overlay, words in pairs{[R.OV_FINALE] = W.finale, [R.OV_COMPLETE] = W.complete} do
        local card = {match3.popup_header(words.title)}
        for _, line in ipairs(words.lines) do
            card[#card+1] = N.label {text=line[1]:format(rules.LEVELS),wrap=true,em=line[2],text_style=line[3] or PAL_WHITE}
        end
        card[#card+1] = N.button {id="back",text=words.button,height=50}
        local form = ui.form(N.column {panel=true,children=card})
        if overlay == R.OV_COMPLETE then R.complete_form = form end
        popup(overlay, form,
            {width=416, dismiss=false, handle=function() R.overlay = R.OV_NONE end})
    end

    -- Draws the open dialog over everything; it alone receives input.
    function R.overlays(dt)
        if R.overlay ~= R.modal_for then   -- a new dialog opens
            R.modal_for = R.overlay
            if R.overlay ~= R.OV_NONE then R.open_dialog()
            else R.dialog = nil end
        end
        if R.overlay == R.OV_NONE then return end
        if R.overlay == R.OV_SHOP then R.draw_catalogue(dt); return end
        if R.overlay == R.OV_STORY_CHOICE then R.draw_story_choice(dt); return end
        local d = R.dialog
        local inp = input.get()
        local covered = R.leaderboard_active()
        if covered then d.ready = false end
        if not d:step(dt, inp, R.reduced_motion) then return end
        d.n = 0
        local modal = assert(popups[R.overlay], "overlay has no vertical popup form")
        if modal.prepare and not d.after_exit and modal.prepare(d) == false then R.overlay = R.OV_NONE; return end
        local width = math.min(modal.width, R.SCREEN_W - 32)
        local _, height = modal.form:measure(width, skin)
        local center = vec2(240, 450 + (modal.shift or 0))
        local bounds = rect.centered(center, size2(width, height))
        -- Centre the design-space card in the phone's safe layout.
        local hit_offset = vec2(0, R.drop / 2)
        P.offset = hit_offset
        local interactive = not covered and d.interactive
        local event = d:paint(function()
            return modal.form:draw(bounds, skin, {hit_offset=hit_offset, interactive=interactive,
                dim_controls=false, dt=dt, input=inp, reduced_motion=R.reduced_motion,
                paint_scope=function(group, draw)
                    local previous = R.section(table.unpack(group))
                    local action = draw()
                    set_paint(previous)
                    return action
                end})
        end, {dim=rgba(5, 22, 22, 185), blur=7})
        local visible_bounds = pr(bounds)
        reset_paint()
        if event then
            if R.overlay == R.OV_RESULT or (modal.live and modal.live(event)) then modal.handle(event)
            else close_popup(function() modal.handle(event) end) end
        elseif modal.dismiss ~= false and ui.modal_dismiss(visible_bounds, {interactive=interactive, input=inp}) then
            close_popup(function() R.overlay = R.OV_NONE end)
        end
    end

    ----------------------------------------------------- shop and levels

    -- Modal lists: the engine owns measured rows, focus, hit testing and
    -- input capture and motion.
    -- Both lists are full-screen sheets from under the wallet row to the
    -- bottom of the safe screen; a tap on the strip around them closes.
    local function sheet(screen)
        local header = R.town.cfg.header
        local top = screen.y + header.y + (header.band_height or header.height)
        return rect(screen.x + 8, top, screen.w - 16, screen:max().y - 10 - top)
    end
    local MODAL = {bounds=sheet, blur=7, dim=color(5, 22, 22, 185), cancel="close"}
    local C = W.catalogue
    local categories, category = C.categories, 1
    for i, cat in ipairs(categories) do if cat[1] == C.category then category = i end end
    shop = ui.modals(skin)
    local ACTION_W = 100   -- the right-hand column: the action pill or why it waits
    local function row_card(box, face)
        R.rrect(box:offset(vec2(0, 2)), 13, rgba(201, 164, 100))
        R.rrect(box, 13, face)
    end
    local ROW_FACE, ROW_DIM = rgba(255, 246, 214), rgba(243, 229, 192)
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
    local catalogue_form = match3.catalogue_form(C.title, C.close, paint_row, W.corner_close)
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
        if shop:active() then shop:close(nil, nil, true) end
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
        if event.id == "close" or event.kind == "cancel" then shop:close(nil, function() R.overlay = R.OV_NONE end)
        elseif event.id == "category_prev" or event.id == "category_next" then
            category = (category - 1 + (event.id == "category_next" and 1 or -1)) % #categories + 1
            refresh_catalogue()
            catalogue_form:scroll_to("stock")
        elseif event.source == "stock" then
            local record = catalogue_form:get_item("stock", event.key)
            if record and record.available then
                shop:close(nil, function()
                    R.overlay = R.OV_NONE
                    R.island_begin(record.kind, true)
                end)
            end
        end
    end

    ------------------------------------------------------------- town

    local town = require("town.screen")
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
        local upgrade = R.upgrade_card and R.upgrade_card(kind)
        return definition.name .. "\n" .. journey.building_about(kind, R.prog.level, definition.about)
            .. (upgrade and upgrade.short and "\n" .. upgrade.short or "")
    end

    local function owes_building() return island.wonder_count(R.island) < journey.earned(R.prog.level) end

    -- Play starts the next level, or resumes it. With every level cleared
    -- there is none, and it opens the "You won" card instead.
    local function can_play() return R.prog.level < LEVELS end
    function R.play_next()
        if can_play() then return R.play_level(R.prog.level) end
        R.overlay = R.OV_COMPLETE
        return false
    end

    function R.town_setup()
        local function visit_for_kind(kind)
            return journey.visit(R.prog, island.buildings[kind + 1].key)
        end
        R.town = town.new(R.island, require("town_config"), {
            skin = skin,
            wallet = function() return R.prog.wallet end,
            notice = R.notice,
            capsules = R.header_capsules,
            pause = function() R.overlay = R.OV_PAUSE end,
            middle_icon = function(at) R.town_middle_icon(at) end,
            build = function()
                local _, position = island.next_step(R.island, R.prog.level)
                local step = island.ladder[position]
                if step and step.after <= LEVELS then
                    R.inspect, R.inspect_item, R.overlay = step.kind, -1, R.OV_WONDER
                else R.open_catalogue("all") end
            end,
            build_rim = function(center, radius)
                local kind = island.next_step(R.island, R.prog.level)
                if kind and not R.reduced_motion and R.overlay == R.OV_NONE
                    and island.can_buy(R.island, R.prog.wallet, R.prog.level, kind) then
                    R.vfx_ready_rim(center, radius, R.now)
                end
            end,
            play = R.play_next,
            about = R.building_words,
            unheard_visit = function(kind)
                return journey.unheard_visit(R.prog, visit_for_kind(kind))
            end,
            tap_building = function(item)
                local visit = visit_for_kind(R.island.items[item + 1].type)
                if not visit then return false end
                R.open_story_choice(visit)
                return true
            end,
            zone = function(z) R.zone_card, R.overlay = z, R.OV_ZONE end,
            can_buy = function(kind) return island.can_buy(R.island, R.prog.wallet, R.prog.level, kind) end,
            suggest = function(kind) return island.island_suggestion(kind) end,
            placed = function(ev, fresh)
                if fresh then
                    local kind = R.island.items[ev.building + 1].type
                    journey.placed(R.prog, island.buildings[kind + 1].key)
                end
                if fresh and island.purchase_confirmed then
                    local site = island.purchase_confirmed(R.island, R.island.items[ev.building + 1].type, app.clock())
                    if site then R.island_focus(site, R.island.cam.zoom) end
                end
                for k = 0, 23 do R.vfx_emit(ev.screen - vec2(0, 30), k % 6, false) end
                R.tone(740)
                R.save_progress()   -- the building's story beat follows from R.story_tick
            end,
            bubble_text = function() return R.speech_style(15) end,
            reduced_motion = function() return R.reduced_motion end,
            draw_world = R.draw_town_world,
            overlay = R.vfx_particles,
        })
        R.placement_form = R.town.placement_form
    end

    ------------------------------------------------------------ story

    R.intro_lines = journey.beats[1].lines              -- the opening scene
    R.finale = journey.beats[#journey.beats].lines      -- its end opens the finale

    local function owns_building(building)
        return island.owned(R.island, island.kinds[building]) > 0
    end

    function R.story_lines(beat)
        return journey.lines_for(beat, owns_building, R.prog.story_seen)
    end

    function R.queue_story(beat, preview, before_result)
        R.story_current = beat
        R.story_preview = preview
        R.story_before_result = before_result
        for _, line in ipairs(R.story_lines(beat)) do story.add(line) end
    end

    choices = ui.modals(skin)

    local function choice_reply(beat, index, preview)
        local answer = beat.choices[index]
        R.queue_story({key=answer.key or beat.key, phase=beat.phase, lines=answer.lines}, preview)
    end

    function R.open_story_choice(beat, preview)
        local visit = beat.phase == "visit"
        if visit then beat = journey.visit_menu(R.prog, beat) end
        local children = {match3.popup_header(beat.prompt)}
        for index, option in ipairs(beat.choices) do
            if visit then
                local topic = option.topic == "personal" and "PERSONAL" or "TOWN STORY"
                if option.topic == "meeting" then topic = "THEIR MEETING" end
                local status = R.prog.story_seen[option.key] and "Heard" or "New"
                children[#children + 1] = N.label {text=topic .. " · " .. status, em=15, text_style="caption"}
            end
            children[#children + 1] = N.button {id=tostring(index), text=option.label, height=54, em=visit and 20 or nil}
        end
        if visit then
            children[#children + 1] = N.button {id="cancel", text="Back to town", height=36, role="link", em=18}
        end
        R.choice_form = ui.form{root=N.column {panel=true, children=children}}
        if choices:active() then choices:close(nil, nil, true) end
        assert(choices:open(beat.key, R.choice_form, {}, {width=416, close_on_background=visit}))
        R.story_choice_beat, R.story_choice_preview = beat, preview
        R.overlay = R.OV_STORY_CHOICE
    end

    function R.choose_story_option(index)
        local beat, preview = R.story_choice_beat, R.story_choice_preview
        if not beat or not beat.choices[index] then return false end
        if choices:active() then choices:close(nil, nil, true) end
        R.story_choice_beat, R.story_choice_preview = nil, nil
        R.overlay = R.OV_NONE
        if not preview and beat.phase ~= "visit" then
            R.prog.story_choices = R.prog.story_choices or {}
            R.prog.story_choices[beat.key] = index
            R.save_progress()
        end
        choice_reply(beat, index, preview)
        return true
    end

    function R.draw_story_choice(dt)
        local event = choices:draw(dt, {reduced_motion=R.reduced_motion})
        if not event then return end
        if event.id == "cancel" and R.story_choice_beat.phase == "visit" then
            choices:close(nil, function()
                R.story_choice_beat, R.story_choice_preview = nil, nil
                R.overlay = R.OV_NONE
            end)
        elseif event.kind == "click" then
            choices:close(nil, function() R.choose_story_option(tonumber(event.id)) end)
        end
    end

    function R.next_story(before_level)
        if before_level == nil then
            local arrival = journey.next_arrival(R.prog, owns_building)
            if arrival then return arrival end
            local meeting = journey.next_meeting(R.prog, owns_building)
            if meeting then return meeting end
        end
        return journey.next(R.prog, function(index)
            return island.owned(R.island, wonder_kind(island, index + 1)) > 0
        end, before_level)
    end

    -- Acknowledge a finished beat, then start the next one that is due.
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
            if not journey.acknowledge(R.prog, b) then return end
            R.save_progress()
            if b.key == journey.beats[#journey.beats].key then R.overlay = R.OV_FINALE; return end
        end
        if R.quiet or story.active() then return end
        if R.overlay == R.OV_RESULT and R.g then
            if require("match3.elements_view").reveal_holding(R, rules) then return end   -- the finished picture first
            local b = journey.result_beat(R.prog, R.g, rules.level_of(R.g))
            if b and not (R.clear_scene and R.clear_scene()) then R.queue_story(b, false, true) end
            return
        end
        if R.overlay ~= R.OV_NONE or R.island.placing >= 0 then return end
        if R.prog.story_recap then
            R.on_island = true
            R.queue_story({key="recap", lines=journey.recap(R.prog.level)})
            return
        end
        local before = not R.on_island and R.g and R.g.level or (R.prog.level == 0 and 0 or nil)
        local b = R.next_story(before)
        if not b and R.on_island then b = journey.next_placement(R.prog) end
        if not b and R.on_island and R.upgrade_done then b = journey.next_upgrade(R.prog, R.upgrade_done) end
        if b and (R.on_island or b.phase == "before") then
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
        if save.is_reading(s) then
            R.prog.level = num.clampi(R.prog.level, 0, LEVELS)
            R.prog.wallet[rules.CLEARED] = R.prog.level
        end
        R.island:serialize(s)
        story.serialize(s)
        journey.serialize(s, R.prog)
        if save.is_reading(s) then
            journey.migrate(R.prog, version)
            R.needs_relocation = island.restore_saved(R.island, R.prog.level)
        end
        if R.serialize_campaign then R.serialize_campaign(s) end
    end
    R.serialize = serialize

    function R.serialize_settings(s)
        R.sound = s:int("sound", R.sound and 1 or 0) ~= 0
        R.reduced_motion = s:int("reduce_motion", R.reduced_motion and 1 or 0) ~= 0
    end

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
        if not app.arg("debug-walkthrough") then R.submit_leaderboard_progress() end
        R.save_progress()
        R.on_island = true
        R.overlay = first and R.g.story_clear == journey.beats[#journey.beats].key and R.OV_FINALE
            or first and R.prog.level >= rules.LEVELS and R.OV_COMPLETE or R.OV_NONE
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

    -- The Game Center leaderboard tracks boards cleared when rewards are claimed.
    local boards = require("leaderboard").boards{skin = skin, width = 400, header = match3.popup_header, corner_close = W.corner_close, texts = W.leaderboard and W.leaderboard.texts}
    function R.submit_leaderboard_progress()
        local c = W.leaderboard
        if c then gamecenter.submit(c.board, R.prog.level) end
    end
    function R.open_leaderboard()
        local c = W.leaderboard
        if c then boards:open(c.board, c.title) end
    end
    function R.leaderboard_active() return boards:active() end
    function R.draw_leaderboard(dt) boards:draw(dt, {reduced_motion = R.reduced_motion}) end

    require("match3.debug").bind(R, W)
    require("match3.vfx").bind(R, rules)
    require("match3.shatter").bind(R, rules)
    require("match3.screen").bind(R, rules, W, require("art"), require("economy").pieces)
    return R
end

---------------------------------------------------------------------- app

-- Construction supplies the slot descriptors. Charge, persistence and
-- refreshing a parked board follow the same rules in every square campaign.
function G.bind_campaign_bonuses(R, island, loadout_for, backdrop_for)
    function R.board_context(preview)
        local restored = {preview=preview, bonus_charge=not preview and R.prog and R.prog.bonus_charge}
        for _, step in ipairs(island.ladder) do
            local key = step.unlock.building
            if preview then restored[key] = not app.arg("before-" .. key)
            else restored[key] = island.owned(R.island, step.kind) > 0 end
        end
        return restored
    end

    function R.update_bonus_charges()
        local g = R.g
        if g.bonus_preview or not g.tool_slots then return end
        local saved = R.prog.bonus_charge or {}
        local changed = false
        for tool, charge in pairs(g.tool_meter) do
            if (saved[tool] or 0) ~= charge then saved[tool], changed = charge, true end
        end
        if changed then
            R.prog.bonus_charge = saved
            R.save_progress()
        end
    end

    function R.refresh_board_bonuses()
        local g = R.g
        if not g.tool_slots or g.bonus_preview then return end
        local number, restored = g.level + 1, R.board_context()
        local yields, loadout = loadout_for(number, restored, g.loadout_seed)
        for tool, charge in pairs(loadout.tool_meter) do
            if g.tool_meter[tool] == nil then
                g.tool_meter[tool], g.tools[tool] = charge, charge // g.tool_threshold
            end
        end
        g.resource_yields, g.tool_slots = yields, loadout.tool_slots
        g.bonus, g.bonus_debut = loadout.bonus, loadout.bonus_debut
        if backdrop_for then g.backdrop = backdrop_for(g, number, restored) end
    end
end

-- Keep a completed board's unclaimed earnings across a restart.
-- Each game owns its wallet migration and calls the returned serializer.
function G.bind_completed_rewards(R, rules)
    function R.stash_completed()
        local g = R.g
        if not g.earnings then return end
        R.prog.completed = {level=g.level, rng=g.rng, moves=g.moves, score=g.score,
            earnings={table.unpack(g.earnings)}, items=g.items}
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
        -- Quest pieces the board had counted, by the keys the game lists in R.item_keys.
        local items = {}
        for _, key in ipairs(R.item_keys or {}) do
            local amount = s:int("completed_item." .. key, completed and completed.items and completed.items[key] or 0)
            if amount > 0 then items[key] = amount end
        end
        if reading then
            R.prog.completed = {level=level, rng=rng, moves=moves, score=score,
                earnings={earnings[1],earnings[2],earnings[3]}, items=items}
        end
    end

    function R.resume_completed()
        local completed = R.prog.completed
        if not completed then return end
        local g = R.make_board(completed.level,completed.rng)
        g.rng, g.moves, g.score, g.earnings = completed.rng, completed.moves, completed.score, completed.earnings
        g.items = completed.items or g.items
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
    local elements = require("match3.elements_view")
    local board_screen = require("match3.screen")
    local debug = require("match3.debug")
    require("match3").bind_town_board_hud(R)
    local still = app.arg("shot") and not app.arg("reel")
    local board_exit, resume_overlay
    function R.open_menu()
        resume_overlay = R.overlay
        R.on_menu, R.overlay = true, R.OV_NONE
    end
    local menu = require("menu.screen").new(W.menu, require("art").menu_backdrop, R.skin, {
        can_visit = function() return not R.on_island and not R.g.won and R.prog.level > 0 end,
        continue = function() R.on_menu, R.overlay = false, resume_overlay end,
        town = function()
            R.on_menu, R.on_island = false, true
        end,
        settings = function() R.overlay = R.OV_PAUSE end,
    })
    R.menu = menu

    local transition = require("screen_transition").new(W.transitions, app.arg("transition-style") or app.arg("dive-style"))
    function R.diving() return transition:active() end

    local function town_focus()
        local c, screen = R.island, app.screen()
        if c.count > 0 then
            local at = c.cam:rect_to_screen(c:sprite_rect(c.items[c.count])):center()
            if screen:inflate(-40):contains(at) then return at end
        end
        return screen:center()
    end

    local function describe_transition(from, to)
        return {
            -- The board's story mosaic uses the renderer's mask.
            masked = (from == "menu" or to == "menu") and to or "town",
            focuses = {town = town_focus(), match3 = R.BOARD_CLIP:center()},
            board_gone = from == "match3" and board_exit == BOARD_OUT,
            label = ("%d. %s"):format(R.g.level + 1, rules.level_of(R.g).name),
            say = R.say,
        }
    end

    local function paint_transition(id, inp, dt, effect, zoom, pan)
        if id == "menu" then menu:frame(inp, dt, false); return end
        if id == "match3" then
            R.board_screen:transition(inp, dt, effect.board_gone and 1 or 0)
            return
        end
        if not zoom then
            R.town:frame(inp, dt, false)
            return
        end
        local cam = R.island.cam
        local view = zoom ~= 1 and cam:zoom_at(zoom, effect.focus) or cam
        R.island.cam = pan and view:pan(pan) or view
        R.town:frame(inp, dt, false)
        R.island.cam = cam
    end

    local function frame(dt)
        local inp = input.get()
        R.layout()
        transition:watch(R.on_menu and "menu" or R.on_island and "town" or "match3",
            not R.reduced_motion and (not R.quiet or app.arg("dive")), describe_transition)
        if not R.on_menu and not transition:active() then R.story_tick() end
        local talking = story.active()
        local board = R.leaderboard_active()
        tween.instant(R.reduced_motion)   -- reduced motion: every tween settles on its next frame
        if app.arg("smoke") then (app.arg("campaign") and R.campaign_smoke or R.smoke)() end
        R.debug_frame()
        R.now = R.now + dt
        if not talking then R.toast_time = R.toast_time - dt end
        if inp.back and not R.on_menu and not talking and not transition:active() and R.overlay == R.OV_NONE then R.overlay = R.OV_PAUSE end

        if not R.on_menu and not transition:covering() then R.board_update(dt) end
        R.vfx_update(dt)

        local drawn_overlay = R.overlay
        local at_result = drawn_overlay == R.OV_RESULT
        local outcome = at_result or drawn_overlay == R.OV_FAILED
        local revealing = at_result and elements.reveal_holding(R, rules)
        local clear_due = at_result and not R.quiet and journey.result_beat(R.prog, R.g, rules.level_of(R.g))
        local story_wait = talking or revealing or clear_due
        if outcome then
            ui.block(app.bleed())
            if not story_wait and not R.on_island then
                board_exit = (R.reduced_motion or still) and BOARD_OUT
                    or board_exit and math.min(board_exit + dt, BOARD_OUT) or 0
            end
        else board_exit = nil end

        local switching = transition:active()
        local backdrop_only = not R.on_island and R.intro and R.intro:showing_backdrop()
        local interactive = R.overlay == R.OV_NONE and not talking and not board and not switching
        local world = interactive and input.world() or input{pos = inp.pos, pinch = 1}
        ui.set_enabled(interactive)
        if switching then
            transition:frame(inp, dt, paint_transition)
        else
            local screen = R.on_menu and menu or R.on_island and R.town or R.board_screen
            screen:frame(world, dt, interactive, ease.in_out_cubic((board_exit or 0) / BOARD_OUT))
        end
        if app.arg("debug-walkthrough") and not backdrop_only and not R.on_menu and not talking and not board and not transition:active()
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
        if not R.on_menu and not backdrop_only then R.draw_toast() end
        ui.set_enabled(true)
        local scene = clear_due and not revealing and R.clear_scene and R.clear_scene()
        if scene then R.draw_clear_scene(scene, inp) end
        if not story_wait and not transition:active() and drawn_overlay == R.overlay
            and (not outcome or board_exit == BOARD_OUT) then R.overlays(dt) end
        if not talking then R.draw_leaderboard(dt) end   -- above every dialog, closing returns to it
        story.frame(dt)
        -- Keep the HUD above ordinary dialogs. Level endings, the guide and
        -- leaderboard own the whole foreground.
        local hud_above = not R.on_menu and not backdrop_only and not outcome and R.overlay ~= R.OV_GUIDE and not board
        if hud_above and (R.overlay ~= R.OV_NONE or talking) then
            ui.set_enabled(false)
            if R.on_island then R.town:header() else R.draw_board_hud() end
            ui.set_enabled(true)
        end
    end

    local function init()
        R.font = R.skin:font("lilita")
        story.setup(R.cast, story_style{text = R.speech_style(21), name = R.pal(R.PAL_CREAM, W.speech.name), bubble = color(255, 246, 222, 252),
                                      edge = color(102, 68, 39), dim = color(5, 22, 22, 150), backdrop_blur = 7,
                                      portrait_height = .34, centered = true, inward = true,
                                      edge_to_edge = true, skip = "SKIP"})
        local art = require("art")
        local board_skin = art.skin()
        for _, action in ipairs{"action-build", "action-play", "action-pause"} do
            R.skin.images[action] = assert(board_skin[action], "missing campaign icon: " .. action)
        end
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
        board_screen.load(R, art, W.board)
        R.hud_art = art.load_hud()
        R.shop_built_art, R.shop_locked_art = R.hud_art["shop-built"], R.hud_art["shop-locked"]
        -- The painted green tick marks every met amount: board goals and cards.
        R.skin.images.tick = R.shop_built_art
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

        R.sound, R.reduced_motion = true, false
        R.inspect, R.zone_card = -1, -1
        R.test_mode = app.arg("smoke") ~= nil or app.arg("shot") ~= nil or app.arg("fresh") ~= nil
        R.quiet = app.arg("shot") ~= nil   -- stills skip the story unless asked for (--dialog)
        R.prog = {level = 0, seed = 782341, wallet = purse(), story_seen = {}}
        local loaded
        if not app.arg("smoke") then
            loaded = save.read(R.progress_slot(), R.serialize)
            save.read("settings", R.serialize_settings)
            sfx.enable(R.sound)
        end
        -- Seed the town while the player starts on the board.
        if island.new_game and R.prog.level == 0 and R.island.count == 0 then island.new_game(R.island, app.clock()) end
        local preview = debug.direct_preview() or app.arg("debug-walkthrough")
        if not loaded and not preview and not app.arg("main-menu") then R.save_progress() end
        if not app.arg("smoke") and not app.arg("debug-walkthrough") then
            R.submit_leaderboard_progress()
        end
        R.story_current, R.story_preview, R.story_before_result = nil, false, false
        R.story_choice_beat, R.story_choice_preview = nil, nil
        R.layout()
        R.start_level()
        if R.prog.level >= LEVELS then
            R.g.won, R.on_island = true, true
        end
        if R.prog.story_recap or R.next_story(nil) or journey.next_placement(R.prog) then R.on_island = true end
        if R.needs_relocation then R.on_island = true; R.notice(W.notices.relocate) end
        if W.menu.continue_in_town and R.prog.level > 0 then R.on_island = true end
        if R.resume_completed then R.resume_completed() end
        R.debug_screens()
        if app.arg("main-menu") or loaded and not R.test_mode and not preview then
            R.open_menu()
            if app.arg("dialog") == "pause" then R.overlay = R.OV_PAUSE end
        end
    end

    return {
        title = W.app.title,
        id = W.app.id,
        gamecenter_board = W.leaderboard and W.leaderboard.board,
        design = size2(R.SCREEN_W, R.SCREEN_H),
        fixed = true,
        max_aspect = 2.2,   -- tall phones (19.5:9) get a taller screen, not bars
        clear = hex(W.app.clear),
        init = init,
        frame = frame,
    }
end

return G
