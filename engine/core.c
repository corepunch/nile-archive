/* core.c — window, logical screen, main loop, input gestures, screenshots. */
#include "render.h"
#include "viewport.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#include <emscripten/html5.h>

/* The page's query string as command line words: ?tiles=jewels&fresh -> --tiles jewels --fresh */
EM_JS(char *, web_query_args, (void), {
    var words = [];
    new URLSearchParams(location.search).forEach(function(value, key) {
        words.push('--' + key);
        if (value !== "") words.push(value);
    });
    var text = words.join('\n'), n = lengthBytesUTF8(text) + 1, p = _malloc(n);
    stringToUTF8(text, p, n);
    return p;
});

static int web_args(char ***out)
{
    static char *argv[64];
    int argc = 0;
    argv[argc++] = "game";
    for (char *word = web_query_args(); word && *word && argc < 63;) {
        argv[argc++] = word;
        char *end = strchr(word, '\n');
        if (!end) break;
        *end = 0;
        word = end + 1;
    }
    argv[argc] = NULL;
    *out = argv;
    return argc;
}
#endif

#define STB_IMAGE_WRITE_IMPLEMENTATION
#define STBIW_ASSERT(x) ((void)0)
#include "third_party/stb_image_write.h"

#define DRAG_THRESHOLD 10.0f

static struct {
    app_desc desc;
    int argc;
    char **argv;
    bool running;
    size2 logical;
    rect view;
    size2 output;   /* window points */
    float pixel_scale;
    double time;
    float dt;
    longTime_t last_counter;
    input in;
    const char *shot_path;
    int shot_frames;
    int frame_index;
} A;

#ifdef ENGINE_TEST
#include "test.h"
static bool window_open, in_frame;
#endif

const char *app_id(void) { return A.desc.id ? A.desc.id : "game"; }
rect app_screen(void) { return rect_make(v2(0, 0), A.logical); }

/* Games draw controls in the safe, logical screen; backgrounds may run on
 * under the status bar, the home indicator and any letterbox bars. */
rect app_bleed(void)
{
    float scale = A.logical.w > 0 ? A.view.size.w / A.logical.w : 0;
    if (scale <= 0) return app_screen();
    return rect_make(vec2_scale(A.view.pos, -1 / scale), size2_scale(A.output, 1 / scale));
}
float app_pixel_scale(void) { return A.pixel_scale; }
double app_time(void) { return A.time; }
float app_dt(void) { return A.dt; }
#ifdef ENGINE_TEST
static double test_clock;
static bool test_clock_active;
void app_test_reset(void)
{
    memset(&A, 0, sizeof A);
    A.logical = sz2(1200, 900);
    A.view = rc(0, 0, 1200, 900);
    A.output = A.logical;
    A.pixel_scale = 1;
    A.in.pinch = 1;
    test_clock = 1700000000;
    test_clock_active = true;
    ui_restart(); story_restart(); fx_restart(); city_restart();
}
void app_test_advance(double dt) { A.dt = (float)dt; A.time += dt; test_clock += dt; }
void app_test_input(input in) { A.in = in; }
double app_clock(void) { return test_clock_active ? test_clock : (double)time(NULL); }
#else
double app_clock(void) { return (double)time(NULL); }
#endif
void app_quit(void) { A.running = false; }
input input_get(void) { return A.in; }

/* Queue window coordinates, just like native pointer events. */
static void inject_pointer(vec2 p, uint32_t event)
{
    float scale = A.view.size.w / A.logical.w;
    vec2 offset = A.view.pos;
    vec2 at = vec2_add(offset, vec2_scale(p, scale));
    uint32_t xy = MAKEDWORD((int)lroundf(at.x), (int)lroundf(at.y));
    axPostMessageW(NULL, event, xy, NULL);
}

void app_inject_press(vec2 p) { inject_pointer(p, kEventLeftButtonDown); }
void app_inject_move(vec2 p) { inject_pointer(p, kEventLeftButtonDragged); }
void app_inject_release(vec2 p) { inject_pointer(p, kEventLeftButtonUp); }
void app_inject_click(vec2 p) { app_inject_press(p); app_inject_release(p); }

const char *app_path(const char *rel)
{
    static char buf[4][512];
    static int slot;
    const char *root = app_arg("data");
    if (!root || !*root) root = A.desc.data_dir;
    if (!rel || rel[0] == '/' || !root || !*root) return rel;
    char *out = buf[slot++ & 3];
    snprintf(out, sizeof buf[0], "%s/%s", root, rel);
    return out;
}

