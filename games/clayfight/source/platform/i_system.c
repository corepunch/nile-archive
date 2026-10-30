/* Shared platform adapter: no SDL window or event loop. */
#include "platform/platform.h"
#include "../../../../engine/third_party/platform/platform.h"
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
int I_GetTime(void) { static double base; struct timespec ts;clock_gettime(CLOCK_MONOTONIC,&ts);double now=ts.tv_sec+ts.tv_nsec/1e9;if(!base)base=now;return (int)((now-base)*TICRATE); }
void I_Sleep(int ms) { axSleep(ms); }
void I_Shutdown(void) { I_CloseCreator();I_ShutdownSound();I_ShutdownGraphics(); }
void I_Error(const char *fmt,...) { va_list ap;va_start(ap,fmt);vfprintf(stderr,fmt,ap);va_end(ap);fputc('\n',stderr);exit(1); }
void I_Log(const char *fmt,...) { va_list ap;va_start(ap,fmt);vprintf(fmt,ap);va_end(ap);putchar('\n'); }
void *I_Malloc(size_t n) { void *p=calloc(1,n?n:1);if(!p)I_Error("Out of memory");return p; }
void I_InitGraphics(bool headless) {(void)headless;}
void I_ShutdownGraphics(void) {}
void I_FinishUpdate(const pixel_t *pixels) {(void)pixels;}
void I_StartTic(void) {}
bool I_QuitRequested(void) { return false; }
static void put32(FILE *f,uint32_t n) { for(int i=0;i<4;i++)fputc((n>>(i*8))&255,f); }
void I_SaveScreenshot(const pixel_t *pixels,const char *path) {
    FILE *f=fopen(path,"wb");if(!f)I_Error("Cannot save %s",path);
    fputs("BM",f);put32(f,54+SCREENWIDTH*SCREENHEIGHT*4);put32(f,0);put32(f,54);put32(f,40);put32(f,SCREENWIDTH);put32(f,SCREENHEIGHT);
    fputc(1,f);fputc(0,f);fputc(32,f);fputc(0,f);put32(f,0);put32(f,SCREENWIDTH*SCREENHEIGHT*4);for(int i=0;i<4;i++)put32(f,0);
    for(int y=SCREENHEIGHT-1;y>=0;y--)for(int x=0;x<SCREENWIDTH;x++)put32(f,pixels[y*SCREENWIDTH+x]);
    if(fclose(f))I_Error("Cannot finish screenshot %s",path);
}
