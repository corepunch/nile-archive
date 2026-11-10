/* Compiled only in the platform unity unit (Objective-C on Apple). GameKit is
 * iOS only; every other target reports no backend and the engine keeps the
 * player's results locally. Names are the game's own: the Game Center
 * identifier is "<bundle id>.<name>". Completion handlers hop to the main
 * queue, where the game runs, before they touch engine state. */
#include "gamecenter.h"

#if defined(AX_PLATFORM_IOS)
#import <UIKit/UIKit.h>
#import <GameKit/GameKit.h>

extern UIWindow *ios_window;

static NSString *gc_identifier(const char *name)
{
    return [NSString stringWithFormat:@"%@.%s", NSBundle.mainBundle.bundleIdentifier, name];
}

static void gc_main(dispatch_block_t block)
{
    if (NSThread.isMainThread) block();
    else dispatch_async(dispatch_get_main_queue(), block);
}

static UIViewController *gc_top_controller(void)
{
    UIViewController *top = ios_window.rootViewController;
    while (top.presentedViewController) top = top.presentedViewController;
    return top;
}

@interface GCFinish : NSObject <GKGameCenterControllerDelegate>
@end
@implementation GCFinish
- (void)gameCenterViewControllerDidFinish:(GKGameCenterViewController *)controller
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}
@end
static GCFinish *gc_finish;

bool gamecenter_platform_available(void) { return NSBundle.mainBundle.bundleIdentifier != nil; }

void gamecenter_platform_start(void)
{
    GKLocalPlayer.localPlayer.authenticateHandler = ^(UIViewController *login, NSError *error) {
        (void)error;
        gc_main(^{
            if (login) {   /* Apple's sign-in sheet; the handler runs again afterwards */
                [gc_top_controller() presentViewController:login animated:YES completion:nil];
                return;
            }
            GKLocalPlayer *me = GKLocalPlayer.localPlayer;
            gamecenter_on_auth(me.isAuthenticated, me.isAuthenticated ? me.displayName.UTF8String : "");
        });
    };
}

void gamecenter_platform_report_score(const char *board, double score)
{
    NSString *name = @(board);
    [GKLeaderboard submitScore:(NSInteger)llround(score) context:0 player:GKLocalPlayer.localPlayer
                leaderboardIDs:@[gc_identifier(board)]
             completionHandler:^(NSError *error) {
        gc_main(^{ gamecenter_on_report(false, name.UTF8String, score, error == nil); });
    }];
}

void gamecenter_platform_report_achievement(const char *achievement, double percent)
{
    NSString *name = @(achievement);
    GKAchievement *a = [[GKAchievement alloc] initWithIdentifier:gc_identifier(achievement)];
    a.percentComplete = percent;
    a.showsCompletionBanner = YES;
    [GKAchievement reportAchievements:@[a] withCompletionHandler:^(NSError *error) {
        gc_main(^{ gamecenter_on_report(true, name.UTF8String, percent, error == nil); });
    }];
    [a release];
}

void gamecenter_platform_load(const char *board, int scope, int count)
{
    NSString *name = @(board);
    GKLeaderboardPlayerScope players = scope == GAMECENTER_FRIENDS ? GKLeaderboardPlayerScopeFriendsOnly : GKLeaderboardPlayerScopeGlobal;
    [GKLeaderboard loadLeaderboardsWithIDs:@[gc_identifier(board)] completionHandler:^(NSArray<GKLeaderboard *> *boards, NSError *error) {
        if (error || boards.count == 0) {
            gc_main(^{ gamecenter_on_entries(name.UTF8String, scope, NULL, 0, false); });
            return;
        }
        [boards[0] loadEntriesForPlayerScope:players timeScope:GKLeaderboardTimeScopeAllTime range:NSMakeRange(1, (NSUInteger)count)
                           completionHandler:^(GKLeaderboardEntry *mine, NSArray<GKLeaderboardEntry *> *entries, NSInteger total, NSError *err) {
            (void)total;
            gc_main(^{
                if (err) { gamecenter_on_entries(name.UTF8String, scope, NULL, 0, false); return; }
                gamecenter_entry rows[GAMECENTER_ENTRY_MAX];
                int n = 0;
                for (GKLeaderboardEntry *e in entries) {
                    if (n >= GAMECENTER_ENTRY_MAX) break;
                    gamecenter_entry *row = &rows[n++];
                    memset(row, 0, sizeof *row);
                    row->rank = (int)e.rank;
                    row->score = (double)e.score;
                    row->me = [e.player.gamePlayerID isEqualToString:GKLocalPlayer.localPlayer.gamePlayerID];
                    snprintf(row->name, sizeof row->name, "%s", e.player.displayName.UTF8String ?: "");
                }
                (void)mine;
                gamecenter_on_entries(name.UTF8String, scope, rows, n, true);
            });
        }];
    }];
}

void gamecenter_platform_show(int view, const char *board)
{
    gc_main(^{
        UIViewController *top = gc_top_controller();
        if (!top || [top isKindOfClass:GKGameCenterViewController.class]) return;
        GKGameCenterViewController *page;
        if (view == GAMECENTER_LEADERBOARD && *board)
            page = [[GKGameCenterViewController alloc] initWithLeaderboardID:gc_identifier(board)
                                                                 playerScope:GKLeaderboardPlayerScopeGlobal
                                                                   timeScope:GKLeaderboardTimeScopeAllTime];
        else
            page = [[GKGameCenterViewController alloc] initWithState:view == GAMECENTER_ACHIEVEMENTS
                        ? GKGameCenterViewControllerStateAchievements : GKGameCenterViewControllerStateDashboard];
        if (!gc_finish) gc_finish = [[GCFinish alloc] init];
        page.gameCenterDelegate = gc_finish;
        [top presentViewController:page animated:YES completion:nil];
        [page release];
    });
}

void gamecenter_platform_access_point(bool on)
{
    gc_main(^{
        GKAccessPoint.shared.location = GKAccessPointLocationTopTrailing;
        GKAccessPoint.shared.active = on;
    });
}

#else
bool gamecenter_platform_available(void) { return false; }
void gamecenter_platform_start(void) {}
void gamecenter_platform_report_score(const char *board, double score) { (void)board; (void)score; }
void gamecenter_platform_report_achievement(const char *name, double percent) { (void)name; (void)percent; }
void gamecenter_platform_load(const char *board, int scope, int count) { (void)board; (void)scope; (void)count; }
void gamecenter_platform_show(int view, const char *board) { (void)view; (void)board; }
void gamecenter_platform_access_point(bool on) { (void)on; }
#endif