input input_world(void)
{
    input in = A.in;
    if (in.captured) {
        in.pressed = in.released = in.tap = in.dragging = false;
        in.drag = v2(0, 0);
    }
    return in;
}

const char *app_arg(const char *name)
{
    for (int i = 1; i < A.argc; i++) {
        const char *a = A.argv[i];
        if (a[0] == '-' && a[1] == '-' && !strcmp(a + 2, name))
            return i + 1 < A.argc && strncmp(A.argv[i + 1], "--", 2) ? A.argv[i + 1] : "";
    }
    return NULL;
}

/* The logical screen keeps the design's short side and grows along the long
 * side with the screen, up to max_aspect (beyond that the renderer letterboxes).
 * Portrait screens use the design rotated, so layouts can adapt. Games with
 * `fixed` set get exactly the design size, letterboxed. */
static void update_logical_size(void)
{
    struct AXsize output = {1, 1};
    axGetSize(&output);
    float left = 0, top = 0, right = 0, bottom = 0;
#ifdef AX_PLATFORM_IOS
    axIOSGetSafeArea(&left, &top, &right, &bottom);
#endif
    const char *insets = app_arg("safe-area");
    if (insets) sscanf(insets, "%f,%f,%f,%f", &left, &top, &right, &bottom);
    left = clampf(left, 0, maxf(0, output.width - 1));
    right = clampf(right, 0, maxf(0, output.width - left - 1));
    top = clampf(top, 0, maxf(0, output.height - 1));
    bottom = clampf(bottom, 0, maxf(0, output.height - top - 1));
    rect safe = rc(left, top, maxf(1, output.width - left - right), maxf(1, output.height - top - bottom));
    float ow = safe.size.w * axGetScaling(), oh = safe.size.h * axGetScaling();
    size2 d = A.desc.design;
    float long_side = maxf(d.w, d.h), short_side = minf(d.w, d.h);
    bool portrait = oh > ow;
    float ratio = portrait ? (float)oh / maxf((float)ow, 1) : (float)ow / maxf((float)oh, 1);
    float max_ratio = A.desc.max_aspect > 0 ? A.desc.max_aspect : long_side / short_side;
    size2 l = ratio >= long_side / short_side ? sz2(short_side * minf(ratio, max_ratio), short_side)
                                               : sz2(long_side, long_side / ratio);
    l = sz2(roundf(l.w), roundf(l.h));
    if (portrait) l = sz2(l.h, l.w);
    if (A.desc.fixed) {
        /* fixed keeps the design's short side and layout; with a max_aspect it
         * may still grow along its long side, so a tall phone gets a taller
         * screen instead of letterbox bars */
        bool same_way = portrait == (d.h > d.w);
        float grown = roundf(short_side * minf(ratio, A.desc.max_aspect));
        l = d;
        if (same_way && grown > long_side) {
            if (d.h > d.w) l.h = grown;
            else l.w = grown;
        }
    }
    if (l.w != A.logical.w || l.h != A.logical.h) {
        A.logical = l;
    }
    A.view = app_fit_view(l, safe);
    A.output = sz2(output.width, output.height);
    A.pixel_scale = A.view.size.w * axGetScaling() / l.w;
}

static vec2 window_to_logical(vec2 p)
{
    float scale = A.view.size.w / A.logical.w;
    if (scale <= 0) return v2(0, 0);
    vec2 offset = A.view.pos;
    return vec2_scale(vec2_sub(p, offset), 1 / scale);
}

static void pointer_down(vec2 p)
{
    input *in = &A.in;
    in->pos = in->press_pos = p;
    in->down = in->pressed = true;
    in->dragging = false;
    in->captured = ui_blocks(p);
    in->multi_touch = false;
}

static void pointer_move(vec2 p)
{
    input *in = &A.in;
    vec2 delta = vec2_sub(p, in->pos);
    in->pos = p;
    if (!in->down || in->multi_touch) return;
    if (!in->dragging && vec2_dist(p, in->press_pos) > DRAG_THRESHOLD) {
        in->dragging = true;
        delta = vec2_sub(p, in->press_pos);
    }
    if (in->dragging) in->drag = vec2_add(in->drag, delta);
}

static void pointer_up(vec2 p)
{
    input *in = &A.in;
    pointer_move(p);
    if (!in->down) return;
    in->down = false;
    in->released = true;
    in->tap = !in->dragging && !in->multi_touch;
}

