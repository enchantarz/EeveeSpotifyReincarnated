// The Now playing page of the redesign, under Player (App/Pages.m puts it there): the bar and the
// player behind it.
#import "Core/EeveeCore.h"
#import "Settings/EeveeModPage.h"
#import "NowPlayingBar.h"
#import "Redesigned/Player/Player.h"

UIViewController *EeveeRNowPlayingBarSettingsPage(void) {
    return [[EeveeModPage alloc] initWithTitle:@"Now playing" intro:EeveeRestartNote sections:@[
        EeveeSection(nil, @[
            EeveeHideRow(@"Hide the device button", nil, EeveeRHideBarConnect),
        ]),
        EeveeSection(nil, @[
            EeveeSwitchRow(@"Moving background", nil, EeveeRKeyPlayerMotion),
        ]),
    ] footer:nil];
}
