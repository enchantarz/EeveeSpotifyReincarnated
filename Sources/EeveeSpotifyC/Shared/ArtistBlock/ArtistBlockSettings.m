// The Blocked artists page: the switch, whether a featured credit counts, blocking someone off the
// track playing now, and the list, swiped to unblock. The hook reads all of it per track, so a change
// needs no restart.
#import "Core/EeveeCore.h"
#import "Settings/EeveePage.h"
#import "Settings/EeveePageStyle.h"
#import "ArtistBlock.h"

typedef NS_ENUM(NSInteger, EeveeArtistSection) {
    EeveeArtistSectionSwitch,
    EeveeArtistSectionMode,
    EeveeArtistSectionAdd,
    EeveeArtistSectionList,
    EeveeArtistSectionCount,
};

@interface EeveeArtistBlockPage : EeveePage
@end

@implementation EeveeArtistBlockPage {
    NSArray<NSDictionary *> *_blocked;
}

- (instancetype)init {
    if (!(self = [super initWithStyle:UITableViewStyleInsetGrouped])) return nil;
    self.title = @"Blocked Artists";
    _blocked = EeveeBlockedArtists();
    return self;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    EeveeInsetForBars(self.tableView);
}

- (void)reload {
    _blocked = EeveeBlockedArtists();
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)table {
    return EeveeArtistSectionCount;
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    if (section == EeveeArtistSectionMode) return 2;
    if (section == EeveeArtistSectionList) return MAX((NSInteger)_blocked.count, 1);
    return 1;
}

- (UIView *)tableView:(UITableView *)table viewForHeaderInSection:(NSInteger)section {
    if (section == EeveeArtistSectionMode) return EeveeSectionHeader(table, @"Skip when the artist is");
    if (section == EeveeArtistSectionList) return EeveeSectionHeader(table, @"Blocked");
    return nil;
}

- (CGFloat)tableView:(UITableView *)table heightForHeaderInSection:(NSInteger)section {
    return section == EeveeArtistSectionMode || section == EeveeArtistSectionList ? EeveeSectionHeaderHeight : EeveeSectionGap;
}

- (CGFloat)tableView:(UITableView *)table heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)path {
    UITableViewCell *cell = EeveeDequeueCell(table, @"artist");
    switch (path.section) {
        case EeveeArtistSectionSwitch: {
            EeveeFillCell(cell, @"Skip blocked artists", nil, nil, nil);
            UISwitch *toggle = [UISwitch new];
            toggle.onTintColor = EeveeGreen();
            toggle.on = EeveeFlag(EeveeKeyArtistBlock, NO);
            [toggle addTarget:self action:@selector(toggled:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = toggle;
            break;
        }
        case EeveeArtistSectionMode: {
            BOOL featured = path.row == 1;
            EeveeFillCell(cell, featured ? @"Main or featured" : @"The main artist",
                       featured ? @"Any credit on the track" : @"The first name on the track", nil, nil);
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            if (featured == EeveeFlag(EeveeKeyArtistBlockFeatured, NO)) {
                UIImageView *tick = EeveeSymbolView(@"checkmark", 13, UIImageSymbolWeightSemibold, 16);
                tick.tintColor = EeveeGreen();
                cell.accessoryView = tick;
            }
            break;
        }
        case EeveeArtistSectionAdd:
            EeveeFillCell(cell, @"Block from what's playing…", nil, nil, @"person.crop.circle.badge.xmark");
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            break;
        default:
            if (!_blocked.count) {
                EeveeFillCell(cell, @"No one yet", nil, EeveeGrey(), nil);
                break;
            }
            NSDictionary *artist = _blocked[(NSUInteger)path.row];
            EeveeFillCell(cell, artist[EeveeArtistName], artist[EeveeArtistURI], nil, nil);
            break;
    }
    return cell;
}

- (BOOL)tableView:(UITableView *)table canEditRowAtIndexPath:(NSIndexPath *)path {
    return path.section == EeveeArtistSectionList && _blocked.count > 0;
}

- (NSString *)tableView:(UITableView *)table titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)path {
    return @"Unblock";
}

- (void)tableView:(UITableView *)table commitEditingStyle:(UITableViewCellEditingStyle)style forRowAtIndexPath:(NSIndexPath *)path {
    if (style != UITableViewCellEditingStyleDelete) return;
    EeveeUnblockArtist(_blocked[(NSUInteger)path.row][EeveeArtistURI]);
    [self reload];
}

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)path {
    [table deselectRowAtIndexPath:path animated:YES];
    if (path.section == EeveeArtistSectionMode) {
        EeveeSetEnabled(EeveeKeyArtistBlockFeatured, path.row == 1);
        [self reload];
    } else if (path.section == EeveeArtistSectionAdd) {
        [self pickFromPlaying:[table cellForRowAtIndexPath:path]];
    }
}

- (void)pickFromPlaying:(UIView *)source {
    NSArray<NSDictionary *> *artists = EeveePlayingArtists();
    if (!artists.count) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Nothing playing"
                                                                      message:@"Play a track by the artist first, then come back here."
                                                               preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"Block"
                                                                  message:nil
                                                           preferredStyle:UIAlertControllerStyleActionSheet];
    [artists enumerateObjectsUsingBlock:^(NSDictionary *artist, NSUInteger index, BOOL *stop) {
        BOOL blocked = EeveeArtistBlocked(artist[EeveeArtistURI]);
        NSString *title = index == 0 ? artist[EeveeArtistName] : [NSString stringWithFormat:@"%@ (featured)", artist[EeveeArtistName]];
        UIAlertAction *action = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
            EeveeBlockArtist(artist);
            [self reload];
        }];
        action.enabled = !blocked;
        [sheet addAction:action];
    }];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    sheet.popoverPresentationController.sourceView = source;
    sheet.popoverPresentationController.sourceRect = source.bounds;
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)toggled:(UISwitch *)toggle {
    EeveeSetEnabled(EeveeKeyArtistBlock, toggle.on);
}

@end

UIViewController *EeveeArtistBlockSettingsPage(void) {
    return [EeveeArtistBlockPage new];
}
