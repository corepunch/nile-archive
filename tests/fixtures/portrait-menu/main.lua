-- luacheck: globals testing
local desc = require("games/" .. testing.game .. "/lua/main")
local R = require("state")
local init = desc.init
local stage, frames, game = 0, 0
local returning = app.arg("returning") ~= nil
local completed = app.arg("returning") == "result"

function desc.init()
    -- The runner isolates saves with --fresh. Exercise the normal launch path
    -- with a profile that has only opened level one, or with no profile.
    local arg, read, write = app.arg, save.read, save.write
    local wrote_profile = false
    rawset(app, "arg", function(key)
        if key ~= "smoke" and key ~= "fresh" then return arg(key) end
    end)
    rawset(save, "read", function(slot)
        if slot ~= "progress" or not returning then return false end
        if completed then
            R.prog.completed = {level=0, rng=782341, moves=3, score=1200, earnings={40,0,0}}
            R.prog.story_recap = true
        end
        return true
    end)
    rawset(save, "write", function(slot) wrote_profile = wrote_profile or slot == "progress" end)
    init()
    rawset(app, "arg", arg)
    rawset(save, "read", read)
    rawset(save, "write", write)
    R.test_mode = true
    assert(R.on_menu == returning and wrote_profile ~= returning, "only the first launch creates a profile and bypasses the menu")
    assert(not R.on_island and R.g.level == 0, "level one must be the first screen in the campaign")
    assert(R.overlay == R.OV_NONE and R.g.won == completed, "a saved result must wait behind the menu")
    game = R.g
end

local function click(form, id, modal)
    app.inject_click(form.boxes[id]:center() + vec2(0, modal and R.drop / 2 or 0))
end

function R.smoke()
    frames = frames + 1
    assert(frames < 900, "portrait menu timed out at step " .. stage)
    if R.diving() then return end
    assert(not story.active() and not R.story_current, "the campaign must never interrupt play with dialogue")
    local menu = R.menu.form
    if stage == 0 then
        if returning then
            if not menu.boxes.settings then return end
            click(menu, "settings")
            stage = 1
        else
            stage = 4
        end
    elseif stage == 1 and R.overlay == R.OV_PAUSE and R.dialog_settled() then
        assert(not R.pause_form.values.expedition and not R.pause_form.values.in_game, "title settings carry no board actions")
        click(R.pause_form, "motion", true)
        stage = 2
    elseif stage == 2 and R.reduced_motion then
        click(R.pause_form, "resume", true)
        stage = 3
    elseif stage == 3 and R.overlay == R.OV_NONE then
        assert(R.on_menu, "closing title settings must return to the title")
        click(menu, "continue")
        stage = 4
    elseif stage == 4 and not R.on_menu then
        if completed then
            assert(R.overlay == R.OV_RESULT and R.g == game and R.g.earnings[1] == 40, "Continue must restore unclaimed rewards")
            app.quit()
            return
        end
        if R.mission_banner or R.phase == R.PH_PRESENT then app.inject_click(app.screen():center()); return end
        assert(not R.on_island and R.g == game and R.g.level == 0, "the campaign resumes on level one")
        app.inject_click(R.board_pause:center())
        stage = 5
    elseif stage == 5 and R.overlay == R.OV_PAUSE and R.dialog_settled() then
        assert(R.pause_form.values.expedition and R.pause_form.values.in_game, "board settings must offer Main Menu")
        click(R.pause_form, "menu", true)
        stage = 6
    elseif stage == 6 and R.on_menu and menu.boxes.continue then
        click(menu, "continue")
        stage = 7
    elseif stage == 7 and not R.on_menu then
        assert(not R.on_island and R.g == game, "leaving for the title must keep the active board")
        if returning then app.quit(); return end
        R.quiet = true
        assert(R.debug_skip_level(), "complete the opening board to reach town")
        stage = 8
    elseif stage == 8 and R.overlay == R.OV_RESULT and R.dialog_settled() then
        click(R.result_form, "claim", true)
        stage = 9
    elseif stage == 9 and R.on_island and R.overlay == R.OV_NONE and R.town.buttons.play then
        assert(R.prog.level == 1, "claiming the first reward introduces town")
        app.inject_click(R.town.buttons.play)
        stage = 10
    elseif stage == 10 and not R.on_island then
        assert(R.g.level == 1, "town Play opens level two")
        app.inject_click(R.board_pause:center())
        stage = 11
    elseif stage == 11 and R.overlay == R.OV_PAUSE and R.dialog_settled() then
        click(R.pause_form, "menu", true)
        stage = 12
    elseif stage == 12 and R.on_menu and menu.values.visit then
        click(menu, "town")
        stage = 13
    elseif stage == 13 and not R.on_menu then
        assert(R.on_island and R.prog.level == 1, "the menu's visit action returns to town")
        app.quit()
    end
end

return desc
