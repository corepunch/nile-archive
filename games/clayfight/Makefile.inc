CLAY_SRC := $(wildcard games/clayfight/source/game/*.c games/clayfight/source/platform/*.c) games/clayfight/source/runtime.c
CLAY_OBJ := $(CLAY_SRC:%.c=build/%.o)
CLAY_FLAGS := -Igames/clayfight/source -DCLAY_HOST
$(CLAY_OBJ): build/%.o: %.c $(wildcard games/clayfight/source/*/*.h) engine/engine.h
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
	$(CC) $(ALL_CFLAGS) $(CLAY_FLAGS) -o $@ $< $(CLAY_OBJ) $(ENGINE_OBJ) $(LIBS)
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
	$(CC) $(ALL_CFLAGS) $(CLAY_FLAGS) -o $@ $^ $(LIBS)
.PHONY: test-clayfight test-clayfight-retail
# The first pair is suitable for clean CI, without proprietary data.
test-clayfight: build/test/engine build/clayfight-video build/clayfight-photo build/clayfight-input
	./build/test/engine clayfight $(TEST_ARGS)
	./build/clayfight-video
	./build/clayfight-photo
	./build/clayfight-input
	node --test games/clayfight/tests/capture-processing.mjs
test-clayfight-retail: clayfight test-clayfight build/clayfight-flow build/clayfight-retail
	@mkdir -p games/clayfight/build
	cd games/clayfight && ../../build/clayfight-flow -checkflow -data data/primalrage -creatures data/creatures
	cd games/clayfight && ../../build/clayfight-retail -data data/primalrage -creatures data/creatures
	./build/clayfight -data games/clayfight/data/primalrage -creatures games/clayfight/data/creatures -checkanims
	python3 -B games/clayfight/tests/capture.py
dist/clayfight/index.html: $(WEB_OBJ) $(ENGINE_DEPS) $(PLATFORM_DEPS) $(LUA_DIR)/lua.h $(CLAY_SRC) games/clayfight/host.c $(wildcard games/clayfight/source/*/*.h games/clayfight/lua/*.lua) $(shell find games/clayfight/data -type f 2>/dev/null) web/shell.html
	@mkdir -p dist/clayfight
	$(EMCC) $(WEB_FLAGS) $(LUA_FLAGS) $(CLAY_FLAGS) -o $@ games/clayfight/host.c $(CLAY_SRC) \
	    $(WEB_OBJ) \
	    --preload-file games/clayfight/data@/data --preload-file games/clayfight/lua@/lua
.PHONY: clayfight-resources
clayfight-resources:
	python3 games/clayfight/tools/import_resources.py
