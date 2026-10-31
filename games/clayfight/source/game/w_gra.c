// Arcade resource banks: RLE motion objects, original RGB555 palettes and
// packed character/playfield chips. No DOS archives or converted art files.
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include "game/game.h"

#define RLE_BYTES 0x2000000
#define MAX_BANKS 16
static byte *rle, *tiles[3], *characters;
static char resource_dir[768];
static gra_t body;
static gra_t banks[MAX_BANKS];
static int bank_count;
static short *bank_pals[MAX_BANKS];
lumpinfo_t *lumpinfo;
int numlumps;

pixel_t W_RGB(int r,int g,int b) { return raster_rgb(r,g,b); }
static byte *ReadChip(const char *name,int expected)
{
    char path[1024];snprintf(path,sizeof path,"%s/%s",resource_dir,name);
    FILE *f=fopen(path,"rb");if(!f)I_Error("Missing arcade ROM: %s",path);
    byte *data=I_Malloc(expected);
    size_t n=fread(data,1,expected,f);int extra=fgetc(f);fclose(f);
    if(n!=(size_t)expected || extra!=EOF)I_Error("Incorrect arcade chip size: %s",path);
    return data;
}
static unsigned Word(unsigned at)
{
    if(at>=RLE_BYTES/2)I_Error("Arcade RLE address outside ROM: %#x",at);
    return (unsigned)rle[at*2]<<8|rle[at*2+1];
}
static void Pair(const char *low,const char *high,unsigned offset,int size)
{
    byte *a=ReadChip(low,size),*b=ReadChip(high,size);
    for(int i=0;i<size;i++){rle[offset+i*2]=b[i];rle[offset+i*2+1]=a[i];}
    free(a);free(b);
}
static void Palette(palette_t *p,uint32_t address,int count)
{
    p->count=count-1;
    for(int i=0;i<count;i++){
        unsigned v=X_U16(address+i*2);
        p->colors[i]=W_RGB((v>>10&31)*255/31,(v>>5&31)*255/31,(v&31)*255/31);
    }
}
static void Bounds(patch_t *p)
{
    int x0=p->w,y0=p->h,x1=-1,y1=-1;
    for(int y=0;y<p->h;y++)for(int x=0;x<p->w;x++){
        int v=p->pixels[y*p->w+x];p->maxval=MAX(p->maxval,v);
        if(v){x0=MIN(x0,x);y0=MIN(y0,y);x1=MAX(x1,x);y1=y;}
    }
    p->hasbox=x1>=0;p->bx0=x0-p->x;p->by0=y0-p->y;p->bx1=x1-p->x;p->by1=y1-p->y;
}
static int Run(int mode,int value,int *pixel)
{
    if(mode==0 || ((mode==1 || mode==4 || mode==6) && !(value&15))){*pixel=value&15;return (value>>4)+1;}
    if(mode<=3){*pixel=value&31;return (value>>5)+1;}
    *pixel=value&63;return (value>>6)+1;
}
static patch_t *Decode(int id)
{
    if(id<0 || id>=body.numframes)return NULL;
    frame_t *f=&body.frames[id];if(f->decoded)return f->patch;f->decoded=true;
    unsigned flags=Word(id*4+2),start=(flags&255)<<16|Word(id*4+3),at=start;
    if(start<(unsigned)id*4 || start>=RLE_BYTES/2)return NULL;
    int mode=(flags>>8)&7,w=0,h=0;
    while(h<1024){
        unsigned n=Word(at++);if(n&0x8000)n^=65535;if(!n)break;
        if(n>RLE_BYTES/2-at)I_Error("Arcade object %d: truncated row",id);
        int row=0,pixel;
        for(unsigned j=0;j<n;j++){int v=Word(at++);row+=Run(mode,v&255,&pixel);row+=Run(mode,v>>8,&pixel);}
        w=MAX(w,row);h++;
    }
    if(!w || !h)return NULL;
    if(w>4096 || h>=1024)I_Error("Arcade object %d has invalid dimensions",id);
    patch_t *p=I_Malloc(sizeof *p);p->w=f->w=w;p->h=f->h=h;
    p->x=f->x=(int16_t)Word(id*4);p->y=f->y=(int16_t)Word(id*4+1);p->pixels=I_Malloc(w*h);
    at=start;
    for(int y=0;y<h;y++){
        unsigned n=Word(at++);if(n&0x8000)n^=65535;int x=0;
        for(unsigned j=0;j<n;j++){
            int value=Word(at++);
            for(int k=0;k<2;k++){
                int pixel,count=Run(mode,k?value>>8:value&255,&pixel);
                if(count>w-x)I_Error("Arcade object %d row overflow",id);
                memset(p->pixels+y*w+x,pixel,count);x+=count;
            }
        }
    }
    Bounds(p);f->patch=p;return p;
}

