# Shared sprite engine + games written in Lua.
#
#   make                 build every game natively (uses the shared platform submodule)
#   make run-nile-archive build and run Nile Archive        (alias: run-nile)
#   make run-relic-rush   build and run Relic Rush          (alias: run-relic)
#   make run-volcano      build and run Volcano
#   make run-volcano ARGS="--fresh --mute"                 pass game options
#   make test            generated-code freshness, engine tests and the games' Lua rule tests (headless)
#   make lint            luacheck over every game, the engine's Lua and the tests (apt: lua-check)
#   make gen             regenerate the Lua glue, docs/LUA_API.md and engine.d.lua from engine/api.xml
#   make xcode           regenerate games/<name>/<name>.xcodeproj (tools/xcode/generate.py)
#   make shots           regenerate docs/screenshots (headless, software renderer)
#   make web             WebAssembly builds into dist/<game>/ (needs Emscripten's emcc)
#   make clean

GAMES   := nile-archive relic-rush christmas-market volcano clayfight
CC      ?= cc
CFLAGS  ?= -O2 -g
ARGS    ?=
# CFLAGS is yours to override (make CFLAGS="-O0 -g -Werror"); the essentials live in ALL_CFLAGS
# zero is a valid default everywhere, so partial initialisers ({"who", "text"}) are idiomatic
ALL_CFLAGS = $(CFLAGS) -std=c11 -Wall -Wextra -Wno-unused-parameter -Wno-missing-field-initializers -Iengine -D_DEFAULT_SOURCE
# Platform is compiled into each app, with no embedded third-party framework.
PLATFORM_DIR := engine/third_party/platform
ifeq ($(shell uname -s),Darwin)
PLATFORM_FLAGS := -x objective-c -Wno-deprecated-declarations
PLATFORM_LIBS := -framework AppKit -framework OpenGL -framework IOSurface -framework Security -framework AudioToolbox
else
# X11 is the default (also works under Xvfb for CI); make WINDOW_SYSTEM=wayland
WINDOW_SYSTEM ?= x11
ifeq ($(WINDOW_SYSTEM),wayland)
PLATFORM_FLAGS := -DENGINE_WAYLAND $(shell pkg-config --cflags wayland-client wayland-egl xkbcommon egl gl)
PLATFORM_LIBS := $(shell pkg-config --libs wayland-client wayland-egl xkbcommon egl gl)
else
PLATFORM_FLAGS := $(shell pkg-config --cflags x11 egl gl)
PLATFORM_LIBS := $(shell pkg-config --libs x11 egl gl)
endif
ALSA_LIBS := $(shell pkg-config --libs alsa 2>/dev/null)
ifneq ($(ALSA_LIBS),)
PLATFORM_FLAGS += -DHAVE_ALSA $(shell pkg-config --cflags alsa)
PLATFORM_LIBS += $(ALSA_LIBS)
endif
PLATFORM_LIBS += -ldl -lpthread
endif
LIBS := $(PLATFORM_LIBS) -lm

