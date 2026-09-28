// The base of every page of the mod's, pushable onto Spotify's own navigation stack.
#import <UIKit/UIKit.h>

@interface EeveePage : UITableViewController
@end

// Registers EeveePage as one of Spotify's pages; called once from the ported %ctor.
void EeveeRegisterPages(void);
// Pushes the page if it can go on Spotify's stack, presents it otherwise.
void EeveeShowPage(UIViewController *owner, UIViewController *page);
// The ported settings page, which EeveeSpotify's own menu pushes (App/ModSettings.x).
UIViewController *EeveeSpotipwSettingsPage(void);
