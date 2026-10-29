#!/usr/bin/env sh
# Regenerate the documentation screenshots headlessly with the software renderer.
#   make shots
set -eu
cd "$(dirname "$0")/.."
export SDL_VIDEODRIVER="${SDL_VIDEODRIVER:-offscreen}"
tmp="build/shots"
mkdir -p "$tmp"

shot() { # game name size args...
    game=$1 name=$2 size=$3
    shift 3
    "./build/$game" --fresh --size "$size" --frames 4 --shot "$tmp/$game-$name.png" "$@" > /dev/null
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
shot nile-archive characters 1200x900 --screen cast
shot nile-archive reward 1200x900 --screen win
shot nile-archive widescreen 1600x900 --screen island

# Relic Rush: portrait 480 x 900, stills plus two short animated reels
shot relic-rush hex-first 480x900
shot relic-rush hex-late 480x900 --level 8
shot relic-rush island-village 480x900 --showcase
shot relic-rush island-placement 480x900 --city 6 --placing
shot relic-rush island-zones 480x900 --city 3 --overview
shot relic-rush island-unlock 480x900 --city 3 --zone 1
shot relic-rush victory 480x900 --victory
shot relic-rush building-card 480x900 --card 1
shot relic-rush effect-ray 480x900 --fx ray --frames 10
shot relic-rush effect-bomb 480x900 --fx bomb --frames 10
shot relic-rush effect-prism 480x900 --fx prism --frames 10
for level in 1 2 3 4 5 6 7 8 9 10; do
    "./build/relic-rush" --fresh --size 480x900 --frames 3 --level $level --shot "$tmp/shape-$level.png" > /dev/null
done
reel() { # name frames step args...
    name=$1 frames=$2 step=$3
    shift 3
    i=0
    while [ $i -lt "$frames" ]; do
        "./build/relic-rush" --fresh --size 480x900 --frames $((i * step + 1)) --shot "$tmp/$name-$i.png" "$@" > /dev/null
        i=$((i + 1))
    done
}
reel fx-ray 18 2 --fx ray --reel
reel fx-bomb 18 2 --fx bomb --reel
reel fx-prism 18 2 --fx prism --reel
reel result 36 3 --victory --reel
python3 tools/make_reels.py "$tmp" games/relic-rush/docs/screenshots
