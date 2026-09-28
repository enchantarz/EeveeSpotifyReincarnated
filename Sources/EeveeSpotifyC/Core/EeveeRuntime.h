// Private UIKit the SDK does not declare.
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface UIView (EeveePrivate)
- (NSString *)recursiveDescription;
@end

@interface UIViewController (EeveePrivate)
- (NSString *)_printHierarchy;
@end
