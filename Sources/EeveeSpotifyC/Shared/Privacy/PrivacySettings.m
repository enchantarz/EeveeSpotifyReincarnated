#import "Settings/EeveeModPage.h"
#import "Privacy.h"

EeveeModSection *EeveePrivacySection(void) {
    return EeveeSection(@"Privacy", @[
        EeveeWithSymbol(EeveeSwitchRow(@"Block telemetry", @"Spotify's own events still go out, since Recents is built from them", EeveeKeyBlockTelemetry), @"antenna.radiowaves.left.and.right.slash"),
    ]);
}

EeveeModSection *EeveePrivacyCountersSection(void) {
    NSMutableArray<EeveeModRow *> *counts = [NSMutableArray array];
    for (NSString *label in EeveeBlockedLabels()) {
        [counts addObject:EeveeStatRow(label, ^NSString *{
            return @(EeveeBlockedCount(label)).stringValue;
        })];
    }
    [counts addObject:EeveeStatRow(@"Total", ^NSString *{
        return @(EeveeBlockedCount(nil)).stringValue;
    })];
    [counts addObject:EeveeActionRow(@"Reset the telemetry counters", nil, ^{ EeveeResetBlocked(); })];
    return EeveeSection(@"Telemetry blocked so far", counts);
}
