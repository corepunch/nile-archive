/* core.c — window, logical screen, main loop, input gestures, screenshots. */
#include "engine.h"

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
#define MAX_FINGERS 2

static struct {
    app_desc desc;
    SDL_Window *window;
    SDL_Renderer *renderer;
    int argc;
    char **argv;
    bool running;
    size2 logical;
    float pixel_scale;
    double time;
    float dt;
    Uint64 last_counter;
    input in;
    bool pinched;          /* a second finger joined during this press */
    struct { SDL_FingerID id; vec2 pos; bool used; } fingers[MAX_FINGERS];
    float pinch_dist;
    const char *shot_path;
    int shot_frames;
    int frame_index;
} A;

SDL_Renderer *app_renderer(void) { return A.renderer; }
const char *app_id(void) { return A.desc.id ? A.desc.id : "game"; }
rect app_screen(void) { return rect_make(v2(0, 0), A.logical); }
float app_pixel_scale(void) { return A.pixel_scale; }
double app_time(void) { return A.time; }
float app_dt(void) { return A.dt; }
double app_clock(void) { return (double)time(NULL); }
void app_quit(void) { A.running = false; }
input input_get(void) { return A.in; }

/* A press and a release at a logical point, through SDL's event queue so the
 * game sees them exactly as a tap (tests and the smoke run use it). */
void app_inject_click(vec2 p)
{
    SDL_Event e = {0};
    int x, y;
    SDL_RenderLogicalToWindow(A.renderer, p.x, p.y, &x, &y);
    e.type = SDL_MOUSEBUTTONDOWN;
    e.button.button = SDL_BUTTON_LEFT;
    e.button.windowID = SDL_GetWindowID(A.window);   /* SDL maps it to logical units */
    e.button.x = x, e.button.y = y;
    SDL_PushEvent(&e);   /* SDL rewrites the coordinates in place to logical units... */
    e.type = SDL_MOUSEBUTTONUP;
    e.button.x = x, e.button.y = y;   /* ...so the release needs window units again */
    SDL_PushEvent(&e);
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
 * side with the screen, up to max_aspect (beyond that SDL letterboxes).
 * Portrait screens use the design rotated, so layouts can adapt. Games with
 * `fixed` set get exactly the design size, letterboxed. */
static void update_logical_size(void)
{
    int ow = 1, oh = 1;
    SDL_GetRendererOutputSize(A.renderer, &ow, &oh);
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
        SDL_RenderSetLogicalSize(A.renderer, (int)l.w, (int)l.h);
    }
    A.pixel_scale = minf(ow / l.w, oh / l.h);
}

static vec2 finger_to_logical(float nx, float ny)
{
    int ww, wh;
    float lx, ly;
    SDL_GetWindowSize(A.window, &ww, &wh);
    SDL_RenderWindowToLogical(A.renderer, (int)(nx * ww), (int)(ny * wh), &lx, &ly);
    return v2(lx, ly);
}

static int finger_count(void)
{
    int n = 0;
    for (int i = 0; i < MAX_FINGERS; i++) n += A.fingers[i].used;
    return n;
}

