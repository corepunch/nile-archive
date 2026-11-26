-- Guided opening moves and contextual lessons for the construction tools.
local l10n = require("l10n")
local tr = l10n.tr

local Tutorial = {}
Tutorial.__index = Tutorial

local lessons = {
    {copy=tr("Clear the targets before you run out of moves. Swap these pieces to match three in a line."), length=3, seed=1},
    {copy=tr("Match four in a line to make a Line Gem."), length=4, special="striped", seed=12,
        follow=tr("Match the Line Gem with pieces of its kind to clear a whole line.")},
    {copy=tr("Match five in a line to make a Rainbow Gem."), length=5, special="color_bomb", seed=24,
        follow=tr("Swap the Rainbow Gem with a piece to clear every piece of that kind.")},
    {length=3, chain=true, seed=1},
}

local function find_swap(rules, g, accept)
    local wave = rules.new_match()
    for a = 0, rules.CELLS - 1 do
        for axis = 0, rules.AXES - 1 do
            local b = rules.hex_neighbor(a, axis)
            if rules.game_swap_matches(g, a, b) then
                local trial = rules.game_copy(g)
                if rules.game_swap(trial, a, b, wave) then
                    local action = accept(a, b, trial, wave)
                    if action then return action end
                end
            end
        end
    end
end

local function activate_move(rules, g, name)
    return find_swap(rules, g, function(a, b, trial, wave)
        rules.game_apply(trial, wave)
        for _, effect in ipairs(wave.special_effects or {}) do
            if effect.name == name then
                local cells = {[a]=true, [b]=true}
                if name == "striped" then
                    for cell in pairs(wave.ordinary) do cells[cell] = true end
                end
                return {a=a, b=b, cells=cells}
            end
        end
    end)
end

local function opening_move(rules, g, lesson)
    return find_swap(rules, g, function(a, b, trial, wave)
        if wave.hits ~= lesson.length then return end
        local _, award = next(wave.special_awards or {})
        if (award and award.name) ~= lesson.special then return end
        local target, chain
        for cell in pairs(wave.ordinary) do
            target = target or g.oil[cell] > 0
            chain = chain or g.chain[cell] > 0
        end
        if not target or lesson.chain and not chain then return end
        local cells = {[a]=true, [b]=true}
        for cell in pairs(wave.ordinary) do cells[cell] = true end
        local action = {a=a, b=b, cells=cells, copy=lesson.copy}
        if not lesson.special then return action end

        -- Pick a normal deal where the actual cascade leaves the gem usable.
        local fall = rules.new_match()
        rules.game_apply(trial, wave)
        repeat
            rules.game_collapse(trial, true)
            rules.game_matches(trial, fall)
            if fall.hits > 0 then rules.game_apply(trial, fall) end
        until fall.hits == 0
        if trial.oil_left == 0 then return end
        action.next = activate_move(rules, trial, lesson.special)
        if action.next then
            action.next.copy = lesson.follow
            return action
        end
    end)
end

function Tutorial.new(R, rules, chain_copy, goal_line)
    local skip = ui.form(ui.node.button {id="skip", text=tr("Skip"), role="link", em=16, height=44})
    return setmetatable({R=R, rules=rules, chain_copy=chain_copy, goal_line=goal_line, skip=skip}, Tutorial)
end

function Tutorial:start(level, seed, make)
    self.move, self.tip, self.goal_shown = nil, nil, false
    local g = make(level, seed)
    local lesson = lessons[level + 1]
    if not self.enabled or not lesson or level ~= self.R.prog.level then return g end
    local action = opening_move(self.rules, g, lesson)
    if not action and seed ~= lesson.seed then
        -- Both campaigns have a verified deal for each lesson. If a level is
        -- edited and no longer fits that deal, leave its normal board playable.
        local fallback = make(level, lesson.seed)
        action = opening_move(self.rules, fallback, lesson)
        if action then g = fallback end
    end
    if action then
        action.copy = action.copy or self.chain_copy
        self.move = action
    end
    return g
end

function Tutorial:ready()
    local R = self.R
    return self.enabled and R.g and R.phase == R.PH_IDLE and not R.mission_banner and not R.art_review
        and not R.g.won and not R.g.lost and R.overlay == R.OV_NONE
end

function Tutorial:show_goal_reminder()
    local R, g = self.R, self.R.g
    if not self.goal_line or self.goal_shown or not R.dialogue_on() or not self:ready()
        or g.level ~= 0 or R.prog.level ~= 0 or g.oil_left == 0
        or self.rules.level_of(g).moves - g.moves < 3 then return end
    self.goal_shown = true
    story.add(self.goal_line)
    return true
end

function Tutorial:allows_cell(cell)
    return not self.move or cell == self.move.a or cell == self.move.b
end

function Tutorial:allows_swap(a, b)
    return self:allows_cell(a) and self:allows_cell(b)
end

function Tutorial:swapped()
    if self.move then self.move = self.move.next end
end

function Tutorial:serialize(s)
    local p = self.R.prog
    p.tutorial_tools = s:int("tutorial_tools", p.tutorial_tools or 0)
end

