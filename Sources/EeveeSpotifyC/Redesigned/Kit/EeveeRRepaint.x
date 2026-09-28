// Keeps the areas the redesign stripped transparent when Spotify repaints them, and learns which view
// is the now playing bar's card from the album-colour paint.
#import "Core/EeveeCore.h"
#import "EeveeRRepaint.h"

__weak UIView *eeveeR_nowPlayingRoot = nil;
__weak UIView *eeveeR_nowPlayingCard = nil;
__weak UIView *eeveeR_lyricsPageRoot = nil;
__weak UIView *eeveeR_playlistRoot = nil;
__weak UIView *eeveeR_albumRoot = nil;
__weak UIView *eeveeR_artistRoot = nil;

%hook CALayer
- (void)setBackgroundColor:(CGColorRef)color {
    if (color && (eeveeR_nowPlayingRoot || eeveeR_lyricsPageRoot || eeveeR_playlistRoot || eeveeR_albumRoot || eeveeR_artistRoot)) {
        UIView *view = (UIView *)self.delegate;
        if ([view isKindOfClass:UIView.class] && view.layer == self && !EeveeKeepsColor(view)) {
            if (EeveeIsInside(view, eeveeR_nowPlayingRoot)) {
                if (EeveeLooksLikeCard(view, color) && eeveeR_nowPlayingCard != view) {
                    eeveeR_nowPlayingCard = view;
                    UIView *bar = eeveeR_nowPlayingRoot;
                    dispatch_async(dispatch_get_main_queue(), ^{ [bar.superview setNeedsLayout]; });
                }
                color = NULL;
            } else if (EeveeIsInside(view, eeveeR_lyricsPageRoot)) {
                color = NULL;
            } else if (EeveeIsBaseSurface(color) && (EeveeIsInside(view, eeveeR_playlistRoot) || EeveeIsInside(view, eeveeR_albumRoot) || EeveeIsInside(view, eeveeR_artistRoot))) {
                color = NULL;
            }
        }
    }
    %orig(color);
}
%end

%ctor {
    if (!EeveeRedesignedUI()) return;
    %init;
}
