// Flags: Spotify's remote-config flags. Flags.x forces an override into the configuration
// provider; EeveeFlagList.m is the table of every flag, generated from the IPA by
// scripts/extract-flags.py; FlagsPage.m is the searchable All flags page and FlagPages.m the Labs
// page. Flags that change a part of the app sit on that part's own page.
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, EeveeFlagType) { EeveeFlagUnknown, EeveeFlagBool, EeveeFlagInt, EeveeFlagEnum };
typedef struct { const char *key; EeveeFlagType type; long value, lower, upper; } EeveeFlagDef;
extern const EeveeFlagDef EeveeFlagTable[];
extern const NSUInteger EeveeFlagCount;

UIViewController *EeveeAllFlagsPage(void);
UIViewController *EeveeLabsPage(void);
