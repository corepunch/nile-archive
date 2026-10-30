# Shared sprite engine + games written in Lua.
#
#   make                 build every game natively (needs SDL2 development files)
#   make run-nile        build and run Nile Archive        (also: run-relic)
#   make test            generated-code freshness, engine tests and the games' Lua rule tests (headless)
#   make gen             regenerate the Lua glue, docs/LUA_API.md and engine.d.lua from engine/api.xml
#   make shots           regenerate docs/screenshots (headless, software renderer)
#   make web             WebAssembly builds into dist/<game>/ (needs Emscripten's emcc)
#   make clean

GAMES   := nile-archive relic-rush
ENGINE  := core gfx font ui save city audio story script api_lua
CC      ?= cc
CFLAGS  ?= -O2 -g
# CFLAGS is yours to override (make CFLAGS="-O0 -g -Werror"); the essentials live in ALL_CFLAGS
# zero is a valid default everywhere, so partial initialisers ({"who", "text"}) are idiomatic
ALL_CFLAGS = $(CFLAGS) -std=c11 -Wall -Wextra -Wno-unused-parameter -Wno-missing-field-initializers -Iengine
SDL_CFLAGS := $(shell pkg-config --cflags sdl2 2>/dev/null || sdl2-config --cflags 2>/dev/null)
SDL_LIBS   := $(shell pkg-config --libs sdl2 2>/dev/null || sdl2-config --libs 2>/dev/null)
LIBS    := $(SDL_LIBS) -lm

# Lua 5.4: the lua/lua git mirror as a submodule in engine/third_party/lua (MIT),
# pinned to a release tag and built as one translation unit (engine/lua_lib.c).
LUA_DIR    := engine/third_party/lua
LUA_SRC    := engine/lua_lib.c
LUA_FLAGS  := -Wno-unused-function
ENGINE_OBJ := $(ENGINE:%=build/engine/%.o) build/engine/lua.o
game_lua    = $(wildcard games/$(1)/lua/*.lua)

.PHONY: all test gen gen-check shots web clean run-nile run-relic $(GAMES)
all: $(GAMES)

build/engine/%.o: engine/%.c engine/engine.h engine/api_lua.h
	@mkdir -p $(dir $@)
	$(CC) $(ALL_CFLAGS) $(SDL_CFLAGS) -c $< -o $@

$(LUA_DIR)/lua.h:
	@echo "Lua sources missing: run 'git submodule update --init' (the Lua interpreter is a submodule)" >&2; exit 1

build/engine/lua.o: $(LUA_SRC) $(LUA_DIR)/lua.h $(wildcard $(LUA_DIR)/*.c) $(wildcard $(LUA_DIR)/*.h)
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -std=c11 -Wall $(LUA_FLAGS) -c $< -o $@

# Every game is the same launcher pointed at games/<name>: lua/ for code, data/ for assets.
define GAME_RULES
$(1): build/$(1)
build/$(1): $(ENGINE_OBJ) engine/launcher.c engine/engine.h
	@mkdir -p build
	$$(CC) $$(ALL_CFLAGS) $$(SDL_CFLAGS) -DGAME_DIR='"games/$(1)"' -o $$@ engine/launcher.c $(ENGINE_OBJ) $$(LIBS)
endef
$(foreach g,$(GAMES),$(eval $(call GAME_RULES,$(g))))

run-nile: build/nile-archive
	./build/nile-archive
run-relic: build/relic-rush
	./build/relic-rush

# --- generated Lua glue ---------------------------------------------------
# engine/api.xml describes the API once; tools/luagen.py writes the glue, the
# reference and the editor annotations. They are committed, so building needs
# no Python; `make test` fails when they are stale.
GENERATED := engine/api_lua.c engine/api_lua.h docs/LUA_API.md engine/engine.d.lua
gen:
	python3 tools/luagen.py
gen-check:
	python3 tools/luagen.py --check

# --- tests ----------------------------------------------------------------
# Engine tests in C, then the games' rules in Lua (tests/lua/*.lua) run by the
# same binary through the engine's Lua state, without a window.
TEST_SRC := tests/test_main.c
build/tests: $(TEST_SRC) $(ENGINE_OBJ) engine/engine.h
	$(CC) $(ALL_CFLAGS) $(SDL_CFLAGS) -o $@ $(TEST_SRC) $(ENGINE_OBJ) $(LIBS)

test: gen-check build/tests
	SDL_VIDEODRIVER=dummy XDG_DATA_HOME=$(CURDIR)/build/test-home ./build/tests tests/lua/*.lua

shots: all
	./tools/screenshots.sh

# --- WebAssembly (Emscripten) ------------------------------------------------
# gnu11 rather than c11: Emscripten's EM_JS/EM_ASM macros need GNU extensions.
EMCC      ?= emcc
WEB_FLAGS := -std=gnu11 -O2 -Iengine -sUSE_SDL=2 -sALLOW_MEMORY_GROWTH=1 -sINITIAL_MEMORY=64MB \
             -sEXPORTED_FUNCTIONS=_main,_malloc,_free \
             -sEXPORTED_RUNTIME_METHODS=ccall,UTF8ToString,stringToUTF8,lengthBytesUTF8 \
             '-sDEFAULT_LIBRARY_FUNCS_TO_INCLUDE=$$UTF8ToString,$$stringToUTF8,$$lengthBytesUTF8' \
             --shell-file web/shell.html

web: $(GAMES:%=dist/%/index.html)

define WEB_RULES
dist/$(1)/index.html: $(ENGINE:%=engine/%.c) $(LUA_SRC) $(LUA_DIR)/lua.h engine/launcher.c engine/engine.h engine/api_lua.h web/shell.html $(call game_lua,$(1)) $(shell find games/$(1)/data -type f 2>/dev/null)
	@mkdir -p dist/$(1)
	$$(EMCC) $$(WEB_FLAGS) $(LUA_FLAGS) -DGAME_DIR='"/game"' -DGAME_DATA_DIR='"/data"' -DGAME_LUA_DIR='"/lua"' -o $$@ \
	    engine/launcher.c $(ENGINE:%=engine/%.c) $(LUA_SRC) \
	    --preload-file games/$(1)/data@/data --preload-file games/$(1)/lua@/lua
endef
$(foreach g,$(GAMES),$(eval $(call WEB_RULES,$(g))))

clean:
	rm -rf build dist
