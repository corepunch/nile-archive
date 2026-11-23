/* Exercise feedback tones through the platform callback, without hardware. */
#include "engine.h"
#include "render.h"
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
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
    mix(out,1024); sfx_note(440,.05f,.01f,1); mix(out,12);
    for(int i=0;i<24;i++) assert(!out[i]); // a delayed note waits
    mix(out,441); mix(out,12); assert(out[20]!=0);
    for(int k=0;k<20;k++) sfx_note(300+k*10,.05f,0,1); // more notes than voices steal the oldest
    mix(out,12); assert(out[20]!=0 && out[20]==out[21]);
    sfx_shutdown(); assert(closes==2 && !locks);
    // music: a staged song plays in stereo through the same device
    muted=true; music_note(MUSIC_PAD,0,4,60,.8f); music_play(120,4); assert(opens==2 && music_playing()); muted=false;
    music_restart(); assert(!music_playing());
    music_note(-1,0,1,60,1); music_note(MUSIC_PAD,NAN,1,60,1); music_play(0,4); assert(!music_playing());
    for(int k=0;k<4;k++) music_note(MUSIC_PAD,0,4,57+k*4,.8f);
    music_note(MUSIC_PLUCK,1,.5f,72,.8f); music_note(MUSIC_KICK,0,.5f,36,1);
    music_play(120,4); assert(opens==3 && music_playing());
    static int16_t song[44100*2]; float energy=0, side=0;
    for(int k=0;k<43;k++) mix(song+k*2048,1024);
    for(int i=22050;i<44100;i++) { energy+=abs(song[i*2]); side+=abs(song[i*2]-song[i*2+1]); }
    assert(energy>0 && side>0); // audible and wider than mono
    assert(music_beat()>1.9f); // two seconds at 120 bpm wrapped the four-beat loop once
    music_stop(.05f); assert(!music_playing());
    for(int k=0;k<4;k++) mix(out,1024);
    mix(out,1024); for(int i=0;i<2048;i++) assert(!out[i]); // faded out and stopped
    assert(music_render("build/test-audio.wav",.1f)); // nothing staged anew: renders silence
    music_restart();
    for(int k=0;k<MUSIC_INSTRUMENTS;k++) music_note(k,k*.25f,.5f,60,.8f);
    music_play(120,4); assert(music_render("build/test-audio.wav",.5f));
    FILE *f=fopen("build/test-audio.wav","rb"); assert(f); fseek(f,0,SEEK_END); assert(ftell(f)==44+22050*4); fclose(f);
    remove("build/test-audio.wav");
    sfx_shutdown(); music_restart(); assert(!locks);
    puts("audio: tones, delayed polyphonic notes, expiry, mute, disable, device lifecycle and music passed");
}
