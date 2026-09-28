// Spotify's own list look, for every page of the mod's: a 13pt white title over an 11pt grey
// subtitle on #121212, 38pt uppercase section headers, green switches.
#import <UIKit/UIKit.h>

UIColor *EeveeGrey(void);
UIColor *EeveeGreen(void);
UIColor *EeveeRed(void);
UIColor *EeveePageBackground(void);
UIColor *EeveeCardBackground(void);
UIFont *EeveeTitleFont(void);
UIFont *EeveeSubtitleFont(void);
// Takes the 13pt and 11pt fonts off Spotify's own settings list, once, so the pages match it.
void EeveeAdoptFonts(UIView *list, UIView *exclude);

UIImageView *EeveeSymbolView(NSString *name, CGFloat size, UIImageSymbolWeight weight, CGFloat box);
// A symbol on a rounded grey square, the leading icon of a row that opens a page.
UIImage *EeveeTileImage(NSString *symbol);
// A grey note in a wrapper view, for a table header or footer; EeveeFitNote sizes it to its text.
UIView *EeveeNote(NSString *text);
void EeveeFitNote(UITableView *table, UIView *wrapper, CGFloat top, CGFloat bottom);
// The now playing bar and the tab bar float over the content, so a page insets itself under them.
void EeveeInsetForBars(UITableView *table);

extern const CGFloat EeveeSectionHeaderHeight;
extern const CGFloat EeveeSectionGap;   // above a section with no header, so its card does not touch the one before
void EeveeFillCell(UITableViewCell *cell, NSString *title, NSString *subtitle, UIColor *color, NSString *symbolName);
UIView *EeveeSectionHeader(UITableView *table, NSString *title);
UIView *EeveeSectionFooter(UITableView *table, NSString *text);
CGFloat EeveeSectionFooterHeight(UITableView *table, NSString *text);
UITableViewCell *EeveeDequeueCell(UITableView *table, NSString *identifier);

void EeveeOpenURL(NSString *url);
extern NSString *const EeveeSiteURL;
extern NSString *const EeveeRepoURL;
// The controller on top of the key window, through whatever is presented over it.
UIViewController *EeveeTopController(void);
