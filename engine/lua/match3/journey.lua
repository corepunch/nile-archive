-- Campaign story rules and persistence. This module has no screen or engine dependencies.
-- The story's bookkeeping. `content` is the game's: beats (story_content),
-- wonder_levels, recap(level), regions, building lines and save version.
-- Checkpoints are stable keys, acknowledged after a whole beat ends.
local function new(content)
    local M = {}
    for key, value in pairs(content) do M[key] = value end
    M.about = M.about or {}
    -- Upgrade arrival scenes ({phase="upgrade", event="man_03", no level}) are
    -- kept apart from the level beats: they play on the next return to town
    -- once their user event is done, and never hold the story back.
    local scenes, upgrades, placements = {}, {}, {}
    local by_key, by_building, site_visits = {}, {}, {}
    local answers, meetings, visit_options, recalls = {}, {}, {}, {}
    local answer_sites = {}
    local function register_answer(answer, site)
        answers[#answers + 1] = answer
        answer_sites[answer.key] = site
    end
    for _, beat in ipairs(M.beats) do
        assert(not by_key[beat.key], "duplicate story beat: " .. beat.key)
        by_key[beat.key] = beat
        if beat.recall then recalls[#recalls + 1] = beat end
        if beat.phase == "placed" then
            placements[#placements + 1] = beat
            by_building[beat.building] = beat
        elseif beat.phase == "visit" then
            local site = beat.building
            for _, answer in ipairs(beat.choices) do register_answer(answer, site) end
            site_visits[site] = site_visits[site] or {}
            table.insert(site_visits[site], beat)
        elseif beat.phase == "meeting" then meetings[#meetings + 1] = beat
        elseif beat.phase == "upgrade" then upgrades[#upgrades + 1] = beat
        else scenes[#scenes + 1] = beat end
    end
    M.beats, M.upgrades, M.placements = scenes, upgrades, placements

    -- A shared scene's questions keep their heard keys across every visit stage at a home.
    local function register_followups(scene)
        for _, answer in ipairs(scene.followups or {}) do
            register_answer(answer, answer.building)
            for _, stage in ipairs(site_visits[answer.building]) do
                local options = visit_options[stage] or {table.unpack(stage.choices)}
                options[#options + 1] = answer
                visit_options[stage] = options
            end
        end
    end
    for _, meeting in ipairs(meetings) do register_followups(meeting) end
    for _, beat in ipairs(recalls) do register_followups(beat.recall) end

    -- Absent until a fresh purchase, false while due, true once acknowledged.
    -- Old saves therefore never receive a backlog for the town they already own.
    function M.placed(p, building)
        local beat = by_building[building]
        if beat and p.story_seen[beat.key] == nil then p.story_seen[beat.key] = false end
    end

    function M.next_placement(p)
        for _, beat in ipairs(placements) do
            if not beat.resident and p.story_seen[beat.key] == false then return beat end
        end
    end

    -- Check ownership here too: a town saved before a resident was written
    -- can welcome them even though its original purchase dialogue is finished.
    function M.next_arrival(p, owns)
        for _, beat in ipairs(placements) do
            if beat.resident and p.story_seen[beat.invitation] and not p.story_seen[beat.key]
                and owns(beat.building) then return beat end
        end
    end

    function M.next_meeting(p, owns)
        for _, beat in ipairs(meetings) do
            local a, b = table.unpack(beat.sites)
            if not p.story_seen[beat.key] and p.story_seen[by_building[a].key] and p.story_seen[by_building[b].key]
                and owns(a) and owns(b) then return beat end
        end
    end

    function M.visit(p, building)
        local stages = site_visits[building]
        if not stages or not p.story_seen[by_building[building].key] then return end
        for i = #stages, 1, -1 do
            local beat = stages[i]
            if p.story_seen[beat.checkpoint] then return beat end
        end
    end

    function M.visit_after_answer(p, key)
        return M.visit(p, answer_sites[key])
    end

    local function available(p, answer)
        if p.story_seen[answer.key] or p.pending_answer == answer then return false end
        if answer.when and not p.story_seen[answer.when] then return false end
        if not answer.heard_any then return true end
        for _, key in ipairs(answer.heard_any) do
            if p.story_seen[key] then return true end
        end
        return false
    end

    function M.visit_menu(p, visit)
        local choices, other = {}, {}
        for _, answer in ipairs(visit_options[visit] or visit.choices) do
            if available(p, answer) then
                -- Put a fresh lead first when the player comes back to talk.
                local group = (answer.source or answer.topic == "recall") and choices or other
                group[#group + 1] = answer
            end
        end
        for _, answer in ipairs(other) do choices[#choices + 1] = answer end
        return {key=visit.key, phase=visit.phase, prompt=visit.prompt, choices=choices}
    end

    function M.unheard_visit(p, visit)
        if visit then
            for _, answer in ipairs(visit_options[visit] or visit.choices) do
                if available(p, answer) then return true end
            end
        end
        return false
    end

    -- Story delivery calls this only after playback finishes (including Skip).
    function M.acknowledge(p, beat)
        if beat.key == "recap" then
            p.story_recap = false
        else
            if beat.phase == "visit" and p.story_seen[beat.key] then return false end
            if p.pending_answer and p.pending_answer.key == beat.key then p.pending_answer = nil end
            p.story_seen[beat.key] = true
        end
        return true
    end

    local function recall_ready(recall, owns, seen)
        if not seen or seen[recall.key] or not seen[recall.meeting] then return false end
        local sites = by_key[recall.meeting].sites
        return owns(sites[1]) and owns(sites[2])
    end

    function M.next_recall(p, owns)
        for _, beat in ipairs(recalls) do
            local recall = beat.recall
            if recall.lines and p.story_seen[beat.key] and recall_ready(recall, owns, p.story_seen) then return recall end
        end
    end

    local function recalled_exchange(recall, owns, seen)
        if not recall_ready(recall, owns, seen) then return end
        local meeting = by_key[recall.meeting]
        local first, second = table.unpack(meeting.sites)
        local heard = {}
        for _, answer in ipairs(meeting.followups) do
            if seen[answer.key] then heard[answer.building] = true end
        end
        if heard[first] and heard[second] then return recall.exchanges.both end
        if heard[first] then return recall.exchanges[first] end
        if heard[second] then return recall.exchanges[second] end
        return recall.exchanges.neither
    end

    function M.lines_for(beat, owns, seen)
        if not beat.replies and not beat.recall then return beat.lines end
        local lines, selected = beat.lines, {}
        for _, reply in ipairs(beat.replies or {}) do
            -- Missing history is the ownership-only preview used by older callers.
            local met = not reply.introduction or not seen or seen[reply.introduction]
            local remembered = not reply.when or (seen and seen[reply.when])
            if not selected[reply.index] and met and remembered and owns(reply.building) then
                if lines == beat.lines then lines = {table.unpack(beat.lines)} end
                lines[reply.index] = reply.line
                selected[reply.index] = true
            end
        end
        local exchange = beat.recall and recalled_exchange(beat.recall, owns, seen)
        if exchange then
            if lines == beat.lines then lines = {table.unpack(beat.lines)} end
            for _, line in ipairs(exchange) do lines[#lines + 1] = line end
            return lines, beat.recall.key
        end
        return lines
    end

    function M.find_upgrade(event)
        for _, beat in ipairs(M.upgrades) do if beat.event == event then return beat end end
    end

    -- The first unseen upgrade scene whose event `done(event)` says has happened.
    function M.next_upgrade(p, done)
        for _, beat in ipairs(M.upgrades) do
            if not (p.story_seen or {})[beat.key] and done(beat.event) then return beat end
        end
    end

    function M.earned(level)
        local n = 0
        for _, at in ipairs(M.wonder_levels) do if level >= at then n = n + 1 end end
        return n
    end

    function M.wonder_at(level)
        for i, at in ipairs(M.wonder_levels) do if level == at then return i end end
    end

    function M.find(key)
        return by_key[key]
    end

    -- Legacy clears remain clears; already-owned buildings stay. A recap
    -- bridges the old abbreviated dialogue without replaying rewards.
    function M.migrate(p, version)
        p.story_seen = p.story_seen or {}
        if version < M.version then
            for _, b in ipairs(M.beats) do
                if b.level <= p.level then p.story_seen[b.key] = true end
            end
            p.story_recap = p.level > 0
        end
    end

    function M.serialize(s, p)
        p.story_seen = p.story_seen or {}
        p.story_choices = p.story_choices or {}
        for _, b in ipairs(M.beats) do
            p.story_seen[b.key] = s:int("narrative.v1." .. b.key, p.story_seen[b.key] and 1 or 0) == 1
            if b.recall then
                local key = b.recall.key
                p.story_seen[key] = s:int("narrative.recall." .. key, p.story_seen[key] and 1 or 0) == 1
            end
            if b.choices then
                local choice = s:int("narrative.choice." .. b.key, p.story_choices[b.key] or 0)
                p.story_choices[b.key] = b.choices[choice] and choice or nil
            end
        end
        for _, b in ipairs(meetings) do
            p.story_seen[b.key] = s:int("narrative.v1." .. b.key, p.story_seen[b.key] and 1 or 0) == 1
        end
        -- Keep existing 0/1 saves. State 2 resumes the selected answer after relaunch.
        local pending
        for _, answer in ipairs(answers) do
            local key = answer.key
            local state = s:int("narrative.visit." .. key, p.story_seen[key] and 1 or p.pending_answer == answer and 2 or 0)
            p.story_seen[key] = state == 1
            if state == 2 then pending = answer end
        end
        p.pending_answer = pending
        for _, b in ipairs(M.upgrades) do
            p.story_seen[b.key] = s:int("narrative.v1." .. b.key, p.story_seen[b.key] and 1 or 0) == 1
        end
        for _, b in ipairs(placements) do
            local seen = p.story_seen[b.key]
            local checkpoint = b.resident and ("narrative.arrival." .. b.resident) or ("narrative.v1." .. b.key)
            local state = s:int(checkpoint, seen == nil and 0 or seen and 2 or 1)
            if state == 0 then p.story_seen[b.key] = nil else p.story_seen[b.key] = state == 2 end
        end
        p.story_recap = s:int("narrative.recap", p.story_recap and 1 or 0) == 1
    end

    local function first_unread(p)
        for _, beat in ipairs(M.beats) do
            if not (p.story_seen or {})[beat.key] then return beat end
        end
    end

    function M.result_beat(p, g, level)
        if not g.won or g.level ~= p.level or not (M.clear_before_result or level and level.reveal) then return end
        local key = ("after-%02d"):format(p.level + 1)
        local beat = M.clear_before_result and first_unread(p) or M.find(key)
        if beat and beat.key == key and not beat.choices and not p.story_seen[key] and g.story_clear ~= key then return beat end
    end

    function M.next(p, owns, before_level)
        local b = first_unread(p)
        if not b then return end
        if b.phase == "before" then
            if before_level == b.level - 1 and p.level >= b.level - 1 then return b end
            -- Catch up on the island if this expedition was already cleared.
            if before_level == nil and p.level >= b.level then return b end
        elseif p.level >= b.level then
            local wonder = M.wonder_at(b.level)
            if ((b.phase == "after" and M.clear_before_result) or not wonder or owns(wonder - 1))
                and (not M.ready or M.ready(p, b)) then return b end
        end
    end

    -- The scene that bridges an old save: the opening line, then the lines of
    -- the first {level, line...} step the player has reached.
    local recap = M.recap or {}
    function M.recap(level)
        local lines = {recap[1]}
        for i = 2, #recap do
            if level >= recap[i][1] then
                for k = 2, #recap[i] do lines[#lines + 1] = recap[i][k] end
                break
            end
        end
        return lines
    end

    -- A building's tap line for this point in the story: the last authored
    -- {kind, level, text} the player has reached, or the catalogue line.
    function M.building_about(kind, level, fallback)
        local best
        for _, line in ipairs(M.about) do
            if line[1] == kind and level >= line[2] and (not best or line[2] >= best[2]) then best = line end
        end
        return best and best[3] or fallback
    end

    return M
end

return new
