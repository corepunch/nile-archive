/* Real rendered pixels: a cloud/burst must not engulf the speaker's badge or
 * introduce a large blank band above the words. Also exercise resize/letterbox, centred framed groups and Skip input. */
#include "render.h"
#include "test.h"
#include <stdio.h>

static int sample_index, settling, skip_wait;
static bool testing_skip;
static bool present_pending = true;
static font *lettering;
static character cast[] = {{.id="ann", .name="Ann", .color={30,190,80,255}},
                           {.id="other", .name="Other", .color={30,190,80,255}}};
static texture portrait;
static story_style test_style;
/* 18 caption cases, 24 single-portrait cases, then 12 with listeners. */
enum { TOTAL_CASES = 54 };
static int screen_for(int index)
{
    if (index<18) return index/6;
    index-=18;
    return index<24 ? index/12 : (index-24)/6;
}
static const int widths[] = {480,390,1200}, heights[] = {900,844,900};
#undef CHECK
#define CHECK(c) CHECKF(c, "case %d", sample_index)
static int imin(int a,int b) { return a<b ? a:b; }
static int imax(int a,int b) { return a>b ? a:b; }

static void init(void)
{
    lettering=font_load("fonts/LilitaOne-Regular.ttf");
    CHECK(lettering != NULL);
    test_style=(story_style){.text={.font=lettering,.size=21,.fill={20,20,20,255}},
        .name={.font=lettering,.size=15,.fill={255,255,255,255}},
        .bubble={250,230,200,255},.edge={180,40,30,255}};
    story_setup(cast,2,&test_style);
    unsigned char face[4*5*4];
    for (int i=0;i<20;i++) { face[i*4]=20;face[i*4+1]=70;face[i*4+2]=210;face[i*4+3]=255; }
    portrait=tex_from_pixels(face,4,5);
    CHECK(portrait.tex != NULL);
}

