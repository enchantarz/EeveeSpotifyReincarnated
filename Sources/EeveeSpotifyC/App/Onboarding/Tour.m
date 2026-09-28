#import "Core/EeveeCore.h"
#import "Settings/EeveePageStyle.h"
#import "Onboarding.h"
#import "App/About/About.h"
#import "App/Pages.h"

static const CGFloat kMargin = 24;

#pragma mark - glass

// A view whose glass pane follows its bounds; the panes in EeveeGlass.m are laid out by their hosts.
@interface EeveeGlassView : UIView
@property (nonatomic) CGFloat radius;
@property (nonatomic) BOOL capsule;
@end

@implementation EeveeGlassView
static char kPaneKey;
- (void)layoutSubviews {
    [super layoutSubviews];
    UIVisualEffectView *pane = EeveeGlassFor(self, &kPaneKey);
    pane.frame = self.bounds;
    EeveeShapeGlass(pane, self.radius, self.capsule);
}
@end

static UIButton *glassButton(NSString *title) {
    UIButtonConfiguration *config;
    if (@available(iOS 26.0, *)) config = [UIButtonConfiguration prominentGlassButtonConfiguration];
    else config = [UIButtonConfiguration filledButtonConfiguration];
    config.cornerStyle = UIButtonConfigurationCornerStyleCapsule;
    config.baseBackgroundColor = EeveeGreen();
    config.baseForegroundColor = UIColor.blackColor;
    config.contentInsets = NSDirectionalEdgeInsetsMake(15, 20, 15, 20);
    config.attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold]}];
    UIButton *button = [UIButton buttonWithConfiguration:config primaryAction:nil];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    return button;
}

#pragma mark - the tour

// One page: what the mod is, and the button out of it. spoti.pw asked which look to draw here; this
// build draws one, so there is nothing to choose and everything else waits in Mod Settings.
@interface EeveeOnboardingController : UIViewController
@end

@implementation EeveeOnboardingController {
    UIImageView *_hero;
    UIView *_beta;
    UIButton *_primary;
}

- (instancetype)init {
    if (!(self = [super initWithNibName:nil bundle:nil])) return nil;
    self.modalPresentationStyle = UIModalPresentationOverFullScreen;
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    return self;
}

