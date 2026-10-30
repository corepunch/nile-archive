/* Exercise the public mixer through the platform callback, without hardware. */
#include "engine.h"
#include "render.h"
#include <assert.h>
#include <stdio.h>
#include <string.h>
static AXaudiospec device;
static int opens, closes, locks;
static bool muted;
const char *app_arg(const char *name) { return muted ? "" : NULL; }
bool_t axAudioInit(void) { return 1; }
void axAudioShutdown(void) {}
int axAudioOpen(const AXaudiospec *want, AXaudiospec *got) {
    assert(want->channels==2 && want->freq==44100 && want->format==AX_AUDIO_S16);
    opens++; device=*want; *got=*want; return 1;
}
void axAudioPause(int id,bool_t pause) { assert(id==1); }
void axAudioClose(int id) { assert(id==1 && !locks); closes++; }
void axAudioLock(int id) { assert(id==1 && !locks); locks++; }
void axAudioUnlock(int id) { assert(id==1 && locks==1); locks--; }
static void mix(int16_t *out,int frames) { device.callback(device.userdata,(uint8_t *)out,frames*4); }
int main(void) {
    uint8_t pcm[]={255,0,128,192};
    sfx_sample sample={pcm,4,44100}; int16_t out[24];
    sfx_play((sfx_sample){0},1,0); assert(!opens);
    muted=true; sfx_play(sample,1,0); assert(!opens); muted=false;
    sfx_play(sample,1,-1); sample.length=1; // descriptor is copied
    mix(out,5);
    assert(opens==1 && out[0]==32512 && out[1]==0 && out[2]==-32768 && out[3]==0);
    assert(out[6]==16384 && out[7]==0 && out[8]==0 && out[9]==0);
    sfx_play((sfx_sample){pcm,4,22050},1,1); mix(out,3);
    assert(out[0]==0 && out[1]==32512 && out[3]==32512 && out[5]==-32768);
    sfx_stop_samples(); mix(out,1); assert(!out[0] && !out[1]);
    sfx_play((sfx_sample){pcm,4,44100},1,0);
    sfx_play((sfx_sample){pcm,4,44100},1,0); mix(out,2);
    assert(out[0]==32767 && out[1]==32767 && out[2]==-32768 && out[3]==-32768);
    sfx_enable(false); mix(out,1); assert(!out[0] && !out[1]);
    sfx_enable(true); mix(out,1); assert(!out[0] && !out[1]);
    sfx_tone(440,.02f); mix(out,12);
    assert(opens==1 && out[20]==out[21] && out[20]!=0); // tones share the device
    sfx_shutdown(); assert(closes==1);
    sfx_play((sfx_sample){pcm,4,44100},.5f,0); mix(out,1);
    assert(opens==2 && out[0]==16256 && out[1]==16256);
    sfx_shutdown(); assert(closes==2 && !locks);
    puts("audio: stereo pan, resampling, clipping, mute, tones and device lifecycle passed");
}
