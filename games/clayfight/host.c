/* Game-local Lua extension. Shared engine has no knowledge of Clayfight. */
#include "../../engine/render.h"
#include "../../engine/third_party/lua/lauxlib.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
int clay_start(int,char**);void clay_tick(void);void clay_draw(void);const uint32_t *clay_pixels(void);
void clay_key(int,int);void clay_focus(void);void clay_stop(void);int clay_cli_main(int,char**);
void clay_creator_config(const char*,const char*);
static int saved_argc;static char **saved_argv;
static texture framebuffer;
static unsigned char frame_pixels[672*480*4];
static bool started;
static char root[2048], resource_path[2048], creature_path[2048];
static char *args[256];
static int argc_game;
#ifdef AX_PLATFORM_IOS
const char *clay_ios_prepare(const char *);void clay_ios_controls(void);
#endif
#ifdef __APPLE__
void clay_controllers_init(void);
#if !defined(AX_PLATFORM_IOS) && defined(GAME_IN_BUNDLE)
const char *clay_macos_prepare(const char *);void clay_macos_creator(void);
#endif
#endif
static int start(lua_State *L) {
    const char *base=app_path("");
    snprintf(resource_path,sizeof resource_path,"%s/primrage",base);
    snprintf(creature_path,sizeof creature_path,"%s/creatures",base);
    #ifdef AX_PLATFORM_IOS
    snprintf(creature_path,sizeof creature_path,"%s",clay_ios_prepare(base));
#endif
#if defined(__APPLE__) && !defined(AX_PLATFORM_IOS) && defined(GAME_IN_BUNDLE)
    snprintf(creature_path,sizeof creature_path,"%s",clay_macos_prepare(base));
    clay_macos_creator();
#endif
    args[0]="clayfight";argc_game=1;
    bool has_data=false,has_creatures=false;
    for(int i=1;i<saved_argc&&argc_game<248;i++){
        if(!strcmp(saved_argv[i],"-data"))has_data=true;
        if(!strcmp(saved_argv[i],"-creatures"))has_creatures=true;
        args[argc_game++]=saved_argv[i];
    }
    if(!has_data){args[argc_game++]="-data";args[argc_game++]=resource_path;}
    if(!has_creatures){args[argc_game++]="-creatures";args[argc_game++]=creature_path;}
    const char *data=resource_path;
    for(int i=1;i+1<argc_game;i++)if(!strcmp(args[i],"-data"))data=args[i+1];
    char path[4096];snprintf(path,sizeof path,"%s/136102-1044b.29l",data);
    if(access(path,R_OK)){lua_pushboolean(L,0);return 1;}
    started=clay_start(argc_game,args);
#ifdef __APPLE__
    if(started)clay_controllers_init();
#else
    axJoystickInit();
#endif
#ifdef AX_PLATFORM_IOS
    if(started)clay_ios_controls();
#ifdef DEBUG
    for(int i=1;started&&i<saved_argc;i++)if(!strcmp(saved_argv[i],"--native-checks")){
        extern void CFRunNativeChecks(void);CFRunNativeChecks();
    }
#endif
#endif
    lua_pushboolean(L,started);return 1;
}
static int tick(lua_State *L){if(started)clay_tick();return 0;}
static int key(lua_State *L){clay_key((int)luaL_checkinteger(L,1),lua_toboolean(L,2));return 0;}
static int present(lua_State *L) {
    if(!started)return 0;
    clay_draw();const uint32_t *p=clay_pixels();
    for(int i=0;i<672*480;i++){frame_pixels[i*4]=p[i]>>16;frame_pixels[i*4+1]=p[i]>>8;frame_pixels[i*4+2]=p[i];frame_pixels[i*4+3]=255;}
    if(!framebuffer.tex){framebuffer=tex_from_pixels(frame_pixels,672,480);render_texture_nearest(framebuffer.tex);}
    else render_texture_update(framebuffer.tex,0,0,672,480,frame_pixels);
    draw_image(framebuffer,rc(0,0,672,480),rgba(255,255,255,255));return 0;
}
static int stop(lua_State *L){if(started)clay_stop();tex_free(framebuffer);return 0;}
static void extension(lua_State *L){static const luaL_Reg api[]={{"start",start},{"tick",tick},{"key",key},{"present",present},{"stop",stop},{NULL,NULL}};luaL_newlib(L,api);lua_setglobal(L,"clay");}
void clay_input_event(const struct AXmessage *);
static void event(const struct AXmessage *e) { if(started)clay_input_event(e); }
static int launch(int argc,char **argv){
    saved_argc=argc;saved_argv=argv;
    if(!getcwd(root,sizeof root))root[0]=0;
    char script[4096],exe[4096];snprintf(script,sizeof script,"%s/games/clayfight/tools/capture_server.py",root);snprintf(exe,sizeof exe,"%s/build/clayfight",root);clay_creator_config(script,exe);
    const char *data="games/clayfight/data",*lua="games/clayfight/lua";
#ifdef __EMSCRIPTEN__
    data="/data";lua="/lua";
#endif
#ifdef GAME_IN_BUNDLE
    static char d[2048],l[2048];snprintf(d,sizeof d,"%s/data",axShareDirectory());snprintf(l,sizeof l,"%s/lua",axShareDirectory());data=d;lua=l;
#endif
    /* Legacy headless commands work from the repository root as well. */
    for(int i=1;i<argc;i++)if(!strcmp(argv[i],"-shots")||!strcmp(argv[i],"-checkanims")){
        if(access(data,R_OK) && !access("data",R_OK))data="data";
        char resources[4096],creatures[4096];
        snprintf(resources,sizeof resources,"%s/primrage",data);
        snprintf(creatures,sizeof creatures,"%s/creatures",data);
        bool has_data=false,has_creatures=false;
        int n=0;char **cli=calloc((size_t)argc+5,sizeof *cli);
        if(!cli)return 1;
        for(int j=0;j<argc;j++){cli[n++]=argv[j];if(!strcmp(argv[j],"-data"))has_data=true;if(!strcmp(argv[j],"-creatures"))has_creatures=true;}
        if(!has_data){cli[n++]="-data";cli[n++]=resources;}
        if(!has_creatures){cli[n++]="-creatures";cli[n++]=creatures;}
        int result=clay_cli_main(n,cli);free(cli);return result;
    }
    script_set_extension(extension);app_desc desc=script_boot(lua,data);desc.event=event;
#ifdef AX_PLATFORM_IOS
    desc.design=sz2(672,580);
#endif
    int result=app_run(desc,argc,argv);
#ifndef AX_PLATFORM_IOS
    script_close();
#endif
    return result;
}
#ifdef AX_PLATFORM_IOS
static bool_t ios_launch(int c,char **v){return launch(c,v)==0;}
static void ios_stop(void){app_stop();script_close();}
#endif
int main(int argc,char **argv){
#ifdef AX_PLATFORM_IOS
    return axRunApplication(argc,argv,ios_launch,app_step,ios_stop);
#else
    return launch(argc,argv);
#endif
}
