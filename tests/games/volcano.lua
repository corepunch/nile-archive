-- Volcano: every test, in one start of build/test/volcano. See docs/TESTING.md.
rules("volcano")
smoke("--size 456x342")

shot("menu", "1368x1026")
shot("outskirts", "1368x1026", "--level 1")
shot("suburbs", "1368x1026", "--level 2")
shot("square", "1368x1026", "--level 3")
shot("district", "1368x1026", "--level 4")
shot("centre", "1368x1026", "--level 5")
shot("repaired", "1368x1026", "--level 3 --preview repaired")
shot("complete", "1368x1026", "--level 5 --preview complete")
shot("pause", "1368x1026", "--level 1 --pause")
shot("briefing", "1368x1026", "--level 1 --dialog --frames 150")
