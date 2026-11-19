/* Real GPU/llvmpipe checks and an inclusive blur+readback timing sample. */
#include "render.h"
#include "test/test.h"
#include "viewport.h"
#include <stdio.h>

static int frames, w, h, resizes, settling;
static bool present_pending = true;
static unsigned char *pixels;
static color sample(float x, float y)
{
    rect view=app_fit_view(sz2(480,900),rc(0,0,w,h));
    float scale=view.size.w/480;
    int px = clampi((int)(view.pos.x+x*scale), 0, w - 1), py = clampi((int)(view.pos.y+y*scale), 0, h - 1);
    unsigned char *p = pixels + ((size_t)py * w + px) * 4;
    return rgba(p[0],p[1],p[2],p[3]);
}
static void frame(float dt)
{
    (void)dt;
    struct AXsize size; axGetSize(&size);
    int width = (int)roundf(size.width * axGetScaling()), height = (int)roundf(size.height * axGetScaling());
    /* X11 applies window creation/resizing asynchronously, and EGL may resize
     * its backing surface only on swap. Present once before reading each size. */
    int expected_width = frames >= 5 && frames < 8 ? 320 : 480;
    int expected_height = frames >= 5 && frames < 8 ? 600 : 900;
    if ((int)roundf(size.width) != expected_width || (int)roundf(size.height) != expected_height) {
        if (++settling > 120) { CHECK(false); app_quit(); }
        return;
    }
    settling = 0;
    if (present_pending) { present_pending = false; return; }
    if (width != w || height != h) {
        if (w) resizes++;
        free(pixels); w=width; h=height; pixels=malloc((size_t)w*h*4);
    }
    CHECK(pixels != NULL);
    if (!pixels) { app_quit(); return; }
    draw_rect(rc(0,0,240,900), BLACK); draw_rect(rc(240,0,240,900), WHITE);
    gfx_clip(rc(24,24,10,10));
    gfx_additive(true);
    gfx_backdrop(7,CLEAR);
    CHECK(render_read_pixels(pixels,w,h));
    color c=sample(237,100); CHECK(c.r>15 && c.r<127); /* blur ignores caller's clip */
    c=sample(243,100); CHECK(c.r>127 && c.r<240);
    c=sample(80,100); CHECK(c.r<2); /* no unintended dim or layer inversion */
    gfx_additive(false);
    draw_rect(rc(0,0,480,900),rgba(255,0,0,255));
    CHECK(render_read_pixels(pixels,w,h));
    c=sample(28,28);CHECK(c.r>250 && c.g<5); /* scissor restored */
    c=sample(40,28);CHECK(c.r<2);
    gfx_unclip();
    draw_rect(rc(300,100,40,40),BLACK);
    CHECK(render_read_pixels(pixels,w,h));
    CHECK(sample(301,110).r<2 && sample(299,110).r>250); /* foreground stays sharp */
    gfx_backdrop(4,CLEAR); /* second modal includes the preceding sharp layer */
    CHECK(render_read_pixels(pixels,w,h));
    c=sample(299,110);CHECK(c.r>20 && c.r<250);
    gfx_backdrop(0,rgba(0,0,0,128));
    CHECK(render_read_pixels(pixels,w,h));
    c=sample(440,800);CHECK(c.r>=125 && c.r<=128);
    /* A moving popup keeps its own scissor and opacity at both sizes. */
    ui_popup_transform(v2(0,24),.5f);
    gfx_clip(rc(30,40,30,20));
    draw_rect(rc(25,35,40,30),WHITE);
    gfx_unclip();
    ui_popup_transform(v2(0,0),1);
    draw_rect(rc(80,40,20,20),WHITE);
    CHECK(render_read_pixels(pixels,w,h));
    CHECK(sample(40,50).r<2 && sample(29,75).r<2);
    c=sample(40,75);CHECK(c.r>=125 && c.r<=129);
    CHECK(sample(90,50).r>250 && sample(90,75).r<2);
    frames++;
    if (frames == 5) { axSetSize(320,600,false); present_pending=true; }
    if (frames == 8) { axSetSize(480,900,false); present_pending=true; }
    if (frames == 11) { CHECK(resizes >= 2); app_quit(); }
}
static void quit(void) { free(pixels); pixels=NULL; }
TEST(backdrop)
{
    char *args[]={"test-backdrop","--headless","--mute","--size","480x900"};
    app_desc d={.design={480,900},.fixed=true,.frame=frame,.quit=quit};
    CHECK(app_run(d,5,args)==0);
}
