#import "Core/EeveeCore.h"
#import "Settings/EeveeModPage.h"
#import "Settings/EeveePageStyle.h"
#import "Pages.h"
#import "Shared/ArtistBlock/ArtistBlock.h"
#import "Shared/Gestures/Gestures.h"
#import "Shared/Player/PlayerSettings.h"
#import "Native/Appearance/Appearance.h"
#import "Native/Navbar/Navbar.h"
#import "Native/NowPlayingBar/NowPlayingBar.h"
#import "Native/Player/NowPlaying.h"
#import "Shared/Haptics/Haptics.h"

// spoti.pw's "Redesigned UI" switch, the restart prompt it used to put up and the "Needs iOS 26" row
// that stood in for it on older phones were removed in the merge, as were the pages only the redesign
// had. There is no switch left, its key is ignored, and this build draws Spotify's own screens
// (Core/EeveeUIMode.h) — which is why every page below hands back the native look's. Routing
// everything through one look also means the two looks' pages can no longer disagree about which one
// was running, which is what the routing used to hide.

EeveeModSection *EeveeAppearanceSection(void) {
    // The native look's appearance: AMOLED and the accent colour. The redesign's own rows went with
    // the redesign, and with them AMOLED's absence from that card, so the section is no longer
    // written one way above iOS 26 and another below it.
    return EeveeNotedSection(@"Appearance", EeveeNativeAppearanceRows(), @"Changes apply after you restart Spotify.");
}

UIViewController *EeveeNavbarPage(void) {
    return EeveeNavbarSettingsPage();
}

// spoti.pw's own lyrics engine (Shared/Lyrics*, Native/Lyrics) was dropped in
// the merge: EeveeSpotify already ships one, so its settings live under EeveeSpotify's own
// Lyrics section rather than as a page here.

UIViewController *EeveePlayerSettingsPage(void) {
    EeveeModRow *blocked = EeveePageRow(@"Blocked artists", ^UIViewController *{ return EeveeArtistBlockSettingsPage(); });
    blocked.value = ^NSString *{
        return EeveeFlag(EeveeKeyArtistBlock, NO) ? @(EeveeBlockedArtists().count).stringValue : @"Off";
    };
    NSMutableArray<EeveeModSection *> *sections = [NSMutableArray arrayWithObject:EeveeSection(nil, @[
        EeveeWithSymbol(EeveePageRow(@"Gestures", ^UIViewController *{ return EeveeGesturesSettingsPage(); }), @"hand.tap"),
        EeveeWithSymbol(blocked, @"person.crop.circle.badge.xmark"),
    ])];
    NSMutableArray<EeveeModRow *> *pages = [NSMutableArray array];
    [pages addObject:EeveeWithSymbol(EeveePageRow(@"Now playing bar", ^UIViewController *{ return EeveeNowPlayingBarSettingsPage(); }), @"rectangle.bottomthird.inset.filled")];
    [pages addObject:EeveeWithSymbol(EeveePageRow(@"Queue & devices", ^UIViewController *{ return EeveeQueueSettingsPage(); }), @"text.line.first.and.arrowtriangle.forward")];
    [pages addObject:EeveeWithSymbol(EeveePageRow(@"Lock screen widget", ^UIViewController *{ return EeveeLockScreenWidgetPage(); }), @"lock")];
    [sections addObject:EeveeSection(nil, pages)];
    [sections addObjectsFromArray:EeveeNativePlayerScreenSections()];
    // Vibrations hook Spotify's own controls and its audio, so they answer under either look.
    [sections addObjectsFromArray:EeveeVibrationsSections()];

    return [[EeveeModPage alloc] initWithTitle:@"Player" intro:EeveeRestartNote sections:sections footer:nil];
}
