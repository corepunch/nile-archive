#include "../../../engine/third_party/platform/platform.h"
#include "platform/platform.h"
#include <assert.h>
#include <stdio.h>

void clay_input_event(const struct AXmessage *e);
static int count, focus, keys[64], downs[64];
void clay_key(int key, int down) { assert(count < 64); keys[count] = key; downs[count++] = down; }
void clay_focus(void) { focus++; }
static void key(int code, int down) {
    struct AXmessage e = {.message = down ? kEventKeyDown : kEventKeyUp, .wParam = code};
    clay_input_event(&e);
}
static void axis(int i, int v) {
    struct AXmessage e = {.message=kEventJoyAxisMotion, .wParam=i, .lParam=(void *)(intptr_t)v};
    clay_input_event(&e);
}
int main(void) {
    key('W' | AX_MOD_SHIFT, 1); key('W', 1); key('W', 0);
    assert(count == 2 && keys[0] == 'w' && downs[0] && !downs[1]);
    for(int k=AX_KEY_UPARROW;k<=AX_KEY_RIGHTARROW;k++){key(k,1);key(k,0);assert(keys[count-1]==KEY_UPARROW+k-AX_KEY_UPARROW);}
    key(AX_KEY_TAB,1);key(AX_KEY_TAB,0);assert(keys[count-1]=='\t');
    key(AX_KEY_SEMICOLON,1);key(AX_KEY_SEMICOLON,0);assert(keys[count-1]==';');
    key(AX_KEY_KP_ENTER,1);key(AX_KEY_KP_ENTER,0);assert(keys[count-1]==KEY_ENTER);
    int before=count;key(AX_KEY_F1,1);key(2048,1);assert(count==before);
    axis(0,-20000);axis(0,-21000);assert(count==before+1 && keys[count-1]==PADKEY(0,PK_LEFT));
    axis(0,20000);assert(count==before+3 && !downs[count-2] && keys[count-1]==PADKEY(0,PK_RIGHT));
    struct AXmessage lost={.message=kEventKillFocus};clay_input_event(&lost);assert(focus==1);
    axis(0,20000);assert(count==before+4 && downs[count-1]);
    axis(0,0);assert(!downs[count-1]);
    struct AXmessage button={.message=kEventJoyButtonDown,.wParam=2};clay_input_event(&button);
    assert(keys[count-1]==PADKEY(0,PK_B0) && downs[count-1]);
    button.message=kEventJoyButtonUp;clay_input_event(&button);assert(!downs[count-1]);
    puts("input: physical keys, modifiers, repeat suppression, arrows, Tab, pad edges and focus reset passed");
}
