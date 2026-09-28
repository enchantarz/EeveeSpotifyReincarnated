#import <CoreText/SFNTLayoutTypes.h>
#import "Core/EeveeCore.h"
#import "EeveeRTokens.h"
#import "EeveeRAccent.h"

const CGFloat EeveeRSideMargin = 16;
const CGFloat EeveeRGrid = 8;
const CGFloat EeveeRRadiusArtwork = 12;
const CGFloat EeveeRRadiusCard = 16;
const CGFloat EeveeRRadiusCover = 8;
const CGFloat EeveeRRadiusThumb = 6;
const CGFloat EeveeRGlassCircleSize = 44;
const CGFloat EeveeRActionHeight = 48;
const CGFloat EeveeRActionSpacing = 12;
const CGFloat EeveeRGlassSpacing = 16;
const NSTimeInterval EeveeRCrossfade = 0.35;

// A layout spring settles in about this long without overshooting; a press gives a little back.
static const NSTimeInterval kLayoutDuration = 0.45, kPressDuration = 0.32;
static const CGFloat kPressDamping = 0.62;

UIColor *EeveeRPrimary(void) {
    return UIColor.whiteColor;
}

UIColor *EeveeRSecondary(void) {
    return [UIColor colorWithWhite:1 alpha:EeveeRIncreaseContrast() ? 0.80 : 0.65];
}

UIColor *EeveeRTertiary(void) {
    return [UIColor colorWithWhite:1 alpha:EeveeRIncreaseContrast() ? 0.60 : 0.40];
}

// Read per call: the accent is stored as it is picked, and the colour row reads it the same way.
UIColor *EeveeRAccent(void) {
    return EeveeRAccentColor() ?: [UIColor colorWithRed:0x1E / 255.0 green:0xD7 / 255.0 blue:0x60 / 255.0 alpha:1];
}

UIColor *EeveeRNeutralField(void) {
    return [UIColor colorWithRed:0x12 / 255.0 green:0x12 / 255.0 blue:0x12 / 255.0 alpha:1];
}

UIColor *EeveeRSolidGlassFill(void) {
    return [UIColor colorWithWhite:1 alpha:0.16];
}

UIColor *EeveeRHairline(void) {
    return [UIColor colorWithWhite:1 alpha:EeveeRIncreaseContrast() ? 0.20 : 0.12];
}

UIColor *EeveeRElevated(UIColor *field) {
    CGFloat r = 0, g = 0, b = 0, a = 1;
    if (![field getRed:&r green:&g blue:&b alpha:&a]) return [UIColor colorWithWhite:1 alpha:0.08];
    // 12% towards white keeps a card on a black field clear of the greys EeveeRAmoled.x turns black.
    CGFloat lift = 0.12;
    return [UIColor colorWithRed:r + (1 - r) * lift green:g + (1 - g) * lift blue:b + (1 - b) * lift alpha:1];
}

UIFont *EeveeRFont(UIFontTextStyle style, UIFontWeight weight, UIContentSizeCategory largest) {
    UIContentSizeCategory current = UIApplication.sharedApplication.preferredContentSizeCategory;
    if (largest && UIContentSizeCategoryCompareToCategory(current, largest) == NSOrderedDescending) current = largest;
    UITraitCollection *traits = [UITraitCollection traitCollectionWithPreferredContentSizeCategory:current];
    CGFloat size = [UIFont preferredFontForTextStyle:style compatibleWithTraitCollection:traits].pointSize;
    return [UIFont systemFontOfSize:size weight:weight];
}

UIFont *EeveeRMonospacedDigitsFont(UIFont *font) {
    if (!font) return nil;
    NSArray *features = @[@{UIFontFeatureTypeIdentifierKey: @(kNumberSpacingType), UIFontFeatureSelectorIdentifierKey: @(kMonospacedNumbersSelector)}];
    UIFontDescriptor *descriptor = [font.fontDescriptor fontDescriptorByAddingAttributes:@{UIFontDescriptorFeatureSettingsAttribute: features}];
    return [UIFont fontWithDescriptor:descriptor size:font.pointSize];
}

BOOL EeveeRReduceMotion(void) {
    return UIAccessibilityIsReduceMotionEnabled();
}

BOOL EeveeRReduceTransparency(void) {
    return UIAccessibilityIsReduceTransparencyEnabled();
}

BOOL EeveeRIncreaseContrast(void) {
    return UIAccessibilityDarkerSystemColorsEnabled();
}

void EeveeRAnimate(EeveeRMotion motion, void (^animations)(void), void (^completion)(BOOL finished)) {
    if (!animations) return;
    if (motion != EeveeRMotionFade && EeveeRReduceMotion()) {
        [UIView performWithoutAnimation:animations];
        if (completion) completion(YES);
        return;
    }
    UIViewAnimationOptions options = UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState;
    switch (motion) {
        case EeveeRMotionLayout:
            [UIView animateWithDuration:kLayoutDuration delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:options animations:animations completion:completion];
            break;
        case EeveeRMotionPress:
            [UIView animateWithDuration:kPressDuration delay:0 usingSpringWithDamping:kPressDamping initialSpringVelocity:0 options:options animations:animations completion:completion];
            break;
        case EeveeRMotionFade:
            [UIView animateWithDuration:EeveeRCrossfade delay:0 options:options | UIViewAnimationOptionCurveEaseInOut animations:animations completion:completion];
            break;
    }
}
