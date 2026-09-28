// The Gestures page: the grid over a player-shaped preview, a cell tapped to say what a double tap
// there does, under it the split, the seek step and a reset.
#import "Core/EeveeCore.h"
#import "Settings/EeveePage.h"
#import "Settings/EeveePageStyle.h"
#import "Gestures.h"

static const CGFloat kPreviewHeight = 260;
static const CGFloat kPreviewRatio = 0.46;   // a phone, standing

static NSString *cellLabel(EeveeGestureAction action) {
    if (action == EeveeGestureSeekBack) return [NSString stringWithFormat:@"−%gs", EeveeGestureStep()];
    if (action == EeveeGestureSeekForward) return [NSString stringWithFormat:@"+%gs", EeveeGestureStep()];
    NSArray<NSString *> *names = EeveeGestureActionNames();
    return action >= 0 && action < (NSInteger)names.count ? names[(NSUInteger)action] : @"";
}

#pragma mark - the preview

// The grid the player is read against, drawn at the size of a phone and read the same way, so what
// the page shows and what the double tap does cannot drift apart.
@interface EeveeZoneGridView : UIView
@property (nonatomic, copy) void (^picked)(NSInteger cell);
- (void)reload;
@end

@implementation EeveeZoneGridView {
    NSMutableArray<UILabel *> *_labels;
    UIView *_frame;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (!(self = [super initWithFrame:frame])) return nil;
    _labels = [NSMutableArray array];
    _frame = [[UIView alloc] initWithFrame:CGRectZero];
    _frame.layer.cornerRadius = 18;
    _frame.layer.cornerCurve = kCACornerCurveContinuous;
    _frame.layer.borderWidth = 1;
    _frame.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.22].CGColor;
    _frame.backgroundColor = [UIColor colorWithWhite:1 alpha:0.05];
    _frame.clipsToBounds = YES;
    [self addSubview:_frame];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
    [_frame addGestureRecognizer:tap];
    [self reload];
    return self;
}

- (void)reload {
    NSArray<NSNumber *> *zones = EeveeGestureZones();
    while (_labels.count > zones.count) {
        [_labels.lastObject removeFromSuperview];
        [_labels removeLastObject];
    }
    while (_labels.count < zones.count) {
        UILabel *label = [UILabel new];
        label.font = EeveeSubtitleFont();
        label.textColor = UIColor.whiteColor;
        label.textAlignment = NSTextAlignmentCenter;
        label.numberOfLines = 2;
        label.layer.borderWidth = 0.5;
        label.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.18].CGColor;
        [_frame addSubview:label];
        [_labels addObject:label];
    }
    [zones enumerateObjectsUsingBlock:^(NSNumber *action, NSUInteger index, BOOL *stop) {
        UILabel *label = self->_labels[index];
        EeveeGestureAction value = (EeveeGestureAction)action.integerValue;
        label.text = cellLabel(value);
        label.textColor = value == EeveeGestureNothing ? EeveeGrey() : UIColor.whiteColor;
    }];
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat height = self.bounds.size.height;
    CGFloat width = height * kPreviewRatio;
    _frame.frame = CGRectMake((self.bounds.size.width - width) / 2, 0, width, height);

    NSInteger columns, rows;
    EeveeGestureGrid(&columns, &rows);
    CGFloat cellWidth = width / columns, cellHeight = height / rows;
    [_labels enumerateObjectsUsingBlock:^(UILabel *label, NSUInteger index, BOOL *stop) {
        NSInteger column = (NSInteger)index % columns, row = (NSInteger)index / columns;
        label.frame = CGRectMake(column * cellWidth, row * cellHeight, cellWidth, cellHeight);
    }];
}

- (void)tapped:(UITapGestureRecognizer *)tap {
    NSInteger cell = EeveeGestureCellAt([tap locationInView:_frame], _frame.bounds.size);
    if (cell >= 0 && self.picked) self.picked(cell);
}

@end

#pragma mark - the page

@interface EeveeGesturesPage : EeveePage
@end

@implementation EeveeGesturesPage {
    EeveeZoneGridView *_grid;
    UIView *_header;
    UIView *_footer;
}

