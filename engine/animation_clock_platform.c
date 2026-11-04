#include "animation_clock.h"

#if defined(AX_PLATFORM_IOS)
#import <QuartzCore/QuartzCore.h>

/* The scene already stops delivering frames while inactive. Use the host
 * clock so the first active frames can advance even without a focus event. */
double animation_clock_seconds(void) { return CACurrentMediaTime(); }
#else
#include "third_party/platform/platform.h"

double animation_clock_seconds(void) { return axGetMilliseconds() / 1000.0; }
#endif
