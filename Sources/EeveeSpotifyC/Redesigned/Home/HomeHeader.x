// Home redesign: the header the way the Music app has it. The filter pills (All, Music, Podcasts) go and
// a large title takes their place at the leading edge; the avatar that opens the side drawer moves to the
// trailing edge; the scrim Spotify lays behind the header goes too, the soft scroll edge (Kit/EeveeREdgeEffect.x)
// being what keeps the title clear of the page scrolling under it, as on every other redesigned page.
//
// Tree (trees/clean/home/10.txt:3018-3051): FunkisViewController's view holds a 402x112 UIView around
// Reprise_LiquidGlassKit LiquidGlass.GradientView (the scrim) and, at {0, 62}, an
// ElementView<HomeHeaderElement> 402x50 holding HomeHeaderView > UIStackView {0, 8} 402x34 of two arranged
// views: ListeningActivity_ElementsKit.AdaptiveFaceContainer {16, 0} 32x34 (the avatar,
// id=Components.UI.SideDrawerButton) and LiquidGlass.LeadingFadeMaskView {48, 1} 354x32 around
// Home_PillUIKit.PillScrollView.
//
// The avatar moves by the stack's layout direction rather than by a frame of ours. Right to left, the stack
// lays its first view out at the trailing edge itself on every pass, whatever width the face container
// takes when friends listening show beside the avatar; its leading margin, 16pt, is the one Spotify gives
// the header in a right to left language. The pills stay in the stack with no alpha rather than hidden,
// the way the redesign takes any view out of a stack Spotify arranges (Kit/EeveeRRestyle.h).
//
// The title is Spotify's own name for the tab, read off its tab bar item (id=TabBar.Item.Home, 10.txt:3100),
// so it follows the app's language.
#import "Core/EeveeCore.h"
#import "Redesigned/Kit/EeveeRKit.h"
#import "Home.h"

// Tries at finding the tab's name before settling for the English one: a miss walks the window.
static const NSUInteger kTitleTries = 8;

static char kTitleKey, kTabKey;
static NSString *eevee_tabName;

static void vanish(UIView *view) {
    if (!view) return;
    if (view.alpha != 0) view.alpha = 0;
    view.userInteractionEnabled = NO;
    view.accessibilityElementsHidden = YES;
}

static UIView *childNamed(UIView *host, NSString *marker) {
    for (UIView *sub in host.subviews) {
        if ([NSStringFromClass(sub.class) containsString:marker]) return sub;
    }
    return nil;
}

static NSString *tabName(UIWindow *window) {
    if (eevee_tabName || !window) return eevee_tabName ?: @"Home";
    static NSUInteger tries;
    if (tries >= kTitleTries) return @"Home";
    tries++;
    UIView *item = EeveeRFindByIdentifier(window, @"TabBar.Item.Home", &kTabKey);
    __block NSString *name = nil;
    if (item) EeveeForEachView(item, ^(UIView *v) {
        if (!name && [v isKindOfClass:UILabel.class] && ((UILabel *)v).text.length) name = ((UILabel *)v).text;
    });
    if (!name) {
        if (tries == kTitleTries) EeveeLog(@"redesign home: the Home tab's name not found, the title stays English");
        return @"Home";
    }
    eevee_tabName = [name copy];
    EeveeLog(@"redesign home: title \"%@\" from the tab bar", eevee_tabName);
    return eevee_tabName;
}

