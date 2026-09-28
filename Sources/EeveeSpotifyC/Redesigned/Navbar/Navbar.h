// The redesign's navbar: the glass tab bar (TabBar.x) over Spotify's own, composed from its own list
// (Navbar.x, NavbarLayout.m), which the redesign keeps apart from the native look's: an ordered list of
// entries, each a dictionary. An entry with a URI is a tab of the mod's own; one without names
// one of Spotify's, by the label under its icon. No list at all is Spotify's order, all shown.
#import <UIKit/UIKit.h>

#define EeveeRKeyNavbar @"EeveeSpotify.redesign.navbar"
// Icons only on the glass bar. Off unless set; applies as soon as the bar lays out again.
#define EeveeRKeyNavbarHideLabels @"EeveeSpotify.redesign.navbar.hideLabels"

extern NSString *const EeveeRNavbarID;      // NSString, the entry's identity
extern NSString *const EeveeRNavbarTitle;   // NSString, the name in the settings list and under the icon
extern NSString *const EeveeRNavbarURI;     // NSString, the mod's own tabs only: what a tap opens
extern NSString *const EeveeRNavbarIcon;    // NSString, an SPTEncoreIcon class method such as "podcasts"
extern NSString *const EeveeRNavbarHidden;  // NSNumber
NSArray<NSDictionary *> *EeveeRNavbarLayout(void);
void EeveeRSetNavbarLayout(NSArray<NSDictionary *> *layout);
// Spotify's own tabs in Spotify's order, as Navbar.x last saw them on the bar.
NSArray<NSString *> *EeveeRNavbarStock(void);
void EeveeRSetNavbarStock(NSArray<NSString *> *stock);
// What a tab of the mod's own opens: its URI as typed or pasted, share links made spotify: URIs, and
// the URIs of presets that never opened (spotify:collection:playlists, up to 0.20) moved to the ones
// that replaced them, so a tab saved back then works without being added again.
NSURL *EeveeRNavbarTabURL(NSString *uri);

// Navbar.x, called from the tab bar's layout passes in TabBar.x.
void EeveeRComposeTabBar(UIView *tabBar);
void EeveeRLogTabBarRow(UIView *tabBar);
// Lays the bar out again after the Navbar page changes something, so it does not wait for a touch.
void EeveeRRefreshTabBar(void);

UIViewController *EeveeRNavbarSettingsPage(void);   // the tab editor, in Mod Settings
UIViewController *EeveeRNavbarEditorPage(void);     // the tab editor alone, for the welcome tour
