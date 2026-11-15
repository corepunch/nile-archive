local R = require("state")
local rules = require("rules")
local island = require("island")
local economy = require("economy")

function R.board_context(preview)
    if preview then return not app.arg("before-well") end
    return island.owned(R.island, economy.WELL_KIND) > 0
end

function R.board_lesson(g)
    if g.level == 4 and g.resource_yields[3] == economy.water then
        return "Water stocks your camp. Clear plaques and collect markers."
    end
    return rules.level_of(g).lesson
end

function R.stash_completed()
    local g = R.g
    if not g.earnings then return end
    R.prog.completed = {level=g.level, rng=g.rng, moves=g.moves, score=g.score,
        earnings={table.unpack(g.earnings)}}
    R.save_progress()
end

function R.serialize_campaign(s)
    local reading = save.is_reading(s)
    local version = s:int("resource_version", reading and 0 or economy.CAMPAIGN_VERSION)
    if reading and version < economy.CAMPAIGN_VERSION then island.migrate_wallet(R.prog, R.island) end
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
    g.won, g.relics, g.delivered, g.oil_left = true, spec.relics, g.delivery_total, 0
    for i = 0, rules.CELLS-1 do
        g.oil[i] = 0
        if g.tiles[i].kind == rules.DELIVERY then g.tiles[i] = rules.tile(-1) end
    end
    R.reset_board(g)
    R.on_island, R.overlay, R.intro = false, R.OV_RESULT, nil
end
