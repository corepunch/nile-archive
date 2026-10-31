/* test.h — the test build's macros (make test compiles with -DENGINE_TEST).
 *
 *     #include "test.h"
 *     TEST(camera_clamps)
 *     {
 *         CHECK(cam.zoom > 0);
 *         NEAR(cam.center.x, 100);
 *     }
 *
 * That is a whole test: it registers itself and reports its own name. See
 * docs/TESTING.md. */
#ifndef ENGINE_TEST_H
#define ENGINE_TEST_H

#include "engine.h"
#include <math.h>
#include <stdbool.h>

void test_pass(void);
void test_fail(const char *file, int line, const char *format, ...);
void test_register(const char *name, void (*fn)(void));
int test_failures(void);   /* so far, in this test */

#define CHECK(cond) ((cond) ? test_pass() : test_fail(__FILE__, __LINE__, "CHECK(%s)", #cond))
#define CHECKF(cond, format, ...) ((cond) ? test_pass() : test_fail(__FILE__, __LINE__, "CHECK(%s) " format, #cond, __VA_ARGS__))
#define NEAR(a, b)                                                                      \
    do {                                                                                \
        float near_a_ = (float)(a), near_b_ = (float)(b);                               \
        if (fabsf(near_a_ - near_b_) < 1e-3f) test_pass();                              \
        else test_fail(__FILE__, __LINE__, "NEAR(%s, %s): %g vs %g", #a, #b, near_a_, near_b_); \
    } while (0)
#define TEST(name)                                                                      \
    static void test_##name(void);                                                      \
    __attribute__((constructor)) static void test_register_##name(void) { test_register(#name, test_##name); } \
    static void test_##name(void)

/* The hooks the engine calls under #ifdef ENGINE_TEST. */
_Noreturn void test_abort(const char *message);   /* a broken script ends this test, not the run */
void test_tick(void);                             /* per frame: enforces the time limit */
const char *test_shot_due(int frame, int shot_frames, const char *shot_path, bool *last);
void test_check_picture(const unsigned char *rgba, int width, int height);

/* One entry of tests/games/<suite>.lua, filled in by engine/test_lua.c. */
typedef struct {
    char kind[8], name[80], file[64], roots[160], size[16], press[24], opts[400];
    int count, step;
} test_job;
int test_read_jobs(const char *path, test_job *jobs, int max);

/* core.c and the runner share these. */
void app_test_recover(void);
void app_test_close_window(void);
void app_test_reset(void);
void app_test_advance(double dt);
void app_test_input(input in);
const char *test_suite(void);

int test_main(const char *suite, const char *lua_dir, const char *data_dir, int argc, char **argv);

#endif
