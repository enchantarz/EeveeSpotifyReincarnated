// The list look every page of the mod's draws: the one SwiftUI's own List draws, so a page built by
// hand and a page built in SwiftUI read as the same screen. The sizes, the colours and the section
// metrics come from the system (a 17pt body title over a 13pt footnote subtitle, .label and
// .secondaryLabel, secondarySystemGroupedBackground cards) rather than from numbers picked to match
// Spotify's own 13pt list, and they follow the reader's text size.
//
// Settings/EeveeModPage.h's pages no longer come through here at all: they are drawn by
// Sources/EeveeSpotify/Settings/Sections/Spotipw/Views/EeveeModPageView.swift, in SwiftUI. What is
// left are the pages with controls SwiftUI has no shape for — the Navbar editor, All flags, the
// Audio effects curve editors.
#import <UIKit/UIKit.h>

UIColor *EeveeGrey(void);
UIColor *EeveeGreen(void);
UIColor *EeveeRed(void);
UIColor *EeveePageBackground(void);
UIColor *EeveeCardBackground(void);
UIFont *EeveeTitleFont(void);
UIFont *EeveeSubtitleFont(void);

UIImageView *EeveeSymbolView(NSString *name, CGFloat size, UIImageSymbolWeight weight, CGFloat box);
// The grey chevron a row that opens a page carries on the right, the one SwiftUI's own rows have.
UIImageView *EeveeChevronView(void);
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
