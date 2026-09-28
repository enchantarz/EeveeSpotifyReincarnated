#import "Core/EeveeCore.h"
#import "Settings/EeveePage.h"
#import "Settings/EeveePageStyle.h"
#import "Navbar.h"
#import "Shared/Navigation/Links.h"

// What "Add a tab" offers: URIs Spotify's own router resolves to a page of its own, each with the
// name of the SPTEncoreIcon class method that draws its glyph. Playlists was spotify:collection:playlists
// until 0.20, which 9.1.78 knows only from its old iPad sidebar table and has no handler for (#66);
// spotify:playlists is the form its collection URI parser lists, next to spotify:playlists:by-you.
// The picker still asks the dispatcher about each one and leaves out what it has nowhere to send.
static NSArray<NSDictionary *> *tabPresets(void) {
    return @[
        @{EeveeRNavbarTitle: @"Home", EeveeRNavbarURI: @"spotify:home", EeveeRNavbarIcon: @"home"},
        @{EeveeRNavbarTitle: @"Search", EeveeRNavbarURI: @"spotify:search", EeveeRNavbarIcon: @"search"},
        @{EeveeRNavbarTitle: @"Your Library", EeveeRNavbarURI: @"spotify:collection", EeveeRNavbarIcon: @"collection"},
        @{EeveeRNavbarTitle: @"Liked Songs", EeveeRNavbarURI: @"spotify:collection:tracks", EeveeRNavbarIcon: @"heart"},
        @{EeveeRNavbarTitle: @"Playlists", EeveeRNavbarURI: @"spotify:playlists", EeveeRNavbarIcon: @"playlist"},
        @{EeveeRNavbarTitle: @"Albums", EeveeRNavbarURI: @"spotify:collection:albums", EeveeRNavbarIcon: @"album"},
        @{EeveeRNavbarTitle: @"Artists", EeveeRNavbarURI: @"spotify:collection:artists", EeveeRNavbarIcon: @"artist"},
        @{EeveeRNavbarTitle: @"Podcasts", EeveeRNavbarURI: @"spotify:collection:podcasts", EeveeRNavbarIcon: @"podcasts"},
        @{EeveeRNavbarTitle: @"Audiobooks", EeveeRNavbarURI: @"spotify:collection:audiobooks", EeveeRNavbarIcon: @"audiobook"},
        @{EeveeRNavbarTitle: @"Downloads", EeveeRNavbarURI: @"spotify:collection:downloads", EeveeRNavbarIcon: @"downloaded"},
        @{EeveeRNavbarTitle: @"Your Episodes", EeveeRNavbarURI: @"spotify:collection:your-episodes", EeveeRNavbarIcon: @"bookmark"},
        @{EeveeRNavbarTitle: @"Browse", EeveeRNavbarURI: @"spotify:browse", EeveeRNavbarIcon: @"browse"},
        @{EeveeRNavbarTitle: @"New Releases", EeveeRNavbarURI: @"spotify:new-releases", EeveeRNavbarIcon: @"star"},
        @{EeveeRNavbarTitle: @"Made For You", EeveeRNavbarURI: @"spotify:made-for-you", EeveeRNavbarIcon: @"user"},
        @{EeveeRNavbarTitle: @"Concerts", EeveeRNavbarURI: @"spotify:concerts", EeveeRNavbarIcon: @"events"},
        @{EeveeRNavbarTitle: @"Queue", EeveeRNavbarURI: @"spotify:now-playing:queue", EeveeRNavbarIcon: @"queue"},
        @{EeveeRNavbarTitle: @"Create", EeveeRNavbarURI: @"spotify:create-menu", EeveeRNavbarIcon: @"plus"},
    ];
}

// The list the Navbar page edits: the saved order first, then every tab of Spotify's it does not
// name, in Spotify's order. Entries for tabs Spotify no longer has drop out.
static NSMutableArray<NSMutableDictionary *> *navbarEntries(void) {
    NSArray<NSString *> *stock = EeveeRNavbarStock();
    NSMutableArray<NSMutableDictionary *> *entries = [NSMutableArray array];
    NSMutableSet<NSString *> *seen = [NSMutableSet set];
    for (NSDictionary *entry in EeveeRNavbarLayout()) {
        NSString *ident = entry[EeveeRNavbarID];
        if (![ident isKindOfClass:NSString.class] || [seen containsObject:ident]) continue;
        if (!entry[EeveeRNavbarURI] && ![stock containsObject:ident]) continue;
        [seen addObject:ident];
        [entries addObject:[entry mutableCopy]];
    }
    for (NSString *ident in stock) {
        if ([seen containsObject:ident]) continue;
        [entries addObject:[@{EeveeRNavbarID: ident, EeveeRNavbarTitle: ident} mutableCopy]];
    }
    return entries;
}

