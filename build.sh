#!/usr/bin/env sh
set -eu
cd "$(dirname "$0")"
mkdir -p dist
emcc game.c -s USE_SDL=2 -O2 \
  --preload-file scene.bmp --preload-file scene1.bmp --preload-file scene2.bmp \
  --preload-file island.bmp --preload-file atlas.bmp \
  -s ALLOW_MEMORY_GROWTH=1 \
  -s EXPORTED_FUNCTIONS='["_main","_view","_tap","_showhint","_pan","_magnify","_place","_restore","_coord","_unlock","_resize"]' \
  -s EXPORTED_RUNTIME_METHODS='["ccall"]' \
  -o dist/game.js
