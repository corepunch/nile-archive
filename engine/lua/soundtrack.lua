-- soundtrack.lua — compose looping songs for the music synthesiser.
--
--   local soundtrack = require("soundtrack")
--   local song = soundtrack.song{bpm = 92, bars = 32}
--   song:chord("pad", 1, 0, 4, {"f3", "a3", "c4", "e4"}, .5)
--   song:melody("lead", 9, "r:.5 d5:.5 e5:.5 f5:1.5 e5:.5 d5:.5", .8)
--   soundtrack.play(song)
--
-- Bars count from 1 and beats within a bar from 0. Pitches are MIDI numbers or
-- note names: a letter, an optional # or b, then the octave ("c#5", "bb3").
-- Notes get a small deterministic velocity variation so repeats breathe.
local soundtrack = {}

local INSTRUMENTS = {
    pad = music.PAD, keys = music.KEYS, bass = music.BASS, pluck = music.PLUCK, bell = music.BELL,
    lead = music.LEAD, kick = music.KICK, snare = music.SNARE, hat = music.HAT, shaker = music.SHAKER,
    jingle = music.JINGLE,
}
local STEPS = {c = 0, d = 2, e = 4, f = 5, g = 7, a = 9, b = 11}

function soundtrack.pitch(name)
    if type(name) == "number" then return name end
    local letter, accidental, octave = name:match("^(%a)([#b]?)(%-?%d)$")
    assert(letter and STEPS[letter], "soundtrack: bad note name " .. tostring(name))
    return 12 * (tonumber(octave) + 1) + STEPS[letter] + (accidental == "#" and 1 or accidental == "b" and -1 or 0)
end

local Song = {}
Song.__index = Song

function soundtrack.song(o)
    local song = setmetatable({bpm = o.bpm, bars = o.bars, meter = o.meter or 4, notes = {}, seed = o.seed or 1}, Song)
    song.beats = song.bars * song.meter
    return song
end

function Song:wobble(amount)   -- deterministic, so a song always sounds the same
    self.seed = (self.seed * 1103515245 + 12345) % 2147483648
    return (self.seed / 2147483648 - .5) * 2 * amount
end

function Song:note(instrument, bar, beat, length, pitch, velocity)
    local inst = assert(INSTRUMENTS[instrument], "soundtrack: unknown instrument " .. tostring(instrument))
    local at = (bar - 1) * self.meter + beat
    if at < 0 or at >= self.beats then return end
    local vel = (velocity or .8) * (1 + self:wobble(.08))
    self.notes[#self.notes + 1] = {inst, at, length, soundtrack.pitch(pitch or 60), vel}
end

function Song:chord(instrument, bar, beat, length, pitches, velocity)
    for _, p in ipairs(pitches) do self:note(instrument, bar, beat, length, p, velocity) end
end

-- "d5:.5 r:1 f#5:1.5" — note:length tokens played one after another; r rests.
-- Returns the beat after the last token, relative to bar's start.
function Song:melody(instrument, bar, tokens, velocity, transpose, legato)
    local beat = 0
    for name, length in tokens:gmatch("([%w#]+):([%d%.]+)") do
        length = tonumber(length)
        if name ~= "r" then
            self:note(instrument, bar, beat, length * (legato or .92), soundtrack.pitch(name) + (transpose or 0), velocity)
        end
        beat = beat + length
    end
    return beat
end

-- Play `pattern` (a function of bar number) over bars first..last.
function Song:each(first, last, pattern)
    for bar = first, last do pattern(bar) end
end

local current
function soundtrack.play(song)
    if current == song and music.playing() then return end
    current = song
    music.clear()
    for _, n in ipairs(song.notes) do music.note(n[1], n[2], n[3], n[4], n[5]) end
    music.play(song.bpm, song.beats)
end

function soundtrack.stop(fade)
    current = nil
    music.stop(fade or 1)
end

function soundtrack.current() return current end

return soundtrack
