-- A motion fixture (engine/tween.lua): six bars arrive on six curves, staggered
-- in a timeline; a badge punches, a counter counts, the badge shakes. Rendered
-- as a reel by `make test` into docs/screenshots/motion-reel.gif. Run it with
-- `build/nile-archive --lua tests/fixtures/motion`.
local names = {"out_cubic", "out_back", "out_elastic", "out_bounce", "in_out_quad", "steps"}
local bars, badge, counter = {}, {pos = vec2(760, 760), scale = 1}, {shown = 0, total = 2480}
local label, big

local function init()
    local sans, bold = font.load("fonts/PT_Sans-Web-Regular.ttf"), font.load("fonts/PT_Sans-Web-Bold.ttf")
    label = style{font = sans, size = 22, fill = color.hex(0x12393B)}
    big = style{font = bold, size = 46, fill = color.hex(0xF4E8CA)}
    for i = 1, 6 do bars[i] = {y = 110 + (i - 1) * 86, x = -560, alpha = 0} end
    local tl = tween.timeline{defaults = {ease = "linear"}}
    for i, bar in ipairs(bars) do
        tl:to(bar, .9, {x = 90, alpha = 1}, (i - 1) * .07):ease(names[i], names[i] == "steps" and 6 or nil)
    end
    tl:label("land")
    tl:punch(badge, .5, {scale = .45}, {vibrato = 10}, "land-=.3")
    tl:to(counter, .7, {shown = counter.total}, "land-=.3"):ease("out_quart")
    tl:shake(badge, .45, {pos = vec2(14, 14)}, nil, "land+=.25")
end

local function frame()
    local screen = app.screen()
    gfx.rect_grad(screen, color.hex(0x12393B), color.hex(0x0E2B2E))
    for i, bar in ipairs(bars) do
        local r = rect(bar.x, bar.y, 560, 62)
        gfx.round_rect(r, 10, color(242, 210, 140, math.floor(255 * bar.alpha)))
        text.draw(label, r:point(vec2(0, .5)) + vec2(18, 0), vec2(0, .5), "ease." .. names[i])
    end
    local s = 150 * badge.scale
    gfx.round_rect(rect(badge.pos.x - s / 2, badge.pos.y - s / 2, s, s), 18, color.hex(0xD6AA5C))
    text.draw(big, badge.pos, vec2(.5, .5), "!")
    local box = rect(760, 120, 340, 64)
    gfx.round_rect(box, 10, color.hex(0x1F4E4C))
    gfx.round_rect(rect(box.x, box.y, box.w * counter.shown / counter.total, box.h), 10, color.hex(0xE4C080))
    text.draw(big, box:center(), vec2(.5, .5), tostring(math.floor(counter.shown + .5)))
end

return {title = "motion", id = "motion-fixture", design = size2(1200, 900), landscape = true,
        clear = color(14, 43, 46), init = init, frame = frame}
