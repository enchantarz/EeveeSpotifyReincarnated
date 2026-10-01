#import "EeveePageStyle.h"
#import "Core/EeveeCore.h"

// The system's own sizes, read at the moment of use so a page built before the reader changed their
// text size still comes out at the size they set. SwiftUI's List draws a 17pt body title over a 13pt
// footnote subtitle; the ported pages drew 13pt bold over 11pt, which is what made them read as a
// second, smaller screen inside the same menu.
UIColor *EeveeGrey(void) { return UIColor.secondaryLabelColor; }
UIFont *EeveeTitleFont(void) { return [UIFont preferredFontForTextStyle:UIFontTextStyleBody]; }
UIFont *EeveeSubtitleFont(void) { return [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote]; }

UIImageView *EeveeSymbolView(NSString *name, CGFloat size, UIImageSymbolWeight weight, CGFloat box) {
    UIImage *image = [UIImage systemImageNamed:name withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:size weight:weight]];
    UIImageView *view = [[UIImageView alloc] initWithImage:image];
    view.tintColor = UIColor.whiteColor;
    view.contentMode = UIViewContentModeCenter;
    view.frame = CGRectMake(0, 0, box, box);
    return view;
}

// A row's chevron. SwiftUI draws its own in .tertiaryLabel, 14pt semibold; this is the same glyph at
// the size the ported rows used, in the colour SwiftUI would use, so the two agree at a glance.
UIImageView *EeveeChevronView(void) {
    UIImageView *view = EeveeSymbolView(@"chevron.right", 13, UIImageSymbolWeightSemibold, 16);
    view.tintColor = UIColor.tertiaryLabelColor;
    return view;
}

// A grey note in a wrapper view, for the table header and footer.
UIView *EeveeNote(NSString *text) {
    UILabel *label = [UILabel new];
    label.text = text;
    label.font = EeveeSubtitleFont();
    label.textColor = EeveeGrey();
    label.numberOfLines = 0;
    UIView *wrapper = [UIView new];
    [wrapper addSubview:label];
    return wrapper;
}

// Header and footer views keep the height they are given, so size them to their text. Only the
// size is compared: the table moves the footer's origin itself, and reassigning on that would
// loop forever.
void EeveeFitNote(UITableView *table, UIView *wrapper, CGFloat top, CGFloat bottom) {
    UILabel *label = wrapper.subviews.firstObject;
    CGFloat inset = table.layoutMargins.left;
    CGFloat width = table.bounds.size.width - 2 * inset;
    CGFloat height = ceil([label sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)].height);
    label.frame = CGRectMake(inset, top, width, height);
    CGSize size = CGSizeMake(table.bounds.size.width, top + height + bottom);
    if (CGSizeEqualToSize(wrapper.bounds.size, size)) return;
    wrapper.frame = (CGRect){wrapper.frame.origin, size};
    if (wrapper == table.tableHeaderView) table.tableHeaderView = wrapper;
    else table.tableFooterView = wrapper;
}

static CGFloat barsHeight(UIView *view) {
    UIWindow *window = view.window;
    __block CGFloat top = window.bounds.size.height;
    EeveeForEachView(window, ^(UIView *v) {
        NSString *name = NSStringFromClass(v.class);
        BOOL bar = [name containsString:@"NowPlaying_BarPageImpl"] || [name isEqualToString:@"_TtC23NavigationUI_TabBarImpl10TabBarView"];
        if (!bar || v.hidden || v.alpha == 0 || v.bounds.size.height == 0) return;
        top = MIN(top, EeveeFrameIn(v, window).origin.y);
    });
    return window.bounds.size.height - top;
}

// The now playing bar and the tab bar float over the content, and the safe area does not cover
// them, so the pages inset themselves by however much of the window the bars take.
void EeveeInsetForBars(UITableView *table) {
    CGFloat bottom = MAX(0, barsHeight(table) - table.safeAreaInsets.bottom);
    if (table.contentInset.bottom == bottom) return;
    UIEdgeInsets inset = table.contentInset;
    inset.bottom = bottom;
    table.contentInset = inset;
    table.verticalScrollIndicatorInsets = inset;
}

// The pages follow Spotify's own background and accent colour, read here by their keys so the page
// framework depends on no layer: Native/Appearance's AMOLED switch and accent picker write them.
static NSString *const kAccentKey = @"EeveeSpotify.accent";

static UIColor *lookAccent(void) {
    NSInteger rgb = EeveeInt(kAccentKey, -1);
    if (rgb < 0 || rgb > 0xFFFFFF) return nil;
    return [UIColor colorWithRed:((rgb >> 16) & 0xFF) / 255.0 green:((rgb >> 8) & 0xFF) / 255.0 blue:(rgb & 0xFF) / 255.0 alpha:1];
}

// The accent the switches are tinted with, which with nothing picked is 0x1ED760 — the colour
// EeveeSpotify's own SwiftUI rows are tinted with — so a switch here and a Toggle there match.
UIColor *EeveeGreen(void) { return lookAccent() ?: [UIColor colorWithRed:0x1E / 255.0 green:0xD7 / 255.0 blue:0x60 / 255.0 alpha:1]; }
UIColor *EeveeRed(void) { return [UIColor colorWithRed:0xF1 / 255.0 green:0x5E / 255.0 blue:0x6B / 255.0 alpha:1]; }
// Spotify's own dark page, which is what a SwiftUI List sits on in this app. AMOLED is EeveeSpotify's
// own theme now (AmoledTheme.x.swift), which blacks these surfaces out itself.
UIColor *EeveePageBackground(void) { return [UIColor colorWithWhite:0x12 / 255.0 alpha:1]; }
// The card SwiftUI's grouped List puts a section in, rather than a guess at it: the old 0x2A was
// lighter than anything iOS draws, so a ported card stood out from an EeveeSpotify one above it.
UIColor *EeveeCardBackground(void) { return UIColor.secondarySystemGroupedBackgroundColor; }

