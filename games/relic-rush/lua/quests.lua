-- quests.lua — the crew's requests: each asks for one piece of its own, which
-- stands on the boards only while the request is open and banks nothing in
-- the wallet. Matching it fills the request across expeditions; handing it in
-- on the island plays its scene (lua/quest_scenes.lua, from docs/story.md).
--
-- Two lines run side by side. A request opens once its building stands and
-- the one before it on its line is handed in. Open requests take the board's
-- free score slots in list order (economy.QUEST_KINDS); one with no slot
-- waits for the next free one.
-- Vault Door leaves two score slots open even after the whole ladder is built.
local Q = {REPLAY_LEVEL=5}

-- `levels` is the stretch a request is written for: previews and review
-- boards show it there. `need` is fitted to the pieces a won board banks
-- (tests/lua/relic_balance.lua reports them).
Q.list = {
    {key="chart", line="search", piece="chart", name="Chart pages", need=25, after="well", levels={2, 4},
        title="Piece the harbor chart together", giver="elena", ready_line="That looks like the last corner. Lay the pages out on my desk.",
        request="I've got a corner of the harbor chart. Bring me the loose pages. I want to see what lay off this shore."},
    {key="supper", line="crew", piece="berries", name="Berries", need=25, after="well", levels={2, 4},
        title="Fill the supper pot", giver="mara", ready_line="The pot is on. Bring those berries over before Elena eats the lot.",
        request="I've a pot, a spoon and nothing to stir. Will you pick the berries up by the lookout?"},
    {key="trail", line="search", piece="marker", name="Trail arrows", need=45, after="log_cabin", levels={5, 7},
        title="Uncover the painted arrows", giver="tomas", ready_line="There's the last arrow. Come down with me. I'll show you where it leads.",
        request="I painted arrows on the sound stones. Help me clear the vines so we can follow them down."},
    {key="tools", line="crew", piece="tools", name="Tool rolls", need=45, after="log_cabin", levels={5, 7},
        title="Dig out the keeper's tools", giver="tomas", ready_line="I know that stitching. Let's unroll them together.",
        request="My father wrapped his chisels in oiled canvas. Help me dig the rolls out before the salt gets in."},
    {key="cable", line="search", piece="cable", name="Relay cable", need=60, after="workshop", levels={8, 10},
        title="Haul up the relay cable", giver="tomas", ready_line="That's the end of it. Bring the break up into the light.",
        request="Take the loose coils from my end of the quay. Somewhere along this cable we'll find the break."},
}

-- A field action has no quota, board yield, or purchase requirement of its own.
Q.shutter = {key="shutter", giver="tomas", title="Test the hand shutter",
    request="Mara's skiff is off the reef. Lift the brass ring on the spare lamp. Let's see what she sees."}

function Q.shutter_open(state) return state.done.cable and not state.done.shutter end

Q.entries = {table.unpack(Q.list)}
Q.entries[#Q.entries + 1] = Q.shutter
Q.by_key = {}
for index, quest in ipairs(Q.list) do
    quest.index = index
    -- The board piece: the engine counts each one matched under `item`.
    quest.yield = {key=quest.piece, name=quest.name, item=quest.key, amount=1}
    -- Handing it in pays Coins: two for every piece it asked for.
    quest.coins = quest.coins or 2 * quest.need
    Q.by_key[quest.key] = quest
end

-- A save's request state: pieces banked and requests handed in, by key.
function Q.new_state() return {have={}, done={}, introduced={}, ready_seen={}} end

function Q.have(state, quest) return math.min(quest.need, state.have[quest.key] or 0) end
function Q.ready(state, quest) return (state.have[quest.key] or 0) >= quest.need end
-- How far along a request is, 0 to 1: its marker's gauge. A request of several
-- requirements will average their shares.
function Q.progress(state, quest) return Q.have(state, quest) / quest.need end

-- The open requests in list order. `owns(building)` says whether a ladder
-- building stands.
function Q.open(state, owns)
    local open, line_busy = {}, {}
    for _, quest in ipairs(Q.list) do
        if not state.done[quest.key] then
            if not line_busy[quest.line] and owns(quest.after) then open[#open + 1] = quest end
            line_busy[quest.line] = true   -- later requests on the line wait for this one
        end
    end
    return open
end

-- The open requests still short of pieces: these hold a board slot.
function Q.collecting(state, owns)
    local out = {}
    for _, quest in ipairs(Q.open(state, owns)) do
        if not Q.ready(state, quest) then
            -- If timber leaves only one slot, an unfinished supper or tool
            -- roll must never be a hidden prerequisite for finding the cable.
            table.insert(out, quest.line == "search" and 1 or #out + 1, quest)
        end
    end
    return out
end

-- The requests written for expedition `number`, for previews and reviews.
function Q.scheduled(number)
    local open = {}
    for _, quest in ipairs(Q.list) do
        if number >= quest.levels[1] and number <= quest.levels[2] then open[#open + 1] = quest end
    end
    return open
end

-- Bank a won board's pieces. Pieces beyond the need are not kept.
function Q.bank(state, items)
    for key, amount in pairs(items or {}) do
        local quest = Q.by_key[key]
        if quest and not state.done[key] then
            state.have[key] = math.min(quest.need, (state.have[key] or 0) + amount)
        end
    end
end

-- Hand a filled request in. False while pieces are missing.
function Q.deliver(state, quest)
    if state.done[quest.key] or not Q.ready(state, quest) then return false end
    state.done[quest.key], state.have[quest.key] = true, nil
    return true
end

function Q.serialize(s, state)
    for _, quest in ipairs(Q.list) do
        local key = quest.key
        local have = s:int("quest.have." .. key, state.have[key] or 0)
        state.ready_seen[key] = s:int("quest.ready_seen." .. key, state.ready_seen[key] and 1 or 0) == 1 or nil
        state.have[key] = have > 0 and math.min(quest.need, have) or nil
    end
    -- Persist by name so a later epoch can add or reorder requests.
    local pending
    for _, quest in ipairs(Q.entries) do
        local key = quest.key
        state.done[key] = s:int("quest.done." .. key, state.done[key] and 1 or 0) == 1 or nil
        state.introduced[key] = s:int("quest.intro." .. key, state.introduced[key] and 1 or 0) == 1 or nil
        if s:int("quest.unread." .. key, state.pending == key and 1 or 0) == 1 then pending = key end
    end
    state.pending = pending
end

return Q
