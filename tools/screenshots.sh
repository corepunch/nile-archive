#!/usr/bin/env sh
# Regenerate the documentation screenshots headlessly with the software renderer.
#   make shots
set -eu
cd "$(dirname "$0")/.."
tmp="build/shots"
mkdir -p "$tmp"

shot() { # game name size args...
    game=$1 name=$2 size=$3
    shift 3
    # four frames unless the shot names its own (the first --frames on the command line wins)
    case " $* " in *" --frames "*) frames="" ;; *) frames="--frames 4" ;; esac
    "./build/$game" --headless --mute --fresh --size "$size" $frames --shot "$tmp/$game-$name.png" "$@" > /dev/null
    out="games/$game/docs/screenshots/$name.jpg"
    mkdir -p "$(dirname "$out")"
    python3 -c "import sys; from PIL import Image; Image.open(sys.argv[1]).convert('RGB').save(sys.argv[2], quality=86)" \
        "$tmp/$game-$name.png" "$out"
    echo "$out"
}

shot nile-archive island 1200x900 --screen island
shot nile-archive scene0 1200x900 --screen scene0 --found
shot nile-archive scene1 1200x900 --screen scene1
shot nile-archive scene2 1200x900 --screen scene2
shot nile-archive characters 1200x900 --screen cast --frames 30
shot nile-archive chapters 1200x900 --screen chapters --frames 30
shot nile-archive build 1200x900 --screen build
shot nile-archive reward 1200x900 --screen win --frames 60
shot nile-archive widescreen 1600x900 --screen island
shot nile-archive dialogue 1200x900 --screen story --frames 200
shot nile-archive dialogue-horem 1200x900 --screen horem --frames 200
shot nile-archive dialogue-merit 1600x900 --screen merit --frames 200

# Relic Rush: portrait 480 x 900, stills plus two short animated reels
shot relic-rush hex-first 480x900
shot relic-rush hex-late 480x900 --level 8
shot relic-rush island-village 480x900 --showcase
shot relic-rush island-placement 480x900 --city 6 --placing
shot relic-rush island-zones 480x900 --city 3 --overview
shot relic-rush island-unlock 480x900 --city 3 --zone 1
shot relic-rush victory 480x900 --victory
shot relic-rush building-card 480x900 --card 1
shot relic-rush dialogue-elena 480x900 --dialog intro --frames 240
shot relic-rush dialogue-mara 480x900 --dialog mara --frames 240
shot relic-rush dialogue-tomas 480x900 --dialog tomas --frames 240
shot relic-rush dialogue-adrian 480x900 --dialog adrian --frames 240
shot relic-rush island-bubble 480x900 --dialog bubble --frames 30
shot relic-rush phone-island 390x844 --city 3 --safe-area 0,47,0,34
shot relic-rush phone-board 390x844 --safe-area 0,47,0,34
shot relic-rush effect-ray 480x900 --fx ray --frames 10
shot relic-rush effect-bomb 480x900 --fx bomb --frames 10
shot relic-rush effect-prism 480x900 --fx prism --frames 10
for pack in relics jewels resources; do
    "./build/relic-rush" --headless --mute --fresh --size 480x900 --tiles $pack --shot "$tmp/tiles-$pack.png" > /dev/null
done
for level in 1 2 3 4 5 6 7 8 9 10; do
    "./build/relic-rush" --headless --mute --fresh --size 480x900 --frames 3 --level $level --shot "$tmp/shape-$level.png" > /dev/null
done
reel() { # name frames step args...
    name=$1 frames=$2 step=$3
    shift 3
    i=0
    while [ $i -lt "$frames" ]; do
        "./build/relic-rush" --headless --mute --fresh --size 480x900 --frames $((i * step + 1)) --shot "$tmp/$name-$i.png" "$@" > /dev/null
        i=$((i + 1))
    done
}
reel fx-ray 18 2 --fx ray --reel
reel fx-bomb 18 2 --fx bomb --reel
reel fx-prism 18 2 --fx prism --reel
reel result 36 3 --victory --reel
python3 tools/make_reels.py "$tmp" games/relic-rush/docs/screenshots

# Volcano: live campaign stages; previews play normal paid jobs in the simulation.
shot volcano menu 1368x1026
shot volcano outskirts 1368x1026 --level 1
shot volcano suburbs 1368x1026 --level 2
shot volcano square 1368x1026 --level 3
shot volcano district 1368x1026 --level 4
shot volcano centre 1368x1026 --level 5
shot volcano repaired 1368x1026 --level 3 --preview repaired
shot volcano complete 1368x1026 --level 5 --preview complete
shot volcano pause 1368x1026 --level 1 --pause
shot volcano briefing 1368x1026 --level 1 --dialog --frames 150