static void frame(float dt)
{
    (void)dt;
    if (testing_skip) {
        story_frame(1.f/60);
        if (!story_active()) { CHECK(true);app_quit(); }
        else if (++skip_wait>12) { CHECK(false);app_quit(); }
        return;
    }
    int screen=screen_for(sample_index);
    struct AXsize window;axGetSize(&window);
    if ((int)window.width!=widths[screen] || (int)window.height!=heights[screen]) {
        if (++settling>120) { CHECK(false);app_quit(); }
        return;
    }
    settling=0;
    if (present_pending) { present_pending=false;return; } /* EGL backing resize happens on swap */
    bubble_kind kind=(bubble_kind)(sample_index%3);
    bool framed=sample_index>=18;
    bool listening=sample_index>=42;
    const char *line=sample_index%6<3 ? "A short line" : "Another line belongs below the first line";
    if (framed) {
        cast[0].portrait=cast[1].portrait=portrait;
        cast[0].right=(sample_index-18)%(listening ? 6 : 12)>=(listening ? 3 : 6);
        cast[1].right=!cast[0].right;
        test_style.framed=true;test_style.portrait_height=.27f;
        story_setup(cast,2,&test_style);
    }
    if (listening) {
        story_line_add((story_line){"other","Previous speaker",kind});
        story_line_add((story_line){"ann",line,kind});
        story_frame(10);story_next();
        draw_rect(app_bleed(),rgba(10,20,70,255));
    } else story_line_add((story_line){"ann",line,kind});
    story_frame(10); /* settled bubble, complete text */
    int w=(int)roundf(window.width*axGetScaling()),h=(int)roundf(window.height*axGetScaling());
    unsigned char *pixels=malloc((size_t)w*h*4);
    CHECK(pixels && render_read_pixels(pixels,w,h));
    if (!pixels) { app_quit();return; }
    if (framed) {
        int x0=w,y0=h,x1=-1,y1=-1;
        for (int y=0;y<h;y++) for (int x=0;x<w;x++) {
            unsigned char *p=pixels+((size_t)y*w+x)*4;
            if (p[0]>70 && p[1]<65 && p[2]<65) {
                x0=imin(x0,x);y0=imin(y0,y);x1=imax(x1,x);y1=imax(y1,y);
            }
        }
        float scale=w/app_bleed().size.w;
        vec2 expected=vec2_scale(vec2_sub(rect_center(app_screen()),app_bleed().pos),scale);
        CHECK(x1>x0 && y1>y0);
        CHECK(fabsf((x0+x1+1)*.5f-expected.x)<3*scale+1);
        CHECK(fabsf((y0+y1+1)*.5f-expected.y)<3*scale+1);
        CHECK(x0>0 && y0>0 && x1<w-1 && y1<h-1);
        if (test_failures()) fprintf(stderr,"  framed %d,%d..%d,%d expected %.2f,%.2f scale %.2f\n",x0,y0,x1,y1,expected.x,expected.y,scale);
        if (sample_index==TOTAL_CASES-1) {
            /* Find the real rendered Skip pill above a two-portrait unit,
             * then activate it through the platform's input queue. */
            test_style.skip="SKIP";story_setup(cast,2,&test_style);
            draw_rect(app_bleed(),rgba(10,20,70,255));story_frame(0);
            CHECK(render_read_pixels(pixels,w,h));
            int sx0=w,sy0=h,sx1=-1,sy1=-1;
            for (int y=0;y<y0-4*scale;y++) for (int x=0;x<w;x++) {
                unsigned char *p=pixels+((size_t)y*w+x)*4;
                if (p[0]>100 && p[1]<65 && p[2]<65) {
                    sx0=imin(sx0,x);sy0=imin(sy0,y);sx1=imax(sx1,x);sy1=imax(sy1,y);
                }
            }
            CHECK(sx1>sx0 && sy1>sy0);
            app_inject_click(vec2_add(app_bleed().pos,v2((sx0+sx1+1)*.5f/scale,(sy0+sy1+1)*.5f/scale)));
            free(pixels);testing_skip=true;sample_index=TOTAL_CASES;return;
        }
    } else {
        int left=w,right=-1,top=h,bottom=-1;
        for (int y=h/2;y<h;y++) for (int x=0;x<w;x++) {
            unsigned char *p=pixels+((size_t)y*w+x)*4;
            if (p[0]<70 && p[1]>160 && p[2]>50 && p[2]<110) {
                left=imin(left,x);right=imax(right,x);top=imin(top,y);bottom=imax(bottom,y);
            }
        }
        CHECK(right>left && bottom>top);
        float scale=w/app_bleed().size.w, center=(top+bottom+1)*.5f;
        int outline=h,ink=h;
        for (int y=h/2;y<h;y++) for (int x=0;x<w;x++) {
            unsigned char *p=pixels+((size_t)y*w+x)*4;
            if ((x<left-4*scale || x>right+4*scale) && p[0]>150 && p[1]<65 && p[2]<60) outline=imin(outline,y);
            if (p[0]>=18 && p[0]<=22 && p[1]>=18 && p[1]<=22 && p[2]>=18 && p[2]<=22) ink=imin(ink,y);
        }
        /* A peak hidden behind the badge may be up to six logical pixels above
         * the next visible spike. Rounded/cloud outlines agree to a pixel. */
        CHECK(fabsf(center-outline)<=(kind==BUBBLE_SHOUT ? 6 : 2)*scale+1);
        CHECK(ink>center+12*scale && ink<center+34*scale);
        if (test_failures()) fprintf(stderr,"  badge %.2f, outline %d, ink %d, scale %.2f\n",center,outline,ink,scale);
    }
    free(pixels);story_next();story_frame(0);
    int previous_screen=screen_for(sample_index);
    if (++sample_index==TOTAL_CASES) { app_quit();return; }
    screen=screen_for(sample_index);
    if (screen!=previous_screen) {
        axSetSize(widths[screen],heights[screen],false);present_pending=true;
    }
}

static void quit(void) { tex_free(portrait); }

TEST(story_layouts)
{
    char *args[]={"test-story","--headless","--mute","--size","480x900","--safe-area","0,47,0,34"};
    app_desc desc={.design={480,900},.fixed=true,.max_aspect=2.2f,.clear={10,20,70,255},
        .data_dir="games/relic-rush/data",.init=init,.frame=frame,.quit=quit};
    CHECK(app_run(desc,7,args)==0);
    CHECK(sample_index==TOTAL_CASES);
}
