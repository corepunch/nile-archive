#include "engine.h"
#include <string.h>

#if defined(AX_PLATFORM_IOS)
#import <UIKit/UIKit.h>
#elif defined(__APPLE__)
#import <AppKit/AppKit.h>
#endif

bool app_has_https_opener(void)
{
#if defined(__APPLE__)
    return true;
#else
    return false;
#endif
}

bool app_open_https(const char *url)
{
#if defined(__APPLE__)
    if (!url || strncmp(url, "https://", 8) != 0) return false;
    NSURL *link = [NSURL URLWithString:[NSString stringWithUTF8String:url]];
    if (!link.host.length) return false;
#if defined(AX_PLATFORM_IOS)
    [[UIApplication sharedApplication] openURL:link options:@{} completionHandler:nil];
    return true;
#else
    return [[NSWorkspace sharedWorkspace] openURL:link];
#endif
#else
    (void)url;
    return false;
#endif
}
