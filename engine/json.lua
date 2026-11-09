-- json.lua — a small strict JSON decoder for game configuration
-- (`require("json").decode(text)`). Objects become tables with string keys,
-- arrays become sequences, null becomes json.null. Errors name the offset.
local J = {}
J.null = setmetatable({}, {__tostring = function() return "null" end})

local escapes = {['"'] = '"', ['\\'] = '\\', ['/'] = '/', b = '\b', f = '\f', n = '\n', r = '\r', t = '\t'}

local function fail(at, what) error(("json: %s at offset %d"):format(what, at), 0) end

local function skip(s, i)
    local _, e = s:find("^[ \t\r\n]*", i)
    return e + 1
end

local function utf8_char(code)
    if code < 0x80 then return string.char(code) end
    return utf8.char(code)
end

local value

local function str(s, i)   -- s:sub(i, i) == '"'
    local out, j = {}, i + 1
    while true do
        local c = s:sub(j, j)
        if c == "" then fail(i, "unterminated string") end
        if c == '"' then return table.concat(out), j + 1 end
        if c == "\\" then
            local e = s:sub(j + 1, j + 1)
            if e == "u" then
                local hex = s:sub(j + 2, j + 5)
                if not hex:match("^%x%x%x%x$") then fail(j, "bad \\u escape") end
                local code = tonumber(hex, 16)
                j = j + 6
                if code >= 0xD800 and code <= 0xDBFF and s:sub(j, j + 1) == "\\u" then   -- surrogate pair
                    local low = tonumber(s:sub(j + 2, j + 5), 16)
                    if low and low >= 0xDC00 and low <= 0xDFFF then
                        code = 0x10000 + (code - 0xD800) * 0x400 + (low - 0xDC00)
                        j = j + 6
                    end
                end
                out[#out + 1] = utf8_char(code)
            elseif escapes[e] then
                out[#out + 1] = escapes[e]
                j = j + 2
            else fail(j, "bad escape") end
        else
            local run_end = s:find('["\\]', j) or (#s + 1)
            out[#out + 1] = s:sub(j, run_end - 1)
            j = run_end
        end
    end
end

local function array(s, i)
    local out, j = {}, skip(s, i + 1)
    if s:sub(j, j) == "]" then return out, j + 1 end
    while true do
        local v
        v, j = value(s, j)
        out[#out + 1] = v
        j = skip(s, j)
        local c = s:sub(j, j)
        if c == "]" then return out, j + 1 end
        if c ~= "," then fail(j, "expected , or ]") end
        j = skip(s, j + 1)
    end
end

local function object(s, i)
    local out, j = {}, skip(s, i + 1)
    if s:sub(j, j) == "}" then return out, j + 1 end
    while true do
        if s:sub(j, j) ~= '"' then fail(j, "expected a string key") end
        local k
        k, j = str(s, j)
        j = skip(s, j)
        if s:sub(j, j) ~= ":" then fail(j, "expected :") end
        local v
        v, j = value(s, skip(s, j + 1))
        out[k] = v
        j = skip(s, j)
        local c = s:sub(j, j)
        if c == "}" then return out, j + 1 end
        if c ~= "," then fail(j, "expected , or }") end
        j = skip(s, j + 1)
    end
end

value = function(s, i)
    i = skip(s, i)
    local c = s:sub(i, i)
    if c == "{" then return object(s, i)
    elseif c == "[" then return array(s, i)
    elseif c == '"' then return str(s, i)
    elseif s:sub(i, i + 3) == "true" then return true, i + 4
    elseif s:sub(i, i + 4) == "false" then return false, i + 5
    elseif s:sub(i, i + 3) == "null" then return J.null, i + 4
    end
    local num = s:match("^-?%d+%.?%d*[eE]?[-+]?%d*", i)
    if num and #num > 0 then
        local n = tonumber(num)
        if n then return n, i + #num end
    end
    fail(i, "unexpected character")
end

function J.decode(s)
    assert(type(s) == "string", "json.decode expects a string")
    local v, i = value(s, 1)
    i = skip(s, i)
    if i <= #s then fail(i, "trailing characters") end
    return v
end

-- A data-root JSON file, decoded; errors name the file.
function J.load(path)
    local text = app.read_text(path)
    assert(text, "json: cannot read " .. path)
    local ok, v = pcall(J.decode, text)
    if not ok then error(path .. ": " .. v, 2) end
    return v
end

return J
