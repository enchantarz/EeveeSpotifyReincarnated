// Keeps the areas the native look's tweaks stripped transparent when Spotify repaints them.
#import "Core/EeveeCore.h"
#import "Repaint.h"

__weak UIView *eevee_lyricsCardRoot = nil;
__weak UIView *eevee_lyricsPageRoot = nil;
__weak UIView *eevee_homeRoot = nil;
__weak UIView *eevee_npvBackdropRoot = nil;

%hook CALayer
- (void)setBackgroundColor:(CGColorRef)color {
    if (color && (eevee_lyricsCardRoot || eevee_lyricsPageRoot || eevee_homeRoot || eevee_npvBackdropRoot)) {
        UIView *view = (UIView *)self.delegate;
        if ([view isKindOfClass:UIView.class] && view.layer == self && !EeveeKeepsColor(view)) {
            if (EeveeIsInside(view, eevee_lyricsCardRoot) || EeveeIsInside(view, eevee_lyricsPageRoot)) {
                color = NULL;
            } else if (EeveeIsInside(view, eevee_npvBackdropRoot)) {
                // The album colour arrives on the plane per track, outside any layout pass.
                color = NULL;
            } else if (EeveeIsBaseSurface(color) && EeveeIsInside(view, eevee_homeRoot)) {
                // Home keeps its cards and its placeholders; only the base surface the gradient
                // of Native/Home/HomeGradient.x sits behind goes.
                color = NULL;
            }
        }
    }
    %orig(color);
}
%end

%ctor {
    if (!EeveeNativeUI()) return;
    %init;
}