void W_Init(const char *directory)
{
    snprintf(resource_dir,sizeof resource_dir,"%s",directory);
    W_SoundDirectory(directory);
    if(!X_Init(directory))I_Error("Supply Primal Rage 2.3 arcade ROMs in %s",directory);
    rle=I_Malloc(RLE_BYTES);
    Pair("136102-1100a.2v","136102-1101a.2w",0,0x80000);
    for(int i=0;i<12;i++){
        char lo[64],hi[64];int n=i<4?332+2*i:316+2*(i-4),bank=i<4?1:0,slot=i<4?i:i-4;
        snprintf(lo,sizeof lo,"136102-%04d.mol%d.%d",n,bank,slot);
        snprintf(hi,sizeof hi,"136102-%04d.moh%d.%d",n+1,bank,slot);
        Pair(lo,hi,(i<4?0x800000+i*0x200000:0x1000000+(i-4)*0x200000),0x100000);
    }
    unsigned lowest=RLE_BYTES/2;
    for(unsigned at=0;at<lowest;at+=4){unsigned p=(Word(at+2)&255)<<16|Word(at+3);if(p>at && p<lowest)lowest=p;}
    body.numframes=lowest/4;if(body.numframes!=12000)I_Error("Unsupported arcade RLE object table");
    snprintf(body.name,sizeof body.name,"arcade");body.frames=I_Malloc(body.numframes*sizeof *body.frames);
    body.numpalettes=28;body.palettes=I_Malloc(body.numpalettes*sizeof *body.palettes);
    for(int ch=0;ch<7;ch++)for(int alt=0;alt<4;alt++)Palette(&body.palettes[ch*4+alt],X_U32(0x6e38c+ch*4)+alt*128,64);
    tiles[0]=ReadChip("136102-0050a.25n",0x80000);tiles[1]=ReadChip("136102-0051a.27n",0x80000);tiles[2]=ReadChip("136102-0052a.28n",0x80000);
    characters=ReadChip("136102-1045b.23p",0x20000);
    I_Log("W_Init: 12000 arcade motion-object slots, tile planes and character ROM");
}

