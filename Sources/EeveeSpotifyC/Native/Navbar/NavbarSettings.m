#import "Core/EeveeCore.h"
#import "Settings/EeveePage.h"
#import "Settings/EeveePageStyle.h"
#import "Navbar.h"

// What "Add a tab" offers: URIs Spotify's own router resolves to a page of its own, each with the
// name of the SPTEncoreIcon class method that draws its glyph.
static NSArray<NSDictionary *> *tabPresets(void) {
    return @[
        @{EeveeNavbarTitle: @"Home", EeveeNavbarURI: @"spotify:home", EeveeNavbarIcon: @"home"},
        @{EeveeNavbarTitle: @"Search", EeveeNavbarURI: @"spotify:search", EeveeNavbarIcon: @"search"},
        @{EeveeNavbarTitle: @"Your Library", EeveeNavbarURI: @"spotify:collection", EeveeNavbarIcon: @"collection"},
        @{EeveeNavbarTitle: @"Liked Songs", EeveeNavbarURI: @"spotify:collection:tracks", EeveeNavbarIcon: @"heart"},
        @{EeveeNavbarTitle: @"Playlists", EeveeNavbarURI: @"spotify:playlists", EeveeNavbarIcon: @"playlist"},
        @{EeveeNavbarTitle: @"Albums", EeveeNavbarURI: @"spotify:collection:albums", EeveeNavbarIcon: @"album"},
        @{EeveeNavbarTitle: @"Artists", EeveeNavbarURI: @"spotify:collection:artists", EeveeNavbarIcon: @"artist"},
        @{EeveeNavbarTitle: @"Podcasts", EeveeNavbarURI: @"spotify:collection:podcasts", EeveeNavbarIcon: @"podcasts"},
        @{EeveeNavbarTitle: @"Audiobooks", EeveeNavbarURI: @"spotify:collection:audiobooks", EeveeNavbarIcon: @"audiobook"},
        @{EeveeNavbarTitle: @"Downloads", EeveeNavbarURI: @"spotify:collection:downloads", EeveeNavbarIcon: @"downloaded"},
        @{EeveeNavbarTitle: @"Your Episodes", EeveeNavbarURI: @"spotify:collection:your-episodes", EeveeNavbarIcon: @"bookmark"},
        @{EeveeNavbarTitle: @"Browse", EeveeNavbarURI: @"spotify:browse", EeveeNavbarIcon: @"browse"},
        @{EeveeNavbarTitle: @"New Releases", EeveeNavbarURI: @"spotify:new-releases", EeveeNavbarIcon: @"star"},
        @{EeveeNavbarTitle: @"Made For You", EeveeNavbarURI: @"spotify:made-for-you", EeveeNavbarIcon: @"user"},
        @{EeveeNavbarTitle: @"Concerts", EeveeNavbarURI: @"spotify:concerts", EeveeNavbarIcon: @"events"},
        @{EeveeNavbarTitle: @"Queue", EeveeNavbarURI: @"spotify:now-playing:queue", EeveeNavbarIcon: @"queue"},
        @{EeveeNavbarTitle: @"Create", EeveeNavbarURI: @"spotify:create-menu", EeveeNavbarIcon: @"plus"},
    ];
}

// The list the Navbar page edits: the saved order first, then every tab of Spotify's it does not
// name, in Spotify's order. Entries for tabs Spotify no longer has drop out.
static NSMutableArray<NSMutableDictionary *> *navbarEntries(void) {
    NSArray<NSString *> *stock = EeveeNavbarStock();
    NSMutableArray<NSMutableDictionary *> *entries = [NSMutableArray array];
    NSMutableSet<NSString *> *seen = [NSMutableSet set];
    for (NSDictionary *entry in EeveeNavbarLayout()) {
        NSString *ident = entry[EeveeNavbarID];
        if (![ident isKindOfClass:NSString.class] || [seen containsObject:ident]) continue;
        if (!entry[EeveeNavbarURI] && ![stock containsObject:ident]) continue;
        [seen addObject:ident];
        [entries addObject:[entry mutableCopy]];
    }
    for (NSString *ident in stock) {
        if ([seen containsObject:ident]) continue;
        [entries addObject:[@{EeveeNavbarID: ident, EeveeNavbarTitle: ident} mutableCopy]];
    }
    return entries;
}

// A tab of the mod's own carries an identity of its own, so the same page can sit on the bar twice
// and renaming one does not shuffle the order.
static void appendTab(NSDictionary *tab) {
    NSMutableDictionary *entry = [tab mutableCopy];
    entry[EeveeNavbarID] = NSUUID.UUID.UUIDString;
    EeveeSetNavbarLayout([navbarEntries() arrayByAddingObject:entry]);
    EeveeRefreshTabBar();
}

