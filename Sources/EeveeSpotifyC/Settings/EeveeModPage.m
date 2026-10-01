#import "EeveeModPage.h"
#import "EeveePageStyle.h"
#import "Core/EeveeCore.h"

NSString *const EeveeRestartNote = @"Changes apply after you restart Spotify.";
NSString *const EeveeSpotipwRowSuffix = @" (from spoti.pw)";

@implementation EeveeModRow
@end

@implementation EeveeModSection
@end

EeveeModRow *EeveeSwitchRow(NSString *title, NSString *subtitle, NSString *key) {
    EeveeModRow *row = [EeveeModRow new];
    row.title = title;
    row.subtitle = subtitle;
    row.key = key;
    row.defaultOn = YES;
    return row;
}

EeveeModRow *EeveeHideRow(NSString *title, NSString *subtitle, NSString *key) {
    EeveeModRow *row = EeveeSwitchRow(title, subtitle, key);
    row.defaultOn = NO;
    return row;
}

// A switch for something the mod adds rather than takes away: off until it is asked for.
EeveeModRow *EeveeOptionRow(NSString *title, NSString *subtitle, NSString *key) {
    EeveeModRow *row = EeveeSwitchRow(title, subtitle, key);
    row.defaultOn = NO;
    return row;
}

EeveeModRow *EeveeFlagRow(NSString *title, NSString *key) {
    EeveeModRow *row = EeveeHideRow(title, nil, key);
    row.flag = YES;
    return row;
}

// A flag Spotify ships on: the switch forces it off.
EeveeModRow *EeveeKillRow(NSString *title, NSString *key) {
    EeveeModRow *row = EeveeFlagRow(title, key);
    row.forceOff = YES;
    return row;
}

EeveeModRow *EeveeStatRow(NSString *title, NSString *(^value)(void)) {
    EeveeModRow *row = [EeveeModRow new];
    row.title = title;
    row.value = value;
    return row;
}

EeveeModRow *EeveeActionRow(NSString *title, NSString *subtitle, void (^action)(void)) {
    EeveeModRow *row = [EeveeModRow new];
    row.title = title;
    row.subtitle = subtitle;
    row.action = action;
    return row;
}

// Red, with a warning symbol: something is wrong and tapping the row says what to do about it.
// No subtitle: a list of pages reads as a list, not as a wall of explanations.
EeveeModRow *EeveePageRow(NSString *title, UIViewController *(^page)(void)) {
    EeveeModRow *row = [EeveeModRow new];
    row.title = title;
    row.page = page;
    return row;
}

// No key on the row: the key lives in the blocks, so the page draws the row as the link it is
// rather than as a switch. The renderer draws the list from the names kept on the row.
EeveeModRow *EeveeChoiceRow(NSString *title, NSString *subtitle, NSString *key, NSArray<NSString *> *choices, NSInteger fallback) {
    EeveeModRow *row = [EeveeModRow new];
    row.title = title;
    row.subtitle = subtitle;
    row.choiceNames = choices;
    row.choiceKey = key;
    row.choiceFallback = fallback;
    row.value = ^NSString *{
        NSInteger index = EeveeInt(key, fallback);
        return index >= 0 && index < (NSInteger)choices.count ? choices[(NSUInteger)index] : choices.firstObject;
    };
    return row;
}

EeveeModRow *EeveeSliderRow(NSString *title, NSString *subtitle, double minimum, double maximum, double step,
                      double (^get)(void), void (^set)(double value), NSString *(^format)(double value)) {
    EeveeModRow *row = [EeveeModRow new];
    row.title = title;
    row.subtitle = subtitle;
    row.minimum = minimum;
    row.maximum = maximum;
    row.step = step;
    row.number = get;
    row.setNumber = set;
    row.format = format;
    return row;
}

EeveeModRow *EeveeLinkRow(NSString *title, NSString *subtitle, NSString *url) {
    return EeveeActionRow(title, subtitle, ^{ EeveeOpenURL(url); });
}

// A value on the right and a tap: the Updates row reads its status out of About/Update.m every tick,
// and a tap asks the site again instead of waiting for the six hour cache to lapse.
EeveeModRow *EeveeStatActionRow(NSString *title, NSString *subtitle, NSString *(^value)(void), void (^action)(void)) {
    EeveeModRow *row = [EeveeModRow new];
    row.title = title;
    row.subtitle = subtitle;
    row.value = value;
    row.action = action;
    return row;
}

EeveeModSection *EeveeSection(NSString *title, NSArray<EeveeModRow *> *rows) {
    EeveeModSection *s = [EeveeModSection new];
    s.title = title;
    s.rows = rows;
    return s;
}

EeveeModSection *EeveeNotedSection(NSString *title, NSArray<EeveeModRow *> *rows, NSString *footer) {
    EeveeModSection *s = EeveeSection(title, rows);
    s.footer = footer;
    return s;
}

EeveeModRow *EeveeWithSymbol(EeveeModRow *row, NSString *symbol) {
    row.symbol = symbol;
    return row;
}

#pragma mark - the page

// The page as data, drawn by EeveeModPageView.swift: the row model above is all a renderer needs, so
// this is a container rather than the UITableView it used to be. The rows carry what a switch, a link,
// a slider or a choice needs; nothing here draws.
@implementation EeveeModPage {
    NSArray<EeveeModSection *> *_sections;
}

- (instancetype)initWithTitle:(NSString *)title intro:(NSString *)intro sections:(NSArray<EeveeModSection *> *)sections footer:(NSString *)footer {
    if (!(self = [super initWithStyle:UITableViewStyleInsetGrouped])) return nil;
    self.title = title;
    _titleText = [title copy];
    _introText = [intro copy];
    _footerText = [footer copy];
    _sections = sections;
    return self;
}

@end
