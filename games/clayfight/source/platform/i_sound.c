// Legacy game calls adapted to the shared engine's stereo PCM mixer.
#include "game/resources.h"
void I_InitSound(void) {} // the shared device opens on first playback
void I_ShutdownSound(void) { sfx_stop_samples(); }
void I_StartSound(const sfxdata_t *sfx, float vol, float sep)
{
    if (sfx) sfx_play((sfx_sample){sfx->data,sfx->length,sfx->rate},vol,sep);
}