# Lua 5.4: the lua/lua git mirror as a submodule in engine/third_party/lua (MIT),
# pinned to a release tag and built as one translation unit (engine/lua_lib.c).
LUA_DIR    := engine/third_party/lua
UNITY      := tools/unity.sh
LUA_FLAGS  := -Wno-unused-function
ENGINE_OBJ := build/engine/engine.o build/engine/script.o build/engine/lua.o build/engine/platform.o
ENGINE_DEPS := $(UNITY) $(wildcard engine/*.c engine/*.h)
PLATFORM_DEPS := $(shell find $(PLATFORM_DIR) -type f \( -name '*.c' -o -name '*.m' -o -name '*.h' \) 2>/dev/null)
game_lua    = $(wildcard games/$(1)/lua/*.lua)

.PHONY: all test gen gen-check lint xcode xcode-check shots web clean run-nile run-relic $(GAMES:%=run-%) $(GAMES)
all: $(GAMES)

build/engine/%.o: $(ENGINE_DEPS)
	@mkdir -p $(dir $@)
	sh $(UNITY) $* | $(CC) $(ALL_CFLAGS) -x c -c -o $@ -

$(LUA_DIR)/lua.h:
	@echo "Lua sources missing: run 'git submodule update --init' (the Lua interpreter is a submodule)" >&2; exit 1

build/engine/lua.o: $(UNITY) engine/lua_lib.c $(LUA_DIR)/lua.h $(wildcard $(LUA_DIR)/*.c) $(wildcard $(LUA_DIR)/*.h)
	@mkdir -p $(dir $@)
	sh $(UNITY) lua | $(CC) $(CFLAGS) -std=c11 -Wall $(LUA_FLAGS) -Iengine -x c -c -o $@ -

build/engine/platform.o: $(UNITY) engine/web_audio.c $(PLATFORM_DEPS)
	@mkdir -p $(dir $@)
	sh $(UNITY) platform | $(CC) $(CFLAGS) -std=gnu11 -Wall -Iengine -x c $(PLATFORM_FLAGS) -c -o $@ -

# Every game is the same launcher pointed at games/<name>: lua/ for code, data/ for assets.
define GAME_RULES
$(1): build/$(1)
build/$(1): $(ENGINE_OBJ) engine/launcher.c engine/engine.h
	@mkdir -p build
	$$(CC) $$(ALL_CFLAGS) -DGAME_DIR='"games/$(1)"' -o $$@ engine/launcher.c $(ENGINE_OBJ) $$(LIBS)
run-$(1): build/$(1)
	./build/$(1) $$(ARGS)
endef
$(foreach g,$(filter-out clayfight,$(GAMES)),$(eval $(call GAME_RULES,$(g))))
include games/clayfight/Makefile.inc

run-nile: run-nile-archive
run-relic: run-relic-rush

# --- generated Lua glue ---------------------------------------------------
# engine/api.xml describes the API once; tools/luagen.py writes the glue, the
# reference and the editor annotations. They are committed, so building needs
# no Python; `make test` fails when they are stale.
GENERATED := engine/api_lua.c engine/api_lua.h docs/LUA_API.md engine/engine.d.lua engine/ui_forms_lua.h
gen:
	python3 tools/luagen.py
gen-check:
	python3 tools/luagen.py --check

# --- lint -----------------------------------------------------------------
# .luacheckrc declares the engine's globals, so an undefined global is a typo
# or a missing import and an unused local is dead code.
lint:
	luacheck -q games/*/lua engine/ui_forms.lua engine/city_smoke.lua tests/lua tests/fixtures tools/*.lua

# --- Xcode projects -------------------------------------------------------
# One committed project per game with a macOS and an iOS target (iPad for Nile
# Archive, iPhone for Relic Rush), generating temporary unity units at build time.
# See tools/xcode/README.md.
xcode:
	for g in $(GAMES); do python3 tools/xcode/generate.py $$g --unsigned; done
xcode-check:
	python3 tools/xcode/generate.py --check

# --- tests ----------------------------------------------------------------
# Engine tests in C, then the games' rules in Lua (tests/lua/*.lua) run by the
# same binary through the engine's Lua state, without a window.
TEST_SRC := tests/test_main.c
build/tests: $(TEST_SRC) $(ENGINE_OBJ) engine/engine.h
	$(CC) $(ALL_CFLAGS) -o $@ $(TEST_SRC) $(ENGINE_OBJ) $(LIBS)

build/test-audio: tests/test_audio.c engine/audio.c engine/engine.h
	@mkdir -p build
	$(CC) $(ALL_CFLAGS) -o $@ tests/test_audio.c engine/audio.c -lm

test: gen-check xcode-check build/tests build/test-audio test-clayfight
	./build/test-audio
	python3 games/volcano/tools/check_assets.py
	python3 games/relic-rush/tools/check_art_catalogue.py
	python3 games/christmas-market/tools/check_assets.py
	python3 games/relic-rush/tools/prepare_hud.py --check
	python3 games/relic-rush/tools/building_assets.py --check
	@mkdir -p build/test-home
	SPRITE_SAVE_DIR=$(CURDIR)/build/test-home ./build/tests $(filter-out tests/lua/christmas.lua,$(wildcard tests/lua/*.lua))
	SPRITE_SAVE_DIR=$(CURDIR)/build/test-home ./build/tests --lua-dir games/christmas-market/lua tests/lua/christmas.lua

shots: all
	./tools/screenshots.sh

# --- WebAssembly (Emscripten) ------------------------------------------------
# gnu11 rather than c11: Emscripten's EM_JS/EM_ASM macros need GNU extensions.
EMCC      ?= emcc
WEB_FLAGS := -std=gnu11 -O2 -Iengine -sUSE_WEBGL2=1 -sMIN_WEBGL_VERSION=2 -sMAX_WEBGL_VERSION=2 -sALLOW_MEMORY_GROWTH=1 -sINITIAL_MEMORY=64MB \
             -sEXPORTED_FUNCTIONS=_main,_malloc,_free \
             -sEXPORTED_RUNTIME_METHODS=ccall,UTF8ToString,stringToUTF8,lengthBytesUTF8 \
             '-sDEFAULT_LIBRARY_FUNCS_TO_INCLUDE=$$UTF8ToString,$$stringToUTF8,$$lengthBytesUTF8' \
             --shell-file web/shell.html

WEB_OBJ := $(addprefix build/web/,$(addsuffix .o,engine script lua platform))
build/web/%.o: $(ENGINE_DEPS) $(PLATFORM_DEPS) $(LUA_DIR)/lua.h $(wildcard $(LUA_DIR)/*.c $(LUA_DIR)/*.h)
	@mkdir -p $(dir $@)
	sh $(UNITY) $* | $(EMCC) -std=gnu11 -O2 -Iengine $(LUA_FLAGS) -x c -c -o $@ -

web: $(GAMES:%=dist/%/index.html)

define WEB_RULES
dist/$(1)/index.html: $(WEB_OBJ) $(ENGINE_DEPS) $(PLATFORM_DEPS) $(LUA_DIR)/lua.h web/shell.html $(call game_lua,$(1)) $(shell find games/$(1)/data -type f 2>/dev/null)
	@mkdir -p dist/$(1)
	$$(EMCC) $$(WEB_FLAGS) $(LUA_FLAGS) -DGAME_DIR='"/game"' -DGAME_DATA_DIR='"/data"' -DGAME_LUA_DIR='"/lua"' -o $$@ \
	    engine/launcher.c $(WEB_OBJ) \
	    --preload-file games/$(1)/data@/data --preload-file games/$(1)/lua@/lua
endef
$(foreach g,$(filter-out clayfight,$(GAMES)),$(eval $(call WEB_RULES,$(g))))

clean:
	rm -rf build dist

# Exercises the real renderer/event queue; run under Xvfb on Linux.
.PHONY: test-platform
build/test-platform: tests/test_platform.c $(ENGINE_OBJ) engine/render.h
	$(CC) $(ALL_CFLAGS) -o $@ $< $(ENGINE_OBJ) $(LIBS)
build/test-backdrop: tests/test_backdrop.c $(ENGINE_OBJ) engine/render.h
	$(CC) $(ALL_CFLAGS) -o $@ $< $(ENGINE_OBJ) $(LIBS)
build/test-story: tests/test_story.c $(ENGINE_OBJ) engine/render.h
	$(CC) $(ALL_CFLAGS) -o $@ $< $(ENGINE_OBJ) $(LIBS)
build/city-gesture: tools/capture_city_gesture.c $(ENGINE_OBJ) engine/render.h
	$(CC) $(ALL_CFLAGS) -o $@ $< $(ENGINE_OBJ) $(LIBS)
test-platform: build/test-platform build/test-backdrop build/test-story
	./build/test-platform
	./build/test-platform --safe-area-test
	./build/test-backdrop
	./build/test-story
