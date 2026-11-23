-- l10n.lua — the words a player reads, in the player's language.
--
-- Catalogues are GNU gettext PO files. Source code holds the source-language
-- text and marks it for translation through local aliases, which is what
-- xgettext looks for:
--
--     local l10n = require("l10n")
--     local tr, trn, trc = l10n.tr, l10n.trn, l10n.trc
--     tr("Restart this level?")
--     trn("%d move left", "%d moves left", n):format(n)
--     trc("verb on a button", "Build")
--     local N_ = l10n.N_      -- marks text kept as a key, shown later with tr(key)
--
-- A comment starting "TRANSLATORS:" on the line before a marked string
-- reaches the translator with it.
--
-- The marked text is the msgid, as in gettext: tools/l10n.py extracts it with
-- xgettext and merges it into every catalogue with msgmerge. A missing or
-- untranslated entry shows the source text. Two catalogues are consulted in
-- turn: the game's (data/common/l10n/<tag>.po) and the engine's own words
-- (engine/data/common/l10n/<tag>.po).
--
-- The language is chosen once, when the engine's Lua loads, before any game
-- module runs: the player's preferred languages (app.languages(), which
-- --lang overrides) against the list in data/common/l10n/languages.txt, whose
-- first line is the language the game is written in. Strings resolve when the
-- module that marks them loads; a new language takes effect on the next start,
-- which is how iOS applies a per-app language. The module also sets the fonts
-- for scripts no game font covers (font.set_global_fallback).
-- See docs/LOCALIZATION.md.
local l10n = {}

local GAME_DIR = "common/l10n/"
local ENGINE_DIR = "data/common/l10n/"
local ENGINE_SOURCE = "en"

------------------------------------------------------------------ PO files

local ESCAPES = {n = "\n", t = "\t", r = "\r", ['"'] = '"', ["\\"] = "\\"}

local function unquote(s)
    return (s:gsub("\\(.)", function(c) return ESCAPES[c] or c end))
end

