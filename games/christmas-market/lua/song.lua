-- song.lua — Christmas Market's soundtrack, "Lanterns on the Square": a calm
-- F major loop at 84 bpm that stays in the background. 32 bars: an intro of
-- pad, keys and bass (1-8), the tune on the soft lead with a light groove
-- (9-16), a warmer middle with slow plucked arpeggios (17-24) and the tune
-- again with a quiet celesta above it (25-32). Sleigh bells only mark the
-- start of each eight-bar phrase.
local soundtrack = require("soundtrack")
local song = soundtrack.song{bpm = 84, bars = 32, seed = 25}

local A = {
    {pad = {"a3", "c4", "f4", "g4"}, bass = "f2"},              -- Fadd9
    {pad = {"g3", "c4", "e4", "g4"}, bass = "e2"},              -- C/E
    {pad = {"a3", "c4", "d4", "f4"}, bass = "d2"},              -- Dm7
    {pad = {"f3", "bb3", "d4", "f4"}, bass = "bb1", then_pad = {"g3", "c4", "e4", "g4"}, then_bass = "c2"},   -- Bb -> C
    {pad = {"a3", "c4", "f4", "g4"}, bass = "f2"},              -- Fadd9
    {pad = {"g3", "c4", "e4", "a4"}, bass = "a1"},              -- Am7
    {pad = {"a3", "d4", "f4", "bb4"}, bass = "bb1"},            -- Bbmaj7
    {pad = {"f3", "bb3", "f4", "g4"}, bass = "c2", then_pad = {"e3", "bb3", "e4", "g4"}},   -- C7sus4 -> C7
}
local B = {
    {pad = {"f3", "bb3", "d4", "f4"}, bass = "bb1"},            -- Bb
    {pad = {"g3", "c4", "e4", "g4"}, bass = "c2"},              -- C
    {pad = {"g3", "c4", "e4", "a4"}, bass = "a1"},              -- Am7
    {pad = {"a3", "c4", "d4", "f4"}, bass = "d2"},              -- Dm7
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

-- Harmony: pad, soft keys on 1 and the "and" of 2, a walking bass.
song:each(1, 32, function(bar)
    local c = chord_of(bar)
    local late_pad = c.then_pad or c.pad
    if c.then_pad then
        song:chord("pad", bar, 0, 2, c.pad, .5)
        song:chord("pad", bar, 2, 2, c.then_pad, .5)
    else
        song:chord("pad", bar, 0, 4, c.pad, .5)
    end
    song:chord("keys", bar, 0, 1.4, {c.pad[2], c.pad[3], c.pad[4]}, .4)
    song:chord("keys", bar, 2.5, 1.2, {late_pad[2], late_pad[3], late_pad[4]}, .3)
    local root = soundtrack.pitch(c.bass)
    local late_root = c.then_bass and soundtrack.pitch(c.then_bass) or root
    if bar <= 4 then
        song:note("bass", bar, 0, 3.8, root, .65)
    else
        song:note("bass", bar, 0, 1.8, root, .75)
        song:note("bass", bar, 2, 1.4, late_root, .6)
        song:note("bass", bar, 3.5, .45, late_root + 7, .45)
    end
end)

-- Percussion: a quiet brush of kick and snare with the tune; sleigh bells
-- only at the top of each phrase.
for _, bar in ipairs({1, 9, 17, 25}) do song:note("jingle", bar, 0, .25, 60 + bar, .4) end
song:each(9, 32, function(bar)
    song:note("kick", bar, 0, .5, 36, .6)
    song:note("kick", bar, 2.5, .5, 36, .45)
    song:note("snare", bar, 2, .5, 38, .35)
    for e = 0, 3 do song:note("shaker", bar, e + .5, .25, 60, .35) end
end)

local tune = {
    "c5:1 f5:1 a5:1.5 g5:.5",
    "g5:2 e5:1 c5:1",
    "d5:1 f5:1 a5:1 g5:1",
    "f5:2 e5:2",
    "c5:1 f5:1 a5:1.5 c6:.5",
    "c6:1.5 a5:.5 g5:2",
    "f5:1 d5:1 f5:1 a5:1",
    "g5:3 r:1",
}
local middle = {
    "f5:1.5 d5:.5 bb4:2",
    "c5:1 e5:1 g5:2",
    "a5:1.5 g5:.5 e5:2",
    "f5:1.5 e5:.5 d5:2",
    "d5:1 g5:1 f5:1 d5:1",
    "e5:1.5 g5:.5 bb5:2",
    "a5:2 f5:1 c5:1",
    "f5:1 g5:1 e5:2",
}
for i = 1, 8 do song:melody("lead", 8 + i, tune[i], .7) end
for i = 1, 8 do song:melody("lead", 16 + i, middle[i], .7) end
for i = 1, 8 do
    song:melody("lead", 24 + i, tune[i], .65)
    song:melody("bell", 24 + i, tune[i], .22, 12)
end

-- Slow plucked eighths through the middle and the reprise.
local shape = {1, 2, 3, 4, 3, 2, 3, 4}
song:each(17, 32, function(bar)
    local c = chord_of(bar)
    for e = 0, 7 do
        local pad = (c.then_pad and e >= 4) and c.then_pad or c.pad
        song:note("pluck", bar, e * .5, .4, up(pad, 12)[shape[e + 1]], e % 4 == 0 and .4 or .25)
    end
end)

return song
