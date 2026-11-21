-- The title screen owns its layout. The app supplies art, copy and actions.
local N = ui.node
local M = {}
local Screen = {}
Screen.__index = Screen

function M.new(copy, art, skin, actions)
    local title = {gap=0}
    for _, line in ipairs(copy.title) do
        title[#title + 1] = N.label {text=line, em=78, height=71, text_style="menu_title"}
    end
    title[#title + 1] = N.label {text=copy.subtitle, em=22, height=39, text_style="menu_subtitle"}
    local controls = ui.form(N.column {gap=12,
        N.button {id="continue",text=copy.play,height=66,em=31},
        N.row {gap=12,
            N.button {id="town",text=copy.town,height=48,grow=1,role="link",em=21,visible_field="visit"},
            N.button {id="settings",text=copy.settings,height=48,grow=1,role="link",em=21},
        },
    })
    return setmetatable({heading=ui.form(N.column(title)), form=controls, art=art, skin=skin, actions=actions}, Screen)
end

function Screen:frame(inp, dt, active)
    local screen, full = app.screen(), app.bleed()
    if not self.backdrop then
        self.backdrop = texture.load(self.art)
        assert(self.backdrop.tex, "missing title screen backdrop: " .. self.art)
    end
    local art = texture.size(self.backdrop)
    local cover = rect.centered(full:center(), art:scale(art:cover(full:size())))
    gfx.bleed(true)
    gfx.image(self.backdrop, cover, color.WHITE)
    gfx.bleed(false)

    local width = screen.w - 36
    local _, height = self.heading:measure(width, self.skin)
    self.heading:draw(rect(screen.x + 18, screen.y + screen.h * .085, width, height), self.skin, {interactive=false})
    self.form.values.visit = self.actions.can_visit()
    width = math.min(screen.w - 36, 290)
    _, height = self.form:measure(width, self.skin)
    local bounds = rect(screen:center().x - width / 2, screen:max().y - height - 33, width, height)
    local event = self.form:draw(bounds, self.skin, {input=inp, dt=dt, interactive=active})
    if event then self.actions[event.id]() end
end

return M
