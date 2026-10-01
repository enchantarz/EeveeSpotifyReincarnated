// Vibrations > Controls: a tap for what a finger does to playback, in the full screen player and the
// now playing bar (EeveeFeedback.m holds which tap each gets).
//
// Buttons: every control's action passes -[UIControl sendAction:to:forEvent:] (target and action) or
// -[UIControl sendAction:] (a UIAction), so the controls are told apart there by accessibility
// identifier, after they have acted. Tree (trees/clean/player/01.txt): id=SPTNowPlayingPlayButton is the
// PlayButtonView (:266, and the sticky header's :492) around the UIButton that acts (CondensedButton, :272),
// in the bar too (trees/clean/home/01.txt:1281); id=SPTNowPlayingPreviousTrackButton and ...NextTrackButton
// are Encore buttons (:257, :282); id=Components.UI.ShuffleButton and Nowplaying-RepeatButton are
// EncoreButtons, UIButtons (:247, :290); id=Components.UI.AddToButton is a UIButton (:205, :425 on a card,
// home/01.txt:1296 in the bar).
// Play or pause is read off the player's state before the button acts, since the tap turns it.
//
// Scrubbing: the position slider is NowPlaying_ECMKit.ProgressBar.Slider, a UISlider
// (id=SPTNowPlayingSliderV2, :216) that overrides UIControl's begin, continue and endTracking
// (objc-methods.txt:83559); a tap when it is taken, a tick at every tenth of the song it passes, a firmer one at
// either end, a soft one when it lets go.
//
// Cover swipes: the player's covers are a list of pages scrolled sideways (AccessibleCollectionView,
// :28) and so are the bar's titles (NowPlaying_BarImpl.InformationCollectionView, home/01.txt:1104);
// a tick when a drag or its fling carries the list past halfway to the next page, where letting go skips.
//
// Gestures (Shared/Gestures) tell of each action a double tap performs.
#import "Core/EeveeCore.h"
#import "Shared/Gestures/Gestures.h"
#import "Shared/Player/PlayerState.h"
#import "Haptics.h"

// How close to either end the scrubber is at it.
static const float kScrubEdge = 0.005f;
// A tenth is only passed once the scrubber is this far past it, so a finger resting on one ticks once.
static const float kScrubHysteresis = 0.004f;
// The share of a page past halfway a swipe has to reach before it ticks.
static const CGFloat kPageHysteresis = 0.02;
// The same control acting twice this quickly (a target and a UIAction, or two targets) is one tap.
static const CFTimeInterval kSameTap = 0.1;

#pragma mark - buttons

typedef NS_ENUM(NSInteger, ControlKind) {
    ControlNone,
    ControlPlay,
    ControlSkip,
    ControlToggle,
    ControlAdd,
};

static ControlKind kindOf(UIControl *control) {
    static NSDictionary<NSString *, NSNumber *> *kinds;
    if (!kinds) {
        kinds = @{
            @"SPTNowPlayingPlayButton": @(ControlPlay),
            @"SPTNowPlayingPreviousTrackButton": @(ControlSkip),
            @"SPTNowPlayingNextTrackButton": @(ControlSkip),
            @"Components.UI.ShuffleButton": @(ControlToggle),
            @"Nowplaying-RepeatButton": @(ControlToggle),
            @"Components.UI.AddToButton": @(ControlAdd),
        };
    }
    NSString *identifier = control.accessibilityIdentifier;
    NSNumber *kind = identifier.length ? kinds[identifier] : nil;
    // The play button's identifier is on the PlayButtonView around the UIButton that acts.
    if (!kind && !identifier.length) kind = kinds[control.superview.accessibilityIdentifier ?: @""];
    return (ControlKind)kind.integerValue;
}

// A touch that has not ended is a control acting on touch down or while dragged, not a tap.
static BOOL isTap(UIEvent *event) {
    NSSet<UITouch *> *touches = event.allTouches;
    if (!touches.count) return YES;
    for (UITouch *touch in touches) {
        if (touch.phase == UITouchPhaseEnded) return YES;
    }
    return NO;
}

static void controlActed(UIControl *control, ControlKind kind, BOOL wasPaused) {
    static __weak UIControl *lastControl;
    static CFTimeInterval lastTime;
    CFTimeInterval now = CACurrentMediaTime();
    if (control == lastControl && now - lastTime < kSameTap) return;
    lastControl = control;
    lastTime = now;
    switch (kind) {
        case ControlNone: return;
        case ControlPlay: EeveePlayFeedback(wasPaused ? EeveeFeedbackPlay : EeveeFeedbackPause); break;
        case ControlSkip: EeveePlayFeedback(EeveeFeedbackSkip); break;
        case ControlToggle: EeveePlayFeedback(EeveeFeedbackToggle); break;
        case ControlAdd: EeveePlayFeedback(EeveeFeedbackAdd); break;
    }
    static NSMutableSet<NSNumber *> *logged;
    if (!logged) logged = [NSMutableSet set];
    if ([logged containsObject:@(kind)]) return;
    [logged addObject:@(kind)];
    EeveeLog(@"redesign haptics: %@ (%@) acted, kind %ld", control.accessibilityIdentifier ?: control.superview.accessibilityIdentifier, NSStringFromClass(control.class), (long)kind);
}

%hook UIControl
- (void)sendAction:(SEL)action to:(id)target forEvent:(UIEvent *)event {
    ControlKind kind = kindOf(self);
    if (kind == ControlNone || !isTap(event)) {
        %orig;
        return;
    }
    BOOL wasPaused = EeveePlayerState().isPaused;
    %orig;
    controlActed(self, kind, wasPaused);
}

