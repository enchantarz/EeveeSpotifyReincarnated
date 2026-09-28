// Home: the gradient behind the top of the page (HomeGradient.x), off until it is asked for, and
// the settings that shape it (HomeGradientChoices.m, the Gradient page in HomeSettings.m).
#import <UIKit/UIKit.h>

#define EeveeKeyHomeGradient @"EeveeSpotify.homeGradient"

// Parts of Home to hide, one switch each (HomeDeclutter.x). An unset switch is off.
#define EeveeHideHomeShortcuts @"EeveeSpotify.hide.homeShortcuts"
#define EeveeHideHomePills @"EeveeSpotify.hide.homePills"
#define EeveeHideHomePromo @"EeveeSpotify.hide.homePromo"
#define EeveeHideHomePreviews @"EeveeSpotify.hide.homePreviews"
#define EeveeHideHomeDJ @"EeveeSpotify.hide.homeDJ"

// Every setting the gradient is shaped by. One entry per setting in HomeGradientChoices.m holds the
// names the Gradient page offers, the key it is stored under and the one it falls back to, so a
// name and what it does cannot drift apart.
typedef NS_ENUM(NSInteger, EeveeHomeChoice) {
    EeveeHomeChoiceTint,       // which colour it fades
    EeveeHomeChoiceStrength,   // how far up or down that colour is taken
    EeveeHomeChoiceHeight,     // how far down the page it reaches
    EeveeHomeChoiceCount,
};

NSArray<NSString *> *EeveeHomeChoiceNames(EeveeHomeChoice choice);
NSString *EeveeHomeChoiceKey(EeveeHomeChoice choice);
NSInteger EeveeHomeChoiceDefault(EeveeHomeChoice choice);
// The index set for `choice`: its own default while nothing is set, or while what is set is a name
// this build no longer offers.
NSInteger EeveeHomeChoiceValue(EeveeHomeChoice choice);

UIViewController *EeveeHomeSettingsPage(void);
UIViewController *EeveeHomeGradientPage(void);
