// The taps of Vibrations > Controls, one per kind of control, from UIKit's feedback generators, so they
// feel like the rest of iOS: impacts for a press that does something, selection ticks for a value moving
// under the finger (Apple's Playing haptics: impact complements a physical action, selection a changing
// value). Starting playback is a crisp tap and stopping it a soft one, so the two can be told apart
// without looking.
//
// Controls' strength scales every impact's intensity. A selection tick has no intensity to scale, so under
// 100% it becomes a rigid impact, the nearest thing UIKit has to it, at about a tick's weight times the
// strength; at 100% it stays the system's own tick.
#import "Core/EeveeCore.h"
#import "Haptics.h"

typedef struct {
    NSInteger style;      // a UIImpactFeedbackStyle, or kSelection
    CGFloat intensity;
} Tap;

static const NSInteger kSelection = -1;
// A rigid impact at this intensity stands in for a selection tick (a bet: UIKit gives the tick no number).
static const CGFloat kTickIntensity = 0.5;

static Tap tapFor(EeveeFeedback feedback) {
    switch (feedback) {
        case EeveeFeedbackPlay: return (Tap){UIImpactFeedbackStyleRigid, 0.8};
        case EeveeFeedbackPause: return (Tap){UIImpactFeedbackStyleSoft, 1};
        case EeveeFeedbackSkip: return (Tap){UIImpactFeedbackStyleLight, 1};
        case EeveeFeedbackToggle: return (Tap){kSelection, 1};
        case EeveeFeedbackAdd: return (Tap){UIImpactFeedbackStyleMedium, 0.8};
        case EeveeFeedbackGrab: return (Tap){UIImpactFeedbackStyleLight, 0.7};
        case EeveeFeedbackDetent: return (Tap){kSelection, 1};
        case EeveeFeedbackEdge: return (Tap){UIImpactFeedbackStyleRigid, 0.6};
        case EeveeFeedbackRelease: return (Tap){UIImpactFeedbackStyleSoft, 0.8};
    }
    return (Tap){kSelection, 1};
}

static Tap tapAtStrength(EeveeFeedback feedback) {
    Tap tap = tapFor(feedback);
    double strength = EeveeHapticsStrength(EeveeKeyControlStrength);
    if (strength >= 1) return tap;
    if (tap.style == kSelection) return (Tap){UIImpactFeedbackStyleRigid, kTickIntensity * strength};
    return (Tap){tap.style, tap.intensity * strength};
}

static UIFeedbackGenerator *generatorFor(NSInteger style) {
    static NSMutableDictionary<NSNumber *, UIFeedbackGenerator *> *generators;
    if (!generators) generators = [NSMutableDictionary dictionary];
    UIFeedbackGenerator *generator = generators[@(style)];
    if (!generator) {
        generator = style == kSelection ? [UISelectionFeedbackGenerator new] : [[UIImpactFeedbackGenerator alloc] initWithStyle:(UIImpactFeedbackStyle)style];
        generators[@(style)] = generator;
    }
    return generator;
}

void EeveePlayFeedback(EeveeFeedback feedback) {
    if (!EeveeEnabled(EeveeKeyControlHaptics)) return;
    Tap tap = tapAtStrength(feedback);
    UIFeedbackGenerator *generator = generatorFor(tap.style);
    if (tap.style == kSelection) [(UISelectionFeedbackGenerator *)generator selectionChanged];
    else [(UIImpactFeedbackGenerator *)generator impactOccurredWithIntensity:tap.intensity];
}

void EeveePrepareFeedback(EeveeFeedback feedback) {
    if (!EeveeEnabled(EeveeKeyControlHaptics)) return;
    [generatorFor(tapAtStrength(feedback).style) prepare];
}
