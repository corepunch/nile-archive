-- scenario_dump.lua — print a game's scenario data as JSON: its cast, its
-- levels or scenes and every story beat. Run by tools/scenario_overview.py
-- under the host's `lua` (5.4+), from the repository root:
--
--   lua tools/scenario_dump.lua relic-rush
--
-- The game's data modules are plain tables. Everything they reach for from
-- the engine (vec2, color, require("match3.game") ...) is an inert stub, so
-- no game starts and no window opens.
local game = assert(arg[1], "usage: lua tools/scenario_dump.lua <game>")

local stub
local stub_mt = {}
stub_mt.__index = function() return stub end
stub_mt.__call = function() return stub end
for _, op in ipairs{"__add", "__sub", "__mul", "__div", "__unm", "__mod", "__pow", "__idiv"} do
    stub_mt[op] = function() return stub end
end
stub_mt.__concat = function() return "" end
stub = setmetatable({}, stub_mt)
local function is_stub(v) return type(v) == "table" and getmetatable(v) == stub_mt end

local function ctor(make)
    return setmetatable({}, {__call = function(_, ...) return make(...) end, __index = function() return stub end})
end
vec2 = ctor(function(x, y) return {x = x, y = y} end)
size2 = ctor(function(w, h) return {w = w, h = h} end)
color = ctor(function(r, g, b, a) return {r, g, b, a} end)
rect = ctor(function(x, y, w, h) return {x = x, y = y, w = w, h = h} end)
local purse_mt = {__add = function(a, b)   -- wallets add slot by slot
    local sum = setmetatable({}, getmetatable(a))
    for slot = 1, math.max(#a, #b) do sum[slot] = (a[slot] or 0) + (b[slot] or 0) end
    return sum
end}
rawset(_G, "purse", ctor(function(...) return setmetatable({...}, purse_mt) end))
-- Dialogue modes (story.THOUGHT, story.SHOUT) become their lowercase names.
story = setmetatable({}, {__index = function(_, k) return type(k) == "string" and k:lower() or stub end})
setmetatable(_G, {__index = function() return stub end})

package.path = ("games/%s/lua/?.lua;"):format(game) .. package.path
local loaded = {state = {}}
function require(name)
    if loaded[name] ~= nil then return loaded[name] end
    -- These engine modules build campaign data without opening a game.
    local engine = name == "match3.game" or name == "match3.bonuses" or name == "match3.shapes" or name == "match3.user_events"
    local file = engine and "engine/lua/" .. name:gsub("%.", "/") .. ".lua" or package.searchpath(name, package.path)
    local value = stub
    if file and (engine or not name:match("^match3")) then
        local ok, result = pcall(dofile, file)
        if ok and result ~= nil then value = result
        elseif not ok then io.stderr:write(("scenario_dump: %s skipped (%s)\n"):format(name, tostring(result))) end
    end
    loaded[name] = value
    return value
end

------------------------------------------------------------------ JSON

local function encode(v, out)
    local t = type(v)
    if t == "string" then
        out[#out + 1] = '"' .. v:gsub('[%c"\\]', function(c)
            local named = {['"'] = '\\"', ['\\'] = '\\\\', ['\n'] = '\\n', ['\t'] = '\\t', ['\r'] = '\\r'}
            return named[c] or ("\\u%04x"):format(c:byte())
        end) .. '"'
    elseif t == "number" or t == "boolean" then out[#out + 1] = tostring(v)
    elseif t == "table" and not is_stub(v) then
        if #v > 0 or next(v) == nil then
            out[#out + 1] = "["
            for i, x in ipairs(v) do
                if i > 1 then out[#out + 1] = "," end
                encode(x, out)
            end
            out[#out + 1] = "]"
        else
            local keys = {}
            for k in pairs(v) do if type(k) == "string" then keys[#keys + 1] = k end end
            table.sort(keys)
            out[#out + 1] = "{"
            for i, k in ipairs(keys) do
                if i > 1 then out[#out + 1] = "," end
                encode(k, out); out[#out + 1] = ":"; encode(v[k], out)
            end
            out[#out + 1] = "}"
        end
    else out[#out + 1] = "null" end
end

------------------------------------------------------------------ data

local function lines_of(raw)
    local lines = {}
    for i, l in ipairs(raw or {}) do
        lines[i] = {speaker = l[1], text = l[2], mode = type(l[3]) == "string" and l[3] or nil}
    end
    return lines
end

local function cast_of(list)
    local cast = {}
    for i, c in ipairs(list or {}) do
        cast[i] = {id = c.id, name = c.name, role = c.role, portrait = c.portrait_path}
    end
    return cast
end

local out = {game = game}
if game == "nile-archive" then
    local content, beats = require("archive_content"), require("archive_story")
    out.kind = "hidden-object"
    out.cast = cast_of(content.cast)
    out.scenes = {}
    for i = 1, content.SCENES do
        local s = content.scenes[i]
        out.scenes[#out.scenes + 1] = {n = i, title = s.title, teaser = s.teaser, background = s.background,
                                       clues = s.clues or {}, names = s.names or {}}
    end
    for chapter, id in ipairs(content.CACHES) do
        local s = content.scenes[id]
        out.scenes[#out.scenes + 1] = {n = id, cache = chapter, title = s.title, teaser = s.teaser,
                                       background = s.background, clues = s.clues or {}, names = s.names or {}}
    end
    out.beats = {}
    for key, b in pairs(beats) do
        if type(b) == "table" then out.beats[#out.beats + 1] = {key = key, note = b.note, lines = lines_of(b.lines)} end
    end
    table.sort(out.beats, function(a, b) return a.key < b.key end)
else
    local campaign, economy = require("campaign"), require("economy")
    local island, journey = require("island"), require("journey")
    require("narrative")
    out.kind = "match3"
    out.cast = cast_of(loaded.state.cast)

    -- Icons are atlas frames; the page crops the ones named here.
    out.frames = {}
    local atlases = dofile(("games/%s/lua/match3_atlases.lua"):format(game))
    local function icon(...)
        for _, name in ipairs{...} do
            for _, atlas in pairs(atlases) do
                local f = atlas.frames[name]
                if f then
                    out.frames[name] = {path = atlas.path, frame = f, grid = atlas.grid}
                    return name
                end
            end
        end
    end
    local function piece_icon(piece, kind) return icon("campaign-" .. (piece.key or ""), "market-" .. kind) end
    out.currencies = {}   -- in the order the games show them
    local order = economy.currency_order or {1, 2, 3}
    for i, slot in ipairs(order) do out.currencies[i] = economy.currencies[slot].name end
    local function price_of(cost)
        local parts = {}
        for _, slot in ipairs(order) do
            if (cost[slot] or 0) > 0 then
                parts[#parts + 1] = {name = economy.currencies[slot].name, amount = cost[slot]}
            end
        end
        return parts
    end

    -- What a ladder purchase puts on later boards, from its economy.unlocks row.
    local function gets_of(unlock)
        local gets = {}
        local bonus = unlock.bonus
        if bonus then
            local first = economy.bonus_slots[bonus.tool].levels[1]
            gets[#gets + 1] = {type = "bonus", icon = icon(bonus.icon), name = bonus.name, effect = bonus.effect,
                               upgrades = bonus.rank > 1 and first.name or nil}
        end
        if unlock.kind then
            local piece = unlock.slot and unlock or economy.pieces[unlock.kind]
            gets[#gets + 1] = {type = "piece", icon = piece_icon(piece, unlock.kind), name = piece.name,
                               amount = piece.amount, currency = economy.currencies[piece.slot].name}
        end
        if unlock.income then
            for _, part in ipairs(price_of(unlock.income)) do
                gets[#gets + 1] = {type = "income", amount = part.amount, currency = part.name}
            end
        end
        return gets
    end

    -- The ladder in purchase order, as the engine builds it (match3.game
    -- campaign_ladder). Optional purchases fill no position.
    local story_key = {}   -- the story building each wonder level waits for
    local purchase_level = {}
    out.ladder = {}
    for position, step in ipairs(island.ladder) do
        local b, unlock = island.buildings[step.kind + 1], step.unlock
        purchase_level[b.key] = step.after
        if step.story then story_key[step.after] = b.key end
        out.ladder[position] = {position = position, key = b.key, kind = step.kind, name = b.name, about = b.about,
            sprite = b.sprite_path, price = price_of(b.cost), after = step.after, story = step.story,
            from = math.max(unlock.first_level or 0, step.after + 1),   -- the first board it changes
            quest = economy.quests and economy.quests[b.key], gets = gets_of(unlock)}
    end

    out.levels = {}
    for i, l in ipairs(campaign.levels) do
        local reveal = type(l.reveal) == "table" and not is_stub(l.reveal) and l.reveal or nil
        local materials
        if l.dress then
            materials = {}
            if type(l.chains) == "number" and l.chains > 0 then materials[#materials + 1] = l.dress.lock or "iron-chain" end
            if l.dress.cover then materials[#materials + 1] = l.dress.cover end
            if l.dress.floor then materials[#materials + 1] = l.dress.floor.covered
            elseif l.oil then materials[#materials + 1] = "river-silt" end
        end
        -- The pieces a player who bought every purchase as it opened sees on
        -- this board, with the seed the captures use.
        local restored = {}
        for _, step in ipairs(island.ladder) do
            if step.after < i then restored[island.buildings[step.kind + 1].key] = true end
        end
        local yields = economy.board_loadout(i, restored, 123478)
        local resources = {}
        for kind = 0, 15 do
            local piece = yields[kind]
            if piece and piece.slot then
                resources[#resources + 1] = {icon = piece_icon(piece, kind), name = piece.name, yield = piece.amount,
                    currency = economy.currencies[piece.slot].name}
            elseif piece and piece.tool then   -- a bonus gem or a booster's charging piece
                resources[#resources + 1] = {icon = piece.icon and icon(piece.icon) or piece_icon(piece, kind),
                    name = piece.name, charges = piece.icon and "bonus" or "booster"}
            end
        end
        out.levels[i] = {n = i, name = l.name, lesson = l.lesson, moves = l.moves, score = l.score,
                         materials = materials, resources = resources,
                         story_piece = l.story_piece,
                         plaques = l.dress and l.dress.floor and l.dress.floor.covered == "tile-tablet-single" and #l.oil or nil,
                         signal = l.signal,
                         reveal = reveal and {picture = reveal.picture, floor = reveal.floor}}
    end
    out.beats = {}
    local upgrade_site = {}
    for _, event in ipairs(require("user_events").events) do
        if event.upgrade then upgrade_site[event.id] = event.upgrade.building end
    end
    for i, b in ipairs(require("story_content")) do
        local choices = {}
        for k, c in ipairs(b.choices or {}) do choices[k] = {key = c.key, label = c.label, lines = lines_of(c.lines)} end
        -- As journey.next schedules it: a scene after a wonder level waits for
        -- that level's story building, unless it plays on the clear itself.
        local waits = b.phase ~= "visit" and b.phase ~= "before" and not (b.phase == "after" and journey.clear_before_result) and story_key[b.level]
        if b.phase == "placed" then waits = b.building
        elseif b.phase == "upgrade" then waits = assert(upgrade_site[b.event]) end
        local variant = b.variant and {building = b.variant.building, index = b.variant.index, lines = lines_of({b.variant.line})}
        if variant and b.variant.memory then
            variant.memory = {answer = b.variant.memory.answer, lines = lines_of({b.variant.memory.line})}
        end
        out.beats[i] = {key = b.key, phase = b.phase, level = b.level or purchase_level[waits], variant = variant, resident = b.resident,
                        visit_site = b.phase == "visit" and b.building or nil, checkpoint = b.checkpoint, prompt = b.prompt, waits_for = waits or nil,
                        lines = lines_of(b.lines), choices = #choices > 0 and choices or nil}
    end
end

local buffer = {}
encode(out, buffer)
io.write(table.concat(buffer), "\n")