patch_t *W_Frame(gra_t *g,int index)
{
    if(!g || index<0 || index>=g->numframes)return NULL;
    if(g==&body)return Decode(index);
    frame_t *f=&g->frames[index];
    if(!f->decoded){f->patch=f->offset>=0?Decode(f->offset):NULL;f->decoded=true;}
    return f->patch;
}
static gra_t *Bank(const char *name,int count,int palettes)
{
    if(bank_count==MAX_BANKS)I_Error("Too many arcade art banks");
    gra_t *g=&banks[bank_count];snprintf(g->name,sizeof g->name,"%s",name);g->numframes=count;g->numpalettes=palettes;
    g->frames=I_Malloc(count*sizeof *g->frames);g->palettes=I_Malloc(palettes*sizeof *g->palettes);
    bank_pals[bank_count]=I_Malloc(count*sizeof **bank_pals);
    for(int i=0;i<count;i++)g->frames[i].offset=-1;
    bank_count++;return g;
}
static void Frame(gra_t *g,int slot,int id,int pal)
{
    g->frames[slot].offset=id;bank_pals[g-banks][slot]=pal;
}
static patch_t *Patch(int w,int h)
{
    patch_t *p=I_Malloc(sizeof *p);p->w=w;p->h=h;p->pixels=I_Malloc(w*h);return p;
}
static void Composite(patch_t *dst,const patch_t *src,int x,int y,int bank)
{
    for(int j=0;j<src->h;j++)for(int i=0;i<src->w;i++){
        int v=src->pixels[j*src->w+i];if(!v || x+i<0 || x+i>=dst->w || y+j<0 || y+j>=dst->h)continue;
        dst->pixels[(y+j)*dst->w+x+i]=v+bank;
    }
}
static gra_t *Select(void)
{
    gra_t *g=Bank("select",155,31);
    static const uint32_t palettes[]={0x64b02,0x64302,0x64502,0x66efa,0x67796,0x66d7a,0x67a16,0x66ffa};
    for(int i=0;i<8;i++)Palette(&g->palettes[i],palettes[i],64);
    const int portrait[]={130,91,141,149,125,113,97};
    const int object[]={852,862,877,882,872,857,867};
    const int pals[]={13,4,16,18,12,11,6};
    const uint32_t pp[]={0x67716,0x67796,0x67816,0x67896,0x67916,0x67996,0x67a16};
    for(int c=0;c<7;c++){
        Palette(&g->palettes[pals[c]],pp[c],64);
        for(int k=0;k<5;k++)Frame(g,portrait[c]+k,object[c]+k,pals[c]);
    }
    Palette(&g->palettes[14],0x6717a,128);
    patch_t *bg=Patch(336,240);Composite(bg,Decode(785),0,0,64);Composite(bg,Decode(784),0,0,0);Bounds(bg);
    g->frames[136]=(frame_t){.w=336,.h=240,.decoded=true,.patch=bg};
    bank_pals[g-banks][136]=14;
    Palette(&g->palettes[9],0x6727a,64);Palette(&g->palettes[10],0x6727a,64);
    Frame(g,105,786,9);Frame(g,106,787,10);
    static const int heads[]={140,139,148,147,103,102,111};
    static const int headids[]={788,790,791,789,794,792,793};
    static const int headpal[]={28,30,29,1,2,0,27};
    static const int headchar[]={0,2,4,1,6,3,5};
    for(int i=0;i<7;i++){g->palettes[headpal[i]]=body.palettes[headchar[i]*4];Frame(g,heads[i],headids[i],headpal[i]);}
    return g;
}
gra_t *W_TryLoadGra(const char *name)
{
    if(!strcasecmp(name,"arcade"))return &body;
    for(int i=0;i<bank_count;i++)if(!strcasecmp(banks[i].name,name))return &banks[i];
    if(!strcasecmp(name,"select"))return Select();
    if(!strcasecmp(name,"slabs")){
        gra_t *g=Bank(name,38,1);Palette(g->palettes,0x61042,64);Frame(g,37,826,0);return g;
    }
    if(!strcasecmp(name,"title")){
        gra_t *g=Bank(name,46,3);Palette(&g->palettes[0],0x68d7a,64);Palette(&g->palettes[1],0x650e2,64);Palette(&g->palettes[2],0x652c2,64);
        Frame(g,37,460,2);Frame(g,19,480,2);for(int i=39;i<=45;i++)Frame(g,i,446,0);return g;
    }
    if(!strcasecmp(name,"globe")){
        gra_t *g=Bank(name,47,4);Palette(&g->palettes[0],0x65cfa,64);Palette(&g->palettes[1],0x65d7a,64);Palette(&g->palettes[2],0x65dfa,64);Palette(&g->palettes[3],0x65e7a,64);
        for(int i=0;i<47;i++)Frame(g,i,MAX(491,491+i-8),i<20?0:1);
        return g;
    }
    if(!strcasecmp(name,"fonts")){
        gra_t *g=Bank(name,128,1);g->palettes[0].count=15;
        for(int v=0;v<16;v++)g->palettes[0].colors[v]=W_RGB(v*17,v*17,v*17);
        for(int c=0;c<128;c++){
            patch_t *p=Patch(8,8);for(int k=0;k<32;k++){int v=characters[c*32+k];p->pixels[k*2]=v>>4;p->pixels[k*2+1]=v&15;}
            Bounds(p);
            if(p->hasbox && p->bx1<7){
                int w=p->bx1+1;byte *crop=I_Malloc(w*8);
                for(int y=0;y<8;y++)memcpy(crop+y*w,p->pixels+y*8,w);
                free(p->pixels);p->pixels=crop;p->w=w;Bounds(p);
            }
            g->frames[c]=(frame_t){.w=8,.h=8,.decoded=true,.patch=p};
        }
        return g;
    }
    return NULL;
}
gra_t *W_LoadGra(const char *name) {gra_t *g=W_TryLoadGra(name);if(!g)I_Error("Unknown arcade art bank: %s",name);return g;}
gra_t *W_GraById(int id) {(void)id;return &body;}
int W_FramePalette(gra_t *g,int index) {return g>=banks && g<banks+bank_count && index>=0 && index<g->numframes?bank_pals[g-banks][index]:0;}
int W_GuessPalette(const patch_t *p,const gra_t *g)
{
    for(int i=0;i<g->numframes;i++)if(g->frames[i].decoded && g->frames[i].patch==p)return W_FramePalette((gra_t *)g,i);
    return 0;
}

