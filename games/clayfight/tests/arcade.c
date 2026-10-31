// One process covers the arcade migration: rules, resources and real captures.
#include <assert.h>
#include <stdio.h>
#include <time.h>
#include <sys/stat.h>
#include <string.h>
#include "game/game.h"
void CF_FlowChecks(void);void CF_RetailChecks(void);
static void shot(const char *name)
{
    char path[512];snprintf(path,sizeof path,"build/arcade-review/%s.bmp",name);
    D_Display();I_SaveScreenshot(screen,path);
}
static void hud_checks(void)
{
    gra_t *g=W_LoadGra("hud");
    for(int i=0;i<HUD_HEART;i++){
        const patch_t *p=W_Frame(g,i);
        assert(p && p->h==16 && p->w==(i<HUD_STUN_LEFT?120:80));
        assert(p->maxval<=15 && p->hasbox);
    }
    assert(W_Frame(g,HUD_HEART)==W_Frame(W_LoadGra("arcade"),1767));
    assert(W_Frame(W_LoadGra("stone-font"),'5')->h==16);
    assert(V_TextWidth(FONT_BIG,"57")>V_TextWidth(FONT_SMALL,"57"));
    bool cpu[2]={false,false};gamemode=GM_ARCADE;
    G_InitNew(roster[5],roster[2],cpu,&stages[2]);
    level.phase=PH_FIGHT;level.leveltime=12;level.time=57*TICRATE;shot("hud-full");
    // The original heart's opaque texels must be presented at exact 2x,
    // including its negative hotspot and the mirrored right-player artwork.
    const patch_t *heart=W_Frame(g,HUD_HEART);
    const palette_t *pal=&g->palettes[2];
    for(int side=0;side<2;side++)for(int y=0;y<heart->h;y++)for(int x=0;x<heart->w;x++){
        int value=heart->pixels[y*heart->w+x],sy=y-heart->y;
        int sx=side?332+heart->x-1-x:4-heart->x+x;
        if(!value || sx<0 || sx>=VIEWWIDTH || sy<0 || sy>=VIEWHEIGHT)continue;
        for(int dy=0;dy<2;dy++)for(int dx=0;dx<2;dx++)
            assert(screen[(sy*2+dy)*SCREENWIDTH+sx*2+dx]==pal->colors[value]);
    }
    level.fighters[0].health=37;level.fighters[0].shownhealth=46;level.fighters[0].flash=8;
    level.fighters[0].stun=22;level.fighters[1].health=level.fighters[1].shownhealth=68;
    level.fighters[1].stun=48;shot("hud-damaged");
    level.fighters[0].health=0;level.fighters[0].shownhealth=0;level.fighters[0].flash=0;
    level.fighters[0].dead=true;level.phase=PH_KO;level.phasetime=40;level.time=0;shot("hud-empty");
    gamemode=GM_TRAINING;G_InitNew(roster[5],roster[2],cpu,&stages[2]);
    level.phase=PH_FIGHT;shot("hud-training");
    gamemode=GM_TUG;G_InitNew(roster[5],roster[2],cpu,&stages[2]);
    level.phase=PH_FIGHT;shot("hud-tug");
    gamemode=GM_ARCADE;G_InitNew(roster[7],roster[2],cpu,&stages[2]);
    char saved[sizeof roster[7]->name];memcpy(saved,roster[7]->name,sizeof saved);
    snprintf(roster[7]->name,sizeof roster[7]->name,"ABCDEFGHIJKLMNOP");
    match.wins[0]=4;match.wins[1]=3;level.phase=PH_FIGHT;shot("hud-custom");
    memcpy(roster[7]->name,saved,sizeof saved);
    puts("arcade HUD: authored bar states, mirrored 2x heart, stone digits and custom-name capture passed");
}
static void capture_checks(void)
{
    M_StartTitle();for(int i=0;i<120;i++)M_Ticker();shot("title");
    M_StartMenu();shot("menu");M_OpenStart();shot("start");M_OpenOptions();shot("options");
    gamemode=GM_TUG;SEL_Start();shot("select");
    event_t tab={ev_keydown,'\t'};SEL_Responder(&tab);shot("select-clay");
    gamemode=GM_ARCADE;
    bool cpu[2]={false,false};
    for(int i=0;i<8;i++){
        G_InitNew(roster[i%7],roster[(i+5)%7],cpu,&stages[i]);
        level.phase=PH_FIGHT;char name[32];snprintf(name,sizeof name,"stage-%d",i);shot(name);
    }
    cpu[0]=cpu[1]=true;
    G_InitNew(roster[0],roster[5],cpu,&stages[2]);
    for(int t=0;t<180;t++){
        G_Ticker();
        if(t%6==0){char name[64];snprintf(name,sizeof name,"reel-%03d",t);shot(name);}
    }
    assert(C_Start(roster[0]));shot("campaign");C_StartFight();
    campaign.active=true;gamestate=GS_CONTINUE;shot("continue");
    gamestate=GS_ENDING;shot("ending");C_Abandon();
    G_InitNew(roster[7],roster[2],cpu,&stages[2]);shot("clay-fight");
}
int main(int argc,char **argv)
{
    clock_t start=clock();myargc=argc;myargv=argv;
    mkdir("build",0777);mkdir("build/arcade-review",0777);
    I_InitGraphics(true);W_Init("data/primrage");assert(PS_Init());V_Init();P_LoadRoster("data/creatures");
    options.sound=false;S_Init();assert(SCREENWIDTH==672 && SCREENHEIGHT==480);assert(numroster>=12);
    // These commands cover effects plus all seven character voice tables.
    for(int c=0;c<7;c++)for(int k=0;k<3;k++){
        const unsigned table[]={0x6b0b0,0x6e3e8,0x69c64};
        const sfxdata_t *sound=W_ArcadeSound(X_U16(table[k]+c*2));
        assert(sound && sound->length>100 && sound->rate==11025);
        int lo=255,hi=0;
        for(int i=0;i<sound->length;i++){lo=MIN(lo,sound->data[i]);hi=MAX(hi,sound->data[i]);}
        assert(hi-lo>4);
    }
    puts("arcade sound: original DSP effects and all seven voice tables decoded");
    assert(P_CheckAnims()==0);
    CF_FlowChecks();CF_RetailChecks();capture_checks();hud_checks();I_Shutdown();
    printf("arcade: all checks passed, CPU %.3f seconds\n",(double)(clock()-start)/CLOCKS_PER_SEC);return 0;
}