// A tab of the mod's own carries an identity of its own, so the same page can sit on the bar twice
// and renaming one does not shuffle the order.
static void appendTab(NSDictionary *tab) {
    NSMutableDictionary *entry = [tab mutableCopy];
    entry[EeveeRNavbarID] = NSUUID.UUID.UUIDString;
    EeveeRSetNavbarLayout([navbarEntries() arrayByAddingObject:entry]);
    EeveeRRefreshTabBar();
}

@interface EeveeRTabPickerPage : EeveePage
@end

// The presets the dispatcher can send somewhere, each verdict logged. When it cannot be asked (not set
// up yet, or 9.1.78's registry is not where it was) every preset stays, as before.
static NSArray<NSDictionary *> *openablePresets(void) {
    NSMutableArray<NSDictionary *> *kept = [NSMutableArray array];
    for (NSDictionary *tab in tabPresets()) {
        NSString *via = nil;
        EeveeLinkRoute route = EeveeSpotifyURIRoute([NSURL URLWithString:tab[EeveeRNavbarURI]], &via);
        EeveeLog(@"navbar: preset %@ -> %@", tab[EeveeRNavbarURI],
              route == EeveeLinkRouteOpens ? via : route == EeveeLinkRouteNone ? @"no handler, left out" : @"unknown");
        if (route != EeveeLinkRouteNone) [kept addObject:tab];
    }
    return kept;
}

@implementation EeveeRTabPickerPage {
    UIView *_footer;
    NSArray<NSDictionary *> *_presets;
}

- (instancetype)init {
    if (!(self = [super initWithStyle:UITableViewStyleInsetGrouped])) return nil;
    self.title = @"Add a Tab";
    _presets = openablePresets();
    return self;
}