static void poll_events(void)
{
    input *in = &A.in;
    in->pressed = in->released = in->tap = false;
    in->drag = v2(0, 0);
    in->wheel = 0;
    in->pinch = 1;
    in->key = 0;
    in->back = false;
    if (!in->down) in->captured = false;

    struct AXmessage e;
    while (axPeekMessage(&e)) {
        if (A.desc.event) A.desc.event(&e);
        vec2 p = window_to_logical(v2((int16_t)e.x, (int16_t)e.y));
        bool hover = !(e.pointer.flags & (AX_POINTER_TOUCH | AX_POINTER_STYLUS));
        switch (e.message) {
        case kEventWindowClosed: A.running = false; break;
        case kEventLeftButtonDown: pointer_down(p); in->hover = hover; break;
        case kEventLeftButtonUp: pointer_up(p); in->hover = hover; break;
        case kEventLeftButtonDragged:
        case kEventMouseMoved: pointer_move(p); in->hover = hover; break;
        case kEventScrollWheel: in->wheel += e.dy; break;
        case kEventGesture:
            if (e.gesture.phase == AX_GESTURE_BEGIN) {
                in->multi_touch = true;
                in->dragging = in->tap = false;
                in->drag = v2(0, 0);
            }
            if (e.gesture.phase == AX_GESTURE_UPDATE && e.gesture.scale > 0) {
                in->pinch *= e.gesture.scale;
                in->pinch_center = window_to_logical(v2(e.gesture.x, e.gesture.y));
            }
            break;
        case kEventPointerCancel:
        case kEventKillFocus:
            in->down = in->pressed = in->released = in->dragging = in->hover = in->tap = false;
            in->captured = false;
            in->multi_touch = false;
            in->drag = v2(0, 0);
            break;
        case kEventKeyDown:
            in->key = e.keyCode;
            if (e.keyCode == AX_KEY_ESCAPE) in->back = true;
            break;
        }
        axDisposeMessage(&e);
    }
}

static bool needs_rotation(void)
{
    struct AXsize output = {1, 1};
    axGetSize(&output);
    return A.desc.landscape && output.width < output.height;
}

static void draw_rotate_prompt(void)
{
    if (!needs_rotation()) return;
    rect s = app_screen();
    draw_rect(s, A.desc.clear);
    vec2 c = vec2_sub(rect_center(s), v2(0, 90));
    rect phone = rect_centered(c, sz2(110, 180));
    draw_round_rect_line(phone, 16, 6, hex(0xE4BD78));
    draw_ring(c, 150, 5, color_alpha(hex(0xE4BD78), .35f));
    const ui_theme *t = ui_theme_get();
    if (t && t->title.font && A.desc.rotate_text)
        text_box(t->title, rc(60, c.y + 170, s.size.w - 120, 300), v2(.5f, 0), A.desc.rotate_text);
}

static void save_screenshot(const char *path)
{
    struct AXsize output = {1, 1};
    axGetSize(&output);
    int w = (int)lroundf(output.width * axGetScaling()), h = (int)lroundf(output.height * axGetScaling());
    unsigned char *px = malloc((size_t)w * h * 4);
    if (!px) return;
    if (render_read_pixels(px, w, h)) {
#ifdef ENGINE_TEST
        test_check_picture(px, w, h);
#endif
        if (stbi_write_png(path, w, h, 4, px, w * 4)) printf("screenshot: %s (%dx%d)\n", path, w, h);
        else fprintf(stderr, "screenshot: cannot write %s\n", path);
    } else {
        fprintf(stderr, "screenshot: cannot read framebuffer\n");
    }
    free(px);
}

void app_step(void)
{
    if (!A.running) return;
    longTime_t now = axGetMilliseconds();
    float dt = (float)(now - A.last_counter) / 1000;
    A.last_counter = now;
    if (A.shot_path || app_arg("smoke") || dt > .1f) dt = 1.0f / 60;
    A.time += dt;
    A.dt = dt;

    axBeginPaint();
#ifdef ENGINE_TEST
    in_frame = true;
    test_tick();
#endif
    update_logical_size();
    poll_events();
    if (needs_rotation()) A.in = (input){.pos = A.in.pos, .pinch = 1};   /* the game waits behind the rotate prompt */
    struct AXsize output = {1, 1};
    axGetSize(&output);
    render_begin(sz2(roundf(output.width * axGetScaling()), roundf(output.height * axGetScaling())), A.logical, rect_make(vec2_scale(A.view.pos, axGetScaling()), size2_scale(A.view.size, axGetScaling())), A.desc.clear);
    ui_begin_frame();
    if (A.desc.frame) A.desc.frame(dt);
    ui_end_frame(dt);
    draw_rotate_prompt();
#ifdef ENGINE_TEST
    if (A.shot_path) {
        bool last = false;
        const char *due = test_shot_due(++A.frame_index, A.shot_frames, A.shot_path, &last);
        if (due) save_screenshot(due);
        if (last) A.running = false;
    }
    in_frame = false;
#else
    if (A.shot_path && ++A.frame_index >= A.shot_frames) {
        save_screenshot(A.shot_path);
        A.running = false;
    }
#endif
    axEndPaint();

#ifdef __EMSCRIPTEN__
    if (!A.running) {
        emscripten_cancel_main_loop();
        app_stop();
    }
#endif
}

