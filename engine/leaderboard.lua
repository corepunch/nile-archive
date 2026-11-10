-- leaderboard.lua - the leaderboard dialog every game shares. It reads the
-- engine's Game Center rows (gamecenter.entries), shows them in a scrolling
-- list under Everyone / Friends tabs, and paints with the game's ui.skin.
--
--   local leaderboard = require("leaderboard")
--   local lb = leaderboard.new{skin = skin, board = "stars", title = "Top explorers"}
--   lb:open()                                  -- from a button
--   -- frame, standalone:
--   if lb:begin() then update_game() end       -- false while the dialog has the input
--   render_game()
--   lb:draw(dt, {reduced_motion = reduced})
--
-- A game that already has a ui.modals stack passes it in (`modals = stack`) and
-- keeps drawing it itself; it calls lb:sync() before the stack draws and
-- lb:handle(event) with every event the stack returns (true when it was ours).
--
-- Options: skin, board (required), title, count (rows asked for, 1-25, default
-- 25), width (default 420), rows (rows visible without scrolling, default 8),
-- format(score) -> string, texts (see DEFAULTS), modals, id (default "leaderboard").
-- Skin roles used if the skin defines them: title, leaderboard_row,
-- leaderboard_me (the player's own row) and leaderboard_note (the status line).
-- Without Game Center it shows the player's own best, so it works everywhere.
local L = {}
L.__index = L

local DEFAULTS = {
    title = "Leaderboard", everyone = "Everyone", friends = "Friends", close = "Close", native = "Game Center",
    you = "(you)", loading = "Loading...", empty = "No scores yet. Be the first!",
    empty_friends = "None of your friends have played yet.",
    sign_in = "Sign in to Game Center to compare with other players.",
    sign_in_friends = "Sign in to Game Center to see your friends.",
}

local function plain(score)
    local text = string.format("%d", math.floor(score + .5))
    local out = text:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    return (out:gsub("^,", ""))
end

function L.new(options)
    assert(type(options) == "table" and type(options.board) == "string" and options.board ~= "", "leaderboard.new needs a board name")
    local self = setmetatable({}, L)
    self.board, self.skin = options.board, options.skin or {}
    self.id = options.id or "leaderboard"
    self.count = math.max(1, math.min(options.count or 25, 25))
    self.format = options.format or plain
    self.scope = gamecenter.GLOBAL
    self.texts = {}
    for k, v in pairs(DEFAULTS) do self.texts[k] = v end
    for k, v in pairs(options.texts or {}) do self.texts[k] = v end
    if options.title then self.texts.title = options.title end
    self.shared = options.modals ~= nil
    self.modals = options.modals or ui.modals(self.skin)
    self.width = options.width or 420
    local texts = self.texts
    local visible_rows = options.rows or 8
    local me_suffix = " " .. texts.you
    self.form = ui.form{root = {kind = "column", panel = true, padding = 24, gap = 14, children = {
        {kind = "label", id = "title", text = texts.title, role = "title", height = 44},
        -- the chosen tab is a button, the other a flat caption, whatever the skin does for "selected"
        {kind = "row", gap = 10, height = 46, children = {
            {kind = "button", id = "global_on", text = texts.everyone, grow = 1, visible_field = "show_global_on"},
            {kind = "button", id = "global", text = texts.everyone, grow = 1, flat = true, visible_field = "show_global_off"},
            {kind = "button", id = "friends_on", text = texts.friends, grow = 1, visible_field = "show_friends_on"},
            {kind = "button", id = "friends", text = texts.friends, grow = 1, flat = true, visible_field = "show_friends_off"},
        }},
        {kind = "label", id = "status", text = "", wrap = true, role = "leaderboard_note", min_height = 26, visible_field = "show_status"},
        {kind = "list", id = "rows", scroll = true, gap = 4, height = visible_rows * 44, item = function(record)
            local role = record.me and "leaderboard_me" or "leaderboard_row"
            return {kind = "row", height = 40, gap = 8, align = "center", children = {
                {kind = "label", text = tostring(record.rank), width = 48, text_align = "start", role = role},
                {kind = "label", text = record.name .. (record.me and me_suffix or ""), grow = 1, text_align = "start", role = role},
                {kind = "label", text = self.format(record.score), width = 110, text_align = "end", role = role},
            }}
        end},
        {kind = "row", gap = 10, height = 50, children = {
            {kind = "button", id = "native", text = texts.native, grow = 1, visible_field = "show_native"},
            {kind = "button", id = "close", text = texts.close, grow = 1, accent = true},
        }},
    }}}
    return self
end

function L:active()
    for _, layer in ipairs(self.modals.layers) do if layer.id == self.id then return true end end
    return false
end

function L:select(scope)
    self.scope = scope
    local values = self.form.values
    values.show_global_on, values.show_global_off = scope == gamecenter.GLOBAL, scope ~= gamecenter.GLOBAL
    values.show_friends_on, values.show_friends_off = scope == gamecenter.FRIENDS, scope ~= gamecenter.FRIENDS
    self.form:invalidate_layout()
    self.signature = nil
    gamecenter.load(self.board, scope, self.count)
    self.form:scroll_to("rows")
end

function L:open()
    if self:active() then return true end
    self.signature = nil
    local ok, message = self.modals:open(self.id, self.form, {}, {width = self.width})
    if ok then self:select(self.scope) end
    return ok, message
end

function L:close()
    if self:active() then self.modals:close(self.id) end
end

-- Which note, if any, goes above the list.
function L:note(rows)
    local texts = self.texts
    local friends = self.scope == gamecenter.FRIENDS
    if gamecenter.state() == gamecenter.UNAVAILABLE then
        if friends then return texts.sign_in_friends end
        return rows and #rows > 0 and texts.sign_in or (rows and texts.empty or texts.loading)
    end
    if rows == nil then return texts.loading end
    if #rows == 0 then return friends and texts.empty_friends or texts.empty end
    return nil
end

-- Pull the engine's rows into the list when they changed. Call before drawing.
function L:sync()
    if not self:active() then return end
    local form = self.form
    local rows = gamecenter.entries(self.board, self.scope)
    local parts = {gamecenter.state(), self.scope}
    for _, row in ipairs(rows or {}) do parts[#parts + 1] = row.rank .. ":" .. row.name .. ":" .. row.score .. (row.me and "*" or "") end
    if rows == nil then parts[#parts + 1] = "-" end
    local signature = table.concat(parts, "|")
    if signature == self.signature then return end
    self.signature = signature
    local items = {}
    for i, row in ipairs(rows or {}) do items[i] = {id = i, rank = row.rank, name = row.name, score = row.score, me = row.me} end
    assert(form:set_items("rows", items))
    local note = self:note(rows)
    form:set("status", note or "")
    form.values.show_status = note ~= nil
    form.values.show_native = gamecenter.state() == gamecenter.SIGNED_IN
    form:invalidate_layout()
end

-- Act on an event returned by the modal stack; true when it belonged to this dialog.
function L:handle(event)
    if not event or event.modal ~= self.id then return false end
    -- global_on / friends_on are the chosen tab: tapping it changes nothing
    if event.kind == "cancel" or event.id == "close" then self:close()
    elseif event.id == "global" then self:select(gamecenter.GLOBAL)
    elseif event.id == "friends" then self:select(gamecenter.FRIENDS)
    elseif event.id == "native" then gamecenter.show(gamecenter.LEADERBOARD, self.board)
    end
    return true
end

function L:begin() return self.modals:begin() end

-- Standalone frame: sync, paint the stack above the game, handle our events.
-- Returns the event when it is not ours (a stack with other dialogs).
function L:draw(dt, options)
    self:sync()
    local event = self.modals:draw(dt, options)
    if event and not self:handle(event) then return event end
end

return L