// Said here rather than by Spotify's alert on the bar later, every time the tab is tapped.
- (void)refuse:(NSString *)uri {
    NSString *message = [NSString stringWithFormat:@"Spotify has nowhere to open %@, so it would not work as a tab.", uri];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Can't open that link" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
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
    return section == 0 ? (NSInteger)_presets.count : 1;
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
        NSDictionary *tab = _presets[(NSUInteger)path.row];
        EeveeFillCell(cell, tab[EeveeRNavbarTitle], tab[EeveeRNavbarURI], nil, nil);
    } else {
        EeveeFillCell(cell, @"Any link…", nil, nil, @"link");
    }
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    return cell;
}

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)path {
    [table deselectRowAtIndexPath:path animated:YES];
    if (path.section == 0) {
        appendTab(_presets[(NSUInteger)path.row]);
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
        NSString *title = alert.textFields[0].text, *icon = alert.textFields[2].text;
        NSString *uri = EeveeSpotifyURIFromText(alert.textFields[1].text).absoluteString;
        if (!uri.length) return;
        NSString *via = nil;
        EeveeLinkRoute route = EeveeSpotifyURIRoute([NSURL URLWithString:uri], &via);
        EeveeLog(@"navbar: custom %@ -> %@", uri, route == EeveeLinkRouteOpens ? via : route == EeveeLinkRouteNone ? @"no handler" : @"unknown");
        if (route == EeveeLinkRouteNone) {
            [self refuse:uri];
            return;
        }
        appendTab(@{EeveeRNavbarTitle: title.length ? title : uri, EeveeRNavbarURI: uri, EeveeRNavbarIcon: icon.length ? icon : @"star"});
        [self.navigationController popViewControllerAnimated:YES];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end

typedef NS_ENUM(NSInteger, EeveeRNavbarSection) {
    EeveeRNavbarSectionSwitch,
    EeveeRNavbarSectionTabs,
    EeveeRNavbarSectionAdd,
    EeveeRNavbarSectionReset,
    EeveeRNavbarSectionCount,
};

// The tabs, in the order the bar shows them: drag to reorder, tap to show or hide, swipe a tab of
// your own away. Spotify's own tabs can only be hidden, never removed. Mod Settings and the welcome
// tour show the same editor.
@interface EeveeRNavbarPage : EeveePage
@end

@implementation EeveeRNavbarPage {
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
    EeveeRSetNavbarLayout(_entries);
    EeveeRRefreshTabBar();
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)table {
    return EeveeRNavbarSectionCount;
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    if (section == EeveeRNavbarSectionSwitch) return 2;
    return section == EeveeRNavbarSectionTabs ? (NSInteger)_entries.count : 1;
}

- (NSString *)headerFor:(NSInteger)section {
    return section == EeveeRNavbarSectionTabs ? @"Tabs" : nil;
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
        case EeveeRNavbarSectionSwitch: {
            BOOL labels = path.row == 1;
            EeveeFillCell(cell, labels ? @"Hide labels" : @"Custom navbar", labels ? @"Icons only" : nil, nil, nil);
            UISwitch *toggle = [UISwitch new];
            toggle.onTintColor = EeveeGreen();
            toggle.tag = path.row;
            toggle.on = labels ? EeveeHidden(EeveeRKeyNavbarHideLabels) : EeveeEnabled(EeveeRKeyNavbar);
            [toggle addTarget:self action:@selector(toggled:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = toggle;
            break;
        }
        case EeveeRNavbarSectionTabs: {
            NSDictionary *entry = _entries[(NSUInteger)path.row];
            BOOL hidden = [entry[EeveeRNavbarHidden] boolValue];
            NSString *uri = entry[EeveeRNavbarURI];
            EeveeFillCell(cell, entry[EeveeRNavbarTitle], hidden ? @"Hidden" : (uri ?: @"Spotify's own tab"),
                     hidden ? EeveeGrey() : nil, hidden ? @"eye.slash" : @"eye");
            break;
        }
        case EeveeRNavbarSectionAdd:
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
    return path.section == EeveeRNavbarSectionTabs;
}

- (BOOL)tableView:(UITableView *)table canEditRowAtIndexPath:(NSIndexPath *)path {
    return path.section == EeveeRNavbarSectionTabs;
}

// Spotify's own tabs stay on the list to be switched back on; only the mod's own can go.
- (UITableViewCellEditingStyle)tableView:(UITableView *)table editingStyleForRowAtIndexPath:(NSIndexPath *)path {
    if (path.section != EeveeRNavbarSectionTabs) return UITableViewCellEditingStyleNone;
    return _entries[(NSUInteger)path.row][EeveeRNavbarURI] ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;
}

- (NSIndexPath *)tableView:(UITableView *)table targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)from toProposedIndexPath:(NSIndexPath *)to {
    return to.section == EeveeRNavbarSectionTabs ? to : from;
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
    if (path.section == EeveeRNavbarSectionTabs) {
        NSMutableDictionary *entry = _entries[(NSUInteger)path.row];
        entry[EeveeRNavbarHidden] = [entry[EeveeRNavbarHidden] boolValue] ? nil : @YES;
        [self save];
        [table reloadRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationNone];
    } else if (path.section == EeveeRNavbarSectionAdd) {
        [self.navigationController pushViewController:[EeveeRTabPickerPage new] animated:YES];
    } else if (path.section == EeveeRNavbarSectionReset) {
        [self reset];
    }
}

- (void)toggled:(UISwitch *)toggle {
    EeveeSetEnabled(toggle.tag == 1 ? EeveeRKeyNavbarHideLabels : EeveeRKeyNavbar, toggle.on);
    EeveeRRefreshTabBar();
}

- (void)reset {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Use Spotify's order"
                                                                  message:@"Every tab of Spotify's comes back where Spotify put it, and the tabs you added go."
                                                           preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Reset" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        EeveeRSetNavbarLayout(@[]);
        EeveeRRefreshTabBar();
        self->_entries = navbarEntries();
        [self.tableView reloadData];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end

UIViewController *EeveeRNavbarSettingsPage(void) {
    return [EeveeRNavbarPage new];
}

UIViewController *EeveeRNavbarEditorPage(void) {
    return [EeveeRNavbarPage new];
}
