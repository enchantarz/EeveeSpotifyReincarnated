// The player's open and close, told from the appearance callbacks of a controller inside the player,
// which UIKit sends as the presentation or the dismissal begins, whatever animates it; the transition
// coordinator says when it is over, a cancelled swipe included. Spotify 9.1.78 presents the player
// through SPTBarInteractivePresentationController, never through NowPlaying_ViewPageImpl's
// Show/CloseFullscreenAnimatedTransitioning animators, whose hooks never once fired.
#import "Core/EeveeCore.h"
#import "PlayerEvents.h"

NSString *const EeveePlayerTransitionNotification = @"EeveeSpotify.playerTransition";
NSString *const EeveePlayerTransitionEndedNotification = @"EeveeSpotify.playerTransitionEnded";
static CFTimeInterval eevee_transitionEnds;
static NSUInteger eevee_transitionGeneration;

CFTimeInterval EeveePlayerTransitionEnds(void) {
    return eevee_transitionEnds > CACurrentMediaTime() ? eevee_transitionEnds : 0;
}

static void announceTransition(UIViewController *unit, BOOL animated, NSString *what) {
    id<UIViewControllerTransitionCoordinator> coordinator = unit.transitionCoordinator;
    if (!animated || !coordinator) return;
    NSTimeInterval duration = MAX(0.1, coordinator.transitionDuration);
    NSUInteger generation = ++eevee_transitionGeneration;
    eevee_transitionEnds = CACurrentMediaTime() + duration;
    [NSNotificationCenter.defaultCenter postNotificationName:EeveePlayerTransitionNotification object:nil];
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        if (generation != eevee_transitionGeneration) return;
        eevee_transitionEnds = 0;
        [NSNotificationCenter.defaultCenter postNotificationName:EeveePlayerTransitionEndedNotification object:nil];
    }];
    static dispatch_once_t once;
    dispatch_once(&once, ^{ EeveeLog(@"player %@ over %.2fs, by its appearance callbacks", what, duration); });
}

%hook _TtC21NowPlaying_ScrollImpl27NPVBackgroundViewController
- (void)viewWillAppear:(BOOL)animated {
    %orig;
    announceTransition((UIViewController *)self, animated, @"opens");
}
- (void)viewWillDisappear:(BOOL)animated {
    %orig;
    announceTransition((UIViewController *)self, animated, @"closes");
}
%end

%ctor {
    %init;
    EeveeRequireClasses(@[@"_TtC21NowPlaying_ScrollImpl27NPVBackgroundViewController"]);
}
