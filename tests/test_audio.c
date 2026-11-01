/* Exercise feedback tones through the platform callback, without hardware. */
#include "engine.h"
#include "render.h"
#include <assert.h>
#include <stdio.h>
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
    int16_t out[2048];
    sfx_tone(NAN,.02f); sfx_tone(440,INFINITY); sfx_tone(0,.02f); assert(!opens);
    muted=true; sfx_tone(440,.02f); assert(!opens); muted=false;
    sfx_enable(false); sfx_tone(440,.02f); assert(!opens && !sfx_enabled());
    sfx_enable(true); assert(sfx_enabled());
    sfx_tone(440,.02f); mix(out,12);
    assert(opens==1 && out[20]==out[21] && out[20]!=0);
    mix(out,1024); mix(out,1); assert(!out[0] && !out[1]); // note expired
    sfx_tone(660,.1f); mix(out,12); assert(out[20]!=0 && opens==1);
    sfx_enable(false); mix(out,12);
    for(int i=0;i<24;i++) assert(!out[i]);
    sfx_enable(true); mix(out,12);
    for(int i=0;i<24;i++) assert(!out[i]); // disabling discards the note
    sfx_shutdown(); assert(closes==1);
    sfx_tone(440,.02f); mix(out,12);
    assert(opens==2 && out[20]==out[21] && out[20]!=0);
    sfx_shutdown(); assert(closes==2 && !locks);
    puts("audio: tones, expiry, mute, disable and device lifecycle passed");
}
