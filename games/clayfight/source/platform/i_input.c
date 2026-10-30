/* Platform events become the original game's edge-triggered virtual keys. */
#include "../../../../engine/third_party/platform/platform.h"
#include "platform/platform.h"
#include <string.h>

void clay_key(int key, int down);
void clay_focus(void);
static bool held[2048];
static int axes[2];

void clay_input_event(const struct AXmessage *e)
{
    if (e->message == kEventKillFocus) {
        memset(held, 0, sizeof held);
        memset(axes, 0, sizeof axes);
        clay_focus();
        return;
    }
#if !defined(__APPLE__) || defined(CLAY_TEST_JOYSTICK)
    if (e->message == kEventJoyButtonDown || e->message == kEventJoyButtonUp) {
        static const int buttons[] = {PK_B2, PK_B3, PK_B0, PK_B1, PK_BACK, PK_START};
        if (e->wParam < sizeof buttons / sizeof *buttons)
            clay_key(PADKEY(0, buttons[e->wParam]), e->message == kEventJoyButtonDown);
    }
    if (e->message == kEventJoyAxisMotion && e->wParam < 2) {
        int i = e->wParam, v = (int16_t)(intptr_t)e->lParam;
        int dir = v < -16000 ? -1 : v > 16000 ? 1 : 0;
        if (dir != axes[i]) {
            int negative = i ? PK_UP : PK_LEFT, positive = i ? PK_DOWN : PK_RIGHT;
            if (axes[i]) clay_key(PADKEY(0, axes[i] < 0 ? negative : positive), 0);
            if (dir) clay_key(PADKEY(0, dir < 0 ? negative : positive), 1);
            axes[i] = dir;
        }
    }
#endif
    if (e->message == kEventKeyDown || e->message == kEventKeyUp) {
        int k = e->keyCode;
        if (k >= 'A' && k <= 'Z') k += 'a' - 'A';
        else if (k >= AX_KEY_UPARROW && k <= AX_KEY_RIGHTARROW) k += KEY_UPARROW - AX_KEY_UPARROW;
        else if (k == AX_KEY_KP_ENTER) k = KEY_ENTER;
        /* Unknown special keys must never collide with the game's virtual keys. */
        else if (k < 9 || k > 126) return;
        bool down = e->message == kEventKeyDown;
        if (held[k] != down) { held[k] = down; clay_key(k, down); }
    }
}
