#import <os/lock.h>
#import "Core/EeveeCore.h"
#import "EeveeRedesign.h"

// Written from the constructors, read by the configuration provider on whatever thread it asks from;
// the lock only guards the swap of the immutable table.
static os_unfair_lock eevee_flagsLock = OS_UNFAIR_LOCK_INIT;
static NSDictionary<NSString *, id> *eevee_flags;

static id forcedNow(NSString *key) {
    os_unfair_lock_lock(&eevee_flagsLock);
    id value = eevee_flags[key];
    os_unfair_lock_unlock(&eevee_flagsLock);
    return value;
}

void EeveeRedesignForceFlags(NSString *owner, NSDictionary<NSString *, id> *flags) {
    if (!flags.count) return;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        EeveeRegisterFlagForcer(YES, ^id(NSString *key) { return EeveeRedesignedUI() ? forcedNow(key) : nil; },
                             ^id(NSString *key) { return EeveeRedesignedUI() ? forcedNow(key) : nil; });
    });
    os_unfair_lock_lock(&eevee_flagsLock);
    NSMutableDictionary *all = [eevee_flags mutableCopy] ?: [NSMutableDictionary dictionary];
    [all addEntriesFromDictionary:flags];
    eevee_flags = [all copy];
    os_unfair_lock_unlock(&eevee_flagsLock);
    if (!EeveeRedesignedUI()) return;
    EeveeLog(@"redesign %@: forcing %lu flags", owner, (unsigned long)flags.count);
    [flags enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
        id override = EeveeFlagOverride(key);
        if (override) EeveeLog(@"redesign %@: flag %@ forced %@ over the All flags override %@", owner, key, value, override);
    }];
}