// Every 8x8 playfield tile combines the three original ROM planes. Granularity
// remains 32 after MAME/Atari's 4+2 bit blend; map colour words are usually even.
static int TilePixel(unsigned code,int x,int y)
{
    unsigned at=code*16+y*2+x/4;if(at>=0x80000)I_Error("Arcade tile index outside ROM");
    int lo=tiles[x%4<2?1:0][at],hi=tiles[2][at];
    return ((lo>>(x%2?0:4))&15)|((hi>>(4+x%4)&1)<<5)|((hi>>(x%4)&1)<<4);
}
static pixel_t *TileMap(uint32_t map,int bank,const palette_t *palette,int *width,int *height)
{
    int w=X_U8(map),h=X_U8(map+1);*width=w*8;*height=h*8;
    if(!w || w>128 || !h || h>64)I_Error("Invalid arcade tilemap %#x",map);
    pixel_t *p=I_Malloc(w*h*64*sizeof *p);
    for(int y=0;y<h*8;y++)for(int x=0;x<w*8;x++){
        int word=X_U16(map+2+2*(y/8*w+x/8));int px=word&0x8000?7-x%8:x%8;
        int value=TilePixel(bank*4096+(word&4095),px,y%8)+((word>>12)&7)*32;
        p[y*w*8+x]=palette->colors[value&255];
    }
    return p;
}
void W_DrawArcadeStage(int stage,int camx)
{
    static struct {pixel_t *far,*floor;int w,h,fw,fh;} cache[8];
    if(stage<0 || stage>=8)I_Error("Invalid arcade stage %d",stage);
    if(!cache[stage].far){
        palette_t pal;Palette(&pal,X_U32(0x5fea2+stage*4),256);
        int bank=X_U8(0x1e5944+stage);
        cache[stage].far=TileMap(X_U32(0x1e58c4+stage*4),bank,&pal,&cache[stage].w,&cache[stage].h);
        // The two source floor strips are adjacent in VRAM, coloured in bank 4.
        uint32_t map=X_U32(0x1e5904+stage*4);int w=X_U8(map),h=X_U8(map+1);
        cache[stage].floor=I_Malloc(w*h*64*sizeof(pixel_t));cache[stage].fw=w*8;cache[stage].fh=h*8;
        for(int y=0;y<h*8;y++)for(int x=0;x<w*8;x++){
            int word=X_U16(map+2+2*(y/8*w+x/8))|0x4000;
            int v=TilePixel(bank*4096+(word&4095),word&0x8000?7-x%8:x%8,y%8)+((word>>12)&7)*32;
            cache[stage].floor[y*w*8+x]=pal.colors[v&255];
        }
    }
    int far_y=cache[stage].h-240;int horizon=HORIZON_Y;
    for(int y=0;y<VIEWHEIGHT;y++)for(int x=0;x<VIEWWIDTH;x++){
        pixel_t c;
        if(y<horizon){
            int px=x+camx*(cache[stage].w-VIEWWIDTH)/MAX(1,ARENA_WIDTH-VIEWWIDTH);px=CLAMP(px,0,cache[stage].w-1);
            int py=CLAMP(y+far_y,0,cache[stage].h-1);c=cache[stage].far[py*cache[stage].w+px];
        }else{
            int py=(y-horizon)*cache[stage].fh/MAX(1,VIEWHEIGHT-horizon);py=MIN(py,cache[stage].fh-1);
            int px=(x+camx)%cache[stage].fw;c=cache[stage].floor[py*cache[stage].fw+px];
        }
        int at=y*2*SCREENWIDTH+x*2;screen[at]=screen[at+1]=screen[at+SCREENWIDTH]=screen[at+SCREENWIDTH+1]=c;
    }
}
// Audio registry is implemented by the CAGE decoder in w_sound.c.
