// Screen dumps for FLEX builds: the visible screen's view tree, served over the phone's loopback
// and logged when the app goes to the background.
#import <Foundation/Foundation.h>

BOOL EeveeIsDebugBuild(void);
NSString *EeveeScreenTree(void);
void EeveeDumpScreen(NSString *reason);