@interface EeveeTabPickerPage : EeveePage
@end

@implementation EeveeTabPickerPage {
    UIView *_footer;
}

- (instancetype)init {
    if (!(self = [super initWithStyle:UITableViewStyleInsetGrouped])) return nil;
    self.title = @"Add a Tab";
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _footer = EeveeNote(@"Paste a share link or a spotify: URI. Icons: home, search, collection, heart, "
                   "playlist, album, artist, podcasts, audiobook, downloaded, bookmark, browse, star, "
                   "user, events, queue, plus, radio, gears, spotifyLogo.");
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)table {
    return 2;
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? (NSInteger)tabPresets().count : 1;
}

- (UIView *)tableView:(UITableView *)table viewForHeaderInSection:(NSInteger)section {
    return EeveeSectionHeader(table, section == 0 ? @"Spotify's pages" : @"Anywhere else");
}

- (CGFloat)tableView:(UITableView *)table heightForHeaderInSection:(NSInteger)section {
    return EeveeSectionHeaderHeight;
}

- (CGFloat)tableView:(UITableView *)table heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)path {
    UITableViewCell *cell = EeveeDequeueCell(table, @"pick");
    if (path.section == 0) {
        NSDictionary *tab = tabPresets()[(NSUInteger)path.row];
        EeveeFillCell(cell, tab[EeveeNavbarTitle], tab[EeveeNavbarURI], nil, nil);
    } else {
        EeveeFillCell(cell, @"Any link…", nil, nil, @"link");
    }
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    return cell;
}

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)path {
    [table deselectRowAtIndexPath:path animated:YES];
    if (path.section == 0) {
        appendTab(tabPresets()[(NSUInteger)path.row]);
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Any link" message:@"Where the tab goes, and the glyph on it." preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) { field.placeholder = @"Name"; }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.placeholder = @"spotify:playlist:…";
        field.autocapitalizationType = UITextAutocapitalizationTypeNone;
        field.autocorrectionType = UITextAutocorrectionTypeNo;
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.placeholder = @"Icon";
        field.text = @"star";
        field.autocapitalizationType = UITextAutocapitalizationTypeNone;
        field.autocorrectionType = UITextAutocorrectionTypeNo;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Add" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *title = alert.textFields[0].text, *uri = alert.textFields[1].text, *icon = alert.textFields[2].text;
        if (!uri.length) return;
        appendTab(@{EeveeNavbarTitle: title.length ? title : uri, EeveeNavbarURI: uri, EeveeNavbarIcon: icon.length ? icon : @"star"});
        [self.navigationController popViewControllerAnimated:YES];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end

typedef NS_ENUM(NSInteger, EeveeNavbarSection) {
    EeveeNavbarSectionSwitch,
    EeveeNavbarSectionTabs,
    EeveeNavbarSectionAdd,
    EeveeNavbarSectionReset,
    EeveeNavbarSectionCount,
};

// The tabs, in the order the bar shows them: drag to reorder, tap to show or hide, swipe a tab of
// your own away. Spotify's own tabs can only be hidden, never removed. Mod Settings and the welcome
// tour show the same editor.
@interface EeveeNavbarPage : EeveePage
@end

@implementation EeveeNavbarPage {
    NSMutableArray<NSMutableDictionary *> *_entries;
    UIView *_intro;
}

- (instancetype)init {
    if (!(self = [super initWithStyle:UITableViewStyleInsetGrouped])) return nil;
    self.title = @"Navbar";
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.allowsSelectionDuringEditing = YES;
    self.tableView.editing = YES;
    _intro = EeveeNote(@"Drag to reorder, tap to show or hide.");
    self.tableView.tableHeaderView = _intro;
    _entries = navbarEntries();
}

// The Add page writes straight to the layout, so the list is read again on the way back.
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _entries = navbarEntries();
    [self.tableView reloadData];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    EeveeFitNote(self.tableView, _intro, 24, 0);
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    EeveeInsetForBars(self.tableView);
}

- (void)save {
    EeveeSetNavbarLayout(_entries);
    EeveeRefreshTabBar();
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)table {
    return EeveeNavbarSectionCount;
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    return section == EeveeNavbarSectionTabs ? (NSInteger)_entries.count : 1;
}

- (NSString *)headerFor:(NSInteger)section {
    return section == EeveeNavbarSectionTabs ? @"Tabs" : nil;
}

- (UIView *)tableView:(UITableView *)table viewForHeaderInSection:(NSInteger)section {
    NSString *title = [self headerFor:section];
    return title ? EeveeSectionHeader(table, title) : nil;
}

- (CGFloat)tableView:(UITableView *)table heightForHeaderInSection:(NSInteger)section {
    if ([self headerFor:section]) return EeveeSectionHeaderHeight;
    return [self tableView:table numberOfRowsInSection:section] ? EeveeSectionGap : CGFLOAT_MIN;
}

- (CGFloat)tableView:(UITableView *)table heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)path {
    UITableViewCell *cell = EeveeDequeueCell(table, @"navbar");
    switch (path.section) {
        case EeveeNavbarSectionSwitch: {
            EeveeFillCell(cell, @"Custom navbar", nil, nil, nil);
            UISwitch *toggle = [UISwitch new];
            toggle.onTintColor = EeveeGreen();
            toggle.on = EeveeEnabled(EeveeKeyNavbar);
            [toggle addTarget:self action:@selector(toggled:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = toggle;
            break;
        }
        case EeveeNavbarSectionTabs: {
            NSDictionary *entry = _entries[(NSUInteger)path.row];
            BOOL hidden = [entry[EeveeNavbarHidden] boolValue];
            NSString *uri = entry[EeveeNavbarURI];
            EeveeFillCell(cell, entry[EeveeNavbarTitle], hidden ? @"Hidden" : (uri ?: @"Spotify's own tab"),
                     hidden ? EeveeGrey() : nil, hidden ? @"eye.slash" : @"eye");
            break;
        }
        case EeveeNavbarSectionAdd:
            EeveeFillCell(cell, @"Add a tab…", nil, nil, @"plus");
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            break;
        default:
            EeveeFillCell(cell, @"Use Spotify's order", nil, nil, @"arrow.uturn.backward");
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            break;
    }
    return cell;
}

- (BOOL)tableView:(UITableView *)table canMoveRowAtIndexPath:(NSIndexPath *)path {
    return path.section == EeveeNavbarSectionTabs;
}

- (BOOL)tableView:(UITableView *)table canEditRowAtIndexPath:(NSIndexPath *)path {
    return path.section == EeveeNavbarSectionTabs;
}

// Spotify's own tabs stay on the list to be switched back on; only the mod's own can go.
- (UITableViewCellEditingStyle)tableView:(UITableView *)table editingStyleForRowAtIndexPath:(NSIndexPath *)path {
    if (path.section != EeveeNavbarSectionTabs) return UITableViewCellEditingStyleNone;
    return _entries[(NSUInteger)path.row][EeveeNavbarURI] ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;
}

- (NSIndexPath *)tableView:(UITableView *)table targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)from toProposedIndexPath:(NSIndexPath *)to {
    return to.section == EeveeNavbarSectionTabs ? to : from;
}

- (void)tableView:(UITableView *)table moveRowAtIndexPath:(NSIndexPath *)from toIndexPath:(NSIndexPath *)to {
    NSMutableDictionary *entry = _entries[(NSUInteger)from.row];
    [_entries removeObjectAtIndex:(NSUInteger)from.row];
    [_entries insertObject:entry atIndex:(NSUInteger)to.row];
    [self save];
}

- (void)tableView:(UITableView *)table commitEditingStyle:(UITableViewCellEditingStyle)style forRowAtIndexPath:(NSIndexPath *)path {
    if (style != UITableViewCellEditingStyleDelete) return;
    [_entries removeObjectAtIndex:(NSUInteger)path.row];
    [self save];
    [table deleteRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)path {
    [table deselectRowAtIndexPath:path animated:YES];
    if (path.section == EeveeNavbarSectionTabs) {
        NSMutableDictionary *entry = _entries[(NSUInteger)path.row];
        entry[EeveeNavbarHidden] = [entry[EeveeNavbarHidden] boolValue] ? nil : @YES;
        [self save];
        [table reloadRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationNone];
    } else if (path.section == EeveeNavbarSectionAdd) {
        [self.navigationController pushViewController:[EeveeTabPickerPage new] animated:YES];
    } else if (path.section == EeveeNavbarSectionReset) {
        [self reset];
    }
}

- (void)toggled:(UISwitch *)toggle {
    EeveeSetEnabled(EeveeKeyNavbar, toggle.on);
    EeveeRefreshTabBar();
}

- (void)reset {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Use Spotify's order"
                                                                  message:@"Every tab of Spotify's comes back where Spotify put it, and the tabs you added go."
                                                           preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Reset" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        EeveeSetNavbarLayout(@[]);
        EeveeRefreshTabBar();
        self->_entries = navbarEntries();
        [self.tableView reloadData];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end

UIViewController *EeveeNavbarSettingsPage(void) {
    return [EeveeNavbarPage new];
}

UIViewController *EeveeNavbarEditorPage(void) {
    return [EeveeNavbarPage new];
}
