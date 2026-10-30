/* Real-context integration checks: pixels, logical pointer mapping and gestures.
 * Linux: xvfb-run -a make test-platform. macOS: make test-platform. */
#include "render.h"
#include "viewport.h"
#include <stdio.h>
#include <string.h>

static int checks, failures, step;
static texture tile;
static unsigned char *pixels;
static int width, height;
#define CHECK(c) do { checks++; if (!(c)) { failures++; fprintf(stderr, "%d: %s\n", __LINE__, #c); } } while (0)

static void post(uint32_t type, int x, int y)
{
    axPostMessageW(NULL, type, MAKEDWORD(x, y), NULL);
}

static void init(void)
{
    const unsigned char rgba[] = {255, 0, 0, 255, 0, 255, 0, 255,
                                 0, 0, 255, 255, 255, 255, 255, 255};
    tile = tex_from_pixels(rgba, 2, 2);
    CHECK(tile.tex != NULL);
    app_inject_click(v2(30, 20));
}

static color pixel(float x, float y)
{
    float l = 0, t = 0, r = 0, b = 0;
    if (app_arg("safe-area")) sscanf(app_arg("safe-area"), "%f,%f,%f,%f", &l, &t, &r, &b);
    float dpi = axGetScaling();
    rect view = app_fit_view(sz2(100, 100), rc(l * dpi, t * dpi, width - (l + r) * dpi, height - (t + b) * dpi));
    float scale = view.size.w / 100;
    int px = (int)(view.pos.x + x * scale);
    int py = (int)(view.pos.y + y * scale);
    unsigned char *p = pixels + (py * width + px) * 4;
    return rgba(p[0], p[1], p[2], p[3]);
}

static void draw_and_check(void)
{
    draw_rect(rc(0, 0, 100, 100), hex(0x000000));
    draw_image(tile, rc(0, 0, 40, 40), hex(0xFFFFFF));
    gfx_clip(rc(50, 0, 10, 10));
    draw_rect(rc(40, 0, 40, 30), hex(0xFF0000));
    gfx_unclip();
    draw_rect(rc(0, 50, 20, 20), rgba(0, 255, 0, 128));
    gfx_additive(true);
    draw_rect(rc(0, 50, 20, 20), rgba(255, 0, 0, 128));
    gfx_additive(false);
    draw_image_part(tile, rc(1, 0, 1, 1), rc(25, 50, 20, 20), hex(0xFFFFFF));
    draw_image_rot(tile, rc(50, 50, 40, 40), ENGINE_PI, hex(0xFFFFFF));
    struct AXsize size;
    axGetSize(&size);
    width = (int)roundf(size.width * axGetScaling()); height = (int)roundf(size.height * axGetScaling());
    pixels = malloc((size_t)width * height * 4);
    CHECK(pixels && render_read_pixels(pixels, width, height));
    if (!pixels) return;
    color c = pixel(5, 5); CHECK(c.r > 240 && c.g < 15 && c.b < 15);
    c = pixel(35, 5); CHECK(c.g > 240 && c.r < 15);
    c = pixel(5, 35); CHECK(c.b > 240 && c.r < 15);
    c = pixel(55, 5); CHECK(c.r > 240);
    c = pixel(45, 5); CHECK(c.r == 0 && c.g == 0 && c.b == 0);
    c = pixel(55, 15); CHECK(c.r == 0);
    c = pixel(10, 60); CHECK(c.r > 120 && c.r < 135 && c.g > 120 && c.g < 135 && c.b == 0);
    c = pixel(35, 60); CHECK(c.g > 230 && c.r < 25);
    c = pixel(85, 85); CHECK(c.r > 240 && c.g < 15 && c.b < 15);
    /* The left letterbox stays at the clear color, outside the logical scene. */
    CHECK(pixels[(height / 2 * width) * 4] == 16);
    free(pixels); pixels = NULL;
}

static void frame(float dt)
{
    (void)dt;
    input in = input_get();
    if (step == 0) {
        CHECK(in.pressed && in.released && in.tap && !in.down);
        CHECK(fabsf(in.pos.x - 30) < 1 && fabsf(in.pos.y - 20) < 1);
        draw_and_check();
        struct AXmessage gesture = {.message = kEventGesture, .gesture = {.phase = AX_GESTURE_BEGIN}};
        axPostMessageOwnedW(gesture);
        gesture.gesture = (ax_gesture_t){.phase = AX_GESTURE_UPDATE, .x = 100, .y = 60, .scale = 1.25f};
        axPostMessageOwnedW(gesture);
        post(kEventKeyDown, AX_KEY_ESCAPE, 0);
    } else if (step == 1) {
        CHECK(!in.pressed && !in.released && !in.tap);
        CHECK(fabsf(in.pinch - 1.25f) < .001f);
        CHECK(in.back && in.key == AX_KEY_ESCAPE);
        post(kEventLeftButtonDown, 100, 60);
        post(kEventPointerCancel, 0, 0);
    } else {
        CHECK(!in.down && !in.pressed && !in.released && !in.dragging && !in.tap && !in.captured);
        CHECK(in.pinch == 1 && !in.back && in.key == 0);
        app_quit();
    }
    step++;
}

static void quit(void) { tex_free(tile); }
int main(int argc, char **argv)
{
    char *args[] = {"test-platform", "--headless", "--size", "320x200", "--mute", "--safe-area", "35,21,11,7"};
    app_desc desc = {.design = {100, 100}, .fixed = true, .clear = {16, 32, 48, 255}, .init = init, .frame = frame, .quit = quit};
    CHECK(app_run(desc, argc > 1 ? 7 : 5, args) == 0);
    CHECK(step == 3);
    printf("platform renderer/input: %d checks, %d failures\n", checks, failures);
    return failures != 0;
}
