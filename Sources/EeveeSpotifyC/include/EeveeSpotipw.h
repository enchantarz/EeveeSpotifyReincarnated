#import <UIKit/UIKit.h>

// The model the ported pages are built out of, plus the preference and flag accessors a row reads.
// A ported page is described rather than only drawn — an EeveeModPage holds its sections, a section
// holds its rows, and a row says what it is (a key to switch, a page to open, a number to read out)
// — so the SwiftUI renderer draws the page from these instead of hosting its table.
//
// Sources/EeveeSpotifyC is on the Swift side's include path for this
// (EeveeSpotify_SWIFTFLAGS in the Makefile): the tree's headers reach each other as
// "Settings/EeveeModPage.h", so the directory has to be findable there too.
#import "Core/EeveePrefs.h"
#import "Core/EeveeFlagForce.h"
#import "Settings/EeveeModPage.h"
#import "Settings/EeveePageStyle.h"

NS_ASSUME_NONNULL_BEGIN

/// The ported spoti.pw settings page: an Appearance card, a page per part of Spotify (Navbar,
/// Player, Audio effects), Labs and All flags. Defined in App/ModSettings.x.
///
/// The declaration lives here, in the header the Swift side sees, rather than in the ported
/// Sources/EeveeSpotifyC/Settings/EeveePage.h: that tree's headers reach each other as
/// `#import "Settings/EeveePage.h"` and are not on Swift's include path, so Swift would not find it.
/// Nothing about spoti.pw's standalone entry point survives — this is only ever pushed from
/// EeveeSpotify's own settings menu. Always an EeveeModPage: the renderer draws it rather than
/// hosting the table it used to be, so the Swift side gets the row model directly.
EeveeModPage *EeveeSpotipwSettingsPage(void);

NS_ASSUME_NONNULL_END
