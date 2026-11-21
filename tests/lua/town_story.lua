-- Use the same town confirmation and story queue that a player sees.
local R, island, journey = require("state"), require("island"), require("journey")
require("main")
R.test_mode, R.quiet, R.overlay, R.on_island = true, false, R.OV_NONE, true
R.island = city.new()
island.island_setup(R.island)
R.wonders, R.buildings = island.wonders, island.buildings
R.prog = {level=6, seed=1, wallet=purse(9999,9999,9999,6), story_seen={}}
for _, beat in ipairs(journey.beats) do
    if beat.level <= 6 then R.prog.story_seen[beat.key] = true end
end
R.town_setup()

local callbacks = {}
for _, beat in ipairs(journey.beats) do
    for _, v in ipairs(beat.replies or {}) do
        local step = island.ladder[island.ladder_position[island.kinds[v.building]]]
        check(step and beat.level > step.after, "callback follows its purchase")
        check(journey.lines_for(beat, function() return false end) == beat.lines, "unbuilt callback uses the campaign line")
        local seen = {}
        if v.introduction then seen[v.introduction] = true end
        if v.when then seen[v.when] = true end
        check(journey.lines_for(beat, function(key) return key == v.building end, seen)[v.index] == v.line, "eligible callback uses its reply")
        callbacks[v.building] = true
    end
end
for _, step in ipairs(island.ladder) do
    local key = step.unlock.building
    if not step.story then
        check(journey.find("placed-" .. key) and callbacks[key], key .. " has a purchase conversation and a later callback")
    end
end

check(R.debug_advance_town(), "confirm the first story building")
local kind = island.next_step(R.island, R.prog.level)
local key = "placed-" .. island.buildings[kind + 1].key
local callback = journey.find("after-07")
check(R.story_lines(callback) == callback.lines, "waiting to build preserves the original exchange")
check(R.town:begin(kind, false), "preview the next purchase")
check(not journey.next_placement(R.prog), "preview has no conversation")
check(R.town:confirm(), "confirm the purchase")
check(R.story_lines(callback)[callback.replies[1].index] == callback.replies[1].line, "confirmation changes the next clear's dialogue")
R.story_tick()
check(R.story_current and R.story_current.key == key, "the town plays the confirmed building's exchange")
story.next()
save.write("town-story-interrupted", function(s) journey.serialize(s, R.prog) end)
while story.active() do story.next() end
R.story_current, R.prog.story_seen = nil, {}
save.read("town-story-interrupted", function(s) journey.serialize(s, R.prog) end)
R.story_tick()
check(R.story_current and R.story_current.key == key, "reload resumes the interrupted conversation")
while story.active() do story.next() end
R.story_tick()
check(R.prog.story_seen[key] and not journey.next_placement(R.prog), "finishing clears the pending conversation")

-- A returning player may already have seen the old conversation at the site.
-- Let them meet the new resident before any queued level can give them a line.
local site = testing.game == "relic-rush" and "aviary" or "glassblower"
local arrival = journey.find("placed-" .. site)
local callback_count = 0
local function owns_site(building) return building == site end
save.write("pre-resident-town", function(s)
    s:int("narrative.v1." .. arrival.key, 2)
    s:int("narrative.v1." .. arrival.invitation, 1)
end)
local resident_save = {story_seen={}}
save.read("pre-resident-town", function(s) journey.serialize(s, resident_save) end)
check(not journey.next_arrival(resident_save, function() return false end), "an invitation alone never brings a resident")
check(journey.next_arrival(resident_save, owns_site) == arrival, "an existing owner receives the new introduction")
resident_save.story_seen[arrival.invitation] = false
check(not journey.next_arrival(resident_save, owns_site), "the introduction waits for the letter or invitation")
resident_save.story_seen[arrival.invitation] = true
R.island:add(vec2(0,0), island.kinds[site], 0)
R.prog = resident_save
R.prog.level = journey.find(arrival.invitation).level
R.story_tick()
check(R.story_current == arrival, "meeting the resident precedes the later campaign scenes")
while story.active() do story.next() end
R.story_tick()
check(resident_save.story_seen[arrival.key], "finishing the introduction welcomes the resident")
save.write("welcomed-resident", function(s) journey.serialize(s, resident_save) end)
resident_save = {story_seen={}}
save.read("welcomed-resident", function(s) journey.serialize(s, resident_save) end)
check(not journey.next_arrival(resident_save, owns_site), "reloading preserves the welcome")
for _, beat in ipairs(journey.beats) do
    for _, reply in ipairs(beat.replies or {}) do
        if reply.introduction == arrival.key and not reply.when then
            check(journey.lines_for(beat, owns_site, {}) == beat.lines, "resident cannot speak before the introduction")
            check(journey.lines_for(beat, owns_site, resident_save.story_seen)[reply.index][1] == arrival.resident,
                "the resident joins the later conversation after reload")
            callback_count = callback_count + 1
        end
    end
