-- song.lua — Christmas Market's soundtrack, "Lanterns on the Square": a warm,
-- uplifting F major loop at 96 bpm that stays in the background. Carol-like
-- harmony (F7 into Bb, D7 into Gm) under a rising tune. 32 bars: an intro of
-- pad, keys and bass with a celesta sparkle (1-8), the tune on the soft lead
-- with celesta above and sleigh bells on 2 and 4 (9-16), a middle with plucked
-- arpeggios (17-24) and the tune again with everything (25-32).
local soundtrack = require("soundtrack")
local song = soundtrack.song{bpm = 96, bars = 32, seed = 25}

local A = {
    {pad = {"a3", "c4", "f4", "g4"}, bass = "f2"},              -- Fadd9
    {pad = {"a3", "c4", "d4", "f4"}, bass = "d2"},              -- Dm7
    {pad = {"f3", "bb3", "d4", "f4"}, bass = "g1"},             -- Gm7
    {pad = {"e3", "bb3", "e4", "g4"}, bass = "c2"},             -- C7
    {pad = {"a3", "c4", "f4", "g4"}, bass = "f2"},              -- Fadd9
    {pad = {"a3", "eb4", "f4", "a4"}, bass = "f2"},             -- F7, lifting to Bb
    {pad = {"a3", "d4", "f4", "bb4"}, bass = "bb1"},            -- Bbmaj7
    {pad = {"f3", "bb3", "f4", "g4"}, bass = "c2", then_pad = {"e3", "bb3", "e4", "g4"}},   -- C7sus4 -> C7
}
local B = {
    {pad = {"f3", "bb3", "d4", "f4"}, bass = "bb1"},            -- Bb
    {pad = {"g3", "c4", "e4", "g4"}, bass = "c2"},              -- C
    {pad = {"g3", "c4", "e4", "a4"}, bass = "a1"},              -- Am7
    {pad = {"f#3", "c4", "d4", "a4"}, bass = "d2"},             -- D7, lifting to Gm
    {pad = {"f3", "bb3", "d4", "g4"}, bass = "g1"},             -- Gm7
    {pad = {"e3", "bb3", "e4", "g4"}, bass = "c2"},             -- C7
    {pad = {"a3", "c4", "f4", "g4"}, bass = "f2"},              -- Fadd9
    {pad = {"f3", "bb3", "f4", "g4"}, bass = "c2", then_pad = {"e3", "bb3", "e4", "g4"}},   -- C7sus4 -> C7
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

-- Harmony: pad, keys on 1, the "and" of 2 and 4, and a gently bouncing bass.
song:each(1, 32, function(bar)
    local c = chord_of(bar)
    local late_pad = c.then_pad or c.pad
    if c.then_pad then
        song:chord("pad", bar, 0, 2, c.pad, .5)
        song:chord("pad", bar, 2, 2, c.then_pad, .5)
    else
        song:chord("pad", bar, 0, 4, c.pad, .5)
    end
    song:chord("keys", bar, 0, 1.4, {c.pad[2], c.pad[3], c.pad[4]}, .42)
    song:chord("keys", bar, 1.5, .9, {c.pad[2], c.pad[3], c.pad[4]}, .3)
    song:chord("keys", bar, 3, .8, {late_pad[2], late_pad[3], late_pad[4]}, .35)
    local root = soundtrack.pitch(c.bass)
    if bar <= 4 then
        song:note("bass", bar, 0, 3.8, root, .65)
    else
        song:note("bass", bar, 0, 1.4, root, .75)
        song:note("bass", bar, 2, .9, root + 7, .6)
        song:note("bass", bar, 3, .45, root + 12, .45)
        song:note("bass", bar, 3.5, .45, root + 7, .5)
    end
end)

-- A celesta sparkle announces the tune: the chord's top notes, rising.
song:each(5, 8, function(bar)
    local tones = up(chord_of(bar).pad, 24)
    for q = 0, 3 do song:note("bell", bar, q, .9, tones[q + 1], .22) end
end)

-- Percussion: sleigh bells on 2 and 4, a soft kick and snare under them.
song:each(9, 32, function(bar)
    song:note("jingle", bar, 1, .25, 60 + bar, .32)
    song:note("jingle", bar, 3, .25, 61 + bar, .32)
    song:note("kick", bar, 0, .5, 36, .6)
    song:note("kick", bar, 2, .5, 36, .5)
    song:note("snare", bar, 1, .5, 38, .28)
    song:note("snare", bar, 3, .5, 38, .32)
    if bar == 16 or bar == 24 or bar == 32 then song:note("snare", bar, 3.5, .25, 38, .25) end
end)
for _, bar in ipairs({1, 9, 17, 25}) do song:note("jingle", bar, 0, .25, 70 + bar, .45) end

local tune = {
    "c5:1 f5:1 g5:1 a5:1",
    "a5:1.5 g5:.5 f5:2",
    "bb5:1 a5:1 g5:1 f5:1",
    "e5:1.5 f5:.5 g5:2",
    "c5:1 f5:1 g5:1 a5:1",
    "c6:1.5 bb5:.5 a5:2",
    "d6:1 c6:1 bb5:1 a5:1",
    "g5:2 e5:1 g5:1",
}
local middle = {
    "f5:1 g5:1 bb5:2",
    "c6:1.5 g5:.5 e5:2",
    "a5:1 g5:1 e5:1 c5:1",
    "d5:1 f#5:1 a5:1 c6:1",
    "bb5:1.5 a5:.5 g5:2",
    "e5:1 g5:1 bb5:1 g5:1",
    "a5:2 c6:1 a5:1",
    "f5:1 g5:1 e5:1 g5:1",
}
for i = 1, 8 do
    song:melody("lead", 8 + i, tune[i], .7)
    song:melody("bell", 8 + i, tune[i], .28, 12)
end
for i = 1, 8 do song:melody("lead", 16 + i, middle[i], .72) end
for i = 1, 8 do
    song:melody("lead", 24 + i, tune[i], .72)
    song:melody("bell", 24 + i, tune[i], .34, 12)
end

-- Plucked eighths through the middle and the reprise.
local shape = {1, 2, 3, 4, 3, 2, 3, 4}
song:each(17, 32, function(bar)
    local c = chord_of(bar)
    for e = 0, 7 do
        local pad = (c.then_pad and e >= 4) and c.then_pad or c.pad
        song:note("pluck", bar, e * .5, .4, up(pad, 12)[shape[e + 1]], e % 4 == 0 and .42 or .27)
    end
end)

return song
