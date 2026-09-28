// The tour goes up the first time Home appears, not at launch: a fresh sideload lands on the login
// screen first, and a tour over that is wrong. A moment after, so Home has drawn under the glass.
#import "Core/EeveeCore.h"
#import "Onboarding.h"

%hook _TtC19Home_FunkisPageImpl20FunkisViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (!EeveeFlag(EeveeKeyOnboardingSeen, NO)) EeveeShowOnboarding();
        });
    });
}
%end

%ctor {
    if (EeveeFlag(EeveeKeyOnboardingSeen, NO)) return;
    %init;
    EeveeRequireClasses(@[@"_TtC19Home_FunkisPageImpl20FunkisViewController"]);
}