UIImage *EeveeTileImage(NSString *symbol) {
    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:14 weight:UIImageSymbolWeightMedium];
    UIImage *glyph = [[UIImage systemImageNamed:symbol withConfiguration:config] imageWithTintColor:UIColor.whiteColor renderingMode:UIImageRenderingModeAlwaysOriginal];
    CGRect box = CGRectMake(0, 0, 28, 28);
    UIImage *tile = [[[UIGraphicsImageRenderer alloc] initWithSize:box.size] imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
        [[UIColor colorWithWhite:1 alpha:0.12] setFill];
        [[UIBezierPath bezierPathWithRoundedRect:box cornerRadius:7] fill];
        CGSize size = glyph.size;
        [glyph drawInRect:CGRectMake((box.size.width - size.width) / 2, (box.size.height - size.height) / 2, size.width, size.height)];
    }];
    return [tile imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

// iOS's own inset-grouped header metrics, which is what SwiftUI's grouped List draws on an iPhone:
// 32pt tall with the label 16pt down from the card above it.
const CGFloat EeveeSectionHeaderHeight = 32;
const CGFloat EeveeSectionGap = 20;

// Every page below draws the list row SwiftUI draws: a 17pt .label title over a 13pt .secondaryLabel
// subtitle, with an optional symbol in the leading slot.
void EeveeFillCell(UITableViewCell *cell, NSString *title, NSString *subtitle, UIColor *color, NSString *symbolName) {
    UIListContentConfiguration *content = [UIListContentConfiguration subtitleCellConfiguration];
    content.text = title;
    content.secondaryText = subtitle;
    content.textProperties.font = EeveeTitleFont();
    content.textProperties.color = color ?: UIColor.labelColor;
    content.secondaryTextProperties.font = EeveeSubtitleFont();
    content.secondaryTextProperties.color = EeveeGrey();
    content.textToSecondaryTextVerticalPadding = 2;
    content.directionalLayoutMargins = NSDirectionalEdgeInsetsMake(10, 16, 10, 16);
    if (symbolName) {
        content.image = [UIImage systemImageNamed:symbolName withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:15 weight:UIImageSymbolWeightRegular]];
        content.imageProperties.tintColor = color ?: UIColor.labelColor;
        content.imageToTextPadding = 14;
    }
    cell.contentConfiguration = content;
    cell.backgroundColor = EeveeCardBackground();
    cell.accessoryView = nil;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
}

// As written, not uppercased: SwiftUI's Section(header:) shows the title it is given, and every
// EeveeSpotify page writes its headers in sentence case. Uppercasing here was the loudest difference
// between a ported page and EeveeSpotify's own — "APPEARANCE" over "UI & Liquid Glass Adjustments".
UIView *EeveeSectionHeader(UITableView *table, NSString *title) {
    UILabel *label = [UILabel new];
    label.text = title;
    label.font = EeveeSubtitleFont();
    label.textColor = EeveeGrey();
    label.frame = CGRectMake(16, 14, table.bounds.size.width - 32, 16);
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, table.bounds.size.width, EeveeSectionHeaderHeight)];
    [header addSubview:label];
    return header;
}

static const CGFloat kFooterTop = 8, kFooterBottom = 4;

static CGFloat footerTextHeight(UITableView *table, NSString *text) {
    CGFloat width = MAX(table.bounds.size.width - 32, 100);
    return ceil([text boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX)
                                   options:NSStringDrawingUsesLineFragmentOrigin
                                attributes:@{NSFontAttributeName: EeveeSubtitleFont()}
                                   context:nil].size.height);
}

UIView *EeveeSectionFooter(UITableView *table, NSString *text) {
    UILabel *label = [UILabel new];
    label.text = text;
    label.font = EeveeSubtitleFont();
    label.textColor = EeveeGrey();
    label.numberOfLines = 0;
    label.frame = CGRectMake(16, kFooterTop, table.bounds.size.width - 32, footerTextHeight(table, text));
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, table.bounds.size.width, EeveeSectionFooterHeight(table, text))];
    [footer addSubview:label];
    return footer;
}

CGFloat EeveeSectionFooterHeight(UITableView *table, NSString *text) {
    return kFooterTop + footerTextHeight(table, text) + kFooterBottom;
}

UITableViewCell *EeveeDequeueCell(UITableView *table, NSString *identifier) {
    return [table dequeueReusableCellWithIdentifier:identifier]
        ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
}

UIViewController *EeveeTopController(void) {
    UIViewController *top = nil;
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class]) continue;
        for (UIWindow *window in ((UIWindowScene *)scene).windows) {
            if (window.hidden) continue;
            if (!top || window.isKeyWindow) top = window.rootViewController;
        }
    }
    while (top.presentedViewController) top = top.presentedViewController;
    return top;
}

NSString *const EeveeSiteURL = @"https://EeveeSpotify";
NSString *const EeveeRepoURL = @"https://github.com/skopevoj/EeveeSpotify";

void EeveeOpenURL(NSString *url) {
    NSURL *target = url ? [NSURL URLWithString:url] : nil;
    if (!target) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication.sharedApplication openURL:target options:@{} completionHandler:nil];
    });
}