function Tutorial:remember_tip(tip)
    local R = self.R
    R.prog.tutorial_tools = (R.prog.tutorial_tools or 0) | tip.flag
    self.tip = nil
    return true
end

function Tutorial:charge_changed()
    local tip = self.tip
    if tip and self.R.g.tool_meter[tip.tool] ~= tip.points then return self:remember_tip(tip) end
end

function Tutorial:tool_selected(tool)
    local tip = self.tip
    if tip and tip.tool == tool and tip.points == self.R.g.tool_threshold then
        self:remember_tip(tip)
        self.R.save_progress()
    end
end

local function tool_flag(bonus, ready)
    return 1 << (4 * (bonus.tool - 1) + 2 * (bonus.rank - 1) + (ready and 1 or 0))
end

function Tutorial:tool_tip()
    local R, g = self.R, self.R.g
    if not g.tool_meter or g.bonus_preview then return end
    local seen = R.prog.tutorial_tools or 0
    for _, bonus in ipairs(g.tool_slots) do
        local points, flag = g.tool_meter[bonus.tool], tool_flag(bonus, true)
        if points == g.tool_threshold and seen & flag == 0 and R.tool < 0
            and R.bonus_display_charge(bonus.tool) == points then
            -- TRANSLATORS: a tool's name, then the sentence saying what it does
            return {tool=bonus.tool, flag=flag, points=points, copy=tr("Tap %s. %s"):format(bonus.name, bonus.effect)}
        end
    end
    local bonus = g.bonus
    if not bonus then return end
    local points, flag = g.tool_meter[bonus.tool], tool_flag(bonus, false)
    if not points or points >= g.tool_threshold or seen & flag ~= 0 then return end
    local cells = {}
    for cell = 0, self.rules.CELLS - 1 do
        local tile = g.tiles[cell]
        if not tile.special and g.resource_yields[tile.kind] == bonus then cells[cell] = true end
    end
    if next(cells) then
        return {tool=bonus.tool, flag=flag, points=points, cells=cells,
            -- TRANSLATORS: %s is a tool's name (Hammer, Bomb ...): its pieces charge it
            copy=tr("Match %s pieces to charge the tool."):format(bonus.name)}
    end
end

function Tutorial:step()
    if not self:ready() then return end
    self.tip = not self.move and self:tool_tip() or nil
    return self.move or self.tip
end

function Tutorial:frame(inp, dt, step)
    local R, move = self.R, self.move
    local ink = color(255, 227, 151)
    local hole
    if move then
        local a, b = R.cell_pos(move.a), R.cell_pos(move.b)
        local full = app.bleed()
        hole = rect.corners(a, b):inflate2(vec2(R.cell_width * .5, R.cell_height * .5)):intersect(full)
        local edge = hole:max()
        local shade = color(0, 0, 0, 178)
        gfx.bleed(true)
        gfx.rect(full:top(hole.y - full.y), shade)
        gfx.rect(full:bottom(full:max().y - edge.y), shade)
        gfx.rect(rect(full.x, hole.y, hole.x - full.x, hole.h), shade)
        gfx.rect(rect(edge.x, hole.y, full:max().x - edge.x, hole.h), shade)
        gfx.bleed(false)
        gfx.round_rect_line(hole, 0, 1.5, ink)
        local direction = (b - a):norm()
        local slide = R.reduced_motion and 0 or 4 * math.sin(R.now * 5)
        local center = (a + b):scale(.5) + direction:scale(slide)
        local bounds = rect.centered(center, size2.splat(R.cell_width * .88))
        gfx.image_rot(self.arrow, bounds:fit(texture.size(self.arrow)), math.atan(direction.y, direction.x), color.WHITE)
    end

    local style = R.pal(R.PAL_CREAM, 18)
    local width = R.SCREEN_W - 36
    local height = math.max(58, text.box_size(style, width - 100, step.copy).h + 14)
    local hud_bottom = R.hud_rect:max().y
    local y = hud_bottom + 22
    if hole and y + height + 8 > hole.y and y < hole:max().y then
        local above = hole.y - height - 8
        y = above >= hud_bottom + 6 and above or hole:max().y + 8
    end
    if step.tool then
        local button = R.board_tool_bounds(step.tool - 1)
        gfx.round_rect_line(button:inflate(-6), 9, 2, ink)
        y = button.y - height - 15
    end
    local panel = rect(18, y, width, height)
    gfx.shadow(panel, 10, 12, color(0, 0, 0, 130))
    gfx.round_rect(panel, 11, R.skin:color("moves_face"))
    gfx.round_rect_line(panel, 11, 1.5, ink)
    local copy = rect(panel.x + 14, panel.y + 5, panel.w - 100, panel.h - 10)
    text.box(style, copy, vec2(0, .5), step.copy)
    local skip = rect(panel:max().x - 78, panel:center().y - 22, 70, 44)
    ui.block(panel)
    if self.skip:draw(skip, R.skin, {input=inp, dt=dt}) then
        if move then self.move = nil
        else self:remember_tip(step); R.save_progress() end
        R.selected = -1
        return true
    end
end

return Tutorial
