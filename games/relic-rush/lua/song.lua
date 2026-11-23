-- song.lua — Relic Rush's soundtrack, "Valley of Echoes": a warm D Dorian
-- loop at 92 bpm. 32 bars: an intro of pad, keys and bass (1-8), the theme on
-- the lead with the groove (9-16), a brighter bridge with plucked arpeggios
-- (17-24) and the theme again with a bell above it (25-32), which breathes
-- back into the intro.
local soundtrack = require("soundtrack")
local song = soundtrack.song{bpm = 92, bars = 32, seed = 7}

-- Each chord: a pad voicing, the bass root and an optional second half (from
-- beat 2) for suspensions that resolve inside the bar.
local A = {
    {pad = {"f3", "a3", "c4", "e4"}, bass = "d2"},              -- Dm9
    {pad = {"f3", "a3", "c4", "d4"}, bass = "bb1"},             -- Bbmaj9
    {pad = {"a3", "c4", "e4", "g4"}, bass = "f2"},              -- Fmaj9
    {pad = {"g3", "c4", "e4", "a4"}, bass = "c2", bass2 = "e2"}, -- C6, walking to E
    {pad = {"f3", "a3", "c4", "e4"}, bass = "d2"},              -- Dm9
    {pad = {"f3", "a3", "c4", "d4"}, bass = "bb1"},             -- Bbmaj9
    {pad = {"f3", "bb3", "d4", "a4"}, bass = "g2"},             -- Gm9
    {pad = {"g3", "d4", "e4", "a4"}, bass = "a1", then_pad = {"g3", "c#4", "e4", "a4"}},   -- A7sus4 -> A7
}
local B = {
    {pad = {"f3", "a3", "d4", "f4"}, bass = "bb1"},             -- Bbmaj7
    {pad = {"g3", "c4", "e4", "g4"}, bass = "c2"},              -- C
    {pad = {"g3", "c4", "e4", "a4"}, bass = "a1"},              -- Am7
    {pad = {"f3", "a3", "c4", "e4"}, bass = "d2"},              -- Dm9
    {pad = {"f3", "bb3", "d4", "a4"}, bass = "g2"},             -- Gm9
    {pad = {"g3", "c4", "f4", "g4"}, bass = "c2", then_pad = {"g3", "c4", "e4", "g4"}},   -- Csus4 -> C
    {pad = {"a3", "c4", "e4", "g4"}, bass = "f2"},              -- Fmaj9
    {pad = {"g3", "d4", "e4", "a4"}, bass = "a1", then_pad = {"g3", "c#4", "e4", "a4"}},   -- A7sus4 -> A7
}
local function chord_of(bar)
    local section = (bar >= 17 and bar <= 24) and B or A
    return section[(bar - 1) % 8 + 1]
end

local function up(pitches, by)
    local out = {}
    for i, p in ipairs(pitches) do out[i] = soundtrack.pitch(p) + by end
    return out
end

-- Harmony: pad, keys comping, bass.
song:each(1, 32, function(bar)
    local c = chord_of(bar)
    local intro = bar <= 8
    if c.then_pad then
        song:chord("pad", bar, 0, 2, c.pad, .5)
        song:chord("pad", bar, 2, 2, c.then_pad, .5)
    else
        song:chord("pad", bar, 0, 4, c.pad, .5)
    end
    -- keys: the top three notes on 1, the "and" of 2, and 4, under the lead
    local top = {c.pad[2], c.pad[3], c.pad[4]}
    local late = c.then_pad and {c.then_pad[2], c.then_pad[3], c.then_pad[4]} or top
    song:chord("keys", bar, 0, 1.4, top, intro and .45 or .5)
    song:chord("keys", bar, 1.5, .9, top, .35)
    song:chord("keys", bar, 3, .8, late, .4)
    -- bass: whole notes to open, then a gentle pattern with the octave
    local root = soundtrack.pitch(c.bass)
    local second = c.bass2 and soundtrack.pitch(c.bass2) or root
    if bar <= 4 then
        song:note("bass", bar, 0, 3.8, root, .7)
    else
        song:note("bass", bar, 0, 1.4, root, .8)
        song:note("bass", bar, 1.5, .45, root, .55)
        song:note("bass", bar, 2, .9, second, .7)
        song:note("bass", bar, 3, .45, second + 12, .5)
        song:note("bass", bar, 3.5, .45, second + 7, .55)
    end
end)

-- Percussion: a shaker joins in bar 5, the soft groove at the theme.
song:each(5, 32, function(bar)
    for e = 0, 7 do song:note("shaker", bar, e * .5, .25, 60, e % 2 == 1 and .8 or .45) end
    if bar < 9 then return end
    song:note("kick", bar, 0, .5, 36, .9)
    song:note("kick", bar, 2, .5, 36, .8)
    if bar % 4 == 0 then song:note("kick", bar, 2.75, .25, 36, .5) end
    song:note("snare", bar, 1, .5, 38, .55)
    song:note("snare", bar, 3, .5, 38, .6)
    if bar % 2 == 0 then song:note("hat", bar, 3.5, 1, 42, .5) end
    if bar == 16 or bar == 24 or bar == 32 then
        song:note("snare", bar, 3.5, .25, 38, .35)
        song:note("snare", bar, 3.75, .25, 38, .45)
    end
end)

-- The theme, and the bridge's answer.
local theme = {
    "r:.5 d5:.5 e5:.5 f5:1.5 e5:.5 d5:.5",
    "c5:1 a4:2 r:1",
    "r:.5 c5:.5 d5:.5 e5:1.5 g5:.5 f5:.5",
    "e5:3 r:1",
    "r:.5 d5:.5 e5:.5 f5:1.5 a5:.5 g5:.5",
    "f5:1 d5:2 c5:.5 d5:.5",
    "bb4:1 d5:1 c5:1.5 bb4:.5",
    "a4:3 r:1",
}
local bridge = {
    "f5:1.5 d5:.5 f5:1 g5:1",
    "e5:1.5 c5:.5 e5:1 g5:1",
    "a5:2 g5:1 e5:1",
    "f5:1.5 e5:.5 d5:1 a4:1",
    "d5:1.5 bb4:.5 d5:1 f5:1",
    "f5:2 e5:2",
    "c5:1 e5:1 g5:1 a5:1",
    "a5:1.5 g5:.5 e5:1 c#5:1",
}
for i = 1, 8 do song:melody("lead", 8 + i, theme[i], .75) end
for i = 1, 8 do song:melody("lead", 16 + i, bridge[i], .8) end
for i = 1, 7 do
    song:melody("lead", 24 + i, theme[i], .75)
    song:melody("bell", 24 + i, theme[i], .4, 12)
end
song:melody("lead", 32, "a4:2 c#5:1 e5:1", .7)
song:melody("bell", 32, "a4:2 c#5:1 e5:1", .35, 12)

-- Plucked sixteenth arpeggios through the bridge and the reprise.
local shape = {1, 2, 3, 4, 3, 2, 1, 2, 3, 4, 5, 4, 3, 2, 3, 4}
song:each(17, 32, function(bar)
    local c = chord_of(bar)
    for s = 0, 15 do
        local pad = (c.then_pad and s >= 8) and c.then_pad or c.pad
        local tones = up(pad, 12)
        tones[5] = tones[1] + 12
        song:note("pluck", bar, s * .25, .22, tones[shape[s + 1]], s % 4 == 0 and .55 or .35)
    end
end)

return song