end
check(callback_count >= 2, "the resident returns in later level conversations")

-- Level progress can run ahead of the dialogue, and a building can arrive late.
local milestones = site == "aviary" and {"after-85","restore-91","after-92","restore-96","after-100"}
    or {"after-74","after-84","after-89","after-94","after-100"}
local visiting = {level=100, story_seen={}}
local function check_stage(checkpoint)
    local visit = journey.visit(visiting, site)
    check(visit and visit.checkpoint == checkpoint and #visit.choices == 2, "tap follows the latest witnessed milestone")
    for _, answer in ipairs(visit.choices) do
        check(#answer.lines >= 2 and answer.label:sub(-1) == "?", "each question has an exchange")
    end
    check(visit == journey.visit(visiting, site) and not visiting.story_seen[visit.key], "visit is repeatable and never advances the campaign")
end
visiting.story_seen[arrival.key] = true
check_stage(arrival.key)
for _, milestone in ipairs(milestones) do
    visiting.story_seen[milestone] = true
    check_stage(milestone)
end
visiting.story_seen[arrival.key] = false
check(not journey.visit(visiting, site), "even the finale cannot introduce a resident by tapping")
save.write("resident-visit", function(s) journey.serialize(s, visiting) end)
save.read("resident-visit", function(s) journey.serialize(s, visiting) end)
visiting.story_seen[arrival.key] = true
check_stage("after-100")

-- The pre-question save format can credit only the original story answer.
local checkpoint = site == "aviary" and "after-85" or "after-84"
local later = journey.find(site == "aviary" and "after-91" or "after-90")
local memory, ordinary = table.unpack(later.replies)
visiting.story_seen = {[arrival.key]=true, [checkpoint]=true}
local visit = journey.visit(visiting, site)
local personal, original = table.unpack(visit.choices)
check(memory.when == personal.key, "the level recalls this specific question")
check(journey.lines_for(later, owns_site, visiting.story_seen)[ordinary.index] == ordinary.line, "welcomed resident speaks even without a visit")
check(journey.lines_for(later, owns_site, {[personal.key]=true}) == later.lines, "an unmet resident never recalls an answer")

save.write("heard-resident", function(s) s:int("narrative.visit." .. visit.key, 1) end)
local reloaded = {}
save.read("heard-resident", function(s) journey.serialize(s, reloaded) end)
check(reloaded.story_seen[original.key] and not reloaded.story_seen[personal.key], "legacy save recognises the original answer")
check(journey.unheard_visit(reloaded, visit), "legacy player can discover the new personal question")

reloaded.story_seen[arrival.key] = true
check(journey.lines_for(later, owns_site, reloaded.story_seen)[ordinary.index] == ordinary.line, "the other question alone does not trigger the memory")

-- A question leaves the menu on selection; the reply resumes until it is heard.
R.prog, R.quiet = visiting, true
R.open_story_choice(visit)
check(R.choose_story_option(1) and story.active(), "selecting the personal question opens its answer")
save.write("interrupted-answer", function(s) journey.serialize(s, visiting) end)
reloaded = {}
save.read("interrupted-answer", function(s) journey.serialize(s, reloaded) end)
check(not reloaded.story_seen[personal.key] and reloaded.pending_answer == personal
    and journey.visit_menu(reloaded, visit).choices[1] == original, "an interrupted question stays off the menu")
check(journey.lines_for(later, owns_site, reloaded.story_seen)[ordinary.index] == ordinary.line, "interrupted answer leaves the ordinary reply")
while story.active() do story.next() end
R.story_current, R.prog, R.quiet = nil, reloaded, false
R.story_tick()
check(story.active() and R.story_current.key == personal.key, "town resumes the pending answer without asking again")
R.quiet = true
while story.active() do story.next() end
R.story_tick()
check(not reloaded.pending_answer and reloaded.story_seen[personal.key] and not reloaded.story_seen[original.key],
    "only the finished answer is heard")
save.write("one-answer", function(s) journey.serialize(s, reloaded) end)
reloaded = {}
save.read("one-answer", function(s) journey.serialize(s, reloaded) end)
check(reloaded.story_seen[personal.key] and journey.unheard_visit(reloaded, visit), "partial visit survives reload")
R.prog = reloaded
check(R.story_lines(later)[ordinary.index] == memory.line, "the loaded campaign uses the remembered reply")
check(journey.lines_for(later, function() return false end, R.prog.story_seen) == later.lines, "an absent building keeps the original scene")
R.open_story_choice(visit)
check(#R.story_choice_beat.choices == 1 and R.story_choice_beat.choices[1] == original and R.choose_story_option(1),
    "only the remaining question can be selected")
while story.active() do story.next() end
R.story_tick()
save.write("both-answers", function(s) journey.serialize(s, reloaded) end)
reloaded = {}
save.read("both-answers", function(s) journey.serialize(s, reloaded) end)
check(journey.visit(reloaded, site) == visit and not journey.unheard_visit(reloaded, visit), "both answers stay heard on reload")
check(journey.lines_for(later, owns_site, reloaded.story_seen)[ordinary.index] == memory.line, "hearing both answers preserves the memory")
reloaded.story_seen[site == "aviary" and "restore-91" or "after-89"] = true
check(journey.visit(reloaded, site) ~= visit and journey.lines_for(later, owns_site, reloaded.story_seen)[ordinary.index] == memory.line,
    "changing the available questions keeps the earlier memory")

-- A later scene can react on two lines; priority applies to each line independently.
local scene = {lines={original.lines[1], original.lines[2]}, replies={
    {index=1, building=site, when=personal.key, line=personal.lines[1]},
    {index=1, building=site, when=checkpoint, line=personal.lines[2]},
    {index=2, building=site, when=checkpoint, line=original.lines[1]},
}}
local resolved = journey.lines_for(scene, owns_site, {[checkpoint]=true, [personal.key]=true})
check(resolved[1] == personal.lines[1] and resolved[2] == original.lines[1], "first eligible reply wins independently on each line")
resolved = journey.lines_for(scene, owns_site, {[checkpoint]=true})
check(resolved[1] == personal.lines[2], "a later eligible rule wins when an earlier rule is unavailable")
check(journey.lines_for(scene, owns_site, {}) == scene.lines and scene.lines[1] == original.lines[1],
    "resolving another player's history leaves the authored scene intact")

-- Towns saved before the second resident existed may have both buildings.
-- Each introduction, heard flag and callback belongs to its own site.
local site2 = testing.game == "relic-rush" and "map_room" or "station_kiosk"
local arrival2 = journey.find("placed-" .. site2)
local later2 = journey.find(testing.game == "relic-rush" and "after-67" or "after-63")
local function owns_both(building) return building == site or building == site2 end
save.write("second-resident-old-town", function(s)
    s:int("narrative.v1." .. arrival2.key, 2) -- original purchase dialogue, before this introduction
    s:int("narrative.v1." .. arrival2.invitation, 1)
    s:int("narrative.arrival." .. arrival.resident, 2)
    s:int("narrative.visit." .. personal.key, 1)
end)
local both = {}
save.read("second-resident-old-town", function(s) journey.serialize(s, both) end)
check(not journey.visit(both, site2) and journey.next_arrival(both, owns_both) == arrival2,
    "old building owner can meet the second resident without buying it again")
check(journey.lines_for(later2, owns_both, both.story_seen) == later2.lines, "before the welcome the original cast speaks")
journey.acknowledge(both, arrival2)
local first2 = journey.visit(both, site2)
local remembered2, ordinary2 = table.unpack(later2.replies)
R.island:add(vec2(0,0), island.kinds[site2], 0)
R.prog = both
for _, index in ipairs({2, 1}) do
    check(R.story_lines(later2)[ordinary2.index] == ordinary2.line, "the other resident or the other question cannot trigger the memory")
    R.open_story_choice(first2)
    check(R.choose_story_option(index) and story.active(), "play the second resident's selected answer")
    while story.active() do story.next() end
    R.story_tick()
end
save.write("second-resident-heard", function(s) journey.serialize(s, both) end)
R.prog = {}
save.read("second-resident-heard", function(s) journey.serialize(s, R.prog) end)
check(R.story_lines(later2)[remembered2.index] == remembered2.line and R.prog.story_seen[personal.key],
    "both residents keep their own memories across a reload")
R.prog.story_seen[later2.key] = true
check(journey.unheard_visit(R.prog, journey.visit(R.prog, site2)), "the callback opens fresh questions at the building")

local meeting = journey.find("meeting-" .. site2 .. "-" .. site)
for _, intro in ipairs({arrival, arrival2}) do
    check(not journey.next_meeting({level=100, story_seen={[intro.key]=true}}, owns_both),
        "clearing the campaign and welcoming one resident cannot start their meeting")
    check(not journey.next_meeting(R.prog, function(building) return building == intro.building end),
        "both residents need their homes")
end
R.prog.level = 100
check(R.next_story(nil) == meeting and R.next_story(99) ~= meeting, "their meeting is due in town")
local questions = journey.visit(R.prog, site2)
for _, index in ipairs({2, 1}) do
    check(R.story_lines(meeting) == meeting.lines, "only the particular conversation changes the meeting")
    R.open_story_choice(questions)
    check(R.choose_story_option(index), "ask the resident at their building")
    while story.active() do story.next() end
    R.story_tick()
end
R.quiet = false
R.story_tick()
check(R.story_current == meeting, "both welcomed residents meet in town")
story.next()
save.write("interrupted-meeting", function(s) journey.serialize(s, R.prog) end)
while story.active() do story.next() end
R.story_current, R.prog = nil, {level=100}
save.read("interrupted-meeting", function(s) journey.serialize(s, R.prog) end)
R.story_tick()
check(R.story_current == meeting, "an interrupted meeting is offered again")
for _, home in ipairs(meeting.sites) do
    local stage = journey.visit(R.prog, home)
    for _, option in ipairs(journey.visit_menu(R.prog, stage).choices) do
        check(option.topic ~= "meeting", "the meeting must finish before either follow-up appears")
    end
    for _, answer in ipairs(stage.choices) do R.prog.story_seen[answer.key] = true end
    check(not journey.unheard_visit(R.prog, stage), "a pending meeting cannot light a fully heard roof")
end
local exchange = R.story_lines(meeting)
for _, reply in ipairs(meeting.replies) do
    check(exchange[reply.index] == reply.line, "the exchange recalls the building answer across a reload")
end
R.quiet = true
while story.active() do story.next() end
R.story_tick()
save.write("completed-meeting", function(s) journey.serialize(s, R.prog) end)
local reunited = {}
save.read("completed-meeting", function(s) journey.serialize(s, reunited) end)
check(reunited.story_seen[meeting.key] and not journey.next_meeting(reunited, owns_both),
    "the residents meet only once, including after relaunch")

local function menu(home)
    return journey.visit_menu(R.prog, journey.visit(R.prog, home)).choices
end

local function ask_meeting_question(home, answer_key)
    R.open_story_choice(journey.visit(R.prog, home))
    for index, answer in ipairs(R.story_choice_beat.choices) do
        if answer.key == answer_key then
            check(R.choose_story_option(index) and R.story_current.lines == answer.lines,
                "the selected question plays its own exchange")
            return
        end
    end
    check(false, "missing resident question " .. answer_key)
end

local function finish_answer()
    while story.active() do story.next() end
    R.story_tick()
end

for i, first_home in ipairs(meeting.sites) do
    local other_home = meeting.sites[3-i]
    local first_key, other_key = meeting.key .. "." .. first_home, meeting.key .. "." .. other_home
    R.prog = {level=100}
    save.read("completed-meeting", function(s) journey.serialize(s, R.prog) end)
    for _, home in ipairs(meeting.sites) do
        check(#menu(home) == 1 and R.town.hooks.unheard_visit(island.kinds[home]),
            "both buildings offer their own story when the meeting ends")
    end
    ask_meeting_question(first_home, first_key)
    save.write("unfinished-followup", function(s) journey.serialize(s, R.prog) end)
    local interrupted = {}
    save.read("unfinished-followup", function(s) journey.serialize(s, interrupted) end)
    check(#journey.visit_menu(interrupted, journey.visit(interrupted, other_home)).choices == 1,
        "selecting an account without finishing it never unlocks the other side")
    finish_answer()
    save.write("one-side-heard", function(s) journey.serialize(s, R.prog) end)
    R.prog = {level=100}
    save.read("one-side-heard", function(s) journey.serialize(s, R.prog) end)
    check(#menu(first_home) == 0 and #menu(other_home) == 2 and not R.town.hooks.unheard_visit(island.kinds[first_home]),
        "only the other resident can respond to the account after reload")
    check(menu(other_home)[1].key == other_key .. ".reply", "the fresh lead appears first")
    ask_meeting_question(other_home, other_key .. ".reply")
    check(#menu(first_home) == 0, "the return question waits for the full reply")
    finish_answer()
    check(not R.prog.story_seen[other_key] and R.town.hooks.unheard_visit(island.kinds[other_home]),
        "the other resident's original account remains independently available")
    check(#menu(other_home) == 1 and menu(other_home)[1].key == other_key, "a heard reply disappears")
    check(#menu(first_home) == 1 and R.town.hooks.unheard_visit(island.kinds[first_home]),
        "the new detail can travel back and relights the first roof")
    ask_meeting_question(first_home, first_key .. ".reply")
    finish_answer()
    ask_meeting_question(other_home, other_key)
    finish_answer()
    check(not R.town.hooks.unheard_visit(island.kinds[first_home]) and not R.town.hooks.unheard_visit(island.kinds[other_home]),
        "hearing all four exchanges clears both markers")
    save.write("both-sides-heard", function(s) journey.serialize(s, R.prog) end)
    R.prog = {level=100}
    save.read("both-sides-heard", function(s) journey.serialize(s, R.prog) end)
    R.prog.story_seen["after-100"] = true
    for _, home in ipairs(meeting.sites) do
        check(R.prog.story_seen[meeting.key .. "." .. home .. ".reply"], "the second resident keeps the memory")
        for _, option in ipairs(menu(home)) do
            check(option.topic ~= "meeting", "heard meeting questions stay gone across milestones and relaunch")
        end
    end
end

-- A town saved with the previous release has the original keys and no reply keys.
save.write("legacy-both-accounts", function(s)
    s:int("narrative.v1." .. meeting.key, 1)
    for _, home in ipairs(meeting.sites) do
        s:int("narrative.arrival." .. journey.find("placed-" .. home).resident, 2)
        s:int("narrative.visit." .. meeting.key .. "." .. home, 1)
    end
end)
R.prog = {level=100}
save.read("legacy-both-accounts", function(s) journey.serialize(s, R.prog) end)
for _, home in ipairs(meeting.sites) do
    check(#menu(home) == 3 and menu(home)[1].key == meeting.key .. "." .. home .. ".reply",
        "previously heard accounts unlock both new replies in an existing town")
end
