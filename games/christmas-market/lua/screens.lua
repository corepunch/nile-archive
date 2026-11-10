-- screens.lua — Christmas Market's art in the shared dialogs: the results card, the
-- guide's rows and icons, and the wallet and town icons. The dialogs, their
-- motion, the paint helpers and every other popup are the engine's
-- (engine/match3_game.lua); words are data/game.json.
local R = require("match3.game").bind(require("state"))
local match3 = require("match3")
local rules = require("rules")
local PAL_GOLD, PAL_CREAM = R.PAL_GOLD, R.PAL_CREAM
local RELIC_IDOL = rules.RELIC_IDOL
local rgba = color
local P, pp = R.P, R.pp
local rrect, picture, picture_fit = R.rrect, R.picture, R.picture_fit
local say, say_left, button, panel = R.say, R.say_left, R.button, R.panel
local set_paint, section = R.set_paint, R.section

function R.star_icon(center, radius)
    picture(R.hud_art.complete, rect.centered(center, size2(radius*2.6,radius*2.6)), 255)
end
local star_icon = R.star_icon

function R.wallet_icons() return {R.life_art, R.relics[RELIC_IDOL + 1], R.hud_art.complete} end
function R.town_middle_icon(at) gfx.image(R.hud_art.complete, rect.centered(at, size2(44, 44)), color.WHITE) end

-- The win card says three things: how well you did (stars, score), what you
-- earned (one chip per resource) and what comes next. Breakdowns of grants
-- and bonuses stay out of it; the build shop explains spending.
local RESULT = {card = rect(40, 238, 400, 534), header = rect(64, 210, 352, 72), stars = rect(110, 310, 260, 74),
                score = rect(90, 388, 300, 62), chips = rect(68, 462, 344, 92), next = rect(64, 572, 352, 72),
                claim = rect(70, 676, 340, 60)}
local function reward_chip(box, icon, value, label)
    rrect(box:offset(vec2(0, 3)), 16, rgba(201, 164, 100))
    rrect(box, 16, rgba(255, 246, 214))
    rrect(box:inflate(-3), 13, rgba(255, 238, 190))
    icon(rect(box.x + 12, box.y + (box.h - 54) / 2, 54, 54))
    say_left(value, rect(box.x + 74, box.y + 10, box.w - 82, 42), 32, PAL_GOLD)
    say_left(label, rect(box.x + 76, box.y + box.h - 34, box.w - 84, 20), 13, PAL_CREAM)
