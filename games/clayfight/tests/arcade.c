// One process covers the arcade migration: rules, resources and real captures.
#include <assert.h>
#include <stdio.h>
#include <time.h>
#include <sys/stat.h>
#include <string.h>
#include <stdlib.h>
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
static void scenery_checks(void)
{
    // Independently decoded source samples at native (168,100)/(168,230),
    // centred camera and time zero. Catch wrong banks, floor halves and crop.
    const pixel_t pixels[8][2]={
        {0xff731041,0xff6a3900},
        {0xffc54a10,0xff621810},
        {0xffc5e6ee,0xff626a5a},
        {0xffcd5252,0xff003900},
        {0xffb4bdcd,0xff8394c5},
        {0xffc5bdb4,0xff52524a},
        {0xff94948b,0xff4a3110},
        {0xff182039,0xff524139}
    };
    pixel_t *saved=I_Malloc(sizeof screen);bool cpu[2]={false,false};
    int middle=(ARENA_WIDTH-VIEWWIDTH)/2;
    assert(ARENA_WIDTH==1080); // native camera bounds: signed 26.6 value 5d00
    for(int kind=0;kind<2;kind++)for(int i=0;i<10;i++){
        const patch_t *p=W_Frame(W_LoadGra("arcade"),(kind?33:62)+i);
        assert(p->maxval<=W_ArcadeImpactPalette(kind!=0)->count);
    }
    assert(W_ArcadeImpactPalette(true)->colors[51]==W_RGB(0,0,255));
    M_ClearRandom();int expected_random=P_Random();M_ClearRandom();
    for(int stage=0;stage<8;stage++){
        G_InitNew(roster[stage%7],roster[(stage+5)%7],cpu,&stages[stage]);
        level.leveltime=0;W_DrawArcadeStage(stage,middle);
        assert(screen[100*2*SCREENWIDTH+168*2]==pixels[stage][0]);
        assert(screen[230*2*SCREENWIDTH+168*2]==pixels[stage][1]);
        for(int y=0;y<SCREENHEIGHT;y+=2)for(int x=0;x<SCREENWIDTH;x+=2){
            int at=y*SCREENWIDTH+x;
            assert(screen[at]==screen[at+1] && screen[at]==screen[at+SCREENWIDTH] && screen[at]==screen[at+SCREENWIDTH+1]);
        }
        level.leveltime=120;
        for(int cam=0;cam<=ARENA_WIDTH-VIEWWIDTH;cam+=middle){
            R_DrawStage(level.stage,cam);R_DrawStageForeground(level.stage,cam);
            memcpy(saved,screen,sizeof screen);
            R_DrawStage(level.stage,cam);R_DrawStageForeground(level.stage,cam);
            assert(!memcmp(saved,screen,sizeof screen));
        }
    }
    assert(P_Random()==expected_random); // rendering never consumes combat RNG
    G_InitNew(roster[0],roster[5],cpu,&stages[7]);level.leveltime=120;
    R_DrawStage(level.stage,middle);R_DrawStageForeground(level.stage,middle);memcpy(saved,screen,sizeof screen);
    level.leveltime=0;R_DrawStage(level.stage,middle);R_DrawStageForeground(level.stage,middle);
    level.leveltime=120;R_DrawStage(level.stage,middle);R_DrawStageForeground(level.stage,middle);
    assert(!memcmp(saved,screen,sizeof screen)); // deterministic rewind/round reset
    level.leveltime=0;W_DrawArcadeStage(1,middle);memcpy(saved,screen,sizeof screen);
    level.leveltime=20;W_DrawArcadeStage(1,middle);assert(memcmp(saved,screen,sizeof screen));
    free(saved);
    assert(W_ArcadeShadow(0,3818)==W_Frame(W_LoadGra("arcade"),7152));
    assert(W_ArcadeShadow(1,5126)==W_Frame(W_LoadGra("arcade"),10578));
    for(int c=0;c<7;c++){
        const state_t *stand=&roster[c]->states[roster[c]->anims[ANIM_STAND].first];
        assert(W_ArcadeShadow(c,stand->frame));
        assert(C_Start(roster[0]));campaign.order[0]=c;C_StartFight();
        assert(level.stage==&stages[X_U8(0x69a40+c)]);C_Abandon();
    }
    G_InitNew(roster[5],roster[2],cpu,&stages[2]);level.phase=PH_FIGHT;
    P_SpawnSpark(middle+158,90,SPARK_HIT);P_SpawnSpark(middle+196,90,SPARK_BLOCK);
    assert(level.particles[0].animation.frameid==62 && level.particles[1].animation.frameid==33);
    for(int t=0;t<9;t++)P_RunParticles();shot("impacts");
    for(int t=0;t<40;t++)P_RunParticles();assert(level.numparticles==0);
    const int clips[]={0,1,2,7};
    for(int c=0;c<4;c++){
        G_InitNew(roster[0],roster[5],cpu,&stages[clips[c]]);level.phase=PH_FIGHT;
        for(int t=0;t<12;t++){
            level.leveltime=60+t*4;level.camx=middle-20+t*4;
            char name[64];snprintf(name,sizeof name,"scene-reel-%03d",c*12+t);shot(name);
        }
    }
    G_InitNew(roster[0],roster[5],cpu,&stages[0]);level.phase=PH_FIGHT;
    level.camx=0;level.fighters[0].x=98;level.fighters[1].x=238;shot("stage-left");
    level.camx=ARENA_WIDTH-VIEWWIDTH;level.fighters[0].x=level.camx+98;level.fighters[1].x=level.camx+238;shot("stage-right");
    M_StartTitle();
    for(int t=0;t<=110;t++){
        M_Ticker();
        if(t>=32 && (t-32)%6==0){char name[64];snprintf(name,sizeof name,"title-reel-%03d",t);shot(name);}
    }
    puts("arcade scenery: eight source banks/crops, both floor halves, 2x pixels, camera extremes, deterministic animations, shadows, impacts and campaign mapping passed");
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
    CF_FlowChecks();CF_RetailChecks();capture_checks();hud_checks();scenery_checks();I_Shutdown();
    printf("arcade: all checks passed, CPU %.3f seconds\n",(double)(clock()-start)/CLOCKS_PER_SEC);return 0;
}