- (void)sendAction:(UIAction *)action {
    ControlKind kind = kindOf(self);
    if (kind == ControlNone) {
        %orig;
        return;
    }
    BOOL wasPaused = EeveePlayerState().isPaused;
    %orig;
    controlActed(self, kind, wasPaused);
}
%end

#pragma mark - scrubbing

static int eevee_scrubTenth;
static BOOL eevee_scrubAtEdge;
static NSUInteger eevee_scrubTicks;

static float positionOf(UISlider *slider) {
    float span = slider.maximumValue - slider.minimumValue;
    return span > 0 ? (slider.value - slider.minimumValue) / span : 0;
}

static BOOL atEdge(float position) {
    return position <= kScrubEdge || position >= 1 - kScrubEdge;
}

static void scrubBegan(UISlider *slider) {
    float position = positionOf(slider);
    eevee_scrubTenth = (int)floor(MIN(position, 0.9999f) * 10);
    eevee_scrubAtEdge = atEdge(position);
    eevee_scrubTicks = 0;
    EeveePlayFeedback(EeveeFeedbackGrab);
    EeveePrepareFeedback(EeveeFeedbackDetent);
}

static void scrubMoved(UISlider *slider) {
    float position = positionOf(slider);
    BOOL edge = atEdge(position);
    if (edge) {
        if (!eevee_scrubAtEdge) EeveePlayFeedback(EeveeFeedbackEdge);
        eevee_scrubAtEdge = YES;
        eevee_scrubTenth = (int)floor(MIN(position, 0.9999f) * 10);
        return;
    }
    eevee_scrubAtEdge = NO;
    int tenth = (int)floor(position * 10);
    if (tenth == eevee_scrubTenth) return;
    float boundary = (tenth > eevee_scrubTenth ? tenth : eevee_scrubTenth) / 10.0f;
    if (fabsf(position - boundary) < kScrubHysteresis) return;
    eevee_scrubTenth = tenth;
    eevee_scrubTicks++;
    EeveePlayFeedback(EeveeFeedbackDetent);
}

// Hook collision note: EeveeSpotify hooks this same class in
// Sources/EeveeSpotify/SponsorBlock/SponsorBlockHooks.x.swift (ProgressBarSliderHook), but the two
// share no selector — that one swizzles layoutSubviews to attach its overlay, this one the three
// tracking methods to fire haptics — so there is nothing to reconcile.
%hook _TtCO17NowPlaying_ECMKit11ProgressBar6Slider
- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    BOOL tracking = %orig;
    if (tracking) scrubBegan((UISlider *)self);
    return tracking;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    BOOL tracking = %orig;
    scrubMoved((UISlider *)self);
    return tracking;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    %orig;
    EeveePlayFeedback(EeveeFeedbackRelease);
    static NSUInteger logged;
    if (logged++ < 3) EeveeLog(@"redesign haptics: scrubbed to %.2f of the song, %lu ticks", positionOf((UISlider *)self), (unsigned long)eevee_scrubTicks);
}
%end

#pragma mark - cover swipes

static void pageDetent(UIScrollView *list, NSInteger *lastPage) {
    CGFloat width = list.bounds.size.width;
    if (width < 1) return;
    CGFloat position = list.contentOffset.x / width;
    NSInteger page = lround(position);
    if (!list.isTracking && !list.isDecelerating) {
        *lastPage = page;
        return;
    }
    if (page == *lastPage || fabs(position - *lastPage) < 0.5 + kPageHysteresis) return;
    *lastPage = page;
    EeveePlayFeedback(EeveeFeedbackDetent);
}

%hook _TtC35NowPlaying_ContentLayerPlatformImpl24AccessibleCollectionView
- (void)setContentOffset:(CGPoint)offset {
    %orig;
    static NSInteger lastPage;
    pageDetent((UIScrollView *)self, &lastPage);
}
%end

%hook _TtC18NowPlaying_BarImpl25InformationCollectionView
- (void)setContentOffset:(CGPoint)offset {
    %orig;
    static NSInteger lastPage;
    pageDetent((UIScrollView *)self, &lastPage);
}
%end

#pragma mark - gestures

static void gesturePerformed(EeveeGestureAction action) {
    switch (action) {
        case EeveeGestureNothing: break;
        case EeveeGesturePlayPause: EeveePlayFeedback(EeveePlayerState().isPaused ? EeveeFeedbackPlay : EeveeFeedbackPause); break;
        case EeveeGestureSeekBack:
        case EeveeGestureSeekForward:
        case EeveeGestureNextTrack:
        case EeveeGesturePreviousTrack: EeveePlayFeedback(EeveeFeedbackSkip); break;
        case EeveeGestureShuffle:
        case EeveeGestureRepeat: EeveePlayFeedback(EeveeFeedbackToggle); break;
    }
}

%ctor {
    EeveeMigrateKey(EeveeKeyControlHapticsWas, EeveeKeyControlHaptics);
    EeveeMigrateKey(EeveeKeyControlStrengthWas, EeveeKeyControlStrength);
    %init;
    EeveeGestureSetObserver(^(EeveeGestureAction action) { gesturePerformed(action); });
    EeveeRequireClasses(@[
        @"_TtCO17NowPlaying_ECMKit11ProgressBar6Slider",
        @"_TtC35NowPlaying_ContentLayerPlatformImpl24AccessibleCollectionView",
        @"_TtC18NowPlaying_BarImpl25InformationCollectionView",
    ]);
}
