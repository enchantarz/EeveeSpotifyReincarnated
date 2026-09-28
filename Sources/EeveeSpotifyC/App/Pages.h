// The pages of Mod Settings that bring the layers together: what each layer offers is its own
// (Shared/, Native/, Redesigned/). This build draws Spotify's own screens — spoti.pw's Liquid Glass
// redesign was dropped in the merge, switch and all (Core/EeveeUIMode.h) — so a page always hands
// back the native look's.
#import <UIKit/UIKit.h>

@class EeveeModSection;

EeveeModSection *EeveeAppearanceSection(void);   // the Appearance card at the top of Mod Settings
UIViewController *EeveePlayerSettingsPage(void);
UIViewController *EeveeNavbarPage(void);       // the tab editor
