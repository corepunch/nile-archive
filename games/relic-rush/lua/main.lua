-- Relic Rush · The Lost Valley — hex straight-line match-3 expeditions that restore an island.
--
-- The game is data: lua/game_config.lua (words), lua/town_config.lua (the town), the
-- campaign, story and building tables, skin.lua, art.lua and the PNGs. The
-- flow around the board, every dialog, the shop, the level list, saving and
-- the debug entry points are the engine's (engine/match3_game.lua); board.lua
-- and screens.lua paint the game's own art. See docs/PORTRAIT_GAMES.md.
local R = require("state")
require("screens")
require("board")
require("finale")
require("narrative")
require("quests")
require("progress")
require("smoke")
require("user_events_runtime")   -- after every hook it wraps

return require("match3.game").app(R)
