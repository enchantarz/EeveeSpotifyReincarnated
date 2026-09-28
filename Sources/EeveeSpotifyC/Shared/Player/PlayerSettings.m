// The player's settings that do not depend on the look: the lock screen widget's flags.
#import "Core/EeveeCore.h"
#import "Settings/EeveeModPage.h"
#import "PlayerSettings.h"

UIViewController *EeveeLockScreenWidgetPage(void) {
    return [[EeveeModPage alloc] initWithTitle:@"Lock screen widget" intro:EeveeRestartNote sections:@[
        EeveeSection(@"Controls", @[
            EeveeFlagRow(@"Like and dislike buttons", @"ios-feature-lockscreen.like_dislike_enabled"),
            EeveeFlagRow(@"Skip button on podcasts", @"ios-feature-lockscreen.skip_button_on_podcasts"),
            EeveeFlagRow(@"Chapter skip controls", @"ios-feature-lockscreen.enable_chapter_skip_controls"),
            EeveeFlagRow(@"Burst skip", @"ios-feature-lockscreen.burst_skip_enabled"),
        ]),
        EeveeSection(@"Artwork", @[
            EeveeFlagRow(@"Animated artwork", @"ios-feature-lockscreen.animated_artwork_enabled"),
            EeveeFlagRow(@"Video artwork", @"ios-feature-lockscreen.vit_artwork_enabled"),
            EeveeFlagRow(@"Companion content", @"ios-feature-lockscreen.companion_content_enabled"),
        ]),
    ] footer:nil];
}
