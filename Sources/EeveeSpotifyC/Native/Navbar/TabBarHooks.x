// What drives the native look's navbar: Spotify's tab bar composed on its layout passes (Navbar.x), and
// holding Home opens Mod Settings.
//
// Tree (trees/home.txt): NavigationUI_TabBarImpl.TabBarView > TabBarCompactView > UIStackView of
//   ElementContentView<TabBarItemElement>, each with an SPTEncoreIconView and an SPTEncoreLabel.
#import "Core/EeveeCore.h"
#import "Navbar.h"
// spoti.pw opened its own Mod Settings page off a hold on Home; the merge routes everything through
// EeveeSpotify's settings menu instead, so EeveeHomeHold no longer pushes a page.
#import "Settings/EeveePage.h"

@interface EeveeHomeHold : UILongPressGestureRecognizer
@end

@implementation EeveeHomeHold
+ (void)held:(EeveeHomeHold *)hold {
    (void)hold;
}
@end

// On Spotify's own bar a hold that begins fails the item's tap recognizer, so Home is not tapped too.
static void holdHome(UIView *stockBar) {
    UIView *home = EeveeRowIn(stockBar).arrangedSubviews.firstObject;
    if (!home) return;
    for (UIGestureRecognizer *recognizer in home.gestureRecognizers) {
        if ([recognizer isKindOfClass:EeveeHomeHold.class]) return;
    }
    [home addGestureRecognizer:[[EeveeHomeHold alloc] initWithTarget:EeveeHomeHold.class action:@selector(held:)]];
}

static UIView *tabBarOf(UIView *item) {
    Class barClass = NSClassFromString(@"_TtC23NavigationUI_TabBarImpl10TabBarView");
    for (UIView *v = item.superview; v; v = v.superview) if ([v isKindOfClass:barClass]) return v;
    return nil;
}

%hook _TtC23NavigationUI_TabBarImpl10TabBarView
- (void)layoutSubviews {
    %orig;
    EeveeComposeTabBar((UIView *)self);
    holdHome((UIView *)self);
    EeveeLogTabBarRow((UIView *)self);
}
%end

// The bar's own pass runs before Spotify has filled the row; the items lay out as they arrive.
static void itemDidLayOut(UIView *item) {
    UIView *bar = tabBarOf(item);
    if (!bar) return;
    EeveeComposeTabBar(bar);
    holdHome(bar);
    EeveeLogTabBarRow(bar);
}

%hook _TtC23NavigationUI_TabBarImpl21TabBarItemElementView
- (void)layoutSubviews {
    %orig;
    itemDidLayOut((UIView *)self);
}
%end

%hook _TtC25CreateMenu_TabBarItemImpl24CreateMenuTabBarItemView
- (void)layoutSubviews {
    %orig;
    itemDidLayOut((UIView *)self);
}
%end

%ctor {
    if (!EeveeNativeUI()) return;
    %init;
    EeveeRequireClasses(@[
        @"_TtC23NavigationUI_TabBarImpl10TabBarView",
        @"_TtC23NavigationUI_TabBarImpl21TabBarItemElementView",
        @"_TtC25CreateMenu_TabBarItemImpl24CreateMenuTabBarItemView",
    ]);
}