static void pinch_measure(float *dist, vec2 *center)
{
    *dist = vec2_dist(A.fingers[0].pos, A.fingers[1].pos);
    *center = vec2_lerp(A.fingers[0].pos, A.fingers[1].pos, .5f);
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

static void handle_finger(const SDL_Event *e)
{
    vec2 p = finger_to_logical(e->tfinger.x, e->tfinger.y);
    int slot = -1;
    for (int i = 0; i < MAX_FINGERS; i++)
        if (A.fingers[i].used && A.fingers[i].id == e->tfinger.fingerId) slot = i;
    if (e->type == SDL_FINGERDOWN && slot < 0) {
        for (int i = 0; i < MAX_FINGERS && slot < 0; i++)
            if (!A.fingers[i].used) slot = i;
        if (slot < 0) return;
        A.fingers[slot].used = true;
        A.fingers[slot].id = e->tfinger.fingerId;
        A.fingers[slot].pos = p;
        if (finger_count() == 2) {
            vec2 c;
            pinch_measure(&A.pinch_dist, &c);
            A.pinched = true;
            A.in.dragging = false;
        }
        return;
    }
    if (slot < 0) return;
    A.fingers[slot].pos = p;
    if (e->type == SDL_FINGERMOTION && finger_count() == 2) {
        float d;
        vec2 c;
        pinch_measure(&d, &c);
        if (A.pinch_dist > 1 && d > 1) A.in.pinch *= d / A.pinch_dist;
        A.in.pinch_center = c;
        A.pinch_dist = d;
    }
    if (e->type == SDL_FINGERUP) A.fingers[slot].used = false;
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

    SDL_Event e;
    while (SDL_PollEvent(&e)) {
        switch (e.type) {
        case SDL_QUIT: A.running = false; break;
        case SDL_MOUSEBUTTONDOWN:
            if (e.button.button == SDL_BUTTON_LEFT) pointer_down(v2((float)e.button.x, (float)e.button.y));
            in->hover = e.button.which != SDL_TOUCH_MOUSEID;
            break;
        case SDL_MOUSEBUTTONUP:
            if (e.button.button == SDL_BUTTON_LEFT) pointer_up(v2((float)e.button.x, (float)e.button.y));
            in->hover = e.button.which != SDL_TOUCH_MOUSEID;
            break;
        case SDL_MOUSEMOTION:
            pointer_move(v2((float)e.motion.x, (float)e.motion.y));
            in->hover = e.motion.which != SDL_TOUCH_MOUSEID;
            break;
        case SDL_MOUSEWHEEL: in->wheel += e.wheel.preciseY; break;
        case SDL_FINGERDOWN:
        case SDL_FINGERMOTION:
        case SDL_FINGERUP: handle_finger(&e); break;
        case SDL_WINDOWEVENT:
            if (e.window.event == SDL_WINDOWEVENT_LEAVE) in->hover = false;
            break;
        case SDL_KEYDOWN:
            in->key = e.key.keysym.sym;
            if (e.key.keysym.sym == SDLK_ESCAPE || e.key.keysym.sym == SDLK_AC_BACK) in->back = true;
            break;
        }
    }
}

static bool needs_rotation(void)
{
    int ow, oh;
    SDL_GetRendererOutputSize(A.renderer, &ow, &oh);
    return A.desc.landscape && ow < oh;
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
    int w, h;
    SDL_GetRendererOutputSize(A.renderer, &w, &h);
    unsigned char *px = malloc((size_t)w * h * 4);
    if (!px) return;
    SDL_RenderSetLogicalSize(A.renderer, 0, 0);
    SDL_RenderSetScale(A.renderer, 1, 1);
    if (SDL_RenderReadPixels(A.renderer, NULL, SDL_PIXELFORMAT_ABGR8888, px, w * 4) == 0) {
        if (stbi_write_png(A.shot_path, w, h, 4, px, w * 4)) printf("screenshot: %s (%dx%d)\n", A.shot_path, w, h);
        else fprintf(stderr, "screenshot: cannot write %s\n", A.shot_path);
    } else {
        fprintf(stderr, "screenshot: %s\n", SDL_GetError());
    }
    free(px);
    A.running = false;
}

static void frame(void)
{
    Uint64 now = SDL_GetPerformanceCounter();
    float dt = (float)(now - A.last_counter) / (float)SDL_GetPerformanceFrequency();
    A.last_counter = now;
    if (A.shot_path || dt > .1f) dt = 1.0f / 60;
    A.time += dt;
    A.dt = dt;

    poll_events();
    update_logical_size();
    if (needs_rotation()) A.in = (input){.pos = A.in.pos, .pinch = 1};   /* the game waits behind the rotate prompt */
    SDL_SetRenderDrawColor(A.renderer, A.desc.clear.r, A.desc.clear.g, A.desc.clear.b, 255);
    SDL_RenderClear(A.renderer);
    ui_begin_frame();
    if (A.desc.frame) A.desc.frame(dt);
    ui_end_frame(dt);
    draw_rotate_prompt();
    if (A.shot_path && ++A.frame_index >= A.shot_frames) save_screenshot();
    SDL_RenderPresent(A.renderer);

#ifdef __EMSCRIPTEN__
    if (!A.running) {
        emscripten_cancel_main_loop();
        if (A.desc.quit) A.desc.quit();
    }
#endif
}

int app_run(app_desc desc, int argc, char **argv)
{
#ifdef __EMSCRIPTEN__
    if (argc <= 1) argc = web_args(&argv);   /* on the web, options come from the URL */
#endif
    A.desc = desc;
    A.argc = argc;
    A.argv = argv;
    if (A.desc.design.w <= 0) A.desc.design = sz2(1200, 900);
    if (A.desc.clear.a == 0) A.desc.clear = hex(0x102F32);
    A.shot_path = app_arg("shot");
    if (A.shot_path && !*A.shot_path) A.shot_path = NULL;
    A.shot_frames = app_arg("frames") ? atoi(app_arg("frames")) : 3;

    SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "1");
    SDL_SetHint(SDL_HINT_MOUSE_TOUCH_EVENTS, "0");
#ifdef SDL_HINT_EMSCRIPTEN_KEYBOARD_ELEMENT
    SDL_SetHint(SDL_HINT_EMSCRIPTEN_KEYBOARD_ELEMENT, "#canvas");
#endif
    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_EVENTS) != 0) {
        fprintf(stderr, "SDL_Init: %s\n", SDL_GetError());
        return 1;
    }

    int w = (int)A.desc.design.w, h = (int)A.desc.design.h;
    const char *size = app_arg("size");
    if (size && sscanf(size, "%dx%d", &w, &h) != 2) w = (int)A.desc.design.w, h = (int)A.desc.design.h;
