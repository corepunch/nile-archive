CLAY_SRC := $(wildcard games/clayfight/source/game/*.c games/clayfight/source/platform/*.c) games/clayfight/source/runtime.c
CLAY_CPP := $(wildcard games/clayfight/source/sound/*.cpp)
CLAY_OBJ := $(CLAY_SRC:%.c=build/%.o) $(CLAY_CPP:%.cpp=build/%.o)
CLAY_CXXLIB := $(if $(filter Darwin,$(shell uname -s)),-lc++,-lstdc++)
$(CLAY_CPP:%.cpp=build/%.o): build/%.o: %.cpp $(wildcard games/clayfight/source/sound/*.hpp games/clayfight/source/sound/*.ipp)
	@mkdir -p $(dir $@)
	$(CXX) $(filter-out -std=c11,$(ALL_CFLAGS)) -std=c++20 $(CLAY_FLAGS) -c $< -o $@

CLAY_FLAGS := -Igames/clayfight/source -DCLAY_HOST
$(CLAY_SRC:%.c=build/%.o): build/%.o: %.c $(wildcard games/clayfight/source/*/*.h) engine/engine.h
	@mkdir -p $(dir $@)
	$(CC) $(ALL_CFLAGS) $(CLAY_FLAGS) -c $< -o $@
ifeq ($(shell uname -s),Darwin)
CLAY_OBJ += build/games/clayfight/controllers.o
LIBS += -framework GameController
build/games/clayfight/controllers.o: games/clayfight/controllers.m
	@mkdir -p $(dir $@)
	$(CC) $(ALL_CFLAGS) $(CLAY_FLAGS) -fobjc-arc -c $< -o $@
endif
clayfight: build/clayfight
build/clayfight: games/clayfight/host.c $(CLAY_OBJ) $(ENGINE_OBJ)
	$(CC) $(ALL_CFLAGS) $(CLAY_FLAGS) -o $@ $< $(CLAY_OBJ) $(ENGINE_OBJ) $(LIBS) $(CLAY_CXXLIB)
run-clayfight: build/clayfight
	./build/clayfight $(ARGS)
build/clayfight-video: games/clayfight/tests/video.c games/clayfight/source/game/v_video.c engine/raster.c
	@mkdir -p $(dir $@)
	$(CC) $(ALL_CFLAGS) $(CLAY_FLAGS) -o $@ $^ -lm
build/clayfight-photo: games/clayfight/tests/photo.c games/clayfight/source/game/w_photo.c engine/photo.c engine/raster.c
	@mkdir -p $(dir $@)
	$(CC) $(ALL_CFLAGS) $(CLAY_FLAGS) -o $@ $^ -lm
build/clayfight-input: games/clayfight/tests/input.c games/clayfight/source/platform/i_input.c
	@mkdir -p $(dir $@)
	$(CC) $(ALL_CFLAGS) $(CLAY_FLAGS) -DCLAY_TEST_JOYSTICK -o $@ $^ -lm
build/clayfight-%: games/clayfight/tests/%.c $(CLAY_OBJ) $(ENGINE_OBJ)
	$(CC) $(ALL_CFLAGS) $(CLAY_FLAGS) -o $@ $^ $(LIBS) $(CLAY_CXXLIB)
build/clayfight-arcade: games/clayfight/tests/arcade.c games/clayfight/tests/flow.c games/clayfight/tests/retail.c $(CLAY_OBJ) $(ENGINE_OBJ)
	$(CC) $(ALL_CFLAGS) $(CLAY_FLAGS) -DCLAY_COMBINED -o $@ $^ $(LIBS) $(CLAY_CXXLIB)
.PHONY: test-clayfight test-clayfight-native test-clayfight-retail
# The first pair is suitable for clean CI, without proprietary data.
test-clayfight: build/test/engine test-clayfight-native
	./build/test/engine --fast "rules clayfight" $(TEST_ARGS)
test-clayfight-native: build/clayfight-video build/clayfight-photo build/clayfight-input
	./build/clayfight-video
	./build/clayfight-photo
	./build/clayfight-input
	node --test games/clayfight/tests/capture-processing.mjs
test-clayfight-retail: clayfight build/clayfight-arcade
	@mkdir -p games/clayfight/build games/clayfight/build/arcade-review
	cd games/clayfight && ../../build/clayfight-arcade -nosound -creatures data/creatures
	python3 -B games/clayfight/tests/capture.py
CLAY_WEB_CPP := $(CLAY_CPP:%.cpp=build/web/%.o)
$(CLAY_WEB_CPP): build/web/%.o: %.cpp $(wildcard games/clayfight/source/sound/*.hpp games/clayfight/source/sound/*.ipp)
	@mkdir -p $(dir $@)
	$(EMCC) -std=c++20 -O2 -Iengine $(CLAY_FLAGS) -c $< -o $@
dist/clayfight/index.html: $(CLAY_WEB_CPP) $(WEB_OBJ) $(ENGINE_DEPS) $(PLATFORM_DEPS) $(LUA_DIR)/lua.h $(CLAY_SRC) games/clayfight/host.c $(wildcard games/clayfight/source/*/*.h games/clayfight/lua/*.lua) $(shell find games/clayfight/data -type f 2>/dev/null) web/shell.html
	@mkdir -p dist/clayfight
	$(EMCC) $(WEB_FLAGS) $(LUA_FLAGS) $(CLAY_FLAGS) -o $@ games/clayfight/host.c $(CLAY_SRC) $(CLAY_WEB_CPP) -lc++ \
	    $(WEB_OBJ) \
	    --preload-file games/clayfight/data@/data --preload-file games/clayfight/lua@/lua
.PHONY: clayfight-resources
clayfight-resources:
	python3 games/clayfight/tools/import_resources.py
