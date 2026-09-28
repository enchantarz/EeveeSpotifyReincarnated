// The Live Activity page (App/ModSettings.x links it from the root, under either look).
#import "Core/EeveeCore.h"
#import "Settings/EeveeModPage.h"
#import "LiveActivity.h"

static NSArray<NSString *> *viewNames(void) {
    return @[@"Lyrics", @"Queue", @"Control menu"];
}

UIViewController *EeveeLiveActivitySettingsPage(void) {
    EeveeModRow *on = EeveeOptionRow(@"Live Activity", nil, EeveeKeyLiveActivity);
    on.changed = ^(BOOL value) { EeveeSetLiveActivityEnabled(value); };
    EeveeModRow *view = EeveeChoiceRow(@"Shows", nil, EeveeKeyLiveActivityView, viewNames(), EeveeLiveActivityLyrics);
    return [[EeveeModPage alloc] initWithTitle:@"Live Activity" intro:nil sections:@[
        EeveeSection(nil, @[on, view]),
    ] footer:nil];
}

NSString *EeveeLiveActivitySummary(void) {
    if (!EeveeFlag(EeveeKeyLiveActivity, NO)) return @"Off";
    NSInteger index = EeveeInt(EeveeKeyLiveActivityView, EeveeLiveActivityLyrics);
    NSArray<NSString *> *names = viewNames();
    return index >= 0 && index < (NSInteger)names.count ? names[index] : names.firstObject;
}
