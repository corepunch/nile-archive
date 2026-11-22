# Shared sprite engine + games written in Lua.
#
#   make                 build every game natively (uses the shared platform submodule)
#   make run-nile-archive build and run Nile Archive        (alias: run-nile)
#   make run-relic-rush   build and run Relic Rush          (alias: run-relic)
#   make run-emergency      build and run Emergency
#   make run-emergency ARGS="--fresh --mute"                 pass game options
#   make test            generated-code freshness, engine tests and the games' Lua rule tests (headless)
#   make lint            luacheck over every game, the engine's Lua and the tests (apt: lua-check)
#   make gen             regenerate the Lua glue, docs/LUA_API.md and engine.d.lua from engine/api.xml
#   make xcode           regenerate games/<name>/<name>.xcodeproj (tools/xcode/generate.py)
#   make ios GAME=<game> build, sign, install and launch on a connected iPhone/iPad
#   make ios-<game>      same; DEVICE="name or UDID" / TEAM=... override selection
#   make list-devices    list paired devices and their availability
#   make buildings GAME=relic-rush [KEYS="lodge well"] [REBUILD=1]
#                        render city buildings by name from the game's Blender master
#   make shots           regenerate docs/screenshots (headless, software renderer)
#   make levels-preview regenerate one 100-level overview sheet per match-3 game
#   make reference-levels-preview regenerate both Cradle of Rome comparison sheets
#   make smoke           every game's smoke run
#   make web             WebAssembly builds into dist/<game>/ (needs Emscripten's emcc)
#   make clean

GAMES   := nile-archive relic-rush christmas-market emergency
CC      ?= cc
CFLAGS  ?= -O2 -g
ARGS    ?=
# CFLAGS is yours to override (make CFLAGS="-O0 -g -Werror"); the essentials live in ALL_CFLAGS
# zero is a valid default everywhere, so partial initialisers ({"who", "text"}) are idiomatic
ALL_CFLAGS = $(CFLAGS) -std=c11 -Wall -Wextra -Wno-unused-parameter -Wno-missing-field-initializers $(ENGINE_INC) -D_DEFAULT_SOURCE
# engine/ for third_party/ and generated/, engine/src for the engine's own headers.
ENGINE_INC := -Iengine -Iengine/src
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
# pinned to a release tag and built as one translation unit (engine/src/lua_lib.c).
LUA_DIR    := engine/third_party/lua
UNITY      := tools/unity.sh
LUA_FLAGS  := -Wno-unused-function
ENGINE_OBJ := build/engine/engine.o build/engine/script.o build/engine/lua.o build/engine/platform.o
ENGINE_DEPS := $(UNITY) $(wildcard engine/src/*.[ch] engine/src/platform/*.c engine/generated/*.[ch])
PLATFORM_DEPS := $(shell find $(PLATFORM_DIR) -type f \( -name '*.c' -o -name '*.m' -o -name '*.h' \) 2>/dev/null)
game_lua    = $(wildcard games/$(1)/lua/*.lua)
# the engine's own Lua, shared by every game (the web build serves it from /engine)
ENGINE_LUA  := $(wildcard engine/lua/*.lua engine/lua/*/*.lua)

.PHONY: all test gen gen-check lint xcode xcode-check shots smoke buildings levels-preview level-sheets reference-levels-preview web clean run-nile run-relic $(GAMES:%=run-%) $(GAMES)
all: $(GAMES)

build/engine/%.o: $(ENGINE_DEPS)
	@mkdir -p $(dir $@)
	sh $(UNITY) $* | $(CC) $(ALL_CFLAGS) -x c -c -o $@ -

$(LUA_DIR)/lua.h:
	@echo "Lua sources missing: run 'git submodule update --init' (the Lua interpreter is a submodule)" >&2; exit 1

