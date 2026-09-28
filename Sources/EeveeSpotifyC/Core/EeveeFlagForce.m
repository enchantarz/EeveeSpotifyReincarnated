#import <os/lock.h>
#import "EeveeFlagForce.h"
#import "EeveePrefs.h"

@interface EeveeFlagForcerEntry : NSObject
@property (nonatomic) BOOL beatsOverride;
@property (nonatomic, copy) EeveeFlagForcer atLaunch, locked;
@end

@implementation EeveeFlagForcerEntry
@end

// Swapped whole under the lock, so a reader walks an immutable array.
static os_unfair_lock eevee_lock = OS_UNFAIR_LOCK_INIT;
static NSArray<EeveeFlagForcerEntry *> *eevee_forcers;

void EeveeRegisterFlagForcer(BOOL beatsOverride, EeveeFlagForcer atLaunch, EeveeFlagForcer locked) {
    if (!atLaunch) return;
    EeveeFlagForcerEntry *entry = [EeveeFlagForcerEntry new];
    entry.beatsOverride = beatsOverride;
    entry.atLaunch = atLaunch;
    entry.locked = locked;
    os_unfair_lock_lock(&eevee_lock);
    eevee_forcers = [(eevee_forcers ?: @[]) arrayByAddingObject:entry];
    os_unfair_lock_unlock(&eevee_lock);
}

static NSArray<EeveeFlagForcerEntry *> *forcers(void) {
    os_unfair_lock_lock(&eevee_lock);
    NSArray *list = eevee_forcers;
    os_unfair_lock_unlock(&eevee_lock);
    return list;
}

id EeveeForcedFlagValue(NSString *key) {
    if (!key) return nil;
    NSArray<EeveeFlagForcerEntry *> *list = forcers();
    for (EeveeFlagForcerEntry *entry in list) {
        if (!entry.beatsOverride) continue;
        id value = entry.atLaunch(key);
        if (value) return value;
    }
    id value = EeveeFlagOverride(key);
    if (value) return value;
    for (EeveeFlagForcerEntry *entry in list) {
        if (entry.beatsOverride) continue;
        value = entry.atLaunch(key);
        if (value) return value;
    }
    return nil;
}

id EeveeLockedFlagValue(NSString *key, BOOL *beatsOverride) {
    if (beatsOverride) *beatsOverride = NO;
    if (!key) return nil;
    NSArray<EeveeFlagForcerEntry *> *list = forcers();
    for (int pass = 0; pass < 2; pass++) {
        BOOL first = pass == 0;
        for (EeveeFlagForcerEntry *entry in list) {
            if (entry.beatsOverride != first || !entry.locked) continue;
            id value = entry.locked(key);
            if (!value) continue;
            if (beatsOverride) *beatsOverride = first;
            return value;
        }
    }
    return nil;
}