end
local function result_screen()
    local l = RESULT
    local kind = rules.wonder_at(R.g.level + 1)
    local w = kind and R.wonders[kind]
    local breakdown = rules.reward_breakdown(R.g, R.wonders, R.prog)
    local reward = breakdown.total
    local first = breakdown.first
    local s
    panel(l.card)
    rrect(l.header:offset(vec2(0, 5)), 18, rgba(77, 58, 31))
    rrect(l.header, 18, rgba(31, 83, 69))
    rrect(l.header:inflate(-3), 15, rgba(44, 108, 84))
    say(first and "Wish granted!" or "Replay complete", rect(l.header.x + 14, l.header.y + 8, l.header.w - 28, 36), 32, PAL_GOLD)
    say(("%d. %s"):format(R.g.level + 1, rules.level_of(R.g).name), rect(l.header.x + 12, l.header.y + 46, l.header.w - 24, 16), 15, PAL_CREAM)
    for k = 0, first and 2 or -1 do
        local slot = l.stars:col(3, k, 8)
        local part
        s, part = section(.24 + k * .13, .32, 13)
        local pop = 1 + math.sin(part.u * math.pi) * .14
        local at = slot:center() + vec2(0, k == 1 and -6 or 4)
        R.vfx_halo(pp(at), 48 * P.scale, rgba(255, 201, 77, 65 * P.alpha))
        star_icon(at, (k == 1 and 31 or 25) * pop)
        set_paint(s)
    end
    if not first then say("GOLD FOR YOUR MARKET", l.stars, 22, PAL_GOLD) end
    s = section(.43, .3, 9)
    say("SCORE", rect(l.score.x, l.score.y, l.score.w, 16), 13, PAL_CREAM)
    local count = R.dialog_part(.43, .65).f   -- the score counts up
    say(tostring(math.floor(R.g.score * count + .5)), rect(l.score.x, l.score.y + 16, l.score.w, 46), 42, PAL_GOLD)
    set_paint(s)
    s = section(.62, .28, 10)
    local gold_icon = function(box) picture_fit(R.relics[RELIC_IDOL + 1], box, 255) end
    if first then
        local left, right = rect(l.chips.x, l.chips.y, l.chips.w / 2 - 8, l.chips.h), rect(l.chips:center().x + 8, l.chips.y, l.chips.w / 2 - 8, l.chips.h)
        reward_chip(left, gold_icon, ("+%d"):format(reward[rules.GOLD]), "GOLD")
        reward_chip(right, function(box) star_icon(box:center(), 21) end, ("+%d"):format(reward[rules.STARS]), "STARS")
    else
        reward_chip(rect.centered(l.chips:center(), size2(220, l.chips.h)), gold_icon, ("+%d"):format(reward[rules.GOLD]), "GOLD")
    end
    set_paint(s)
    s = section(.9, .26, 8)
    rrect(l.next, 14, rgba(240, 225, 180))
    if first and w then picture_fit(w.sprite, rect(l.next.x + 8, l.next.y + 4, 66, l.next.h - 8), 255)
    else star_icon(vec2(l.next.x + 40, l.next:center().y), 22) end
    say_left(first and (w and "NEXT: BUILD" or "NEXT") or "SPEND IT IN THE", rect(l.next.x + 84, l.next.y + 10, l.next.w - 96, 18), 13, PAL_CREAM)
    say_left(first and (w and w.name or "The market has news") or "Build shop", rect(l.next.x + 84, l.next.y + 31, l.next.w - 96, 30), 24, PAL_GOLD)
    set_paint(s)
    s = section(1.02, .22, 8)
    if button(l.claim, "COLLECT", not R.modal_closing) and not R.modal_closing then
        if not R.dialog_settled() then R.dialog_skip()   -- first tap fast-forwards
        else R.close_dialog() end
    end
    local boards = R.words.leaderboard
    if boards and boards.level_board and not R.modal_closing then   -- this winter wish's Game Center board
        local y = math.min(l.card.y + l.card.h + 16, R.SCREEN_H - 66)
        if button(rect(l.card.x + 60, y, l.card.w - 120, 46), boards.level_button, true) then R.open_leaderboard(R.g.level) end
    end
    set_paint(s)
end
R.dialogs[R.OV_RESULT] = result_screen

-- One data source and one row resource; the engine measures and stacks every
-- row. Composite icon painting uses the same authored layers as the board.
local guide_entries = {
    {id="neighbors", title="Line up 3+ treats", description="Match straight lines along any of three axes.",
     icon={tiles={{kind=0,special=rules.NORMAL}}}},
    {id="lightning", title="Line of 4: striped treat", description="Its stripes show the line it clears.",
     icon={tiles={{kind=5,special=rules.ROW}}}},
    {id="specials", title="Line of 5+: rainbow star", description="Swap with a treat to clear that colour.",
     icon={tiles={{kind=2,special=rules.PRISM}}}},
    {id="blockers", title="Tinsel & powder snow", description="Match above snow; untangle the tinsel.",
     icon={back="sand",front="chain",tiles={{kind=3,special=rules.NORMAL}}}},
    {id="ice", title="Ice & candy canes", description="Match on ice. Nearby candy canes thaw it.",
     icon={front="ice-2",tiles={{kind=4,special=rules.NORMAL}}}},
}
local function guide_icon(box, icon)
    local at=box:center()
    local layer=rect.centered(at,size2(52,52))
    if icon.back then picture(R.board_art[icon.back .. "-edge"] or R.board_art[icon.back],layer,255) end
    for _,tile in ipairs(icon.tiles) do
        R.draw_relic(rules.tile(tile.kind,tile.special),pp(at+vec2(tile.x or 0,0)),P.scale*(tile.scale or 1),255*P.alpha,1)
    end
    if icon.front then
        local edge = R.board_art[icon.front .. "-edge"] or (icon.front == "chain" and R.board_art["chain-board"])
        picture(edge or R.board_art[icon.front],layer:inflate(edge and 6 or -2),255)
    end
end
local guide_form = match3.guide_form({
    title = "Market keeper's guide", instructions = "SWIPE OR TAP TWO NEIGHBORING TREATS",
    done = "LET'S MAKE MAGIC",
}, guide_icon)
assert(guide_form:set_items("topics",guide_entries))
R.guide_form=guide_form -- measured control bounds are also used by the input smoke test
local function guide_screen() match3.draw_guide(R, guide_form) end
R.dialogs[R.OV_GUIDE] = guide_screen

return R
