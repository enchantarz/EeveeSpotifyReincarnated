// Walking and reading Spotify's view trees.
#import <UIKit/UIKit.h>

void EeveeForEachView(UIView *view, void (^fn)(UIView *));
CGRect EeveeFrameIn(UIView *view, UIView *target);
// Whether `view` sits under `root`, stopping at a visual effect view on the way up.
BOOL EeveeIsInside(UIView *view, UIView *root);
// The first wide stack view under `host` with at least two arranged children: a player row, or
// the row of items in the tab bar.
UIStackView *EeveeRowIn(UIView *host);
// Whether any view under `root` has `marker` in its class name.
BOOL EeveeHasClass(UIView *root, NSString *marker);

// Artwork, glyphs, text and thin lines (progress bar) keep their colour, everything else goes clear.
BOOL EeveeKeepsColor(UIView *view);
void EeveeStripBackgrounds(UIView *view);
// Spotify's base surface: the neutral #121212 it paints its pages with, or the black AMOLED turns
// that into.
BOOL EeveeIsBaseSurface(CGColorRef color);
