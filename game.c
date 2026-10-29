#include <SDL.h>
#include <emscripten.h>
#include <math.h>
#include <string.h>
#include <stdio.h>

SDL_Window *w;
SDL_Renderer *r;
SDL_Texture *bg[3], *island, *atlas;
int mode=0,level=0,mask=0,hint=-1,nb=0,zones=1;
float cx=900,cy=650,zoom=1,scx=600,scy=400,sz=1;
int bx[100],by[100],bt[100];
/* Centers and elliptical hit regions, measured from the actual painted artwork. */
int ox[3][8]={{133,268,491,574,1150,965,195,1094},{180,1023,115,513,450,1063,273,1070},{61,1027,120,527,1109,656,234,379}};
int oy[3][8]={{133,422,316,660,368,575,598,170},{78,617,430,163,617,453,500,226},{109,530,514,334,114,574,98,634}};
int rx[3][8]={{27,82,30,40,45,95,90,42},{25,115,35,30,45,90,195,45},{30,95,35,42,25,105,70,95}};
int ry[3][8]={{55,42,30,24,20,70,42,55},{52,55,35,42,22,70,55,55},{72,50,35,24,62,58,28,30}};
int bs[5]={160,210,190,150,170};

SDL_Texture *load(char *p) {
    SDL_Surface *s=SDL_LoadBMP(p);
    if(!s) return NULL;
    if(!strcmp(p,"atlas.bmp")) SDL_SetColorKey(s,1,SDL_MapRGB(s->format,255,0,255));
    SDL_Texture *t=SDL_CreateTextureFromSurface(r,s);
    SDL_FreeSurface(s);
    return t;
}
void tile(SDL_Texture *t,int x,int y,int width,int height,int sx,int sy,int sw,int sh) {
    SDL_Rect a={sx,sy,sw,sh},b={x,y,width,height};
    SDL_RenderCopy(r,t,&a,&b);
}
void circle(int x,int y,int radius) {
    for(int j=0;j<96;j++) {
        float a=j*6.283185f/96,b=(j+1)*6.283185f/96;
        SDL_RenderDrawLine(r,x+cosf(a)*radius,y+sinf(a)*radius,x+cosf(b)*radius,y+sinf(b)*radius);
    }
}
void frame(void) {
    SDL_SetRenderDrawColor(r,21,81,88,255);
    SDL_RenderClear(r);
    SDL_Rect dst={0,0,1200,800};
    if(mode) {
        SDL_Rect src={(int)(scx-600/sz),(int)(scy-400/sz),(int)(1200/sz),(int)(800/sz)};
        SDL_RenderCopy(r,bg[level],&src,&dst);
        for(int i=0;i<8;i++) {
            int x=(ox[level][i]-scx)*sz+600,y=(oy[level][i]-scy)*sz+400;
            if(mask&(1<<i)) {
                SDL_SetRenderDrawColor(r,172,239,195,230);
                circle(x,y,14); circle(x,y,15);
            } else if(hint==i) {
                SDL_SetRenderDrawColor(r,255,225,116,255);
                int rad=fmaxf(25,fminf(rx[level][i],ry[level][i]))*sz;
                circle(x,y,rad); circle(x,y,rad+2);
            }
        }
    } else {
        SDL_Rect src={(int)(cx-600/zoom),(int)(cy-400/zoom),(int)(1200/zoom),(int)(800/zoom)};
        SDL_RenderCopy(r,island,&src,&dst);
        int order[100];
        for(int i=0;i<nb;i++) {
            int j=i; order[j]=i;
            while(j>0 && by[order[j-1]]>by[order[j]]) {
                int temp=order[j-1]; order[j-1]=order[j]; order[j]=temp; j--;
            }
        }
        for(int n=0;n<nb;n++) {
            int i=order[n],size=bs[bt[i]]*zoom;
            tile(atlas,(bx[i]-cx)*zoom+600-size/2,(by[i]-cy)*zoom+400-size*.88f,size,size,bt[i]*256,0,256,256);
        }
        SDL_SetRenderDrawBlendMode(r,SDL_BLENDMODE_BLEND);
        for(int z=zones;z<4;z++) {
            SDL_SetRenderDrawColor(r,13,46,49,155);
            SDL_Rect a={(int)((800+z*380-cx)*zoom+600),(int)((200-cy)*zoom+400),(int)(380*zoom),(int)(1050*zoom)};
            SDL_RenderFillRect(r,&a);
        }
    }
    SDL_RenderPresent(r);
}
EMSCRIPTEN_KEEPALIVE void view(int m,int l) {
    mode=m;level=l;mask=0;hint=-1;scx=600;scy=400;sz=1;
}
EMSCRIPTEN_KEEPALIVE int tap(int x,int y) {
    if(!mode) return -1;
    float px=scx+(x-600)/sz,py=scy+(y-400)/sz;
    for(int i=0;i<8;i++) if(!(mask&(1<<i))) {
        float dx=(px-ox[level][i])/rx[level][i],dy=(py-oy[level][i])/ry[level][i];
        if(dx*dx+dy*dy<=1) {mask|=1<<i;hint=-1;return i;}
    }
    return -1;
}
EMSCRIPTEN_KEEPALIVE void pan(float dx,float dy) {
    if(mode) {
        scx=fmaxf(600/sz,fminf(1200-600/sz,scx-dx/sz));
        scy=fmaxf(400/sz,fminf(800-400/sz,scy-dy/sz));
    } else {
        cx=fmaxf(600/zoom,fminf(2400-600/zoom,cx-dx/zoom));
        cy=fmaxf(400/zoom,fminf(1600-400/zoom,cy-dy/zoom));
    }
}
EMSCRIPTEN_KEEPALIVE void magnify(float z) {
    if(mode) sz=fmaxf(1,fminf(3,z)); else zoom=fmaxf(.75,fminf(2,z));
    pan(0,0);
}
EMSCRIPTEN_KEEPALIVE void showhint(void) {
    for(int i=0;i<8;i++) if(!(mask&(1<<i))) {hint=i;scx=ox[level][i];scy=oy[level][i];pan(0,0);break;}
}
EMSCRIPTEN_KEEPALIVE int place(int x,int y,int t) {
    float xx=cx+(x-600)/zoom,yy=cy+(y-400)/zoom;
    if(t<0||t>4||xx<580||xx>800+zones*380||yy<400||yy>1170||nb>=100||powf((xx-1230)/760,2)+powf((yy-800)/530,2)>1||(xx>1030&&xx<1320&&yy>920&&yy<1100)) return 0;
    for(int i=0;i<nb;i++) if(hypotf(xx-bx[i],yy-by[i])<120) return 0;
    bx[nb]=xx;by[nb]=yy;bt[nb++]=t;return 1;
}
EMSCRIPTEN_KEEPALIVE void restore(int x,int y,int t) {
    if(nb<100&&t>=0&&t<5) {bx[nb]=x;by[nb]=y;bt[nb++]=t;}
}
EMSCRIPTEN_KEEPALIVE int coord(int q) {return q?by[nb-1]:bx[nb-1];}
EMSCRIPTEN_KEEPALIVE void unlock(int z) {zones=z;}
EMSCRIPTEN_KEEPALIVE void resize(int width,int height) {
    if(!w||!r||width<1||height<1)return;
    SDL_SetWindowSize(w,width,height);
    SDL_RenderSetLogicalSize(r,1200,800);
}
int main(void) {
    SDL_Init(SDL_INIT_VIDEO);
    w=SDL_CreateWindow("Nile",0,0,1200,800,0);
    r=SDL_CreateRenderer(w,-1,SDL_RENDERER_ACCELERATED);
    if(!r)r=SDL_CreateRenderer(w,-1,SDL_RENDERER_SOFTWARE);
    if(!r){fprintf(stderr,"SDL renderer failed: %s\n",SDL_GetError());return 1;}
    SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY,"1");
    SDL_RenderSetLogicalSize(r,1200,800);
    SDL_SetRenderDrawBlendMode(r,SDL_BLENDMODE_BLEND);
    bg[0]=load("scene.bmp");bg[1]=load("scene1.bmp");bg[2]=load("scene2.bmp");
    island=load("island.bmp");atlas=load("atlas.bmp");
    EM_ASM({document.title="Архив Нила";document.getElementById("canvas").dataset.rendererReady="true";window.dispatchEvent(new Event("nile-render-ready"));});
    emscripten_set_main_loop(frame,30,1);
    return 0;
}
