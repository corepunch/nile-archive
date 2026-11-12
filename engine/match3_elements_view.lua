-- Presentation of optional match-three elements. Games provide the atlas;
-- rules and board layouts stay independent of this drawing code.
local E = {}

E.assets = {"stone-1", "stone-2", "stone-3", "tunnel-in", "tunnel-out",
    "hidden-covered", "hidden-partial", "hidden-revealed", "growth", "delivery", "delivery-exit", "object-goal"}
for kind = 0, 5 do
    for hp = 1, 2 do E.assets[#E.assets + 1] = ("crate-%d-%d"):format(kind, hp) end
end

function E.load(art, skin)
    for _, name in ipairs(E.assets) do art[name] = assert(skin[name], "missing element art: " .. name) end
    art.object = art["object-goal"]
end

local function image(R, name, at, size, alpha)
    gfx.image(R.board_art[name], rect.centered(at, size2.splat(size)), color(255, 255, 255, alpha * 255))
end

-- Called after every well has been painted, before snow and pieces. A hidden
-- object's one authored image spans its complete footprint, not one per cell.
function E.ground(R, rules, sx)
    local g = R.g
    for _, object in ipairs(g.objects or {}) do
        local x, y, minx, maxx, miny, maxy = 0, 0, math.huge, -math.huge, math.huge, -math.huge
        for _, cell in ipairs(object.cells) do
            local p = R.cell_pos(cell) + vec2(sx, 0)
            x, y = x + p.x, y + p.y
            minx, maxx, miny, maxy = math.min(minx, p.x), math.max(maxx, p.x), math.min(miny, p.y), math.max(maxy, p.y)
        end
        if #object.cells > 0 then
            local state = object.state == "revealed" and "revealed" or object.state == "partial" and "partial" or "covered"
            local size = 2 * R.HEX_R + math.max(maxx - minx, maxy - miny)
            local cx, cy = x / #object.cells, y / #object.cells
            local radius, height = R.HEX_R - .65, math.sqrt(3) * (R.HEX_R - .65)
            local alpha = R.intro and R.intro:fade() or 1
            local art = object.art and R.board_art[object.art] or R.board_art["hidden-" .. state]
            -- Each hex samples its portion of the same footprint image. This
            -- prevents a large object from spilling into holes or other wells.
            for _, cell in ipairs(object.cells) do
                local p = R.cell_pos(cell) + vec2(sx, 0)
                local src = rect((p.x - cx + size / 2 - radius) * 128 / size,
                    (p.y - cy + size / 2 - height / 2) * 128 / size,
                    2 * radius * 128 / size, height * 128 / size)
                gfx.image_hex(art, src, p, radius, 0, color(255, 255, 255, 255 * alpha))
            end
        end
    end
    for i = 0, rules.CELLS - 1 do
        if rules.game_cell_active(g, i) then
            local at = R.cell_pos(i) + vec2(sx, 0)
            local alpha = R.intro and R.intro:fade() or 1
            if g.tunnel_to and g.tunnel_to[i] then image(R, "tunnel-in", at, 2 * (R.HEX_R - .65), alpha) end
            if g.tunnel_from and g.tunnel_from[i] then image(R, "tunnel-out", at, 2 * (R.HEX_R - .65), alpha) end
            if g.delivery_exits and g.delivery_exits[i] then image(R, "delivery-exit", at, 2 * (R.HEX_R - .65), alpha) end
        end
    end
end

-- Fixed blockers cover the piece area; growth covers a still-present piece.
function E.blockers(R, rules, sx)
    local g = R.g
    for i = 0, rules.CELLS - 1 do
        if rules.game_cell_active(g, i) then
            local name
            local hp = g.stone_hp and g.stone_hp[i] or 0
            local crate = g.crate_hp and g.crate_hp[i] or 0
            if hp > 0 then name = "stone-" .. math.min(hp, 3)
            elseif crate > 0 then name = ("crate-%d-%d"):format(g.crate_kind[i], math.min(crate, 2))
            elseif g.hazard and (g.hazard[i] or 0) > 0 then name = "growth" end
            if name then
                local visible, scale, alpha = true, 1, 1
                if R.intro then visible, scale, alpha = R.intro:blocker(i); alpha = alpha * R.intro:fade() end
                if visible then
                    local radius = (hp > 0 or crate > 0) and R.HEX_R - .65 or R.HEX_R
                    image(R, name, R.cell_pos(i) + vec2(sx, 0), 2 * radius * scale, alpha)
                end
            end
        end
    end
end

-- Hints and selections remain readable above all board elements.
function E.highlights(R, rules, sx, size)
    for i = 0, rules.CELLS - 1 do
        if rules.game_cell_active(R.g, i) then
            local name = i == R.selected and "selected"
                or (i == R.hint_a or i == R.hint_b) and R.phase == R.PH_IDLE and "hint"
            if name then
                local scale, turn, lift = 1, 0, 0
                if R.intro then scale, turn, lift = R.intro:cell(i) end
                local at = R.cell_pos(i) + vec2(sx, lift)
                local alpha = name == "hint" and (R.reduced_motion and 220 or 170 + 60 * math.sin(R.now * 5)) or 255
                gfx.image_rot(R.board_art[name], rect.centered(at, size2.splat(size * scale)), turn, color(255, 255, 255, alpha))
            end
        end
    end
end

-- Leave room to see artwork underneath pieces on special floor cells.
function E.piece_scale(g, cell)
    if (g.tunnel_to and g.tunnel_to[cell]) or (g.tunnel_from and g.tunnel_from[cell])
        or (g.delivery_exits and g.delivery_exits[cell]) then return .58 end
    for _, object in ipairs(g.objects or {}) do
        for _, i in ipairs(object.cells) do if i == cell then return .58 end end
    end
    return 1
end

function E.delivery(R, rules, t, at, scale, alpha, aspect, size)
    if t.kind ~= rules.DELIVERY then return false end
    local box = rect.centered(at, size2(size * scale * aspect, size * scale / aspect))
    gfx.image(R.board_art.delivery, box, color(255, 255, 255, alpha))
    return true
end

return E