#ifdef __EMSCRIPTEN__
    double cw, ch;
    emscripten_get_element_css_size("#canvas", &cw, &ch);
    if (cw > 0 && ch > 0) w = (int)cw, h = (int)ch;
#else
    SDL_DisplayMode dm;
    if (!size && SDL_GetDesktopDisplayMode(0, &dm) == 0) {
        float k = minf(1, minf(dm.w * .9f / w, dm.h * .85f / h));
        w = (int)(w * k), h = (int)(h * k);
    }
#endif
    A.window = SDL_CreateWindow(desc.title ? desc.title : "game", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, w, h,
                                SDL_WINDOW_RESIZABLE | SDL_WINDOW_ALLOW_HIGHDPI);
    if (!A.window) {
        fprintf(stderr, "SDL_CreateWindow: %s\n", SDL_GetError());
        return 1;
    }
    A.renderer = SDL_CreateRenderer(A.window, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
    if (!A.renderer) A.renderer = SDL_CreateRenderer(A.window, -1, SDL_RENDERER_SOFTWARE);
    if (!A.renderer) {
        fprintf(stderr, "SDL_CreateRenderer: %s\n", SDL_GetError());
        return 1;
    }
    SDL_SetRenderDrawBlendMode(A.renderer, SDL_BLENDMODE_BLEND);
    update_logical_size();
    A.in.pinch = 1;
    A.running = true;
    A.last_counter = SDL_GetPerformanceCounter();
    if (desc.init) desc.init();

#ifdef __EMSCRIPTEN__
    emscripten_set_main_loop(frame, 0, 1);
#else
    while (A.running) frame();
    if (desc.quit) desc.quit();
    SDL_DestroyRenderer(A.renderer);
    SDL_DestroyWindow(A.window);
    SDL_Quit();
#endif
    return 0;
}
