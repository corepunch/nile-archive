local character = {}

function character:__call(text, options)
    local line = {self.id, text}
    if options then
        line[3] = options.mode
        line.listener = options.listener
    end
    return line
end

local cast = {
    {id='sela', name='Sela', role='Potter', portrait_path='story/characters/sela.png', color=color(141,70,55), mouth=vec2(.54,.31)},
    {id='oren', name='Oren', role='Miller', portrait_path='story/characters/oren.png', color=color(128,87,43), right=true, mouth=vec2(.52,.26)},
    {id='tavi', name='Tavi', role='Ferry pilot', portrait_path='story/characters/tavi.png', color=color(48,102,107), right=true, mouth=vec2(.68,.29)},
}
local by_id = {}
for _, member in ipairs(cast) do
    by_id[member.id] = setmetatable(member, character)
end

return {all = cast, by_id = by_id}
