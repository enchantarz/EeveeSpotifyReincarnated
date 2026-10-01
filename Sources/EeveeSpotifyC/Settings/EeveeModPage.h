// A page of sections of rows, the shape of every feature's settings page.
#import "EeveePage.h"

// A row is a switch when it has a key, a link to another page when it has a page and a slider when it has
// a number. A flag row
// switches one of Spotify's remote-config flags: on forces it (off for a forceOff row, which is how
// a flag Spotify ships on is turned off), the switch off leaves Spotify's own value. A row
// with a value reads one out on the right and is asked again while the page is open; a page row
// with a value reads it out too, next to the chevron, and is asked when the page appears. A row
// with an action runs it when tapped.
@interface EeveeModRow : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, copy) NSString *key;
@property (nonatomic) BOOL defaultOn;
@property (nonatomic) BOOL flag;
@property (nonatomic) BOOL forceOff;
@property (nonatomic, copy) UIViewController *(^page)(void);
@property (nonatomic, copy) NSString *(^value)(void);
@property (nonatomic, copy) void (^action)(void);
@property (nonatomic, copy) void (^changed)(BOOL on);   // after the switch is stored; the page reloads
@property (nonatomic, strong) UIColor *color;   // title, subtitle and symbol, for a warning row
@property (nonatomic, copy) NSString *symbol;
// An ⓘ button beside the row's switch, whose tap reads this out under the row's title.
@property (nonatomic, copy) NSString *info;
// The row shows only while this answers YES, asked again whenever a switch on the page is flipped or the
// page comes back from a choice's list: the row fades in or out where it sits. Nil shows it always.
@property (nonatomic, copy) BOOL (^visible)(void);
// A choice row's: a line under each name in its list, in the same order, and what runs once one is stored.
@property (nonatomic, copy) NSArray<NSString *> *choiceNotes;
@property (nonatomic, copy) NSString *choiceFooter;   // under a choice row's list
@property (nonatomic, copy) void (^chosen)(NSInteger index);
// The list itself, and where the picked index is kept: the same three `EeveeChoiceRow` was given.
// The renderer (the SwiftUI one) draws the list from these names, so a choice row carries no `page`.
@property (nonatomic, copy) NSArray<NSString *> *choiceNames;
@property (nonatomic, copy) NSString *choiceKey;
@property (nonatomic) NSInteger choiceFallback;
// A slider row's (EeveeSliderRow): its range and step, and the blocks that read its number, store one and
// write one out.
@property (nonatomic) double minimum, maximum, step;
@property (nonatomic, copy) double (^number)(void);
@property (nonatomic, copy) void (^setNumber)(double value);
@property (nonatomic, copy) NSString *(^format)(double value);
@end

@interface EeveeModSection : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSArray<EeveeModRow *> *rows;
@property (nonatomic, copy) NSString *footer;
@end

@interface EeveeModPage : EeveePage
- (instancetype)initWithTitle:(NSString *)title intro:(NSString *)intro sections:(NSArray<EeveeModSection *> *)sections footer:(NSString *)footer;

// What the page was built with. A page is data — a title, the note it opens with, sections, the note
// under them — and these are that data, so the page can be drawn by something other than the table it
// was written to be a subclass of: the SwiftUI renderer reads these
// (Sources/EeveeSpotify/Settings/Sections/Spotipw/Views/EeveeModPageView.swift) rather than hosting
// the table, which is what the ported pages used to be.
@property (nonatomic, readonly, copy) NSString *titleText;
@property (nonatomic, readonly, copy) NSString *introText;
@property (nonatomic, readonly, copy) NSString *footerText;
@property (nonatomic, readonly, copy) NSArray<EeveeModSection *> *sections;
@end

// The intro of every page whose switches the hooks read at launch.
extern NSString *const EeveeRestartNote;

// Appended to the title of every preference row on these pages so it is obvious, while the merge
// settles, which options came over from spoti.pw and which are EeveeSpotify's own. A preference row
// is one with a key (a switch, a flag or a choice) or a number (a slider); page rows, readouts and
// plain actions keep their titles. Temporary: delete this, the use in EeveeModPage.m and the use in
// Sources/EeveeSpotify/Settings/Sections/Spotipw/Views/EeveeModPageView.swift once the ported options
// no longer need telling apart.

extern NSString *const EeveeSpotipwRowSuffix;

EeveeModRow *EeveeSwitchRow(NSString *title, NSString *subtitle, NSString *key);   // on until switched off
EeveeModRow *EeveeHideRow(NSString *title, NSString *subtitle, NSString *key);     // off until switched on
// A switch for something the mod adds rather than takes away: off until it is asked for.
EeveeModRow *EeveeOptionRow(NSString *title, NSString *subtitle, NSString *key);
EeveeModRow *EeveeFlagRow(NSString *title, NSString *key);   // forces one of Spotify's flags on
EeveeModRow *EeveeKillRow(NSString *title, NSString *key);   // forces a flag Spotify ships on off
EeveeModRow *EeveeStatRow(NSString *title, NSString *(^value)(void));
EeveeModRow *EeveeActionRow(NSString *title, NSString *subtitle, void (^action)(void));
EeveeModRow *EeveePageRow(NSString *title, UIViewController *(^page)(void));
// A setting picked from a list of names, stored under `key` as the index into it: the row reads the
// name of the current one out and opens a list of them, a checkmark against that one.
EeveeModRow *EeveeChoiceRow(NSString *title, NSString *subtitle, NSString *key, NSArray<NSString *> *choices, NSInteger fallback);
// A number on a slider under the row's title, written out by `format` on the right: the thumb snaps to
// `step` and each step is stored through `set` as the thumb reaches it, so a setting applying as it
// changes applies while it is dragged. `subtitle` may be nil.
EeveeModRow *EeveeSliderRow(NSString *title, NSString *subtitle, double minimum, double maximum, double step,
                      double (^get)(void), void (^set)(double value), NSString *(^format)(double value));
EeveeModRow *EeveeLinkRow(NSString *title, NSString *subtitle, NSString *url);
EeveeModRow *EeveeStatActionRow(NSString *title, NSString *subtitle, NSString *(^value)(void), void (^action)(void));
EeveeModSection *EeveeSection(NSString *title, NSArray<EeveeModRow *> *rows);
EeveeModSection *EeveeNotedSection(NSString *title, NSArray<EeveeModRow *> *rows, NSString *footer);
// Gives a row its leading symbol, drawn on a tile unless the row has a colour of its own.
EeveeModRow *EeveeWithSymbol(EeveeModRow *row, NSString *symbol);
