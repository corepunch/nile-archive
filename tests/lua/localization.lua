-- engine/lua/l10n.lua: PO catalogues, plural forms, language negotiation and
-- upper case, then every catalogue the repository ships.
local l10n = require("l10n")

-- The engine suite has no data root and no --lang: the source language.
check(l10n.language == "en" and l10n.source == "en", "without a game catalogue the engine shows its source text")
check(l10n.tr("Restart this level?") == "Restart this level?", "an unknown msgid shows itself")
check(l10n.trn("%d coin", "%d coins", 1) == "%d coin" and l10n.trn("%d coin", "%d coins", 0) == "%d coins",
      "an untranslated plural follows English")

------------------------------------------------------------------ parsing
do
    local po = l10n.parse_po(table.concat({
        '# translator comment',
        'msgid ""',
        'msgstr ""',
        '"Language: ru\\n"',
        '"Plural-Forms: nplurals=3; plural=(n%10==1 && n%100!=11 ? 0 : 1);\\n"',
        '',
        '#: lua/a.lua',
        'msgid "Play"',
        'msgstr "Играть"',
        '',
        'msgctxt "verb"',
        'msgid "Build"',
        'msgstr "Строить"',
        'msgctxt "noun"',
        'msgid "Build"',
        'msgstr "Постройка"',
        '',
        '#, lua-format',
        'msgid "%d coin"',
        'msgid_plural "%d coins"',
        'msgstr[0] "%d монета"',
        'msgstr[1] "%d монеты"',
        'msgstr[2] "%d монет"',
        '',
        'msgid ""',
        '"Two "',
        '"lines\\n\\"quoted\\""',
        'msgstr ""',
        '"Две "',
        '"строки\\n\\"в кавычках\\""',
        '',
        '#, fuzzy',
        'msgid "Guess"',
        'msgstr "Догадка"',
        '',
        'msgid "Empty"',
        'msgstr ""',
        '',
        'msgid "Half"',
        'msgid_plural "Halves"',
        'msgstr[0] "Половина"',
        'msgstr[1] ""',
        'msgstr[2] ""',
        '',
        '#~ msgid "Gone"',
        '#~ msgstr "Ушло"',
    }, "\n"))
    local e = po.entries
    check(po.language == "ru" and po.nplurals == 3, "the header gives the language and its plural count")
    check(e.Play == "Играть", "a plain entry")
    check(e["verb\4Build"] == "Строить" and e["noun\4Build"] == "Постройка" and e.Build == nil,
          "contexts key identical msgids apart, even without a blank line between them")
    check(e["%d coin"] and e["%d coin"][3] == "%d монет", "plural forms in order")
    check(e["Two lines\n\"quoted\""] == "Две строки\n\"в кавычках\"", "continued strings join and unescape")
    check(e.Guess == nil and e.Empty == nil and e.Half == nil, "fuzzy, empty and partly translated entries show the source")
    check(e.Gone == nil, "obsolete entries are comments")
end

------------------------------------------------------------------ plurals
do
    local function forms(tag, list)
        local out = {}
        for i, n in ipairs(list) do out[i] = l10n.plural_index(tag, n) end
        return table.concat(out, ",")
    end
    check(forms("ru", {1, 2, 5, 11, 12, 21, 22, 25, 101, 111}) == "0,1,2,2,2,0,1,2,0,2", "Russian plural forms")
    check(forms("pl", {1, 2, 5, 12, 22, 25}) == "0,1,2,2,1,2", "Polish plural forms")
    check(forms("fr", {0, 1, 2}) == "0,0,1" and forms("pt-BR", {0, 1, 2}) == "0,0,1", "French and Brazilian 0 and 1 are singular")
    check(forms("de", {0, 1, 2}) == "1,0,1" and forms("en-GB", {1, 3}) == "0,1", "English and German")
    check(forms("ja", {1, 2}) == "0,0" and forms("zh-Hans", {7}) == "0", "no plural in Japanese and Chinese")
end

------------------------------------------------------------- negotiation
do
    local offered = {"en", "de", "pt-BR", "ru", "ja", "zh-Hans"}
    local function pick(prefs) return l10n.negotiate(prefs, offered) end
    check(pick{"de-AT", "en"} == "de", "a region falls back to its language")
    check(pick{"pt-PT"} == "pt-BR", "another region of the language before giving up")
    check(pick{"zh-Hans-CN"} == "zh-Hans" and pick{"zh-CN"} == "zh-Hans" and pick{"zh"} == "zh-Hans",
          "Simplified Chinese by script or by region")
    check(pick{"zh-TW", "ja-JP"} == "ja" and pick{"zh-Hant-HK"} == nil, "Traditional Chinese never shows Simplified")
    check(pick{"fr-FR", "ru_RU"} == "ru", "unoffered languages are skipped; POSIX separators are accepted")
    check(pick{"EN-gb"} == "en" and pick{} == nil and pick{""} == nil, "case is ignored; nothing found is nil")
    check(l10n.canonical("zh_hans_cn") == "zh-Hans-CN" and l10n.canonical("PT-br") == "pt-BR", "canonical tags")
    local listed = l10n.parse_languages("# comment\nru\n\n en \n# more\nde\n")
    check(#listed == 3 and listed[1] == "ru" and listed[2] == "en", "languages.txt: tags in order, comments skipped")
end

------------------------------------------------------------------- upper
check(l10n.upper("Straße größer") == "STRASSE GRÖSSER", "German capitals")
check(l10n.upper("Sí, señor. Ça déjà") == "SÍ, SEÑOR. ÇA DÉJÀ", "Latin-1 capitals")
check(l10n.upper("Глава ёлки") == "ГЛАВА ЁЛКИ", "Cyrillic capitals")
check(l10n.upper("łódź ąę") == "ŁÓDŹ ĄĘ", "Latin Extended-A capitals")
check(l10n.upper("日本語 abc") == "日本語 ABC", "scripts without case pass through")

---------------------------------------------- every shipped catalogue
-- Each loads, names its language, and declares the plural rule the runtime uses.
local languages = {}
for _, game in ipairs{"relic-rush", "christmas-market", "emergency", "nile-archive"} do
    local listed = l10n.parse_languages(app.read_text("games/" .. game .. "/data/common/l10n/languages.txt"))
    check(#listed > 1, game .. " lists its languages")
    for i, tag in ipairs(listed) do
        languages[tag] = true
        local name = game .. "/" .. tag
        local text = i > 1 and app.read_text("games/" .. game .. "/data/common/l10n/" .. tag .. ".po")
        if i > 1 then
            check(text ~= nil, name .. ".po exists")
            local po = text and l10n.parse_po(text)
            if po then
                check(po.language == tag, name .. " names its language")
                check(text:find(l10n.PLURAL_FORMS[l10n.plural_rule(tag)], 1, true) ~= nil, name .. " declares the runtime's plural rule")
            end
        end
    end
end
for tag in pairs(languages) do
    if tag ~= "en" then
        local text = app.read_engine_text("data/common/l10n/" .. tag .. ".po")
        check(text ~= nil, "the engine has a catalogue for " .. tag)
        if text then check(l10n.parse_po(text).language == tag, "engine/" .. tag .. " names its language") end
    end
    for _, file in ipairs(l10n.script_fonts(tag)) do
        check(font.load_engine("data/common/fonts/" .. file) ~= nil, tag .. " has its script font " .. file)
    end
end
