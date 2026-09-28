// The native look's appearance: the AMOLED background (Amoled.x), the accent colour in place of
// Spotify's green (Accent.x), the soft top edge (EdgeEffect.x) and Repaint.x, which keeps what the
// native tweaks stripped transparent when Spotify repaints it. The switches are off until asked for.
#import <UIKit/UIKit.h>

#define EeveeKeyAmoled @"EeveeSpotify.amoled"
#define EeveeKeyAccent @"EeveeSpotify.accent"   // 0xRRGGBB; unset or negative keeps Spotify's own green

UIColor *EeveeAccentColor(void);   // nil while Spotify's own green is kept
NSString *EeveeAccentLabel(void);  // "#RRGGBB", or the name of Spotify's own
void EeveePickAccent(void);        // the system colour picker over the top of the app, stored on the way out

@class EeveeModRow;
NSArray<EeveeModRow *> *EeveeNativeAppearanceRows(void);   // AMOLED and the accent colour, for the Appearance card
