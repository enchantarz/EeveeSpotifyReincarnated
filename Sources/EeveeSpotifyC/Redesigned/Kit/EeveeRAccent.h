// The redesign's accent colour in place of Spotify's green (EeveeRAccent.x), chosen apart from the native
// look's and stored under its own key; unset is #37F200, negative keeps Spotify's own green.
#import <UIKit/UIKit.h>

#define EeveeRKeyAccent @"EeveeSpotify.redesign.accent"   // 0xRRGGBB

UIColor *EeveeRAccentColor(void);   // nil while Spotify's own green is kept
NSString *EeveeRAccentLabel(void);  // "#RRGGBB", or the name of Spotify's own
void EeveeRPickAccent(void);        // the system colour picker over the top of the app, stored on the way out

@class EeveeModRow;
NSArray<EeveeModRow *> *EeveeRAppearanceRows(void);   // the accent colour, for the Appearance card
