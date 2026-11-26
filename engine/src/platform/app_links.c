#include "engine.h"
#include <string.h>

#if defined(AX_PLATFORM_IOS)
#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>
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

/* The App Store's rating sheet, drawn by the system over the game. Apple
 * shows it at most three times a year per player and never says whether it
 * did, so the engine only reports that the request was handed over. */
bool app_platform_can_request_review(void)
{
#if defined(AX_PLATFORM_IOS)
    return true;
#else
    return false;
#endif
}

bool app_platform_request_review(void)
{
#if defined(AX_PLATFORM_IOS)
    UIWindowScene *scene = nil;
    for (UIScene *open in UIApplication.sharedApplication.connectedScenes) {
        if (open.activationState == UISceneActivationStateForegroundActive && [open isKindOfClass:UIWindowScene.class]) {
            scene = (UIWindowScene *)open;
            break;
        }
    }
    if (!scene) return false;
    /* StoreKit's replacement is Swift only; this is the same sheet. */
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [SKStoreReviewController requestReviewInScene:scene];
#pragma clang diagnostic pop
    return true;
#else
    return false;
#endif
}
