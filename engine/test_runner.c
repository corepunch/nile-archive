/* test_runner.c — main() of the test build: one start runs a suite's every test.
 *
 * A suite is C TEST()s plus the jobs in tests/games/<suite>.lua. Each job gets a
 * fresh Lua state and clean engine state, in one window resized to fit. A failure
 * or a broken script ends that test, never the run, and every test reports PASS or
 * FAIL. Output the game prints stays out of the report unless its test fails.
 *
 *     build/test/relic-rush                  everything
 *     build/test/relic-rush smoke            only tests whose name contains this
 *     build/test/relic-rush --list           what would run
 *
 * Included once per test binary, by launcher.c or tests/test_main.c. */
#include "render.h"
#include "test.h"

#include <fcntl.h>
#include <setjmp.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>
#include <dirent.h>

enum { MAX_C_TESTS = 128, MAX_JOBS = 512, MAX_NOTES = 12, MAX_ARGS = 64, TIME_LIMIT = 600 };

static struct { const char *name; void (*fn)(void); } c_tests[MAX_C_TESTS];
static int c_test_count;
static const char *current_suite = "engine";
const char *test_suite(void) { return current_suite; }

static struct {
    int checks, failed_checks;
    char notes[MAX_NOTES][400];
    jmp_buf abort_to;
    bool can_abort;
    double started;
    const test_job *job;
    char shot_dir[160];
} T;

static double seconds_now(void)
{
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return (double)t.tv_sec + t.tv_nsec / 1e9;
}

void test_register(const char *name, void (*fn)(void))
{
    if (c_test_count < MAX_C_TESTS) c_tests[c_test_count].name = name, c_tests[c_test_count++].fn = fn;
}

void test_pass(void) { T.checks++; }
int test_failures(void) { return T.failed_checks; }

/* file and line locate the failure; Lua passes its "file:line:" as file and zero. */
void test_fail(const char *file, int line, const char *format, ...)
{
    T.checks++;
    if (T.failed_checks < MAX_NOTES) {
        char *note = T.notes[T.failed_checks], message[300];
        va_list args;
        va_start(args, format);
        vsnprintf(message, sizeof message, format, args);
        va_end(args);
        if (line) snprintf(note, sizeof T.notes[0], "%s:%d: %s", file, line, message);
        else snprintf(note, sizeof T.notes[0], "%s%s", file, message);
    }
    T.failed_checks++;
}

void test_abort(const char *message)
{
    test_fail("", 0, "%s", message);
    if (T.can_abort) longjmp(T.abort_to, 1);
    fprintf(stderr, "%s\n", message);
    exit(3);
}

void test_tick(void)
{
    if (seconds_now() - T.started > TIME_LIMIT) test_abort("timed out");
}

/* The picture due on this frame, if any. A reel takes several from one run. */
const char *test_shot_due(int frame, int shot_frames, const char *shot_path, bool *last)
{
    static char path[256];
    const test_job *j = T.job;
    if (j && !strcmp(j->kind, "reel")) {
        int i = (frame - 1) / j->step;
        if ((frame - 1) % j->step || i >= j->count) return NULL;
        snprintf(path, sizeof path, "%s-%d.png", shot_path, i);
        *last = i == j->count - 1;
        return path;
    }
    if (frame < shot_frames) return NULL;
    *last = true;
    return shot_path;
}

void test_check_picture(const unsigned char *rgba, int width, int height)
{
    const test_job *j = T.job;
    bool flat = true;
    for (int i = 4; flat && i < width * height * 4; i += 4) flat = !memcmp(rgba, rgba + i, 4);
    CHECKF(!flat, "the picture is one flat colour, %dx%d", width, height);
    int w, h;
    if (j && sscanf(j->size, "%dx%d", &w, &h) == 2)
        CHECKF(abs(width * h - height * w) <= (w > h ? w : h), "rendered %dx%d, wanted the shape of %s", width, height, j->size);
}

/* ------------------------------------------------------------------- gestures */

static void (*gesture_game_frame)(float);
static int gesture_index;

static void gesture_frame(float dt)
{
    vec2 at = v2(240, 400);
    if (T.job && T.job->press[0]) sscanf(T.job->press, "%f,%f", &at.x, &at.y);
    if (++gesture_index == 30) {
        struct AXsize window;
        axGetSize(&window);
        rect bleed = app_bleed();
        vec2 p = vec2_scale(vec2_sub(at, bleed.pos), window.width / bleed.size.w);
        axPostMessageW(NULL, kEventLeftButtonDown, MAKEDWORD((int)lroundf(p.x), (int)lroundf(p.y)), NULL);
    }
    gesture_game_frame(dt);
}

/* ----------------------------------------------------------------------- jobs */

