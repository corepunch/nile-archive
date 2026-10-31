-- The motion module (engine/tween.lua): the easing catalogue, tweens as a
-- function of their playhead, overwrite, loops, timelines and their positions,
-- staggers, punch, shake, groups and the test reset. Runs without a window.
local suite = require("support").suite("tween")

local function step(n, dt)
    for _ = 1, n do tween.update(dt) end
end

-- easing ------------------------------------------------------------------
suite:case("every curve starts at 0 and ends at 1", function()
    local names = {}
    for name, f in pairs(ease) do if type(f) == "function" and name ~= "get" then names[#names + 1] = name end end
    table.sort(names)
    suite:check(#names == 34, "30 family curves, linear, none, steps and in_out: " .. #names)
    for _, name in ipairs(names) do
        local f = ease[name]
        suite:check(math.abs(f(0)) < 1e-6, name .. " starts at 0")
        suite:check(math.abs(f(1) - 1) < 1e-6, name .. " ends at 1")
        suite:check(f(-1) == f(0) and f(2) == f(1), name .. " clamps t")
    end
end)

suite:case("the historic curves keep their values", function()
    near(ease.out_cubic(.25), 1 - .75 ^ 3, "out_cubic")
    near(ease.in_cubic(.5), .125, "in_cubic")
    near(ease.in_out(.25), 4 * .25 ^ 3, "in_out is cubic in-out")
    near(ease.in_out(.75), 1 - (-2 * .75 + 2) ^ 3 / 2, "in_out upper half")
    local c1, c3 = 1.70158, 2.70158
    near(ease.out_back(.5), 1 + c3 * (-.5) ^ 3 + c1 * .25, "out_back overshoots as before")
    near(ease.out_bounce(.5), 7.5625 * (.5 - 1.5 / 2.75) ^ 2 + .75, "out_bounce")
    near(ease.in_out_cubic(.25), ease.in_out(.25), "in_out_cubic is the same curve")
    suite:check(ease.in_back(1) == 1 and ease.out_back(0) == 0 and ease.in_out_back(1) == 1, "back's ends are exact, not rounding noise")
    local stars = {{s = 0}, {s = 0}}
    tween.to(stars, .3, {s = 1}):ease("out_back"):stagger(.2)
    tween.update(.1)
    suite:check(stars[1].s > 0 and stars[2].s == 0, "a target waiting for its stagger sits exactly at its start")
    testing.reset()
end)

suite:case("families derive out and in-out from in", function()
    for _, fam in ipairs({"sine", "quad", "cubic", "quart", "quint", "expo", "circ", "back", "elastic"}) do
        local fin, fout, finout = ease["in_" .. fam], ease["out_" .. fam], ease["in_out_" .. fam]
        near(fout(.3), 1 - fin(.7), fam .. " out mirrors in")
        near(finout(.25), fin(.5) / 2, fam .. " in-out lower half")
        near(finout(.75), 1 - fin(.5) / 2, fam .. " in-out upper half")
        near(finout(.5), .5, fam .. " in-out passes the middle")
    end
    near(ease.in_quad(.5), .25, "quad")
    near(ease.out_sine(.5), math.sin(math.pi / 4), "sine")
    near(ease.in_expo(.5), 2 ^ -5, "expo")
    near(ease.in_bounce(.2), 1 - ease.out_bounce(.8), "bounce in mirrors out")
    suite:check(ease.out_back(.5, 3) > ease.out_back(.5), "a bigger overshoot goes further")
    suite:check(ease.out_elastic(.1) > 1, "elastic overshoots")
    near(ease.out_elastic(.5, 1, .3), ease.out_elastic(.5), "elastic defaults")
end)

suite:case("steps hold and get resolves names", function()
    near(ease.steps(.1, 4), 0, "first step")
    near(ease.steps(.3, 4), .25, "second step")
    near(ease.steps(1, 4), 1, "last step")
    near(ease.linear(.3), .3, "linear")
    suite:check(ease.get() == ease.out_cubic, "the default is out_cubic")
    suite:check(ease.get("out_back") == ease.out_back, "a name")
    suite:check(ease.get(ease.linear) == ease.linear, "a function")
    suite:check(not pcall(ease.get, "wobble"), "an unknown name is an error")
end)

-- tweens -------------------------------------------------------------------
suite:case("a tween eases a field and finishes exact", function()
    testing.reset()
    local card = {x = 0}
    local t = tween.to(card, 1, {x = 100})
    suite:check(tween.count() == 1 and t:is_active(), "one live tween")
    tween.update(.25)
    near(card.x, 100 * ease.out_cubic(.25), "default out_cubic at a quarter")
    tween.update(.25)
    near(card.x, 100 * ease.out_cubic(.5), "halfway")
    near(t:progress(), .5, "progress reads the playhead")
    tween.update(10)
    suite:check(card.x == 100, "the goal is exact, not a rounded sum")
    suite:check(t:is_done() and tween.count() == 0, "finished tweens leave the group")
end)

suite:case("settings chain, and the options table is the same thing", function()
    testing.reset()
    local a, b = {x = 0}, {x = 0}
    local started, done = 0, 0
    tween.to(a, 1, {x = 10}):ease("linear"):delay(.5):on_start(function() started = started + 1 end):on_complete(function() done = done + 1 end)
    tween.to(b, 1, {x = 10}, {ease = "linear", delay = .5, on_start = function() started = started + 1 end, on_complete = function() done = done + 1 end})
    tween.update(.25)
    suite:check(a.x == 0 and b.x == 0 and started == 0, "nothing happens during the delay")
    tween.update(.5)
    near(a.x, 2.5, "delay then linear"); near(b.x, 2.5, "same through options")
    suite:check(started == 2 and done == 0, "started once each")
    tween.update(1)
    suite:check(done == 2 and a.x == 10 and b.x == 10, "completed once each")
    suite:check(not pcall(tween.to, a, 1, {x = 1}, {wobble = 1}), "an unknown option is an error")
    suite:check(not pcall(tween.to, a, -1, {x = 1}), "a negative duration is an error")
    suite:check(not pcall(function() tween.to(a, 1, {missing = 1}); tween.update(0) end), "a missing field is an error")
end)

suite:case("value tables tween component-wise and keep their type", function()
    testing.reset()
    local sprite = {pos = vec2(0, 0), tint = color(0, 0, 0, 255), box = rect(0, 0, 10, 10)}
    tween.to(sprite, 1, {pos = vec2(100, 50), tint = color(255, 0, 0, 255), box = rect(0, 0, 20, 10)}):ease("linear")
    tween.update(.5)
    near(sprite.pos.x, 50, "vec2 x"); near(sprite.pos.y, 25, "vec2 y")
    suite:check(getmetatable(sprite.pos) == getmetatable(vec2()), "still a vec2")
    near(sprite.pos:len(), math.sqrt(50 * 50 + 25 * 25), "vec2 methods work mid-tween")
    near(sprite.tint.r, 127.5, "color r"); near(sprite.box.w, 15, "rect w")
    tween.update(.5)
    suite:check(sprite.pos.x == 100 and sprite.tint.r == 255 and sprite.box.w == 20, "exact at the end")
end)

suite:case("from, relative and set", function()
    testing.reset()
    local card = {x = 50, y = 5}
    tween.from(card, 1, {x = 0}):ease("linear")
    suite:check(card.x == 0, "from jumps to the start value at once")
    tween.update(.5)
    near(card.x, 25, "from tweens to where the field was")
    tween.update(.5)
    suite:check(card.x == 50, "ends at the original value")
    tween.to(card, 1, {x = 10, y = -5}):relative():ease("linear")
    tween.update(.5)
    near(card.x, 55, "relative x"); near(card.y, 2.5, "relative y")
    tween.update(.5)
    tween.set(card, {x = 1})
    suite:check(card.x == 1 and tween.count() == 0, "set writes now without a live tween")
    local a = {x = 0}
    tween.to(a, 1, {x = 10}):ease("linear"):from({x = 100})
    suite:check(a.x == 100, "from as a modifier writes the start now")
    tween.update(.5)
    near(a.x, 55, "and tweens from it")
end)

suite:case("function values are read per target when the tween starts", function()
    testing.reset()
    local cards = {{x = 0}, {x = 0}, {x = 0}}
    tween.to(cards, 1, {x = function(i) return i * 10 end}):ease("linear")
    tween.update(1)
    suite:check(cards[1].x == 10 and cards[2].x == 20 and cards[3].x == 30, "each target has its own goal")
end)

suite:case("a newer tween takes over the fields it touches", function()
    testing.reset()
    local card = {x = 0, y = 0}
    local first = tween.to(card, 1, {x = 100, y = 100}):ease("linear")
    tween.update(.5)
    local second = tween.to(card, 1, {x = 0}):ease("linear")
    tween.update(.25)
    near(card.x, 50 - 12.5, "x now belongs to the second tween")
    near(card.y, 75, "y still belongs to the first")
    tween.update(.25)
    suite:check(card.y == 100, "the first still completes its own field")
    tween.update(.5)
    suite:check(card.x == 0 and second:is_done() and first:is_done(), "both finish")
    local p = {x = 0}
    tween.to(p, 1, {x = 10}):ease("linear")
    tween.to(p, 1, {x = 10}):delay(1):ease("linear")
    tween.update(.5)
    near(p.x, 5, "a delayed tween does not take fields before it starts")
end)

suite:case("loops restart, yoyo and increment", function()
    testing.reset()
    local a, b, c = {x = 0}, {x = 0}, {x = 0}
    local loops = {}
    tween.to(a, 1, {x = 10}):ease("linear"):loops(2):on_loop(function(_, i) loops[#loops + 1] = i end)
    tween.to(b, 1, {x = 10}):ease("linear"):loops(1, "yoyo")
    tween.to(c, 1, {x = 10}):ease("linear"):loops(2, "incremental")
    tween.update(1.5)
    near(a.x, 5, "second play of a restart loop"); near(b.x, 5, "yoyo comes back"); near(c.x, 15, "incremental keeps adding")
    suite:check(#loops == 1 and loops[1] == 1, "on_loop fired once with the iteration")
    tween.update(.5)
    suite:check(b.x == 0 and tween.count() == 2, "yoyo ends where it began")
    tween.update(1)
    suite:check(a.x == 10 and tween.count() == 0, "restart ends at the goal")
    near(c.x, 30, "incremental ends three goals on")
    local f = {x = 0}
    local t = tween.to(f, 1, {x = 1}):ease("linear"):loops(-1, "yoyo")
    step(10, .3)
    suite:check(t:is_active() and f.x > 0 and f.x <= 1, "forever is still going")
    suite:check(t:total() == math.huge and t:progress() <= 1, "an infinite tween has a finite progress")
end)

suite:case("controls are seeks: pause, seek, progress, reverse, restart, complete, kill", function()
    testing.reset()
    local card = {x = 0}
    local reversed = 0
    local t = tween.to(card, 1, {x = 100}):ease("linear"):on_reverse_complete(function() reversed = reversed + 1 end)
    tween.update(.25)
    t:pause()
    tween.update(.25)
    near(card.x, 25, "paused holds")
    t:resume():seek(.75)
    near(card.x, 75, "seek renders at once")
    t:progress(.5)
    near(card.x, 50, "progress seeks a fraction")
    t:reverse()
    tween.update(.25)
    near(card.x, 25, "reverse runs the playhead back")
    tween.update(.5)
    suite:check(card.x == 0 and reversed == 1 and tween.count() == 0, "reaching the start completes in reverse")
    t:restart()
    tween.update(.5)
    near(card.x, 50, "restart wakes it from the start")
    t:complete()
    suite:check(card.x == 100 and t:is_done(), "complete jumps to the end")
    local k = tween.to(card, 1, {x = 0}):ease("linear")
    tween.update(.5)
    k:kill()
    tween.update(.5)
    near(card.x, 50, "a killed tween leaves the value where it was")
    suite:check(tween.count() == 0, "and leaves the group")
    local pausedtl = tween.to(card, 1, {x = 0}):pause()
    tween.update(1)
    near(card.x, 50, "a tween created paused waits")
    suite:check(tween.count() == 1 and not pausedtl:is_active(), "but stays in the group")
end)

suite:case("time scale on a tween and on the group", function()
    testing.reset()
    local a, b = {x = 0}, {x = 0}
    tween.to(a, 1, {x = 10}):ease("linear"):time_scale(2)
    tween.to(b, 1, {x = 10}):ease("linear")
    tween.update(.25)
    near(a.x, 5, "a fast tween"); near(b.x, 2.5, "a normal one")
    tween.time_scale(.5)
    tween.update(.5)
    near(a.x, 10, "group scale slows the fast one"); near(b.x, 5, "and the normal one")
    suite:check(tween.time_scale() == .5, "reads back")
    tween.time_scale(1)
    tween.pause()
    tween.update(1)
    near(b.x, 5, "a paused group holds")
    tween.play()
end)

suite:case("after chains tweens, value tweens a number, instant finishes at once", function()
    testing.reset()
    local card = {x = 0, y = 0}
    tween.to(card, 1, {x = 10}):ease("linear"):after(1, {y = 10}):ease("linear"):after({x = 0}, 1, {})
    tween.update(.5)
    suite:check(card.y == 0, "the chained tween waits")
    tween.update(.5)
    tween.update(.5)
    near(card.y, 5, "then runs on its own target")
    local seen = {}
    tween.value(0, 10, 1, function(v) seen[#seen + 1] = v end):ease("linear")
    tween.update(.5); tween.update(.5)
    near(seen[1], 5, "value hands each step over"); near(seen[#seen], 10, "to the end")
    tween.instant(true)
    local z, done = {x = 0}, false
    tween.to(z, 5, {x = 1}):delay(3):on_complete(function() done = true end)
    tween.update(.016)
    suite:check(z.x == 1 and done and tween.count() == 0, "instant completes on the first update, callbacks included")
    tween.instant(false)
end)

-- timelines ------------------------------------------------------------------
suite:case("a timeline runs children in sequence with GSAP positions", function()
    testing.reset()
    local card = {x = 0, y = 0, a = 0}
    local calls = {}
    local tl = tween.timeline{defaults = {ease = "linear"}}
    tl:to(card, 1, {x = 10})
    tl:to(card, 1, {y = 10}, "<")               -- with the first
    tl:to(card, 1, {a = 1}, "+=.5")              -- half a second after the end
    tl:call(function() calls[#calls + 1] = "mid" end, 1.25)
    tl:label("tail"):wait(.5)
    tl:to(card, 1, {x = 0}, "tail+=.5")
    near(tl:total(), 4, "the timeline spans its children: 1 + .5 + 1 + .5 + 1")
    tween.update(.5)
    near(card.x, 5, "first"); near(card.y, 5, "joined with <"); near(card.a, 0, "not yet")
    suite:check(#calls == 0, "call waits for its position")
    tween.update(1)
    suite:check(card.x == 10 and card.y == 10, "sequence done")
    suite:check(#calls == 1, "call fired once")
    tween.update(.5)
    near(card.a, .5, "+= offset placed the third")
    tween.update(1)
    near(card.x, 10, "the label and wait hold the last")
    tween.update(.5)
    near(card.x, 5, "label+=offset placed the last")
    tween.update(.5)
    suite:check(card.x == 0 and tween.count() == 0, "the timeline finishes and leaves")
    suite:check(#calls == 1, "the call did not repeat")
end)

suite:case("timeline children are returned, chain their own settings and overwrite only across roots", function()
    testing.reset()
    local card = {x = 0}
    local tl = tween.timeline()
    local child = tl:to(card, 1, {x = 10}):ease("linear"):delay(.5)
    suite:check(getmetatable(child) ~= getmetatable(tl), "to returns the child")
    tl:to(card, 1, {x = 0}):ease("linear")
    near(tl:total(), 2.5, "the child's delay counts")
    tween.update(1)
    near(card.x, 5, "delayed child")
    tween.update(1)
    near(card.x, 5, "the second child owns x after the first ended")
    tween.update(.5)
    suite:check(card.x == 0, "sequential children on one field work")
    tl:restart()
    tween.update(1.5)
    suite:check(card.x == 10, "restart renders the first child again: siblings never overwrote each other")
    local other = tween.to(card, 1, {x = 50}):ease("linear")
    tween.update(.5)
    near(card.x, 30, "a new root takes the field from the timeline's children")
    suite:check(other:is_active(), "and runs")
end)

suite:case("a timeline loops, reverses and seeks like a tween", function()
    testing.reset()
    local card = {x = 0, y = 0}
    local tl = tween.timeline{loops = {1, "yoyo"}, defaults = {ease = "linear"}}
    tl:to(card, 1, {x = 10})
    tl:to(card, 1, {y = 10})
    tween.update(3)
    near(card.x, 10, "yoyo half way back"); near(card.y, 0, "second child undone")
    tween.update(1)
    suite:check(card.x == 0 and tween.count() == 0, "yoyo returned to the start")
    tl:progress(.25)
    near(card.x, 10, "progress over the whole timeline")
    tl:seek(.5)
    near(card.x, 5, "seek")
    tl:pause()
    local paused = tween.timeline{paused = true}
    paused:to(card, 1, {x = 100})
    tween.update(1)
    near(card.x, 5, "a paused timeline waits")
    paused:play()
    tween.update(1)
    suite:check(card.x == 100, "until played")
end)

suite:case("a timeline nests timelines and tweens made elsewhere", function()
    testing.reset()
    local card = {x = 0, y = 0}
    local inner = tween.timeline()
    inner:to(card, 1, {y = 10}):ease("linear")
    local solo = tween.to(card, 1, {x = 10}):ease("linear")
    local outer = tween.timeline()
    outer:add(solo)
    outer:add(inner, ">")
    suite:check(tween.count() == 1, "adding moves clips out of the group")
    tween.update(1.5)
    near(card.x, 10, "first the tween"); near(card.y, 5, "then the inner timeline")
    suite:check(not pcall(outer.add, outer, solo), "a clip cannot be in two timelines")
end)

-- staggers, punch, shake ------------------------------------------------------
suite:case("a stagger offsets each target", function()
    testing.reset()
    local cards = {{x = 0}, {x = 0}, {x = 0}}
    local t = tween.to(cards, 1, {x = 10}):ease("linear"):stagger(.5)
    near(t:total(), 2, "the tween lasts until the last target ends")
    tween.update(1)
    near(cards[1].x, 10, "first done"); near(cards[2].x, 5, "second half way"); near(cards[3].x, 0, "third waiting")
    tween.update(1)
    suite:check(cards[3].x == 10, "all done")
    local more = {{x = 0}, {x = 0}, {x = 0}, {x = 0}, {x = 0}}
    local c = tween.to(more, 1, {x = 10}):ease("linear"):stagger{amount = 1, from = "center"}
    tween.update(.5)
    near(more[3].x, 5, "the centre starts first")
    near(more[1].x, 0, "the edges last")
    near(more[5].x, 0, "both edges")
    near(c:total(), 2, "amount spreads the starts over one second")
    local e = tween.to({{x = 0}, {x = 0}}, 1, {x = 1}):stagger{each = .25, from = "end"}
    near(e.offsets[1], .25, "from end starts the last first")
end)

suite:case("punch springs away and settles back exactly", function()
    testing.reset()
    local card = {scale = 1, pos = vec2(10, 10)}
    local t = tween.punch(card, .5, {scale = .3, pos = vec2(0, -20)}, {vibrato = 8, elasticity = 1})
    tween.update(.03)
    suite:check(card.scale > 1 and card.pos.y < 10, "the punch starts towards the strength")
    local peak = card.scale
    local under = false
    for _ = 1, 14 do
        tween.update(.03)
        if card.scale < 1 then under = true end
        peak = math.max(peak, card.scale)
    end
    suite:check(peak <= 1.3 + 1e-6 and under, "it swings under the start on the way back")
    tween.update(1)
    suite:check(card.scale == 1 and card.pos.x == 10 and card.pos.y == 10, "and settles exactly where it began")
    suite:check(t:is_done(), "done")
    local stiff = {scale = 1}
    tween.punch(stiff, .5, {scale = .3}, {vibrato = 8, elasticity = 0})
    local dipped = false
    for _ = 1, 16 do tween.update(.03); if stiff.scale < 1 - 1e-6 then dipped = true end end
    suite:check(not dipped, "with no elasticity it never goes under")
end)

suite:case("shake jitters, tapers and settles exactly", function()
    testing.reset()
    local cam = {pos = vec2(100, 100), angle = 0}
    tween.shake(cam, .5, {pos = vec2(8, 8), angle = 1}, {vibrato = 20, randomness = 90})
    local early, late = 0, 0
    for i = 1, 16 do
        tween.update(.03)
        local d = cam.pos:dist(vec2(100, 100))
        if i <= 4 then early = math.max(early, d) elseif i >= 13 then late = math.max(late, d) end
        suite:check(d <= 8 * math.sqrt(2) + 1e-6 and math.abs(cam.angle) <= 1 + 1e-6, "within strength")
    end
    suite:check(early > 0 and late < early, "fade out tapers the shake")
    tween.update(1)
    suite:check(cam.pos.x == 100 and cam.pos.y == 100 and cam.angle == 0, "settles exactly")
    local g = tween.group()
    local a, b = {x = 0}, {x = 0}
    g:shake(a, .5, {x = 5}); local ga = {}
    for i = 1, 5 do g:update(.05); ga[i] = a.x end
    local g2 = tween.group()
    g2:shake(b, .5, {x = 5})
    for i = 1, 5 do g2:update(.05); suite:check(b.x == ga[i], "a shake is deterministic per group") end
end)

-- groups, queries and reset --------------------------------------------------
suite:case("groups are independent, queries find tweens, kill drops fields", function()
    testing.reset()
    local g = tween.group()
    local a, b = {x = 0, y = 0}, {x = 0}
    g:to(a, 1, {x = 10}):ease("linear")
    tween.to(b, 1, {x = 10}):ease("linear")
    tween.update(.5)
    suite:check(a.x == 0 and b.x == 5, "the engine's update does not tick a game's group")
    g:update(.5)
    near(a.x, 5, "the group ticks on its own")
    suite:check(g:is_tweening(a) and not tween.is_tweening(a) and tween.is_tweening(b), "of and is_tweening look in one group")
    local tl = tween.timeline()
    tl:to(a, 1, {y = 10})
    suite:check(#tween.of(a) == 1, "of looks inside timelines")
    tween.kill(a)
    suite:check(#tween.of(a) == 0, "kill by target")
    local c = {x = 0, y = 0}
    tween.to(c, 1, {x = 10, y = 10}):ease("linear")
    tween.update(.5)
    tween.kill(c, "x")
    tween.update(.5)
    suite:check(c.x == 5 and c.y == 10, "kill by field drops only that field")
    tween.to(c, 1, {x = 0}); tween.to(b, 1, {x = 0})
    tween.kill_all()
    tween.update(1)
    suite:check(c.x == 5 and tween.count() == 0, "kill_all empties the group")
    suite:check(not pcall(tween.update, -1), "a negative dt is an error")
end)

suite:case("testing.reset clears the default group", function()
    local card = {x = 0}
    tween.to(card, 1, {x = 10})
    tween.time_scale(3)
    tween.instant(true)
    testing.reset()
    suite:check(tween.count() == 0 and tween.time_scale() == 1 and not tween.instant(), "fresh group")
    tween.update(1)
    suite:check(card.x == 0, "the old tween is gone")
    suite:check(pcall(tween.update), "update without an argument takes the frame's dt")
end)

return suite:finish()