- (instancetype)init {
    if (!(self = [super initWithStyle:UITableViewStyleInsetGrouped])) return nil;
    self.title = @"Gestures";
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _grid = [[EeveeZoneGridView alloc] initWithFrame:CGRectMake(0, 12, 0, kPreviewHeight)];
    __weak typeof(self) weakSelf = self;
    _grid.picked = ^(NSInteger cell) { [weakSelf pickActionFor:cell]; };
    // The table sets its header's width itself, and the grid follows it, so the header never has to
    // be handed back during layout: doing that lays the table out again and never settles.
    _grid.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, kPreviewHeight + 24)];
    _header.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [_header addSubview:_grid];
    self.tableView.tableHeaderView = _header;
    _footer = EeveeNote(@"Spotify's own buttons keep their taps.");
    self.tableView.tableFooterView = _footer;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    EeveeFitNote(self.tableView, _footer, 16, 24);
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    EeveeInsetForBars(self.tableView);
}

- (void)refresh {
    [_grid reload];
    [self.tableView reloadData];
}

- (void)pickActionFor:(NSInteger)cell {
    NSArray<NSString *> *names = EeveeGestureActionNames();
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"Double tap here"
                                                                  message:nil
                                                           preferredStyle:UIAlertControllerStyleActionSheet];
    [names enumerateObjectsUsingBlock:^(NSString *name, NSUInteger index, BOOL *stop) {
        [sheet addAction:[UIAlertAction actionWithTitle:name style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            EeveeSetGestureZone(cell, (EeveeGestureAction)index);
            [self refresh];
        }]];
    }];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    sheet.popoverPresentationController.sourceView = _grid;
    sheet.popoverPresentationController.sourceRect = _grid.bounds;
    [self presentViewController:sheet animated:YES completion:nil];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)table {
    return 4;
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 1: return (NSInteger)EeveeGestureSplitNames().count;
        case 2: return (NSInteger)EeveeGestureStepChoices().count;
        default: return 1;
    }
}

- (UIView *)tableView:(UITableView *)table viewForHeaderInSection:(NSInteger)section {
    if (section == 1) return EeveeSectionHeader(table, @"Split");
    if (section == 2) return EeveeSectionHeader(table, @"Seek step");
    return nil;
}

- (CGFloat)tableView:(UITableView *)table heightForHeaderInSection:(NSInteger)section {
    return section == 1 || section == 2 ? EeveeSectionHeaderHeight : EeveeSectionGap;
}

- (CGFloat)tableView:(UITableView *)table heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)path {
    UITableViewCell *cell = EeveeDequeueCell(table, @"gesture");
    switch (path.section) {
        case 0: {
            EeveeFillCell(cell, @"Double tap the player", @"Tap a cell to set it", nil, nil);
            UISwitch *toggle = [UISwitch new];
            toggle.onTintColor = EeveeGreen();
            toggle.on = EeveeFlag(EeveeKeyGestures, NO);
            [toggle addTarget:self action:@selector(toggled:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = toggle;
            break;
        }
        case 1:
        case 2: {
            BOOL split = path.section == 1;
            NSString *title = split ? EeveeGestureSplitNames()[(NSUInteger)path.row]
                                    : [NSString stringWithFormat:@"%@ seconds", EeveeGestureStepChoices()[(NSUInteger)path.row]];
            EeveeFillCell(cell, title, nil, nil, nil);
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            if (path.row == (split ? EeveeGestureSplit() : EeveeGestureStepChoice())) {
                UIImageView *tick = EeveeSymbolView(@"checkmark", 13, UIImageSymbolWeightSemibold, 16);
                tick.tintColor = EeveeGreen();
                cell.accessoryView = tick;
            }
            break;
        }
        default:
            EeveeFillCell(cell, @"Start over", nil, nil, @"arrow.uturn.backward");
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            break;
    }
    return cell;
}

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)path {
    [table deselectRowAtIndexPath:path animated:YES];
    if (path.section == 1) EeveeSetInt(EeveeKeyGestureSplit, path.row);
    else if (path.section == 2) EeveeSetInt(EeveeKeyGestureStep, path.row);
    else if (path.section == 3) EeveeResetGestureZones();
    else return;
    [self refresh];
}

- (void)toggled:(UISwitch *)toggle {
    EeveeSetEnabled(EeveeKeyGestures, toggle.on);
}

@end

UIViewController *EeveeGesturesSettingsPage(void) {
    return [EeveeGesturesPage new];
}
