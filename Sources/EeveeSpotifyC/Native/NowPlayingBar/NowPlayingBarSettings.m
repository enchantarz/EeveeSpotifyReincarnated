#import "Core/EeveeCore.h"
#import "Settings/EeveeModPage.h"
#import "NowPlayingBar.h"

UIViewController *EeveeNowPlayingBarSettingsPage(void) {
    return [[EeveeModPage alloc] initWithTitle:@"Now playing bar" intro:EeveeRestartNote sections:@[
        EeveeSection(nil, @[
            EeveeHideRow(@"Hide the device button", nil, EeveeHideBarConnect),
        ]),
        EeveeSection(@"Spotify's flags", @[
            EeveeFlagRow(@"Two lines of track info", @"ios-feature-nowplayingbar.two_lines_information_unit"),
            EeveeFlagRow(@"Save button", @"ios-feature-nowplayingbar.add_button"),
            EeveeFlagRow(@"Queue badge", @"ios-feature-nowplayingbar.queue_badge"),
            EeveeFlagRow(@"Hold and drag to resize", @"ios-feature-nowplayingbar.hold_and_drag_to_resize"),
            EeveeFlagRow(@"Video in the mini player", @"ios-feature-nowplaying.video_in_miniplayer"),
            EeveeFlagRow(@"Bar to cover art animation", @"ios-feature-nowplaying.bartocoverart_animation_enabled"),
            EeveeFlagRow(@"Mini player transition animations", @"ios-feature-nowplaying.miniplayer_transition_animations"),
        ]),
    ] footer:nil];
}
