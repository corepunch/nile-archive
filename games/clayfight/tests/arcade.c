// One process covers the arcade migration: rules, resources and real captures.
#include <assert.h>
#include <stdio.h>
#include <time.h>
#include <sys/stat.h>
#include "game/game.h"
void CF_FlowChecks(void);void CF_RetailChecks(void);
static void shot(const char *name)
{
    char path[512];snprintf(path,sizeof path,"build/arcade-review/%s.bmp",name);
    D_Display();I_SaveScreenshot(screen,path);
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
    CF_FlowChecks();CF_RetailChecks();capture_checks();I_Shutdown();
    printf("arcade: all checks passed, CPU %.3f seconds\n",(double)(clock()-start)/CLOCKS_PER_SEC);return 0;
}
