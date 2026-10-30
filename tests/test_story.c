/* Real rendered pixels: a cloud/burst must not engulf the speaker's badge or
 * introduce a large blank band above the words. Also exercise resize/letterbox. */
#include "render.h"
#include <stdio.h>

static int checks, failures, sample_index, settling;
static bool present_pending = true;
static font *lettering;
static character speaker = {.id="ann", .name="Ann", .color={30,190,80,255}};
static const int widths[] = {480,390,1200}, heights[] = {900,844,900};
#define CHECK(c) do { checks++; if (!(c)) { failures++; fprintf(stderr,"story %d case %d: %s\n",__LINE__,sample_index,#c); } } while (0)
static int imin(int a,int b) { return a<b ? a:b; }
static int imax(int a,int b) { return a>b ? a:b; }

static void init(void)
{
    lettering=font_load("fonts/LilitaOne-Regular.ttf");
    CHECK(lettering != NULL);
    story_style style={.text={.font=lettering,.size=21,.fill={20,20,20,255}},
        .name={.font=lettering,.size=15,.fill={255,255,255,255}},
        .bubble={250,230,200,255},.edge={180,40,30,255}};
    story_setup(&speaker,1,&style);
}

static void frame(float dt)
{
    (void)dt;
    int screen=sample_index/6;
    struct AXsize window;axGetSize(&window);
    if ((int)window.width!=widths[screen] || (int)window.height!=heights[screen]) {
        if (++settling>120) { CHECK(false);app_quit(); }
        return;
    }
    settling=0;
    if (present_pending) { present_pending=false;return; } /* EGL backing resize happens on swap */
    bubble_kind kind=(bubble_kind)(sample_index%3);
    story_line_add((story_line){"ann",sample_index%6<3 ? "A short line" : "Another line belongs below the first line",kind});
    story_frame(10); /* settled bubble, complete text */
    int w=(int)roundf(window.width*axGetScaling()),h=(int)roundf(window.height*axGetScaling());
    unsigned char *pixels=malloc((size_t)w*h*4);
    CHECK(pixels && render_read_pixels(pixels,w,h));
    if (!pixels) { app_quit();return; }
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
    if (failures) fprintf(stderr,"  badge %.2f, outline %d, ink %d, scale %.2f\n",center,outline,ink,scale);
    free(pixels);story_next();story_frame(0);
    if (++sample_index==18) { app_quit();return; }
    if (sample_index%6==0) {
        screen=sample_index/6;axSetSize(widths[screen],heights[screen],false);present_pending=true;
    }
}

int main(void)
{
    char *args[]={"test-story","--headless","--mute","--size","480x900"};
    app_desc desc={.design={480,900},.fixed=true,.max_aspect=2.2f,.clear={10,20,70,255},
        .data_dir="games/relic-rush/data",.init=init,.frame=frame};
    CHECK(app_run(desc,5,args)==0);
    CHECK(sample_index==18);
    printf("story: %d checks, %d failures; speech/thought/shout, one/two lines, phone/tall-phone/letterbox\n",checks,failures);
    return failures!=0;
}
