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
rawset(_G, "purse", ctor(function(...) return {...} end))
-- Dialogue modes (story.THOUGHT, story.SHOUT) become their lowercase names.
story = setmetatable({}, {__index = function(_, k) return type(k) == "string" and k:lower() or stub end})
setmetatable(_G, {__index = function() return stub end})

package.path = ("games/%s/lua/?.lua;"):format(game) .. package.path
local loaded = {state = {}}
function require(name)
    if loaded[name] ~= nil then return loaded[name] end
    local file = package.searchpath(name, package.path)
    local value = stub
    if file and not name:match("^match3") then
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
    local campaign, buildings = require("campaign"), require("buildings")
    local economy = game == "relic-rush" and require("economy") or nil
    require("narrative")
    out.kind = "match3"
    out.cast = cast_of(loaded.state.cast)
    local wonders = {}
    for _, b in ipairs(buildings) do
        if b.category == "wonder" then
            wonders[#wonders + 1] = {key = b.key, name = b.name, about = b.about, sprite = b.sprite_path,
                price = economy and economy.price_parts(b.cost)}
        end
    end
    local funds, restored = {}, {}
    for i, level in ipairs(campaign.wonder_levels or {}) do funds[level] = wonders[i] end
    if economy then
        for _, piece in pairs(economy.unlocks) do restored[piece.building] = true end
    end
    out.levels = {}
    for i, l in ipairs(campaign.levels) do
        local reveal = type(l.reveal) == "table" and not is_stub(l.reveal) and l.reveal or nil
        local materials
        if l.dress then
            materials = {}
            if l.chains > 0 then materials[#materials + 1] = l.dress.lock or "iron-chain" end
            if l.dress.cover then materials[#materials + 1] = l.dress.cover end
            if l.dress.floor then materials[#materials + 1] = l.dress.floor.covered
            elseif l.oil then materials[#materials + 1] = "river-silt" end
            if l.carpet then materials[#materials + 1] = "drift-sand" end
        end
        local resources, goal_resource
        if economy then
            resources = {}
            local yields = economy.board_yields(l, restored)
            goal_resource = l.goal_kind ~= nil and yields[l.goal_kind] or nil
            for k = 0, campaign.colors - 1 do
                local piece = yields[k]
                if piece then
                    resources[#resources + 1] = {key=piece.key, name=piece.name, yield=piece.amount,
                        currency=economy.currencies[piece.slot].name}
                end
            end
        end
        out.levels[i] = {n = i, name = l.name, lesson = l.lesson, moves = l.moves, score = l.score,
                         quest = l.quest_object, wonder = funds[i], materials = materials,
                         resources = resources, resource_unlock = l.resource_unlock,
                         collection = (l.story_piece or goal_resource) and {
                             key = l.story_piece or goal_resource.key, count = l.relics, resource = goal_resource ~= nil,
                             regular = campaign.colors - (l.omit_kind ~= nil and 1 or 0) - (l.story_piece and 1 or 0)} or nil,
                         plaques = l.dress and l.dress.floor and l.dress.floor.covered == "blue-plaque" and #l.oil or nil,
                         signal = l.signal, delivery_icon = l.deliveries and l.deliveries.icon,
                         reveal = reveal and {picture = reveal.picture, mosaic = reveal.mosaic, floor = reveal.floor,
                             covered_picture = reveal.covered_picture, cells = reveal.object and #l.oil or nil}}
    end
    out.beats = {}
    for i, b in ipairs(require("story_content")) do
        local choices = {}
        for k, c in ipairs(b.choices or {}) do choices[k] = {label = c.label, lines = lines_of(c.lines)} end
        out.beats[i] = {key = b.key, phase = b.phase, level = b.level, prompt = b.prompt,
                        lines = lines_of(b.lines), choices = #choices > 0 and choices or nil}
    end
end

local buffer = {}
encode(out, buffer)
io.write(table.concat(buffer), "\n")
