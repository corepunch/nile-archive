-- Quest tasks follow first clears and confirmed placements. Board numbers and
-- building keys refer to the existing campaign and catalogue.
local R = require("state")
local island = require("island")
local levels = require("campaign").levels

local Q = {}
local function dig(board, label)
    local object = levels[board].quest_object
    return {board=board, label=object and ("Recover · " .. object.name) or label}
end
local function build(key) return {building=key} end

Q.chapters = {
    {title="A Light Below", quests={
        {title="Get the camp talking", points=8, tasks={
            dig(1, "Clear the landing"), build("camp"), dig(2, "Test the lamp"),
            dig(3, "Follow the cable"), dig(4, "Inspect the pump"), build("well"),
        }},
        {title="Find the lower quay", points=12, tasks={
            dig(5, "Clear the vines"), dig(6, "Trace the shore marks"),
            dig(7, "Find tools"), build("workshop"),
        }},
        {title="Open the tide room", points=16, tasks={
            dig(8, "Trace the broken cable"), dig(9, "Reach the old approach"),
            build("market"), dig(10, "Inspect the relay"),
        }},
    }},
    {title="The Keeper’s Return", quests={
        {title="Find the sender", points=20, tasks={
            dig(11, "Follow the changed signal"), dig(12, "Find dry supplies"),
            dig(13, "Compare the marks"), build("gateway"),
        }},
        {title="Make a way home", points=24, tasks={
            dig(14, "Test a route"), dig(15, "Check the quay wall"),
            dig(16, "Prepare shelter"), build("lodge"),
        }},
        {title="Keep the record", points=28, tasks={
            dig(17, "Recover the fragment"), dig(18, "Compare the measurements"),
            dig(19, "Consult the records"), build("archive"), dig(20, "Find the signed plan"),
        }},
    }},
    {title="Keep the Light", quests={
        {title="Protect the warning", points=32, tasks={
            dig(21, "Read the bearings"), dig(22, "Find another landing"),
            dig(23, "Establish a lookout"), build("observatory"),
        }},
        {title="Repair the quay", points=36, tasks={
            dig(24, "Measure the tide"), dig(25, "Secure the materials"),
            dig(26, "Restore water access"), build("fountain"),
        }},
        {title="Let the light speak", points=40, tasks={
            dig(27, "Prepare the wall"), dig(28, "Confront the claim"),
            dig(29, "Restore the station"), build("temple"), dig(30, "Test the signal"),
        }},
    }},
}

local kinds = {}
for i, definition in ipairs(island.catalogue) do kinds[definition.key] = i - 1 end

local by_board, previous = {}, nil
for chapter_index, chapter in ipairs(Q.chapters) do
    for _, quest in ipairs(chapter.quests) do
        quest.chapter, quest.chapter_index = chapter.title, chapter_index
        quest.previous = previous
        for _, task in ipairs(quest.tasks) do
            if task.board then
                by_board[task.board] = quest
            else
                task.kind = assert(kinds[task.building], "unknown quest building: " .. task.building)
                task.label = "Place " .. island.catalogue[task.kind + 1].name
            end
        end
        previous = quest
    end
end

function Q.build_points(kind) return kind < island.WONDERS and 4 or 1 end

function Q.points(city)
    local points = 0
    for _, item in ipairs(city.items) do points = points + Q.build_points(item.type) end
    return points
end

local function complete_task(task, level, city)
    if task.board then return level >= task.board end
    return island.owned(city, task.kind) > 0
end

function Q.current(progress, city)
    local points = Q.points(city)
    for _, chapter in ipairs(Q.chapters) do
        for _, quest in ipairs(chapter.quests) do
            local done, next_task = 0, nil
            for _, task in ipairs(quest.tasks) do
                if complete_task(task, progress.level, city) then done = done + 1
                elseif not next_task then next_task = task end
            end
            if next_task or points < quest.points then return quest, next_task, done, points end
        end
    end
    return nil, nil, 0, points
end

function Q.required_points(board)
    local quest = by_board[board]
    return quest and quest.previous and quest.previous.points or 0
end

function R.quest_allows_board(board)
    local required = Q.required_points(board)
    if Q.points(R.island) >= required then return true end
    R.notice(("Reach %d decoration points to open this quest."):format(required))
    return false
end

R.quest_build_points = Q.build_points

local form = ui.form{root={kind="column", panel=true, role="quest", padding={13,9,13,9}, gap=2, children={
    {kind="label", id="chapter", em=14, text_style="cream", text_align="start", height=18},
    {kind="label", id="quest", em=23, text_style="gold", text_align="start", height=26},
    {kind="label", id="task", em=18, text_style="cream", text_align="start", height=23},
    {kind="label", id="points", em=15, text_style="green", text_align="start", height=20},
}}}

function R.draw_quest(screen)
    if R.overlay ~= R.OV_NONE or story.active() or R.island.placing >= 0 then return end
    local quest, task, done, points = Q.current(R.prog, R.island)
    if not quest then
        form:set("chapter", "THE LOST VALLEY")
        form:set("quest", "Campaign complete")
        form:set("task", "Explore the island or replay a board")
        form:set("points", ("%d decoration points"):format(points))
    else
        form:set("chapter", ("CHAPTER %d  ·  %s"):format(quest.chapter_index, quest.chapter))
        form:set("quest", quest.title)
        form:set("task", task and (task.board and ("%02d  ·  %s"):format(task.board, task.label) or task.label)
            or "Restore the island to continue")
        form:set("points", ("%d/%d tasks  ·  %d/%d decoration points"):format(done, #quest.tasks, points, quest.points))
    end
    form:draw(rect(screen.x + 10, screen.y + 96, 300, 110), R.skin, {interactive=false})
end

return Q