// Under the heading: this build carries two projects' hooks, so a bug report is the way to help.
- (UIView *)betaNote {
    UIImageView *icon = EeveeSymbolView(@"exclamationmark.triangle.fill", 15, UIImageSymbolWeightSemibold, 22);
    icon.tintColor = UIColor.systemYellowColor;
    UILabel *text = [UILabel new];
    text.text = @"This build carries EeveeSpotify and spoti.pw's features in one tweak. Expect the odd rough edge, and if you find one, please report it.";
    text.font = [UIFont systemFontOfSize:13];
    text.textColor = EeveeGrey();
    text.numberOfLines = 0;
    [text setContentHuggingPriority:UILayoutPriorityDefaultLow - 1 forAxis:UILayoutConstraintAxisHorizontal];
    UIStackView *line = [[UIStackView alloc] initWithArrangedSubviews:@[icon, text]];
    line.alignment = UIStackViewAlignmentTop;
    line.spacing = 10;

    UIButtonConfiguration *config = [UIButtonConfiguration plainButtonConfiguration];
    config.contentInsets = NSDirectionalEdgeInsetsMake(4, 32, 4, 0);
    config.baseForegroundColor = EeveeGreen();
    config.attributedTitle = [[NSAttributedString alloc] initWithString:@"Report a bug" attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold]}];
    UIButton *report = [UIButton buttonWithConfiguration:config primaryAction:[UIAction actionWithHandler:^(UIAction *action) {
        EeveeOpenURL([EeveeRepoURL stringByAppendingString:@"/issues"]);
    }]];
    report.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeading;

    UIStackView *note = [[UIStackView alloc] initWithArrangedSubviews:@[line, report]];
    note.axis = UILayoutConstraintAxisVertical;
    note.alignment = UIStackViewAlignmentLeading;
    note.spacing = 2;
    note.layoutMargins = UIEdgeInsetsMake(4, 4, 0, 4);
    note.layoutMarginsRelativeArrangement = YES;
    return note;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.85];

    EeveeGlassView *halo = [EeveeGlassView new];
    halo.capsule = YES;
    halo.translatesAutoresizingMaskIntoConstraints = NO;
    _hero = EeveeSymbolView(@"music.note", 34, UIImageSymbolWeightMedium, 88);
    _hero.translatesAutoresizingMaskIntoConstraints = NO;
    [halo addSubview:_hero];
    // The column stretches its children to its width; the halo keeps its square inside a strip.
    UIView *strip = [UIView new];
    [strip addSubview:halo];

    UILabel *heading = [UILabel new];
    heading.text = @"Welcome.";
    heading.font = [UIFont systemFontOfSize:30 weight:UIFontWeightBold];
    heading.textColor = UIColor.whiteColor;
    heading.numberOfLines = 0;

    // spoti.pw offered its two looks here and let the tour pick one. The merge dropped the redesign
    // and the choice with it (Core/EeveeUIMode.h), so the page says what the mod is and leaves the
    // picking to nobody.
    _beta = [self betaNote];
    _beta.hidden = NO;

    UIStackView *column = [[UIStackView alloc] initWithArrangedSubviews:@[strip, heading, _beta]];
    column.axis = UILayoutConstraintAxisVertical;
    column.spacing = 12;
    [column setCustomSpacing:28 afterView:strip];
    [column setCustomSpacing:24 afterView:heading];
    column.translatesAutoresizingMaskIntoConstraints = NO;

    UIScrollView *scroll = [UIScrollView new];
    scroll.alwaysBounceVertical = YES;
    scroll.showsVerticalScrollIndicator = NO;
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    [scroll addSubview:column];
    [self.view addSubview:scroll];

    _primary = glassButton(@"Start listening");
    [_primary addTarget:self action:@selector(finish) forControlEvents:UIControlEventTouchUpInside];
    UILabel *footer = [UILabel new];
    footer.text = @"Hold Home to open settings.";
    footer.font = [UIFont systemFontOfSize:13];
    footer.textColor = EeveeGrey();
    footer.textAlignment = NSTextAlignmentCenter;
    footer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_primary];
    [self.view addSubview:footer];

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    UILayoutGuide *frame = scroll.frameLayoutGuide, *content = scroll.contentLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [scroll.topAnchor constraintEqualToAnchor:safe.topAnchor],
        [scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:_primary.topAnchor constant:-12],
        [column.topAnchor constraintEqualToAnchor:content.topAnchor constant:48],
        [column.bottomAnchor constraintEqualToAnchor:content.bottomAnchor constant:-24],
        [column.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:kMargin],
        [column.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-kMargin],
        [column.widthAnchor constraintEqualToAnchor:frame.widthAnchor constant:-2 * kMargin],
        [halo.leadingAnchor constraintEqualToAnchor:strip.leadingAnchor],
        [halo.topAnchor constraintEqualToAnchor:strip.topAnchor],
        [halo.bottomAnchor constraintEqualToAnchor:strip.bottomAnchor],
        [halo.widthAnchor constraintEqualToConstant:88],
        [halo.heightAnchor constraintEqualToConstant:88],
        [_hero.centerXAnchor constraintEqualToAnchor:halo.centerXAnchor],
        [_hero.centerYAnchor constraintEqualToAnchor:halo.centerYAnchor],
        [_primary.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:kMargin],
        [_primary.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-kMargin],
        [_primary.bottomAnchor constraintEqualToAnchor:footer.topAnchor constant:-12],
        [footer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:kMargin],
        [footer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-kMargin],
        [footer.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor constant:-8],
    ]];
}

// iOS 16 has no symbol effects and skips the bounce.
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (@available(iOS 17.0, *)) [_hero addSymbolEffect:[NSClassFromString(@"NSSymbolBounceEffect") effect]];
}

- (void)finish {
    // spoti.pw asked for a donation after the tour and ended it in a restart when the look it drew
    // had changed; the merge dropped both, so the tour just ends.
    EeveeSetEnabled(EeveeKeyOnboardingSeen, YES);
    [self dismissViewControllerAnimated:YES completion:^{ EeveeShowSigningFixIfPending(); }];
}

@end

#pragma mark - entry

static __weak EeveeOnboardingController *eevee_tour;

BOOL EeveeOnboardingShowing(void) {
    return eevee_tour != nil;
}

void EeveeShowOnboarding(void) {
    if (eevee_tour) return;
    UIViewController *top = EeveeTopController();
    // Presenting from an alert lands nowhere; the tour waits for it to go.
    if (!top || [top isKindOfClass:UIAlertController.class]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ EeveeShowOnboarding(); });
        return;
    }
    EeveeOnboardingController *tour = [EeveeOnboardingController new];
    eevee_tour = tour;
    [top presentViewController:tour animated:YES completion:nil];
}