static void make_dirs(const char *path)
{
    char buf[256];
    snprintf(buf, sizeof buf, "%s", path);
    for (char *p = buf + 1; *p; p++)
        if (*p == '/') *p = 0, mkdir(buf, 0755), *p = '/';
    mkdir(buf, 0755);
}

static void run_game(const test_job *j, const char *suite, const char *lua_dir, const char *data_dir)
{
    static char line[640], shot[256];
    char *args[MAX_ARGS] = {"test", "--headless", "--mute", "--fresh"};
    int n = 4;
    shot[0] = 0;
    if (!strcmp(j->kind, "shot") || !strcmp(j->kind, "hold")) {
        char dir[200];
        snprintf(dir, sizeof dir, "%s/%s", T.shot_dir, suite);
        make_dirs(dir);
        snprintf(shot, sizeof shot, "%s/%s.png", dir, j->name);
    } else if (!strcmp(j->kind, "frame") || !strcmp(j->kind, "reel")) {
        char dir[200];
        snprintf(dir, sizeof dir, "%s/frames", T.shot_dir);
        make_dirs(dir);
        snprintf(shot, sizeof shot, "%s/%s%s", dir, j->name, !strcmp(j->kind, "reel") ? "" : ".png");
    }
    snprintf(line, sizeof line, "%s", j->opts);
    if (j->size[0]) args[n++] = "--size", args[n++] = (char *)j->size;
    if (shot[0]) args[n++] = "--shot", args[n++] = shot;
    if (!strcmp(j->kind, "hold")) args[n++] = "--frames", args[n++] = "100";
    if (!strcmp(j->kind, "reel")) args[n++] = "--frames", args[n++] = "1";
    for (char *t = strtok(line, " "); t && n < MAX_ARGS; t = strtok(NULL, " ")) args[n++] = t;
    for (int i = 1; i + 1 < n; i++)
        if (!strcmp(args[i], "--lua")) lua_dir = args[i + 1];
    app_desc desc = script_boot(lua_dir, data_dir);
    if (!strcmp(j->kind, "hold")) {
        gesture_game_frame = desc.frame, desc.frame = gesture_frame;
        gesture_index = 0;
    }
    CHECKF(app_run(desc, n, args) == 0, "%s", "the game did not start");
    script_close();
}

static void run_rules(const test_job *j, const char *lua_dir)
{
    char roots[512], path[128];
    snprintf(roots, sizeof roots, "%s;%s%sengine;tests/lua", lua_dir, j->roots, j->roots[0] ? ";" : "");
    snprintf(path, sizeof path, "tests/lua/%s.lua", j->file);
    script_open(roots);
    int result = script_dofile(path);
    if (result > 0 && !test_failures()) test_fail(path, 0, "reported %d failed cases", result);
    script_close();
}

/* ---------------------------------------------------------------------- report */

static int report_fd, log_fd;
static bool colour;

static void say(const char *format, ...)
{
    char buf[1024];
    va_list args;
    va_start(args, format);
    int n = vsnprintf(buf, sizeof buf, format, args);
    va_end(args);
    if (n > 0 && write(report_fd, buf, n < (int)sizeof buf ? (size_t)n : sizeof buf - 1) < 0) return;
}

static void capture_output(const char *log)
{
    fflush(stdout), fflush(stderr);
    log_fd = open(log, O_CREAT | O_TRUNC | O_WRONLY, 0644);
    dup2(log_fd, 1), dup2(log_fd, 2);
}

static void release_output(void)
{
    fflush(stdout), fflush(stderr);
    dup2(report_fd, 1), dup2(report_fd, 2);
    close(log_fd);
}

static void show_log_tail(const char *log)
{
    FILE *f = fopen(log, "r");
    if (!f) return;
    static char lines[8][300];
    int n = 0;
    while (fgets(lines[n % 8], sizeof lines[0], f))
        if (!strstr(lines[n % 8], "App started in")) n++;   /* the platform's greeting */
    fclose(f);
    if (n) say("        output:\n");
    for (int i = n > 8 ? n - 8 : 0; i < n; i++) say("          %s", lines[i % 8]);
}

