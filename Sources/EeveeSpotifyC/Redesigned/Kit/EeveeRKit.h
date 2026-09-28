// The Redesign Kit: what every part of the redesign (Redesigned/<Part>/) builds on, so the screens share
// one look and nothing is hand-rolled per screen. A screen imports this and Core/EeveeCore.h.
//
//     EeveeRedesign.h   Redesigned UI, the one switch, and the flags the redesigned screens force
//     EeveeRTokens.h    colours, type, spacing, radii, motion, the accessibility settings
//     EeveeRPalette.h   the artwork's edge colour, the field colour and the pre-blurred bitmaps
//     EeveeRField.h     the artwork field behind a page
//     EeveeRFlow.h      the player's moving field of the artwork's colours
//     EeveeRGlass.h     glass inside Spotify's round controls
//     EeveeRGlyph.h     bare glyph overlays and glyph buttons
//     EeveeRActionRow.h the Play capsule and the stand-in button of a page's action row
//     EeveeRDownload.h  Spotify's download state, read, and the glyph drawn for it
//     EeveeRHeaderInfo.h a page header's title, creator, length, row and description, the Music app's
//     EeveeRRestyle.h   keeping Spotify's views restyled: suppress, digits, lookups, shadows, firing
//                    controls, taking a list cell's paint off the field
//     EeveeRBridges.h   player state, now playing artwork, the player's open and close
//     EeveeRRepaint.h   the areas the redesign keeps transparent when Spotify repaints them
//     EeveeRAccent.h    the redesign's accent colour; its AMOLED black is EeveeRAmoled.x, always on
//
// Every hook file of the redesign starts its %ctor with `if (!EeveeRedesignedUI()) return;` and every one
// of Native/ with `if (!EeveeNativeUI()) return;` (Core/EeveeUIMode.h), so the two looks never run together.
#import "EeveeRedesign.h"
#import "EeveeRTokens.h"
#import "EeveeRPalette.h"
#import "EeveeRField.h"
#import "EeveeRFlow.h"
#import "EeveeRGlass.h"
#import "EeveeRGlyph.h"
#import "EeveeRActionRow.h"
#import "EeveeRDownload.h"
#import "EeveeRHeaderInfo.h"
#import "EeveeRRestyle.h"
#import "EeveeRBridges.h"
#import "EeveeRRepaint.h"
#import "EeveeRAccent.h"