build/engine/lua.o: $(UNITY) engine/src/lua_lib.c $(LUA_DIR)/lua.h $(wildcard $(LUA_DIR)/*.c) $(wildcard $(LUA_DIR)/*.h)
	@mkdir -p $(dir $@)
	sh $(UNITY) lua | $(CC) $(CFLAGS) -std=c11 -Wall $(LUA_FLAGS) $(ENGINE_INC) -x c -c -o $@ -

build/engine/platform.o: $(UNITY) engine/src/platform/web_audio.c engine/src/platform/haptic_platform.c engine/src/haptic.h engine/src/platform/gamecenter_platform.c engine/src/gamecenter.h engine/src/platform/animation_clock_platform.c engine/src/animation_clock.h engine/src/platform/app_links.c engine/src/engine.h $(PLATFORM_DEPS)
	@mkdir -p $(dir $@)
	sh $(UNITY) platform | $(CC) $(CFLAGS) -std=gnu11 -Wall $(ENGINE_INC) -x c $(PLATFORM_FLAGS) -c -o $@ -

# Every game is the same launcher pointed at games/<name>: lua/ for code, data/ for assets.
define GAME_RULES
$(1): build/$(1)
build/$(1): $(ENGINE_OBJ) engine/src/launcher.c engine/src/engine.h
	@mkdir -p build
	$$(CC) $$(ALL_CFLAGS) -DGAME_DIR='"games/$(1)"' -o $$@ engine/src/launcher.c $(ENGINE_OBJ) $$(LIBS)
run-$(1): build/$(1)
	./build/$(1) $$(ARGS)
endef
$(foreach g,$(GAMES),$(eval $(call GAME_RULES,$(g))))

run-nile: run-nile-archive
run-relic: run-relic-rush

# --- generated Lua glue ---------------------------------------------------
# engine/api.xml describes the API once; tools/luagen.py writes the glue, the
# reference and the editor annotations. They are committed, so building needs
# no Python; `make test` fails when they are stale.
GENERATED := engine/generated/api_lua.c engine/generated/api_lua.h docs/LUA_API.md engine/generated/engine.d.lua
gen:
	python3 tools/luagen.py
gen-check:
	python3 tools/luagen.py --check

# --- lint -----------------------------------------------------------------
# .luacheckrc declares the engine's globals, so an undefined global is a typo
# or a missing import and an unused local is dead code.
lint:
	luacheck -q games/*/lua engine/lua tests/lua tests/games tests/fixtures tools/*.lua

# --- Xcode projects -------------------------------------------------------
# One committed project per game with a macOS and an iOS target (iPad for Nile
# Archive, iPhone for Relic Rush), generating temporary unity units at build time.
# See tools/xcode/README.md.
xcode:
	for g in $(GAMES); do python3 tools/xcode/generate.py $$g --unsigned; done
xcode-check:
	python3 tools/xcode/generate.py --check

# The shared helper selects physical devices and uses each committed iOS scheme.
# Export overrides as data, without interpolating device names/app arguments in shell code.
export DEVICE TEAM CONFIGURATION IOS_BUILD_DIR ARGS
.PHONY: ios list-devices test-ios-deploy $(GAMES:%=ios-%)
ios:
	python3 tools/xcode/deploy.py $(if $(GAME),$(GAME),nile-archive)
$(GAMES:%=ios-%): ios-%:
	python3 tools/xcode/deploy.py $*
list-devices:
	xcrun devicectl list devices
test-ios-deploy:
	python3 -m unittest discover -s tools/xcode -p 'test_deploy.py'

# --- tests ----------------------------------------------------------------
# Engine tests in C, then the games' rules in Lua (tests/lua/*.lua) run by the
# same binary through the engine's Lua state, without a window.
# The test build: engine and launcher with -DENGINE_TEST. One start of a binary runs
# every test of that suite (docs/TESTING.md). make test ONLY=smoke runs a part.
TEST_GAMES := nile-archive relic-rush christmas-market emergency
TEST_BINS := build/test/engine $(TEST_GAMES:%=build/test/%)
TEST_OBJ := build/test-obj/engine.o build/test-obj/script.o build/engine/lua.o build/engine/platform.o
TEST_DEPS := engine/src/test/test.h engine/src/test/test_runner.c engine/src/test/test_lua.c
build/test-obj/%.o: $(ENGINE_DEPS) $(TEST_DEPS)
	@mkdir -p $(dir $@)
	sh $(UNITY) $* | $(CC) $(ALL_CFLAGS) -DENGINE_TEST -x c -c -o $@ -
define TEST_GAME_RULES
build/test/$(1): $(TEST_OBJ) engine/src/launcher.c $(TEST_DEPS)
	@mkdir -p build/test
	$$(CC) $$(ALL_CFLAGS) -DENGINE_TEST -DGAME_NAME='"$(1)"' -DGAME_DIR='"games/$(1)"' -o $$@ engine/src/launcher.c $(TEST_OBJ) $$(LIBS)
endef
$(foreach g,$(TEST_GAMES),$(eval $(call TEST_GAME_RULES,$(g))))
ENGINE_TEST_SRC := tests/test_main.c tests/test_platform.c tests/test_backdrop.c tests/test_story.c tests/test_city_render.c tests/test_haptic.c tests/test_gamecenter.c
build/test/engine: $(ENGINE_TEST_SRC) $(TEST_OBJ) $(TEST_DEPS)
	@mkdir -p build/test
	$(CC) $(ALL_CFLAGS) -DENGINE_TEST -o $@ $(ENGINE_TEST_SRC) $(TEST_OBJ) $(LIBS)
# Every suite in one process and one window: what `make test` and `make test-full` start.
build/test/all: $(ENGINE_TEST_SRC) $(TEST_OBJ) $(TEST_DEPS)
	@mkdir -p build/test
	$(CC) $(ALL_CFLAGS) -DENGINE_TEST -DTEST_ALL_GAMES='"$(TEST_GAMES)"' -o $@ $(ENGINE_TEST_SRC) $(TEST_OBJ) $(LIBS)

build/test-audio: tests/test_audio.c engine/src/audio.c engine/src/engine.h
	@mkdir -p build
	$(CC) $(ALL_CFLAGS) -o $@ tests/test_audio.c engine/src/audio.c -lm

.PHONY: test-assets
test-assets:
	python3 tools/epoch_medals.py --check
	python3 games/emergency/tools/check_assets.py
	python3 games/relic-rush/tools/check_art_catalogue.py
	python3 games/relic-rush/tools/board_assets.py --check
	python3 games/christmas-market/tools/prepare_catalogue.py --check
	python3 games/christmas-market/tools/check_assets.py
	python3 games/christmas-market/tools/prepare_story.py --check
	python3 games/christmas-market/tools/prepare_story_cast.py --check
	python3 games/relic-rush/tools/prepare_hud.py --check
	python3 games/relic-rush/tools/prepare_story.py --check
	python3 tools/buildings.py --check
	python3 tools/match3_atlas.py --check
	python3 tools/match3_elements_art.py --check
	python3 tests/test_hex_tile_art.py
	python3 tests/test_tools_index.py
	python3 tools/board_tiles.py --render-check
# Budget is test execution only: build prerequisites finish before the timer.
TEST_BUDGET ?= 10
TEST_WORKERS ?= 4
TEST_AUX_BINS := build/test-audio
.PHONY: test-full test-fast test-extended test-engine test-match3 $(TEST_GAMES:%=test-%)
test test-fast: build/test/all $(TEST_AUX_BINS)
	python3 tools/run_tests.py --budget $(TEST_BUDGET) --jobs $(TEST_WORKERS) --games "$(TEST_GAMES)" $(if $(filter test-fast,$@),--fast) -- $(ONLY) $(TEST_ARGS)

# CI's preflight job runs the generated and asset checks before this target.
.PHONY: test-ci
test-ci: build/test/all $(TEST_AUX_BINS)
	./build/test-audio
	BALANCE_RUNS= ./build/test/all --with-quick-smoke --extended

# Bots play every board and write the fitted values: move budgets for both
# match-3 games, restoration prices for Relic Rush (tools/balance.py).
#   make balance GAME=relic-rush
#   make balance GAME=christmas-market BALANCE_ARGS=--trim
.PHONY: balance
balance:
	python3 tools/balance.py $(GAME) $(BALANCE_ARGS)

# Complete both real campaigns, including rewards, story and all purchases.
.PHONY: test-bot
test-bot: build/test/all
	BOT_PROFILE=1 ./build/test/all --suite=relic-rush --suite=christmas-market --extended "rules campaign_play"

.PHONY: test-balance
test-balance: export BALANCE_RUNS ?= 40
test-balance:
	@test "$$BALANCE_RUNS" -gt 0 || { echo "BALANCE_RUNS must be a positive integer" >&2; exit 2; }
	python3 tools/balance.py relic-rush --report --seeds $$BALANCE_RUNS

# Full integration with capture export is available on demand.
test-full: gen-check xcode-check test-assets build/test/all $(TEST_AUX_BINS)
	./build/test-audio
	./build/test/all --full $(ONLY) $(TEST_ARGS)

$(TEST_GAMES:%=test-%): test-%: build/test/all
	./build/test/all --suite=$* --fast $(TEST_ARGS)
test-engine: build/test/all build/test-audio
	./build/test/all --suite=engine --fast $(TEST_ARGS)
	./build/test-audio
test-extended:
	$(MAKE) test-fast TEST_ARGS=--extended TEST_BUDGET=60
MATCH3_LUA_DIR ?= engine/lua
test-match3: build/test/all
	test -f "$(MATCH3_LUA_DIR)/match3.lua"
	SPRITE_MATCH3_ROOT="$(MATCH3_LUA_DIR)" ./build/test/all --suite=engine engine_match3 $(TEST_ARGS)

shots: build/test/all
	./build/test/all $(TEST_GAMES:%=--suite=%) shot frame reel hold
	python3 tools/screenshots.py

smoke: build/test/all
	./build/test/all $(TEST_GAMES:%=--suite=%) smoke

buildings:
	python3 tools/buildings.py $(GAME) $(KEYS) $(if $(REBUILD),--rebuild) $(if $(BLENDER),--blender)

# One overview image of every match-3 board per game (docs/LEVEL_DESIGN.md).
#   make levels-preview                       # both games, all 100 levels
#   make levels-preview SHEET_GAMES=relic-rush LEVELS=1-30
SHEET_GAMES ?= relic-rush christmas-market
level-sheets: levels-preview

levels-preview:
	@mkdir -p docs/review/level-sheets
	@for game in $(SHEET_GAMES); do \
		report=$$(python3 tools/hex_levels.py "$$game" --levels "$(or $(LEVELS),1-100)" \
			--sheet "docs/review/level-sheets/$$game$(if $(filter-out 1-100,$(LEVELS)),-$(LEVELS)).png") || { printf '%s\n' "$$report" >&2; exit 1; }; \
		printf '%s\n' "$$report" | tail -2; \
	done

reference-levels-preview:
	python3 tools/reference/cradle-of-rome/level_previews.py --output-dir docs/review/level-sheets

# --- WebAssembly (Emscripten) ------------------------------------------------
# gnu11 rather than c11: Emscripten's EM_JS/EM_ASM macros need GNU extensions.
EMCC      ?= emcc
WEB_FLAGS := -std=gnu11 -O2 $(ENGINE_INC) -sUSE_WEBGL2=1 -sMIN_WEBGL_VERSION=2 -sMAX_WEBGL_VERSION=2 -sALLOW_MEMORY_GROWTH=1 -sINITIAL_MEMORY=64MB \
             -sEXPORTED_FUNCTIONS=_main,_malloc,_free \
             -sEXPORTED_RUNTIME_METHODS=ccall,UTF8ToString,stringToUTF8,lengthBytesUTF8 \
             '-sDEFAULT_LIBRARY_FUNCS_TO_INCLUDE=$$UTF8ToString,$$stringToUTF8,$$lengthBytesUTF8' \
             --shell-file web/shell.html

WEB_OBJ := $(addprefix build/web/,$(addsuffix .o,engine script lua platform))
build/web/%.o: $(ENGINE_DEPS) $(PLATFORM_DEPS) $(LUA_DIR)/lua.h $(wildcard $(LUA_DIR)/*.c $(LUA_DIR)/*.h)
	@mkdir -p $(dir $@)
	sh $(UNITY) $* | $(EMCC) -std=gnu11 -O2 $(ENGINE_INC) $(LUA_FLAGS) -x c -c -o $@ -

web: $(GAMES:%=dist/%/index.html)

define WEB_RULES
dist/$(1)/index.html: $(WEB_OBJ) $(ENGINE_DEPS) $(PLATFORM_DEPS) $(LUA_DIR)/lua.h web/shell.html $(call game_lua,$(1)) $(ENGINE_LUA) $(shell find engine/data -type f) $(shell find games/$(1)/data -type f 2>/dev/null)
	@mkdir -p dist/$(1)
	$$(EMCC) $$(WEB_FLAGS) $(LUA_FLAGS) -DGAME_DIR='"/game"' -DGAME_DATA_DIR='"/data"' -DGAME_LUA_DIR='"/lua"' -DENGINE_DIR='"/engine"' -o $$@ \
	    engine/src/launcher.c $(WEB_OBJ) \
	    --preload-file games/$(1)/data@/data --preload-file games/$(1)/lua@/lua --preload-file engine/lua@/engine/lua --preload-file engine/data@/engine/data
endef
$(foreach g,$(GAMES),$(eval $(call WEB_RULES,$(g))))

clean:
	rm -rf build dist

# Exercises the real renderer/event queue; run under Xvfb on Linux.
.PHONY: test-platform
test-platform: build/test/all
	./build/test/all --suite=engine platform backdrop story_layouts city_render
