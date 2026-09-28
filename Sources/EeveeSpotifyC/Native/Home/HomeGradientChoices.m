// What the Gradient page offers and what the hooks read back, one entry per setting: the names, the
// key it is stored under and the index it falls back to. HomeGradient.x carries the numbers behind
// the names, in the same order as the names themselves.
#import "Core/EeveeCore.h"
#import "Home.h"

static NSDictionary *choiceDef(EeveeHomeChoice choice) {
    static NSDictionary<NSNumber *, NSDictionary *> *table;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        table = @{
            // Eight rotations of the green the wash was born as, at the same depth and saturation
            // around the wheel, so each of them sits behind white text the way the green does.
            @(EeveeHomeChoiceTint): @{
                @"key": @"EeveeSpotify.homeGradientTint",
                @"default": @0,
                @"names": @[@"Spotify green", @"Teal", @"Blue", @"Indigo", @"Purple", @"Pink",
                            @"Red", @"Amber"],
            },
            @(EeveeHomeChoiceStrength): @{
                @"key": @"EeveeSpotify.homeGradientStrength",
                @"default": @1,
                @"names": @[@"Subtle", @"Medium", @"Bold"],
            },
            @(EeveeHomeChoiceHeight): @{
                @"key": @"EeveeSpotify.homeGradientHeight",
                @"default": @1,
                @"names": @[@"Short", @"Medium", @"Tall", @"The whole screen"],
            },
        };
    });
    return table[@(choice)] ?: table[@(EeveeHomeChoiceTint)];
}

NSArray<NSString *> *EeveeHomeChoiceNames(EeveeHomeChoice choice) {
    return choiceDef(choice)[@"names"];
}

NSString *EeveeHomeChoiceKey(EeveeHomeChoice choice) {
    return choiceDef(choice)[@"key"];
}

NSInteger EeveeHomeChoiceDefault(EeveeHomeChoice choice) {
    return [choiceDef(choice)[@"default"] integerValue];
}

NSInteger EeveeHomeChoiceValue(EeveeHomeChoice choice) {
    NSDictionary *def = choiceDef(choice);
    NSInteger fallback = [def[@"default"] integerValue];
    NSInteger index = EeveeInt(def[@"key"], fallback);
    return index >= 0 && index < (NSInteger)[def[@"names"] count] ? index : fallback;
}
