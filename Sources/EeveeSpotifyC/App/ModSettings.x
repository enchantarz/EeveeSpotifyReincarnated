// The ported spoti.pw settings, reached from EeveeSpotify's own settings menu and nowhere else.
//
// spoti.pw used to hang a "Mod Settings" row at the end of Spotify's settings list, at the top of
// the side drawer's list, and off a long-press of Home on the tab bar. In the merge that standalone
// entry point is gone: this file no longer hooks SettingsListViewController, the side drawer's
// ListViewController or UICollectionView, and nothing is added to Spotify's own settings UI.
// EeveeSpotify's menu pushes the page below.
//
// The page itself is spoti.pw's: an Appearance card, then a page per part of Spotify (Navbar,
// Player, Audio effects), and All flags, a searchable list of every flag with an override per flag.
// The switches are read when their tweaks run, so a change shows after a restart.
//
// Dropped in the merge, all of it spoti.pw's own: the Redesigned UI switch (the Liquid Glass look
// is always on, so there is nothing to toggle), the Premium/ads page (EeveeSpotify's ad blocking
// owns that), Live Activity (it ships as a widget extension, not in this dylib), the updates page
// and the donate row.

#import "Core/EeveeCore.h"
#import "Settings/EeveePage.h"
#import "Settings/EeveePageStyle.h"
#import "Settings/EeveeModPage.h"
#import "Native/Home/Home.h"
#import "Shared/Flags/Flags.h"
#import "Shared/JamesDSP/JamesDSPPage.h"
#import "Shared/LiveActivity/LiveActivity.h"
#import "App/About/About.h"
#import "Pages.h"

static EeveeModRow *pageRow(NSString *title, NSString *symbol, UIViewController *(^page)(void)) {
    return EeveeWithSymbol(EeveePageRow(title, page), symbol);
}

UIViewController *EeveeSpotipwSettingsPage(void) {
    NSMutableArray<EeveeModSection *> *sections = [NSMutableArray array];
    // A build the lock screen cannot open leads the page, above the tweaks: it is the one thing here
    // that no switch can put right, and it is worth reading before anything else.
    EeveeModRow *signing = EeveeSigningWarningRow();
    if (signing) [sections addObject:EeveeSection(nil, @[signing])];
    EeveeModRow *mod = pageRow(@"Mod", @"info.circle", ^UIViewController *{ return EeveeAboutPage(); });
    mod.value = ^NSString *{ return @(EEVEE_SPOTIPW_VERSION); };
    // JamesDSP works on the sound, so both looks have it, with what it is doing beside the chevron.
    EeveeModRow *audioEffects = pageRow(@"Audio effects", @"slider.vertical.3", ^UIViewController *{ return EeveeDSPSettingsPage(); });
    audioEffects.value = ^NSString *{ return EeveeDSPSummary(); };
    NSMutableArray<EeveeModRow *> *parts = [NSMutableArray arrayWithArray:@[
        pageRow(@"Navbar", @"dock.rectangle", ^UIViewController *{ return EeveeNavbarPage(); }),
        pageRow(@"Player", @"play.circle", ^UIViewController *{ return EeveePlayerSettingsPage(); }),
        audioEffects,
    ]];
    // The Live Activity draws on the lock screen and the Dynamic Island, not on a Spotify screen, so
    // it has a page under either look. iOS 17 is where ActivityKit's card starts.
    if (@available(iOS 17.0, *)) {
        EeveeModRow *liveActivity = pageRow(@"Live Activity", @"platter.filled.top.iphone", ^UIViewController *{ return EeveeLiveActivitySettingsPage(); });
        liveActivity.value = ^NSString *{ return EeveeLiveActivitySummary(); };
        [parts addObject:liveActivity];
    }
    [parts addObject:pageRow(@"Home & Library", @"house", ^UIViewController *{ return EeveeHomeSettingsPage(); })];
    [sections addObjectsFromArray:@[
        EeveeAppearanceSection(),
        EeveeSection(nil, parts),
        EeveeSection(nil, @[
            pageRow(@"Labs", @"testtube.2", ^UIViewController *{ return EeveeLabsPage(); }),
        ]),
        EeveeSection(nil, @[
            pageRow(@"All flags", @"flag", ^UIViewController *{ return EeveeAllFlagsPage(); }),
            mod,
        ]),
    ]];
    return [[EeveeModPage alloc] initWithTitle:@"EeveeSpotify" intro:nil sections:sections footer:nil];
}

%ctor {
    %init;
    EeveeRegisterPages();
    EeveeCheckSigningOnce();
}