static void report(const char *kind, const char *name, double took, const char *log, int *passed, int *failed, char *failures, size_t size)
{
    char label[100];
    snprintf(label, sizeof label, "%s%s%s", kind, kind[0] ? " " : "", name);
    if (T.failed_checks) {
        say("  %sFAIL%s  %-40s %.2fs\n", colour ? "\033[31;1m" : "", colour ? "\033[0m" : "", label, took);
        for (int i = 0; i < T.failed_checks && i < MAX_NOTES; i++) {   /* a traceback has many lines */
            for (const char *line = T.notes[i], *end; *line; line = *end ? end + 1 : end) {
                end = line + strcspn(line, "\n");
                say("        %.*s\n", (int)(end - line), line);
            }
        }
        if (T.failed_checks > MAX_NOTES) say("        ...and %d more\n", T.failed_checks - MAX_NOTES);
        show_log_tail(log);
        (*failed)++;
        size_t used = strlen(failures);
        snprintf(failures + used, size - used, "  %s\n", label);
    } else {
        char count[32] = "";
        if (T.checks > 1) snprintf(count, sizeof count, "%d checks", T.checks);
        say("  %sPASS%s  %-40s %.2fs  %s\n", colour ? "\033[32m" : "", colour ? "\033[0m" : "", label, took, count);
        (*passed)++;
    }
}

static bool wanted(const char *label, int argc, char **argv)
{
    bool any = false;
    for (int i = 1; i < argc; i++) {
        if (argv[i][0] == '-') continue;
        any = true;
        if (strstr(label, argv[i])) return true;
    }
    return !any;
}

int test_main(const char *suite, const char *lua_dir, const char *data_dir, int argc, char **argv)
{
    current_suite = suite;
    static test_job jobs[MAX_JOBS];
    static char failures[4096];
    char spec[128], log[160];
    bool list = false;
    bool fast = false, checks_only = false;
    for (int i = 1; i < argc; i++) list |= !strcmp(argv[i], "--list");
    for (int i = 1; i < argc; i++) {
        fast |= !strcmp(argv[i], "--fast");
        checks_only |= !strcmp(argv[i], "--check");
        if (!strcmp(argv[i], "--extended")) setenv("SPRITE_TEST_EXTENDED", "1", 1);
    }
    snprintf(spec, sizeof spec, "tests/games/%s.lua", suite);
    int job_count = access(spec, R_OK) ? 0 : test_read_jobs(spec, jobs, MAX_JOBS);
    if (job_count < 0) return 2;
    snprintf(T.shot_dir, sizeof T.shot_dir, "build/shots");
    char home[] = "/tmp/sprite-tests-XXXXXX";
    if (!mkdtemp(home) || setenv("SPRITE_SAVE_DIR", home, 1)) { perror("test save directory"); return 2; }
    snprintf(log, sizeof log, "build/test/%s.log", suite);
    report_fd = dup(1);
    colour = isatty(report_fd);
    int passed = 0, failed = 0;
    double began = seconds_now();
    long checks = 0;
    if (!list) say("%s\n", suite);
    int total = c_test_count + job_count;
    for (int i = 0; i < total; i++) {
        const test_job *j = i < c_test_count ? NULL : &jobs[i - c_test_count];
        const char *kind = j ? j->kind : "", *name = j ? j->name : c_tests[i].name;
        if ((fast || checks_only) && j && strcmp(kind, "rules")) continue;
        if (fast && !j && (
            !strcmp(name, "platform") || !strcmp(name, "platform_safe_area") ||
            !strcmp(name, "backdrop") || !strcmp(name, "story_layouts") ||
            !strcmp(name, "story_portrait_motion") || !strcmp(name, "city_render"))) continue;
        char label[100];
        snprintf(label, sizeof label, "%s%s%s", kind, kind[0] ? " " : "", name);
        if (!wanted(label, argc, argv)) continue;
        if (list) { say("%s\n", label); continue; }
        T.checks = T.failed_checks = 0;
        T.job = j;
        T.started = seconds_now();
        T.can_abort = true;
        capture_output(log);
        if (!setjmp(T.abort_to)) {
            if (!j) c_tests[i].fn();
            else if (!strcmp(j->kind, "rules")) run_rules(j, lua_dir);
            else run_game(j, suite, lua_dir, data_dir);
        } else {
            app_test_recover();
            script_close();
        }
        T.can_abort = false;
        T.job = NULL;
        release_output();
        checks += T.checks;
        report(kind, name, seconds_now() - T.started, log, &passed, &failed, failures, sizeof failures);
    }
    app_test_close_window();
    DIR *dir = opendir(home);
    if (dir) {
        struct dirent *entry;
        while ((entry = readdir(dir))) {
            if (entry->d_name[0] == '.') continue;
            char path[512]; snprintf(path, sizeof path, "%s/%s", home, entry->d_name); unlink(path);
        }
        closedir(dir);
    }
    rmdir(home);
    if (list) return 0;
    say("%s: %s%d passed, %d failed%s, %ld checks, %.1fs\n", suite, colour ? (failed ? "\033[31;1m" : "\033[32m") : "",
        passed, failed, colour ? "\033[0m" : "", checks, seconds_now() - began);
    if (failed) say("failed:\n%s", failures);
    return failed ? 1 : 0;
}
