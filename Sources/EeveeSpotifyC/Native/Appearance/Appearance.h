// The native look's appearance: the accent colour in place of Spotify's green (Accent.x), the soft
// top edge (EdgeEffect.x) and Repaint.x, which keeps what the native tweaks stripped transparent
// when Spotify repaints it. The switches are off until asked for.
//
// spoti.pw's AMOLED background (Amoled.x) was removed: the theme is now EeveeSpotify's own
// (Sources/EeveeSpotify/AmoledTheme.x.swift, the "AMOLED Black Theme" toggle under Customization).
#import <UIKit/UIKit.h>

#define EeveeKeyAccent @"EeveeSpotify.accent"   // 0xRRGGBB; unset or negative keeps Spotify's own green

UIColor *EeveeAccentColor(void);   // nil while Spotify's own green is kept
NSString *EeveeAccentLabel(void);  // "#RRGGBB", or the name of Spotify's own
void EeveePickAccent(void);        // the system colour picker over the top of the app, stored on the way out

@class EeveeModRow;
NSArray<EeveeModRow *> *EeveeNativeAppearanceRows(void);   // the accent colour, for the Appearance card
