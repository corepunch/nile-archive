-- luacheck: globals testing

local desc = require("games/" .. testing.game .. "/lua/main")
local R = require("state")
local draw, background = R.board_screen, R.draw_board_background
local open_dialog = R.open_dialog
local frame = desc.frame
local win = app.arg("victory") ~= nil
local action = win and "claim" or "retry"
local form = win and R.result_form or R.failed_form
local stage, frames, faded, closing = 0, 0, false, false
local pressed, ready_at
local board, cover

-- Keep the live game's fully populated card in the capture.
function R.open_dialog(...)
    open_dialog(...)
    R.dialog.settled = true
end

function R.board_screen(...)
    board = true
    draw(...)
end

function R.draw_board_background(opacity)
    cover = opacity
    background(opacity)
end

function desc.frame(dt)
    board, cover = false, 0
    frame(dt)
    frames = frames + 1
    local outcome = win and R.OV_RESULT or R.OV_FAILED
    local d = R.dialog
    if R.overlay == outcome then
        if cover > 0 and cover < 1 then faded = true end
        if R.modal_for ~= outcome then
            assert(board, "the board stays visible during its fade")
        else
            assert(faded and not board and cover == 1, "the board finishes fading before the popup paints")
            local at = form.boxes[action]:center() + vec2(0, R.drop / 2)
            if stage == 0 and d.entry < .5 then
                app.inject_press(at)
                pressed, stage = at, 1
            elseif stage == 1 and d.entry == 1 then
                app.inject_release(pressed)
                stage = 2
            elseif stage == 2 and d.ready then
                assert(not d.after_exit, "an entrance press cannot activate the popup")
                ready_at = ready_at or frames
                if frames - ready_at >= 18 then
                    app.inject_click(at)
                    stage = 3
                end
            end
            if d.exit > 0 then
                closing = true
                assert(R.prog.level == 0, "the level advances after the popup closes")
            end
        end
    elseif stage == 3 then
        assert(closing, "the popup fades out before leaving the result")
        if win then assert(R.on_island and R.prog.level == 1, "Collect advances to town")
        else assert(not R.on_island and not R.g.lost, "Retry starts a fresh board") end
        stage = 4
    end
    if frames == 85 then assert(stage == 4, "the complete level-end transition fits in the reel") end
end

return desc