int app_run(app_desc desc, int argc, char **argv)
{
#ifdef __EMSCRIPTEN__
    if (argc <= 1) argc = web_args(&argv);   /* on the web, options come from the URL */
#endif
    memset(&A, 0, sizeof A);
#ifdef ENGINE_TEST
    test_clock_active = false;
    /* every test shares this process, and each starts clean */
    ui_restart();
    story_restart();
    fx_restart();
    city_restart();
#endif
    A.desc = desc;
    A.argc = argc;
    A.argv = argv;
    if (A.desc.design.w <= 0) A.desc.design = sz2(1200, 900);
    if (A.desc.clear.a == 0) A.desc.clear = hex(0x102F32);
    A.shot_path = app_arg("shot");
    if (A.shot_path && !*A.shot_path) A.shot_path = NULL;
    A.shot_frames = app_arg("frames") ? atoi(app_arg("frames")) : 3;

#ifdef ENGINE_TEST
    if (!window_open)
#endif
    axInit();

    int w = (int)A.desc.design.w, h = (int)A.desc.design.h;
    const char *size = app_arg("size");
    if (size && sscanf(size, "%dx%d", &w, &h) != 2) w = (int)A.desc.design.w, h = (int)A.desc.design.h;
#ifdef __EMSCRIPTEN__
    double cw, ch;
    emscripten_get_element_css_size("#canvas", &cw, &ch);
    if (cw > 0 && ch > 0) w = (int)cw, h = (int)ch;
#endif
    if (w <= 0 || h <= 0) { fprintf(stderr, "invalid window size\n"); axShutdown(); return 1; }
    uint32_t flags = AX_WINDOW_RESIZABLE | AX_WINDOW_HIGHDPI | AX_WINDOW_DOUBLEBUFFER;
    if (app_arg("headless")) flags |= AX_WINDOW_HIDDEN;
#ifdef ENGINE_TEST
    if (window_open) {   /* one window serves every test, resized for each */
        axClearMessageQueue();
        axSetSize(w, h, false);
    } else
#endif
    if (!axCreateWindow(desc.title ? desc.title : "game", w, h, flags)) {
        fprintf(stderr, "platform: cannot create window\n"); axShutdown(); return 1;
    }
#ifdef ENGINE_TEST
    window_open = true;
#endif
#ifdef ENGINE_TEST
    axSetSwapInterval(0);   /* tests present for real, without waiting for display refresh */
#else
    axSetSwapInterval(app_arg("smoke") || A.shot_path ? 0 : 1);
#endif
    if (!render_init()) { axShutdown(); return 1; }
    update_logical_size();
    A.in.pinch = 1;
    A.running = true;
    A.last_counter = axGetMilliseconds();
    if (desc.init) desc.init();

#ifdef __EMSCRIPTEN__
    emscripten_set_main_loop(app_step, 0, 1);
#elif !defined(AX_PLATFORM_IOS)
    while (A.running) app_step();
    app_stop();
#endif
    return 0;
}

void app_stop(void)
{
    if (!render_ready()) return;
    A.running = false;
    if (A.desc.quit) A.desc.quit();
    sfx_shutdown();
    font_shutdown();
    render_shutdown();
#ifdef ENGINE_TEST
    A.argc = 0;   /* the arguments belonged to this test, and later ones may read app_arg */
#else
    axShutdown();
#endif
}

#ifdef ENGINE_TEST
/* A failed test may stop mid-frame. Finish what it left open; its script is broken,
 * so its quit hook doesn't run. */
void app_test_recover(void)
{
    if (in_frame) axEndPaint();
    in_frame = false;
    A.desc.quit = NULL;
    if (render_ready()) app_stop();
    A.running = false;
}

void app_test_close_window(void)
{
    if (window_open) axShutdown();
    window_open = false;
}
#endif
