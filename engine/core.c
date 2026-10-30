/* core.c — window, logical screen, main loop, input gestures, screenshots. */
#include "render.h"

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
        if (value !== '') words.push(value);
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
    float pixel_scale;
    double time;
    float dt;
    longTime_t last_counter;
    input in;
    bool pinched;          /* a second finger joined during this press */
    const char *shot_path;
    int shot_frames;
    int frame_index;
} A;

const char *app_id(void) { return A.desc.id ? A.desc.id : "game"; }
rect app_screen(void) { return rect_make(v2(0, 0), A.logical); }
float app_pixel_scale(void) { return A.pixel_scale; }
double app_time(void) { return A.time; }
float app_dt(void) { return A.dt; }
double app_clock(void) { return (double)time(NULL); }
void app_quit(void) { A.running = false; }
input input_get(void) { return A.in; }

/* Queue window coordinates, just like native pointer events. */
void app_inject_click(vec2 p)
{
    struct AXsize window = {1, 1};
    axGetSize(&window);
    size2 size = sz2((float)window.width, (float)window.height);
    float scale = size2_fit(A.logical, size);
    vec2 offset = vec2_scale(vec2_sub(size2_vec(size), vec2_scale(size2_vec(A.logical), scale)), .5f);
    vec2 at = vec2_add(offset, vec2_scale(p, scale));
    uint32_t xy = MAKEDWORD((int)lroundf(at.x), (int)lroundf(at.y));
    axPostMessageW(NULL, kEventLeftButtonDown, xy, NULL);
    axPostMessageW(NULL, kEventLeftButtonUp, xy, NULL);
}

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
    float ow = maxf(output.width * axGetScaling(), 1), oh = maxf(output.height * axGetScaling(), 1);
    size2 d = A.desc.design;
    float long_side = maxf(d.w, d.h), short_side = minf(d.w, d.h);
    bool portrait = oh > ow;
    float ratio = portrait ? (float)oh / maxf((float)ow, 1) : (float)ow / maxf((float)oh, 1);
    float max_ratio = A.desc.max_aspect > 0 ? A.desc.max_aspect : long_side / short_side;
    size2 l = ratio >= long_side / short_side ? sz2(short_side * minf(ratio, max_ratio), short_side)
                                               : sz2(long_side, long_side / ratio);
    l = sz2(roundf(l.w), roundf(l.h));
    if (portrait) l = sz2(l.h, l.w);
    if (A.desc.fixed) l = d;
    if (l.w != A.logical.w || l.h != A.logical.h) {
        A.logical = l;
    }
    A.pixel_scale = minf(ow / l.w, oh / l.h);
}

static vec2 window_to_logical(vec2 p)
{
    struct AXsize window = {1, 1};
    axGetSize(&window);
    size2 size = sz2((float)window.width, (float)window.height);
    float scale = size2_fit(A.logical, size);
    if (scale <= 0) return v2(0, 0);
    vec2 offset = vec2_scale(vec2_sub(size2_vec(size), vec2_scale(size2_vec(A.logical), scale)), .5f);
    return vec2_scale(vec2_sub(p, offset), 1 / scale);
}

static void pointer_down(vec2 p)
{
    input *in = &A.in;
    in->pos = in->press_pos = p;
    in->down = in->pressed = true;
    in->dragging = false;
    in->captured = ui_blocks(p);
    A.pinched = false;
}

static void pointer_move(vec2 p)
{
    input *in = &A.in;
    vec2 delta = vec2_sub(p, in->pos);
    in->pos = p;
    if (!in->down || A.pinched) return;
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
    in->tap = !in->dragging && !A.pinched;
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
            if (e.gesture.phase == AX_GESTURE_BEGIN) { A.pinched = true; in->dragging = false; }
            if (e.gesture.phase == AX_GESTURE_UPDATE && e.gesture.scale > 0) {
                in->pinch *= e.gesture.scale;
                in->pinch_center = window_to_logical(v2(e.gesture.x, e.gesture.y));
            }
            break;
        case kEventPointerCancel:
        case kEventKillFocus:
            in->down = in->dragging = in->hover = in->tap = false;
            in->captured = false;
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

static void save_screenshot(void)
{
    struct AXsize output = {1, 1};
    axGetSize(&output);
    int w = (int)lroundf(output.width * axGetScaling()), h = (int)lroundf(output.height * axGetScaling());
    unsigned char *px = malloc((size_t)w * h * 4);
    if (!px) return;
    if (render_read_pixels(px, w, h)) {
        if (stbi_write_png(A.shot_path, w, h, 4, px, w * 4)) printf("screenshot: %s (%dx%d)\n", A.shot_path, w, h);
        else fprintf(stderr, "screenshot: cannot write %s\n", A.shot_path);
    } else {
        fprintf(stderr, "screenshot: cannot read framebuffer\n");
    }
    free(px);
    A.running = false;
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
    update_logical_size();
    poll_events();
    if (needs_rotation()) A.in = (input){.pos = A.in.pos, .pinch = 1};   /* the game waits behind the rotate prompt */
    struct AXsize output = {1, 1};
    axGetSize(&output);
    render_begin(sz2(roundf(output.width * axGetScaling()), roundf(output.height * axGetScaling())), A.logical, A.desc.clear);
    ui_begin_frame();
    if (A.desc.frame) A.desc.frame(dt);
    ui_end_frame(dt);
    draw_rotate_prompt();
    if (A.shot_path && ++A.frame_index >= A.shot_frames) save_screenshot();
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
    A.desc = desc;
    A.argc = argc;
    A.argv = argv;
    if (A.desc.design.w <= 0) A.desc.design = sz2(1200, 900);
    if (A.desc.clear.a == 0) A.desc.clear = hex(0x102F32);
    A.shot_path = app_arg("shot");
    if (A.shot_path && !*A.shot_path) A.shot_path = NULL;
    A.shot_frames = app_arg("frames") ? atoi(app_arg("frames")) : 3;

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
    if (!axCreateWindow(desc.title ? desc.title : "game", w, h, flags)) {
        fprintf(stderr, "platform: cannot create window\n"); axShutdown(); return 1;
    }
    axSetSwapInterval(app_arg("smoke") || A.shot_path ? 0 : 1);
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
    axShutdown();
}
