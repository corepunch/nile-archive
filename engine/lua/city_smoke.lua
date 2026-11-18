-- Engine-owned smoke test for the deliberate city pickup (AGENTS.md): a
-- stationary half-second hold lifts a placed building, an ordinary drag pans
-- even when it starts over one, release only snaps a preview, Cancel keeps
-- the original position and wallet, Confirm moves it for free. Every movable
-- city game drives this through real press/move/release events from its
-- --smoke run, so the contract is checked once and the games only say how
-- to aim the camera and press their own sheet's buttons.
--
-- local move = city.move_test(c, {
--     look = function(at) ... end,             -- aim the camera at a world point
--     wallet = function() return coins end,    -- the amount that must not change
--     cancel = function() ... end,             -- press the sheet's Cancel
--     confirm = function() ... end,            -- press the sheet's Confirm
--     offset = vec2(200, 0),                   -- where to drop the building (optional)
-- })
-- Call move() once per smoke tick while it returns true; it asserts what it
-- expects and returns false once Confirm has moved the first building.
function city.move_test(c, opts)
    local offset = opts.offset or vec2(200, 0)
    local stage, pass = 0, 1   -- pass 1 cancels the move, pass 2 confirms it
    local origin, money, cam_x, press, grab, hold, destination, drop

    -- look at the first building and find a point on its sprite to press
    local function aim()
        opts.look(origin)
        press = c.cam:rect_to_screen(c:sprite_rect(c.items[1])):point(vec2(.5, .65))
    end

    return function()
        if stage == 0 then          -- an ordinary drag pans, even from a building
            origin, money = c.items[1].pos, opts.wallet()
            aim()
            cam_x = c.cam.center.x
            app.inject_press(press)
            stage = 1
        elseif stage == 1 then
            app.inject_move(press + vec2(-40, 0))
            stage = 2
        elseif stage == 2 then
            assert(c.placing < 0 and c.cam.center.x > cam_x, "ordinary building drag must pan")
            app.inject_release(press + vec2(-40, 0))
            stage = 3
        elseif stage == 3 then      -- a stationary hold lifts the building
            aim()
            grab = origin - c.cam:to_world(press)
            app.inject_press(press)
            hold = app.time()
            stage = 4
        elseif stage == 4 then
            if app.time() - hold <= .65 then return true end
            assert(c.moving == 0 and c.held, "long press must lift the building")
            local ok, spot = c:find_spot(c.placing, origin + offset)
            assert(ok, "no move destination")
            destination, drop = spot, c.cam:to_screen(spot - grab)
            app.inject_move(drop)
            stage = 5
        elseif stage == 5 then
            app.inject_release(drop)
            stage = 6
        elseif stage == 6 then      -- release leaves an uncommitted preview
            assert(not c.held and c.placing >= 0 and c.items[1].pos:dist(origin) < .01 and opts.wallet() == money,
                   "release must leave an uncommitted preview")
            if pass == 1 then opts.cancel() else opts.confirm() end
            stage = 7
        elseif stage == 7 then
            assert(c.placing < 0 and opts.wallet() == money, "move must finish without spending")
            if pass == 1 then
                assert(c.items[1].pos:dist(origin) < .01, "cancel moved the building")
                pass, stage = 2, 3
            else
                assert(c.items[1].pos:dist(destination) < .01, "confirm did not move the building")
                return false
            end
        end
        return true
    end
end
