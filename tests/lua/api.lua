-- The generated Lua API: value types, operators, methods, in/out arguments,
-- handles. Runs without a window (nothing here draws).
local failures, checks = 0, 0
local function check(cond, what)
    checks = checks + 1
    if not cond then failures = failures + 1; print("FAIL " .. what) end
end
local function near(a, b, what) check(math.abs(a - b) < 1e-3, what .. (" (%s vs %s)"):format(a, b)) end

-- vec2
local a = vec2(3, 4)
near(a:len(), 5, "vec2 len")
near((a + vec2(1, 1)).x, 4, "vec2 add operator")
near((a - vec2(1, 1)).y, 3, "vec2 sub operator")
near((-a).x, -3, "vec2 unary minus")
near(a:scale(2).y, 8, "vec2 scale")
near(vec2.dot(a, a), 25, "module call form")
check(tostring(vec2(1, 2)) == "vec2(1.0, 2.0)" or tostring(vec2(1, 2)) == "vec2(1, 2)", "tostring " .. tostring(vec2(1, 2)))
check(getmetatable(vec2{x = 1, y = 2}) == getmetatable(a), "table form constructor")
near(vec2().x, 0, "zero default")

-- rect and RectCut
local r = rect(0, 0, 400, 300)
local top = r:cut_top(60)
local side = rect.cut_right(r, 100)
near(top.h, 60, "cut_top slice")
near(side.x, 300, "cut_right slice")
near(r.y, 60, "cut mutates y")
near(r.w, 300, "cut mutates w")
near(r.h, 240, "cut mutates h")
check(r:contains(vec2(10, 70)) and not r:contains(vec2(10, 10)), "contains")
near(rect.col(rect(0, 0, 100, 10), 4, 3, 4).x, 3 * 26, "col")
near(r:center().x, 150, "center")

-- color and purse
local c = color.hex(0xFF8000)
check(c.r == 255 and c.g == 128 and c.b == 0 and c.a == 255, "hex")
check(color(1, 2, 3).a == 255, "default alpha")
check(color.alpha(c, .5).a == 127, "alpha")
local wallet = purse(60, 10, 5)
local cost = purse(20, 5)
check(purse.covers(wallet, cost) and not purse.covers(cost, wallet), "covers")
local left = wallet - cost
check(left[1] == 40 and left[2] == 5 and left[3] == 5 and left[6] == 0, "purse sub")
check((left + purse(1))[1] == 41, "purse add")
check(#(wallet + cost) == purse.MAX, "purse length")

-- camera
local cam = camera{center = vec2(0, 0), zoom = 1, view = rect(0, 0, 200, 100), world = size2(1000, 1000), min_zoom = .5, max_zoom = 2, cover = true}
cam = cam:clamp()
near(cam.center.x, 100, "clamp cover x")
near(cam:to_screen(cam.center).x, 100, "to_screen")
near(cam:to_world(vec2(100, 50)).y, cam.center.y, "to_world")

-- styles keep every field a zero default
local s = style{size = 20}
near(s:sized(30).size, 30, "style sized")
check(s:filled(color.hex(0x112233)).fill.b == 0x33, "style filled")

-- saves: the same visitor reads and writes
local state = {coins = 7, wallet = {1, 2, 3}, pos = vec2(1.5, 2.5)}
local function serialize(sv)
    state.coins = sv:int("coins", state.coins)
    state.wallet = sv:ints("wallet", state.wallet)
    state.pos = sv:vec2("pos", state.pos)
end
check(save.write("lua-slot", serialize), "save write")
state = {coins = 0, wallet = {0, 0, 0}, pos = vec2(0, 0)}
check(save.read("lua-slot", serialize), "save read")
check(state.coins == 7 and state.wallet[2] == 2 and state.pos.y == 2.5, "save round trip")
check(not save.read("no-such-slot", serialize), "missing save")

-- city handle: fields, arrays, callbacks and out arguments
local c2 = city.new()
c2.defs = {{name = "hut", cost = purse(10)}, {name = "well", cost = purse(20), footprint = size2(30, 15)}}
c2.spacing = 100
c2.zones = {{area = rect(0, 0, 500, 500)}, {area = rect(500, 0, 500, 500), cost = purse(5)}}
local calls = 0
c2.buildable = function(self, p) calls = calls + 1; return p.y > 100 end
c2.cam = camera{world = size2(1000, 1000), view = rect(0, 0, 1000, 1000), zoom = 1}
c2:init()
check(#c2.defs == 2 and c2.defs[2].name == "well" and c2.zone_count == 2, "city arrays")
check(c2.open == 1 and c2.selected == -1, "city defaults")
check(c2:can_place(vec2(200, 200), 0) and not c2:can_place(vec2(200, 50), 0), "buildable callback")
check(calls > 0, "callback called")
local ok, spot = c2:find_spot(0, vec2(200, 200))
check(ok and spot.y > 100, "out argument")
check(c2:add(vec2(200, 200), 0) == 0 and c2.count == 1 and c2.items[1].pos.x == 200, "add and items")
local w = purse(100)
check(c2:unlock(1, w) and w[6] == 0 and w[1] == 95, "unlock pays from the wallet in place")
c2:begin_place(1, vec2(700, 300))
local ev = c2:confirm(w, 0)
check(ev.result == city.BUILT and c2.count == 2 and w[1] == 75, "placement session")
local ok2 = pcall(function() return c2.no_such_field end)
check(not ok2, "unknown field errors")

-- story: play once per save
story.setup({{id = "ann", name = "Ann"}, {id = "bob", name = "Bob", right = true}}, story_style{})
check(story.character("bob").right and not story.character("eve") and not story.active(), "cast")
check(story.play("lua-hello", {{"ann", "Hello."}, {who = "bob", text = "Hi.", kind = story.SHOUT}}) and story.active(), "play")
check(not story.play("lua-hello", {{"ann", "Hello."}}), "beat plays once")
story.next(); story.next()
check(not story.active(), "lines consumed")

print(("lua api: %d checks, %d failures"):format(checks, failures))
return failures
