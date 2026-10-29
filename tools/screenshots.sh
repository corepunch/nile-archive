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

shot relic-rush camp 1200x900 --screen camp
shot relic-rush board 1200x900 --screen board
shot relic-rush win 1200x900 --screen win
shot relic-rush fail 1200x900 --screen fail
shot relic-rush levels 1200x900 --screen levels
shot relic-rush portrait-board 600x1200 --screen board
shot relic-rush portrait-camp 600x1200 --screen camp