static UILabel *titleIn(UIView *header) {
    UILabel *title = objc_getAssociatedObject(header, &kTitleKey);
    if (!title) {
        title = [UILabel new];
        title.textColor = EeveeRPrimary();
        title.accessibilityTraits = UIAccessibilityTraitHeader;
        title.adjustsFontSizeToFitWidth = YES;
        title.minimumScaleFactor = 0.6;
        title.userInteractionEnabled = NO;
        objc_setAssociatedObject(header, &kTitleKey, title, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    if (title.superview != header) [header addSubview:title];
    return title;
}

// The header's views, found once: the page lays out again as it appears, and the walk names classes.
static __weak UIView *eevee_header;
static __weak UIStackView *eevee_stack;
static __weak UIView *eevee_scrim;

static BOOL findHeader(UIView *view) {
    if (eevee_stack && [eevee_stack isDescendantOfView:view]) return YES;
    for (UIView *wrapper in view.subviews) {
        UIView *scrim = childNamed(wrapper, @"GradientView");
        if (scrim) eevee_scrim = scrim;
    }
    UIView *header = childNamed(childNamed(view, @"HomeHeaderElement"), @"HomeHeaderView");
    for (UIView *sub in header.subviews) {
        if ([sub isKindOfClass:UIStackView.class]) eevee_stack = (UIStackView *)sub;
    }
    eevee_header = header;
    if (eevee_stack) return YES;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ EeveeLog(@"redesign home: header stack not found, header left as Spotify's"); });
    return NO;
}

static void layoutHeader(UIViewController *page) {
    UIView *view = page.viewIfLoaded;
    if (!view || !findHeader(view)) return;
    UIView *header = eevee_header;
    UIStackView *stack = eevee_stack;
    vanish(eevee_scrim);

    static Class faceClass;
    if (!faceClass) faceClass = NSClassFromString(@"_TtC29ListeningActivity_ElementsKit21AdaptiveFaceContainer");
    UIView *face = nil;
    for (UIView *part in stack.arrangedSubviews) {
        if (faceClass && [part isKindOfClass:faceClass]) face = part;
        else vanish(part);
    }
    if (stack.semanticContentAttribute != UISemanticContentAttributeForceRightToLeft) {
        stack.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
        [stack setNeedsLayout];
    }
    [stack layoutIfNeeded];

    UILabel *title = titleIn(header);
    NSString *text = tabName(header.window);
    if (![title.text isEqualToString:text]) {
        title.text = text;
        title.accessibilityLabel = text;
    }
    UIFont *font = EeveeRFont(UIFontTextStyleLargeTitle, UIFontWeightBold, UIContentSizeCategoryLarge);
    if (![title.font isEqual:font]) title.font = font;

    CGFloat trailing = face ? CGRectGetMinX([stack convertRect:face.frame toView:header]) - EeveeRGrid : header.bounds.size.width - EeveeRSideMargin;
    CGFloat height = ceil(font.lineHeight);
    CGRect frame = CGRectMake(EeveeRSideMargin, round(CGRectGetMidY(stack.frame) - height / 2), MAX(0, trailing - EeveeRSideMargin), height);
    if (!CGRectEqualToRect(title.frame, frame)) title.frame = frame;

    static dispatch_once_t once;
    dispatch_once(&once, ^{
        EeveeLog(@"redesign home: header %@, avatar %@ in the stack %@, title %@, scrim %@", NSStringFromCGRect(header.frame),
              face ? NSStringFromCGRect(face.frame) : @"not found", NSStringFromCGRect(stack.frame), NSStringFromCGRect(frame),
              eevee_scrim ? @"found" : @"not found");
    });
}

%hook _TtC19Home_FunkisPageImpl20FunkisViewController
- (void)viewDidLayoutSubviews {
    %orig;
    CFTimeInterval began = EeveeRHomeProbeBegin();
    layoutHeader((UIViewController *)self);
    EeveeRHomeProbeEnd(EeveeRHomeProbeHeader, began);
}

- (void)traitCollectionDidChange:(UITraitCollection *)previous {
    %orig;
    [((UIViewController *)self).viewIfLoaded setNeedsLayout];
}
%end

%ctor {
    if (!EeveeRedesignedUI()) return;
    %init;
    EeveeRequireClasses(@[
        @"_TtC19Home_FunkisPageImpl20FunkisViewController",
        @"_TtC29ListeningActivity_ElementsKit21AdaptiveFaceContainer",
    ]);
}
