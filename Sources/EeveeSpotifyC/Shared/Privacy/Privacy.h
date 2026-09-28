// Privacy: telemetry blocking (Privacy.x), an NSURLProtocol that answers the analytics endpoints
// itself and counts what it stopped. On unless switched off.
#import <UIKit/UIKit.h>

#define EeveeKeyBlockTelemetry @"EeveeSpotify.blockTelemetry"

// The destinations it knows in the order it lists them, and how many requests to one of them it
// has answered instead of letting out (nil label for all of them).
NSArray<NSString *> *EeveeBlockedLabels(void);
NSUInteger EeveeBlockedCount(NSString *label);
void EeveeResetBlocked(void);

@class EeveeModSection;
// The telemetry switch and what it has stopped, on the Premium, ads & privacy page.
EeveeModSection *EeveePrivacySection(void);
EeveeModSection *EeveePrivacyCountersSection(void);
