#import "EeveePrefs.h"

BOOL EeveeFlag(NSString *key, BOOL fallback) {
    NSUserDefaults *store = NSUserDefaults.standardUserDefaults;
    id value = [store objectForKey:key];
    if (value) return [value boolValue];
    return fallback && ![store boolForKey:EeveeKeyStock];
}

BOOL EeveeEnabled(NSString *key) {
    return EeveeFlag(key, YES);
}

BOOL EeveeHidden(NSString *key) {
    return EeveeFlag(key, NO);
}

void EeveeSetEnabled(NSString *key, BOOL on) {
    [NSUserDefaults.standardUserDefaults setBool:on forKey:key];
}

NSInteger EeveeInt(NSString *key, NSInteger fallback) {
    id value = [NSUserDefaults.standardUserDefaults objectForKey:key];
    return value ? [value integerValue] : fallback;
}

void EeveeSetInt(NSString *key, NSInteger value) {
    [NSUserDefaults.standardUserDefaults setInteger:value forKey:key];
}

NSString *const EeveeFlagOverridePrefix = @"EeveeSpotify.flag.";

id EeveeFlagOverride(NSString *key) {
    return [NSUserDefaults.standardUserDefaults objectForKey:[EeveeFlagOverridePrefix stringByAppendingString:key]];
}

void EeveeSetFlagOverride(NSString *key, id value) {
    key = [EeveeFlagOverridePrefix stringByAppendingString:key];
    if (value) [NSUserDefaults.standardUserDefaults setObject:value forKey:key];
    else [NSUserDefaults.standardUserDefaults removeObjectForKey:key];
}

void EeveeMigrateKey(NSString *from, NSString *to) {
    NSUserDefaults *store = NSUserDefaults.standardUserDefaults;
    id value = [store objectForKey:from];
    if (!value || [store objectForKey:to]) return;
    [store setObject:value forKey:to];
    [store removeObjectForKey:from];
}
