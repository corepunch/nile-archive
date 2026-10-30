/* Capture the actual game while native pointer events exercise city gestures.
 * Works against older engine commits too: no test-only Lua/game hooks needed. */
#include "render.h"
#include <stdio.h>
#include <string.h>

static void (*game_frame)(float);
static int frame_index;

static void pointer(uint32_t event, vec2 logical)
{
    struct AXsize window; axGetSize(&window);
    rect bleed=app_bleed();
    vec2 at=vec2_scale(vec2_sub(logical,bleed.pos),window.width/bleed.size.w);
    axPostMessageW(NULL,event,MAKEDWORD((int)lroundf(at.x),(int)lroundf(at.y)),NULL);
}

static void frame(float dt)
{
    vec2 at=v2(240,400);
    const char *pos=app_arg("press"), *gesture=app_arg("gesture");
    if (pos) sscanf(pos,"%f,%f",&at.x,&at.y);
    int f=++frame_index;
    if (f==30) pointer(kEventLeftButtonDown,at);
    if ((f==36 && gesture && !strcmp(gesture,"pan")) ||
        (f==75 && gesture && !strcmp(gesture,"drag")))
        pointer(kEventLeftButtonDragged,vec2_add(at,v2(-60,10)));
    game_frame(dt);
}

int main(int argc,char **argv)
{
    const char *game="relic-rush";
    for (int i=1;i+1<argc;i++) if (!strcmp(argv[i],"--game")) game=argv[i+1];
    if (strcmp(game,"relic-rush") && strcmp(game,"nile-archive")) return 2;
    char lua[128],data[128];
    snprintf(lua,sizeof lua,"games/%s/lua",game);
    snprintf(data,sizeof data,"games/%s/data",game);
    app_desc desc=script_boot(lua,data);
    game_frame=desc.frame;desc.frame=frame;
    int result=app_run(desc,argc,argv);
    script_close();return result;
}
