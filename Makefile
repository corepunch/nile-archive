# Shared sprite engine + games.
#
#   make                 build every game natively (needs SDL2 development files)
#   make run-nile        build and run Nile Archive        (also: run-relic)
#   make test            engine and game-logic tests (headless)
#   make shots           regenerate docs/screenshots (headless, software renderer)
#   make web             WebAssembly builds into dist/<game>/ (needs Emscripten's emcc)
#   make clean

GAMES   := nile-archive relic-rush
ENGINE  := core gfx font ui save city audio story
CC      ?= cc
CFLAGS  ?= -O2 -g
# CFLAGS is yours to override (make CFLAGS="-O0 -g -Werror"); the essentials live in ALL_CFLAGS
# zero is a valid default everywhere, so partial initialisers ({"who", "text"}) are idiomatic
ALL_CFLAGS = $(CFLAGS) -std=c11 -Wall -Wextra -Wno-unused-parameter -Wno-missing-field-initializers -Iengine
SDL_CFLAGS := $(shell pkg-config --cflags sdl2 2>/dev/null || sdl2-config --cflags 2>/dev/null)
SDL_LIBS   := $(shell pkg-config --libs sdl2 2>/dev/null || sdl2-config --libs 2>/dev/null)
LIBS    := $(SDL_LIBS) -lm

ENGINE_OBJ := $(ENGINE:%=build/engine/%.o)
game_src    = $(wildcard games/$(1)/*.c)

.PHONY: all test shots web clean run-nile run-relic $(GAMES)
all: $(GAMES)

build/engine/%.o: engine/%.c engine/engine.h
	@mkdir -p $(dir $@)
	$(CC) $(ALL_CFLAGS) $(SDL_CFLAGS) -c $< -o $@

define GAME_RULES
$(1): build/$(1)
build/$(1): $(ENGINE_OBJ) $(call game_src,$(1)) $(wildcard games/$(1)/*.h) engine/engine.h
	@mkdir -p build
	$$(CC) $$(ALL_CFLAGS) $$(SDL_CFLAGS) -DGAME_DATA_DIR='"games/$(1)/data"' -o $$@ $(call game_src,$(1)) $(ENGINE_OBJ) $$(LIBS)
endef
$(foreach g,$(GAMES),$(eval $(call GAME_RULES,$(g))))

run-nile: build/nile-archive
	./build/nile-archive
run-relic: build/relic-rush
	./build/relic-rush

# Tests link the games' rule files (no main) together with the engine.
TEST_SRC := tests/test_main.c tests/test_relic.c games/relic-rush/rules.c games/relic-rush/island.c
build/tests: $(TEST_SRC) $(ENGINE_OBJ) engine/engine.h games/relic-rush/relic.h
	$(CC) $(ALL_CFLAGS) $(SDL_CFLAGS) -Igames/relic-rush -o $@ $(TEST_SRC) $(ENGINE_OBJ) $(LIBS)

test: build/tests
	SDL_VIDEODRIVER=dummy XDG_DATA_HOME=$(CURDIR)/build/test-home ./build/tests

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
dist/$(1)/index.html: $(ENGINE:%=engine/%.c) engine/engine.h web/shell.html $(call game_src,$(1)) $(wildcard games/$(1)/*.h) $(shell find games/$(1)/data -type f 2>/dev/null)
	@mkdir -p dist/$(1)
	$$(EMCC) $$(WEB_FLAGS) -DGAME_DATA_DIR='"/data"' -o $$@ $(ENGINE:%=engine/%.c) $(call game_src,$(1)) --preload-file games/$(1)/data@/data
endef
$(foreach g,$(GAMES),$(eval $(call WEB_RULES,$(g))))

clean:
	rm -rf build dist
