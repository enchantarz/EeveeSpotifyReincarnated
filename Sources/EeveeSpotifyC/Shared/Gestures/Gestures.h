// Double tap zones over the player's artwork: the artwork already answers a sideways swipe with the
// next track and a vertical drag with the cards below, so a double tap is what is left free.
#import <UIKit/UIKit.h>

#define EeveeKeyGestures @"EeveeSpotify.gestures"
#define EeveeKeyGestureSplit @"EeveeSpotify.gestures.split"
#define EeveeKeyGestureStep @"EeveeSpotify.gestures.step"
#define EeveeKeyGestureZones @"EeveeSpotify.gestures.zones"

typedef NS_ENUM(NSInteger, EeveeGestureAction) {
    EeveeGestureNothing = 0,
    EeveeGestureSeekBack,
    EeveeGestureSeekForward,
    EeveeGesturePlayPause,
    EeveeGestureNextTrack,
    EeveeGesturePreviousTrack,
    EeveeGestureShuffle,
    EeveeGestureRepeat,
};

NSArray<NSString *> *EeveeGestureActionNames(void);
NSArray<NSString *> *EeveeGestureSplitNames(void);
NSArray<NSNumber *> *EeveeGestureStepChoices(void);

// The split and the seek step as indices into the lists above, and what they mean.
NSInteger EeveeGestureSplit(void);
NSInteger EeveeGestureStepChoice(void);
// The split as a grid: 2x1, 3x1 or 3x3.
void EeveeGestureGrid(NSInteger *columns, NSInteger *rows);
double EeveeGestureStep(void);

// The action of every cell of the current split, row-major, one entry per cell.
NSArray<NSNumber *> *EeveeGestureZones(void);
void EeveeSetGestureZone(NSInteger cell, EeveeGestureAction action);
void EeveeResetGestureZones(void);
// Which cell of the current split holds `point`, in a view of size `size`.
NSInteger EeveeGestureCellAt(CGPoint point, CGSize size);

UIViewController *EeveeGesturesSettingsPage(void);

// Told of each action a double tap is about to perform, before the player has acted on it; one observer,
// for a look that answers the gesture (the redesign's haptics). Main thread.
void EeveeGestureSetObserver(void (^observer)(EeveeGestureAction action));

// Puts the double tap on `host`, the view the player's grid covers, while the switch is on; again on
// every layout pass of the host, so taps Spotify adds later still wait for it. Main thread.
void EeveeGestureAttach(UIView *host);
