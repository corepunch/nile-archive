-- Nile Archive's popups and item bar move on the engine's tween module
-- (docs/MOTION.md): a popup pops in with its backdrop and staggered stars, a
-- name pill arrives, is struck through and leaves, and stills open at rest.
local G = require("archive_state")
local scene = require("archive_scene")

testing.reset()
G.open_modal(G.MODAL_WIN)
local d = G.dialog
check(d.pop == 0 and d.backdrop == 0 and d.tl.paused, "a popup opens paused, until any dialogue is over")
d.tl:resume()
tween.update(.1)
check(d.pop > 0 and d.pop < 1.2, "the box pops in with a little overshoot")
near(d.backdrop, .4, "the backdrop fades in linearly over a quarter second")
tween.update(.15)
check(d.pop == 1 and d.backdrop == 1 and d.stars[1].s == 0, "the box settles before the stars")
tween.update(.3)
check(d.stars[1].s > 0 and d.stars[2].s == 0, "stars arrive one by one")
tween.update(.7)
check(d.stars[1].s == 1 and d.stars[3].s == 1 and d.tl:is_done(), "every star has landed by 1.12 s")

G.open_modal(G.MODAL_WIN, true)
check(G.dialog.pop == 1 and G.dialog.backdrop == 1 and G.dialog.stars[3].s == 1, "stills open a popup settled")

-- the item bar
G.found, G.slots, G.pills, G.marks = {}, {}, {}, {}
scene.refill_slots(0, 0)
check(G.slots[1] == 1 and G.slots[3] == 3 and G.pills[1].arrive == 0, "a refilled pill starts its arrival at once")
tween.update(.03)
check(G.pills[1].arrive > 0 and G.pills[1].arrive < 1, "the name slides up into its pill")
tween.update(.22)
check(G.pills[1].arrive == 1, "and settles in a quarter second")
scene.refill_slots(0, 0)
scene.settle_slots()
check(G.pills[2].arrive == 1 and not tween.is_tweening(G.pills[2]), "the opening list is simply there")

G.found[2] = 0
scene.show_found(2)
local p = G.pills[2]
check(G.marks[2].r == 0 and p.strike == 0 and p.leave == 0, "a find starts its ring and its strike-through")
tween.update(.2)
check(G.marks[2].r > 0, "the ring grows on the item")
near(p.strike, .2 / .45, "the strike runs across the name for .45 s")
check(p.leave == 0, "the pill stays while the strike runs")
tween.update(.3)
check(p.strike == 1 and p.leave == 0, "the strike completes and the drop is queued")
tween.update(.2)
check(p.leave > 0 and p.leave < 1, "then the pill drops away")
tween.update(.2)
check(p.leave == 1, "and is gone by the time refill_slots replaces it")
scene.refill_slots(1, .8)
check(G.slots[2] == 4 and G.pills[2].arrive == 0 and G.pills[2].leave == 0, "the next name takes the slot and arrives")

-- reduced motion settles everything on the next frame
tween.instant(true)
G.open_modal(G.MODAL_PAUSE)
G.dialog.tl:resume()
tween.update(1 / 60)
check(G.dialog.pop == 1 and G.dialog.backdrop == 1, "reduced motion shows a popup at once")
tween.instant(false)
testing.reset()