-- A PO file as {entries = {[key] = msgstr or {forms}}, nplurals, language}.
-- The key is the msgid, or "context\4msgid" with a msgctxt, as gettext keys
-- them. Fuzzy and untranslated entries are left out, so they show the source;
-- obsolete (#~) entries are comments.
local function store(catalogue, entry)
    if entry.msgid == "" then
        local header = "\n" .. (entry.msgstr or "")
        catalogue.language = header:match("\nLanguage: *([^\n]-) *\n")
        catalogue.nplurals = tonumber(header:match("nplurals *= *(%d+)")) or catalogue.nplurals
        return
    end
    local key = entry.msgctxt and entry.msgctxt .. "\4" .. entry.msgid or entry.msgid
    if entry.msgid_plural then
        local forms = {}
        for i = 0, catalogue.nplurals - 1 do
            local form = entry.forms[i]
            if not form or form == "" then return end
            forms[i + 1] = form
        end
        catalogue.entries[key] = forms
    elseif entry.msgstr and entry.msgstr ~= "" then
        catalogue.entries[key] = entry.msgstr
    end
end

function l10n.parse_po(text)
    local catalogue = {entries = {}, nplurals = 2}
    local entry, field = {forms = {}}, nil
    local function finish()
        if entry.msgid and not entry.fuzzy then store(catalogue, entry) end
        entry, field = {forms = {}}, nil
    end
    for line in (text .. "\n"):gmatch("([^\n]*)\n") do
        line = line:gsub("\r$", "")
        -- A comment, msgctxt or msgid after a msgstr begins the next entry.
        if entry.complete and (line:match("^#") or line:match("^msgctxt%s") or line:match("^msgid%s")) then finish() end
        local keyword, index, quoted = line:match('^(msg[%a_]+)(%[?%d*%]?)%s+"(.*)"%s*$')
        if line:match("^#,.*fuzzy") then
            entry.fuzzy = true
        elseif keyword then
            local value = unquote(quoted)
            if index ~= "" then
                local n = tonumber(index:match("%d+"))
                entry.forms[n], field = value, n
            else
                entry[keyword], field = value, keyword
            end
            if keyword == "msgstr" then entry.complete = true end
        elseif field ~= nil and line:match('^%s*".*"%s*$') then
            local more = unquote(line:match('^%s*"(.*)"%s*$'))
            if type(field) == "number" then entry.forms[field] = entry.forms[field] .. more
            else entry[field] = entry[field] .. more end
        elseif line:match("^%s*$") and entry.complete then
            finish()
        end
    end
    finish()
    return catalogue
end

------------------------------------------------------------------- plurals

-- The gettext plural index for n in a language, keyed by its primary subtag
-- (and region where it differs). tools/l10n.py writes the same rules into the
-- Plural-Forms headers; tests/lua/localization.lua checks that they agree.
local function slavic(n)
    local d, h = n % 10, n % 100
    if d == 1 and h ~= 11 then return 0 end
    if d >= 2 and d <= 4 and (h < 10 or h >= 20) then return 1 end
    return 2
end
local PLURALS = {
    one_other = function(n) return n == 1 and 0 or 1 end,
    zero_one = function(n) return n > 1 and 1 or 0 end,
    none = function() return 0 end,
    slavic = slavic,
    polish = function(n)
        if n == 1 then return 0 end
        local d, h = n % 10, n % 100
        return (d >= 2 and d <= 4 and (h < 10 or h >= 20)) and 1 or 2
    end,
}
local PLURAL_RULE = {
    fr = "zero_one", ["pt-BR"] = "zero_one", tr = "zero_one",
    ja = "none", ko = "none", zh = "none", id = "none", th = "none", vi = "none",
    ru = "slavic", uk = "slavic", be = "slavic", pl = "polish",
}
l10n.PLURAL_FORMS = {
    one_other = "nplurals=2; plural=(n != 1);",
    zero_one = "nplurals=2; plural=(n > 1);",
    none = "nplurals=1; plural=0;",
    slavic = "nplurals=3; plural=(n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2);",
    polish = "nplurals=3; plural=(n==1 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2);",
}

-- The name of the plural rule a language tag follows.
function l10n.plural_rule(tag)
    tag = tag or ""
    return PLURAL_RULE[tag] or PLURAL_RULE[tag:match("^[^-]+") or ""] or "one_other"
end

-- The 0-based plural form a language uses for the count n.
function l10n.plural_index(tag, n)
    return PLURALS[l10n.plural_rule(tag)](math.floor(math.abs(n)))
end

------------------------------------------------------------ language tags

-- "zh_hans_cn" -> "zh-Hans-CN": lower language, title script, upper region.
function l10n.canonical(tag)
    local parts = {}
    for part in tostring(tag):gsub("_", "-"):gmatch("[^-]+") do
        if #parts == 0 then part = part:lower()
        elseif #part == 4 then part = part:sub(1, 1):upper() .. part:sub(2):lower()
        elseif #part == 2 or part:match("^%d%d%d$") then part = part:upper()
        else part = part:lower() end
        parts[#parts + 1] = part
    end
    return table.concat(parts, "-")
end

-- Chinese is told apart by script, which a region implies when absent.
local HANT_REGIONS = {TW = true, HK = true, MO = true}
local function with_script(tag)
    local rest = tag:match("^zh(.*)$")
    if not rest or rest:match("^%-Han[st]") then return tag end
    local region = rest:match("^%-(%u%u)")
    return "zh-" .. (region and HANT_REGIONS[region] and "Hant" or "Hans") .. rest
end

-- The first of `preferred` (tags, most preferred first) that `available`
-- offers, or nil. A preference matches the same tag, then the tag with its
-- subtags removed from the end (en-GB finds en), then another region of the
-- same language and script (pt-PT finds pt-BR, zh-Hans-SG finds zh-Hans).
function l10n.negotiate(preferred, available)
    local offered = {}
    for i, tag in ipairs(available) do offered[i] = with_script(l10n.canonical(tag)) end
    local function find(tag)
        for i, have in ipairs(offered) do if have == tag then return available[i] end end
    end
    for _, wanted in ipairs(preferred) do
        local tag = with_script(l10n.canonical(wanted))
        if tag ~= "" then
            local candidate = tag
            while candidate do
                local hit = find(candidate)
                if hit then return hit end
                candidate = candidate:match("^(.+)%-[^-]+$")
            end
            local family = tag:match("^(zh%-Han[st])") or tag:match("^([^-]+)")
            for i, have in ipairs(offered) do
                if have == family or have:sub(1, #family + 1) == family .. "-" then return available[i] end
            end
        end
    end
end

local function split(list, separator)
    local out = {}
    for item in (list or ""):gmatch("[^" .. separator .. "]+") do
        item = item:match("^%s*(.-)%s*$")
        if item ~= "" and not item:match("^#") then out[#out + 1] = item end
    end
    return out
end

-- languages.txt: one tag per line, the source language first; # comments.
function l10n.parse_languages(text) return split(text, "\n") end

--------------------------------------------------------------------- fonts

-- The engine's fonts for scripts the games' display fonts lack, subset to the
-- characters the catalogues use (tools/l10n.py fonts). Han characters need the
-- language's own forms, so Chinese, Japanese and Korean put theirs first.
local FONT_DIR = "data/common/fonts/"
local SCRIPT_FONTS = {
    default = {"NotoSans-Bold.ttf"},
    ja = {"NotoSansCJKjp-Regular.otf", "NotoSans-Bold.ttf"},
    ko = {"NotoSansCJKkr-Regular.otf", "NotoSans-Bold.ttf"},
    ["zh-Hans"] = {"NotoSansCJKsc-Regular.otf", "NotoSans-Bold.ttf"},
}

-- The engine fonts, in fallback order, for a language.
function l10n.script_fonts(tag)
    tag = tag or ""
    return SCRIPT_FONTS[tag] or SCRIPT_FONTS[tag:match("^[^-]+") or ""] or SCRIPT_FONTS.default
end

local loaded_fonts = {}
local function use_fonts(tag)
    local head, tail
    for _, file in ipairs(l10n.script_fonts(tag)) do
        local f = loaded_fonts[file]
        if f == nil then
            f = font.load_engine(FONT_DIR .. file) or false
            loaded_fonts[file] = f
        end
        if f then
            if tail then font.set_fallback(tail, f) else head = f end
            tail = f
        end
    end
    font.set_global_fallback(head)
end

---------------------------------------------------------------- the module

local game_entries, engine_entries = {}, {}

-- The language every string is shown in now, the one the game is written
-- in, and every language the game offers (the source first).
l10n.language, l10n.source, l10n.languages = ENGINE_SOURCE, ENGINE_SOURCE, {ENGINE_SOURCE}

local function catalogue(read, path, tag, source)
    if tag == source then return {} end
    local text = read(path .. tag .. ".po")
    return text and l10n.parse_po(text).entries or {}
end

-- Show everything marked from now on in `tag`, one of l10n.languages.
function l10n.use(tag)
    l10n.language = tag
    game_entries = catalogue(app.read_text, GAME_DIR, tag, l10n.source)
    engine_entries = catalogue(app.read_engine_text, ENGINE_DIR, tag, ENGINE_SOURCE)
    use_fonts(tag)
end

-- Read the game's language list and pick the player's language. Runs when the
-- engine's Lua loads, after the data root and command line are known.
function l10n.init()
    local listed = l10n.parse_languages(app.read_text(GAME_DIR .. "languages.txt"))
    l10n.languages = #listed > 0 and listed or {ENGINE_SOURCE}
    l10n.source = l10n.languages[1]
    l10n.use(l10n.negotiate(split(app.languages(), ","), l10n.languages) or l10n.source)
end

local function lookup(key)
    local found = game_entries[key]
    if found == nil then found = engine_entries[key] end
    return found
end

-- The translation of msgid, or msgid itself.
function l10n.tr(msgid)
    local found = lookup(msgid)
    return type(found) == "string" and found or msgid
end

-- The translation of msgid in a context that tells two identical source
-- strings apart (gettext's pgettext).
function l10n.trc(context, msgid)
    local found = lookup(context .. "\4" .. msgid)
    return type(found) == "string" and found or msgid
end

-- The form of a counted phrase for n (gettext's ngettext). The caller formats
-- the count in: trn("%d coin", "%d coins", n):format(n).
function l10n.trn(singular, plural, n)
    local forms = lookup(singular)
    if type(forms) == "table" then
        return forms[l10n.plural_index(l10n.language, n) + 1] or forms[#forms]
    end
    return PLURALS.one_other(math.floor(math.abs(n))) == 0 and singular or plural
end

-- Marks a string for extraction without translating it, for text that is
-- also a key: store N_("Spring well"), show tr(name). (gettext's N_.)
function l10n.N_(msgid) return msgid end

------------------------------------------------------------- upper case

-- Lua's string.upper knows only ASCII. This also maps Latin-1, Latin
-- Extended-A, Greek and Cyrillic; ß becomes SS, as German capitals write it.
local function upper_codepoint(c)
    if c >= 0x61 and c <= 0x7A then return c - 32 end
    if c < 0xDF then return c end
    if c == 0xDF then return "SS" end
    if c >= 0xE0 and c <= 0xFE and c ~= 0xF7 then return c - 32 end
    if c == 0xFF then return 0x178 end
    if (c >= 0x100 and c <= 0x137) or (c >= 0x14A and c <= 0x177) then return c - c % 2 end
    if (c >= 0x139 and c <= 0x148) or (c >= 0x179 and c <= 0x17E) then return c % 2 == 0 and c - 1 or c end
    if c == 0x3C2 then return 0x3A3 end
    if c >= 0x3B1 and c <= 0x3C9 then return c - 32 end
    if c >= 0x430 and c <= 0x44F then return c - 32 end
    if c >= 0x450 and c <= 0x45F then return c - 80 end
    if c >= 0x460 and c <= 0x4FF and c % 2 == 1 and not (c >= 0x482 and c <= 0x489) then return c - 1 end
    return c
end

-- s in capitals, for the scripts that have them.
function l10n.upper(s)
    if not s:find("[\128-\255]") then return s:upper() end
    local out = {}
    for _, c in utf8.codes(s) do
        local u = upper_codepoint(c)
        out[#out + 1] = type(u) == "string" and u or utf8.char(u)
    end
    return table.concat(out)
end

l10n.init()
return l10n
