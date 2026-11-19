-- The crew's requests: which are open, the board slots their pieces take,
-- counting on a match, banking on a win and handing in.
local rules = require("rules")
local economy = require("economy")
local quests = require("quests")
local Q = quests.by_key

local function owner(...)
    local built = {}
    for _, key in ipairs{...} do built[key] = true end
    return function(building) return built[building] or false end
end
local function keys(list)
    local out = {}
    for i, quest in ipairs(list) do out[i] = quest.key end
    return table.concat(out, " ")
end

-- Two lines; a request waits for its building and for the one before it.
do
    local state = quests.new_state()
    check(keys(quests.open(state, owner())) == "", "nothing is asked before the well")
    check(keys(quests.open(state, owner("well"))) == "chart supper", "the well opens one request on each line")
    check(keys(quests.open(state, owner("well", "log_cabin"))) == "chart supper", "a line holds one request at a time")
    state.have.chart = Q.chart.need
    check(quests.ready(state, Q.chart) and keys(quests.collecting(state, owner("well"))) == "supper",
        "a filled request gives up its board slot")
    check(keys(quests.open(state, owner("well"))) == "chart supper", "and stays open until it is handed in")
    check(quests.deliver(state, Q.chart) and not quests.deliver(state, Q.chart), "a request is handed in once")
    check(keys(quests.open(state, owner("well"))) == "supper", "the next on the line waits for its building")
    check(keys(quests.open(state, owner("well", "log_cabin"))) == "supper trail", "and opens once it stands")
    check(not quests.deliver(state, Q.supper), "a short request cannot be handed in")
end

-- Open requests take the free score slots in list order. A restoration's
-- piece never gives way, and a request with no slot waits.
do
    local function yields(number, restored)
        return (economy.board_loadout(rules.levels[number], number, restored, 19))
    end
    local two = {Q.chart, Q.supper}
    local y = yields(3, {well=true, quests=two})
    check(y[5] == Q.chart.yield and y[4] == Q.supper.yield, "two requests take quartz's and the amphora's slots")
    check(y[3] == economy.unlock_of("well") and y[0].slot == economy.GOLD and y[2] == nil,
        "water, coins and the leaf keep theirs")
    y = yields(9, {well=true, log_cabin=true, workshop=true, quests={Q.trail, Q.tools}})
    check(y[5] == Q.trail.yield and y[4] == economy.unlock_of("workshop"), "timber keeps its slot: the second request waits")
    y = yields(3, {well=true})
    check(y[5] == nil and y[4] == nil, "with nothing asked the score pieces return")
    local fully_restored = {quests={Q.tools, Q.cable}}
    for _, unlock in ipairs(economy.unlocks) do fully_restored[unlock.building] = true end
    y = yields(quests.REPLAY_LEVEL, fully_restored)
    check(y[5] == Q.tools.yield and y[4] == Q.cable.yield,
        "the replay has room for two requests even with the full ladder built")
    for number = 1, 12 do
        local seen = {}
        for _, piece in pairs(yields(number, {preview=true, well=true, log_cabin=true, workshop=true, camp=true})) do
            if piece.item then seen[#seen + 1] = piece.item end
        end
        table.sort(seen)
        local written = {}
        for _, quest in ipairs(quests.scheduled(number)) do written[#written + 1] = quest.key end
        table.sort(written)
        check(table.concat(seen, " ") == table.concat(written, " "),
            ("a preview of expedition %d shows the requests written for it"):format(number))
    end
end

-- A matched request piece counts under its request and pays nothing.
do
    local g = rules.game_start(2, 123, {well=true, quests={Q.chart, Q.supper}})
    local present = false
    for i = 0, rules.CELLS - 1 do present = present or g.tiles[i].kind == 5 end
    check(present, "the opening shows the request's piece")
    for _, i in ipairs(require("support").open_line(rules, g)) do
        g.tiles[i], g.chain[i], g.ice[i] = rules.tile(5), 0, 0
    end
    local m = rules.new_match()
    rules.game_matches(g, m, -1)
    local hits = m.hits
    rules.game_apply(g, m)
    check(hits >= rules.MATCH_MIN and g.items.chart == hits and g.items.supper == nil, "each matched piece counts once")
    check(g.earnings[1] == 0 and g.earnings[2] == 0 and g.earnings[3] == 0, "and banks nothing in the wallet")
    local copy = rules.game_copy(g)
    copy.items.chart = 0
    check(g.items.chart == hits, "a board copy counts on its own")

    -- A win banks the pieces up to the need; a lost board banks none.
    local p = {level=2, seed=1, wallet=purse()}
    g.items.chart = Q.chart.need + 7
    check(not rules.progress_reward(p, g) and not p.quests, "an unfinished board banks nothing")
    g.won = true
    check(rules.progress_reward(p, g) and p.quests.have.chart == Q.chart.need, "a win banks the pieces, up to the need")
    check(quests.deliver(p.quests, Q.chart) and p.quests.done.chart and p.quests.have.chart == nil, "a full request is handed in")
    local again = rules.game_start(2, 124, {well=true, quests={Q.chart}})
    again.won, again.items.chart = true, 5
    p.level = 3
    check(rules.progress_reward(p, again) and p.quests.have.chart == nil, "a handed-in request takes no more pieces")
end

-- Every request has art, words and a scene.
do
    local scenes = require("quest_scenes")
    local seen = {}
    for _, quest in ipairs(quests.list) do
        check(not seen[quest.piece], "requests never share a piece: " .. quest.piece)
        seen[quest.piece] = true
        check(economy.unlock_of(quest.after) ~= nil, quest.key .. " opens with a ladder building")
        check(quest.need > 0 and #quest.title > 0 and #quest.request > 0 and #scenes[quest.key] >= 2, quest.key .. " is written")
        check(quest.levels[1] >= economy.unlock_of(quest.after).first_level, quest.key .. " is scheduled after its building")
    end
end
