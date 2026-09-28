#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// The ported spoti.pw settings page: an Appearance card, a page per part of Spotify (Navbar,
/// Player, Audio effects), Labs and All flags. Defined in App/ModSettings.x.
///
/// The declaration lives here, in the header the Swift side sees, rather than in the ported
/// Sources/EeveeSpotifyC/Settings/EeveePage.h: that tree's headers reach each other as
/// `#import "Settings/EeveePage.h"` and are not on Swift's include path, so Swift would not find it.
/// Nothing about spoti.pw's standalone entry point survives — this is only ever pushed from
/// EeveeSpotify's own settings menu.
UIViewController *EeveeSpotipwSettingsPage(void);

NS_ASSUME_NONNULL_END
