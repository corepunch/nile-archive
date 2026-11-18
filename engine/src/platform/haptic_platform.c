/* Compiled only in the platform unity unit (Objective-C on Apple). */
#include "haptic.h"

#if defined(AX_PLATFORM_IOS)
#import <UIKit/UIKit.h>
#import <CoreHaptics/CoreHaptics.h>

static UIImpactFeedbackGenerator *haptic_impacts[3];
static UINotificationFeedbackGenerator *haptic_notification;

bool haptic_platform_available(void)
{
    return [CHHapticEngine capabilitiesForHardware].supportsHaptics;
}
void haptic_platform_play(int effect, float strength)
{
    if (!haptic_platform_available() || UIApplication.sharedApplication.applicationState != UIApplicationStateActive) return;
    if (effect == HAPTIC_SUCCESS || effect == HAPTIC_ERROR) {
        if (!haptic_notification) haptic_notification = [[UINotificationFeedbackGenerator alloc] init];
        [haptic_notification notificationOccurred:effect == HAPTIC_SUCCESS ? UINotificationFeedbackTypeSuccess : UINotificationFeedbackTypeError];
    } else {
        int slot = effect == HAPTIC_TICK || effect == HAPTIC_COLLECT ? 0
            : effect == HAPTIC_COMBO || effect == HAPTIC_PLACE ? 2 : 1;
        const UIImpactFeedbackStyle styles[] = {UIImpactFeedbackStyleSoft, UIImpactFeedbackStyleLight, UIImpactFeedbackStyleMedium};
        if (!haptic_impacts[slot]) haptic_impacts[slot] = [[UIImpactFeedbackGenerator alloc] initWithStyle:styles[slot]];
        UIImpactFeedbackGenerator *feedback = haptic_impacts[slot];
        [feedback impactOccurredWithIntensity:strength];
        [feedback prepare];
    }
}
void haptic_platform_stop(void)
{
    /* UIKit owns the one-shot pulse; release prepared generators on suspend. */
    for (int i = 0; i < 3; i++) { [haptic_impacts[i] release]; haptic_impacts[i] = nil; }
    [haptic_notification release]; haptic_notification = nil;
}

#elif defined(__APPLE__)
#import <AppKit/AppKit.h>
bool haptic_platform_available(void) { return [NSHapticFeedbackManager defaultPerformer] != nil; }
void haptic_platform_play(int effect, float strength)
{
    if (!NSApp.active) return;
    NSHapticFeedbackPattern pattern = effect == HAPTIC_TICK ? NSHapticFeedbackPatternAlignment
        : effect == HAPTIC_COLLECT || effect == HAPTIC_MATCH ? NSHapticFeedbackPatternLevelChange : NSHapticFeedbackPatternGeneric;
    [[NSHapticFeedbackManager defaultPerformer] performFeedbackPattern:pattern performanceTime:NSHapticFeedbackPerformanceTimeNow];
}
void haptic_platform_stop(void) {}

#elif defined(__EMSCRIPTEN__)
#include <emscripten.h>
EM_JS(bool, haptic_platform_available, (void), { return typeof navigator.vibrate === 'function'; });
EM_JS(void, haptic_platform_play, (int effect, float strength), {
    if (typeof navigator.vibrate !== 'function' || document.hidden ||
        (navigator.userActivation && !navigator.userActivation.hasBeenActive)) return;
    var patterns = [0, 8, 18, [18, 30, 24], 28, 10, [18, 45, 30], [30, 35, 15]];
    var pattern = patterns[effect];
    if (Array.isArray(pattern)) pattern = pattern.map(function(ms, i) { return i % 2 ? ms : Math.max(1, Math.round(ms * strength)); });
    else pattern = Math.max(1, Math.round(pattern * strength));
    try { navigator.vibrate(pattern); } catch (e) {}   // Device/browser policy may decline.
});
EM_JS(void, haptic_platform_stop, (void), {
    if (typeof navigator.vibrate === 'function') { try { navigator.vibrate(0); } catch (e) {} }
});

#else
bool haptic_platform_available(void) { return false; }
void haptic_platform_play(int effect, float strength) {}
void haptic_platform_stop(void) {}
#endif
