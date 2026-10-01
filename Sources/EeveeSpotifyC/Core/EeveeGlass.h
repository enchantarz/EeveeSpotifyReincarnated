// Glass panes: one UIVisualEffectView per host, kept behind the host's own content.
#import <UIKit/UIKit.h>

// UIGlassEffect made the only way that resolves its material, or a dark chrome blur before iOS 26.
UIVisualEffect *EeveeGlassEffect(void);
UIVisualEffectView *EeveeGlassFor(UIView *host, const void *key);
// Several panes on one host, addressed by index; panes past `count` are hidden by EeveeHideGlassFrom.
UIVisualEffectView *EeveeGlassAt(UIView *host, NSUInteger index);
void EeveeHideGlassFrom(UIView *host, NSUInteger count);
// Glass takes its shape from cornerConfiguration on iOS 26; layer.cornerRadius is the fallback.
void EeveeShapeGlass(UIView *glass, CGFloat radius, BOOL capsule);

// The areas kept transparent are Native/Appearance/Repaint.h's.
