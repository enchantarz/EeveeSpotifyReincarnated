// About: what the build points its user at, and whether the now playing card on the lock screen can
// open it (Signing.m).
//
// spoti.pw's update check (Update.m, UpdatePage.m and UpdateNotice.m) and the install-counting body
// it posted (Usage.m) were dropped in the merge: no version endpoint, no newer-release sheet, no
// telemetry. EeveeSpotify's own version view is the one thing that reports where the build stands.
#import <UIKit/UIKit.h>
#import "Settings/EeveeModPage.h"

// Whether the now playing card on the lock screen can open this build. It depends on the signature,
// not on the mod: iOS launches by the App ID of the application-identifier entitlement, so a build
// whose bundle id is not that App ID cannot be opened from the card. Signing.m says so once.
extern NSString *const EeveeSigningHelpURL;
NSString *EeveeSigningAppIdentifier(void);      // App ID without the team prefix, nil if unreadable
BOOL EeveeSigningOpensFromLockScreen(void);     // YES when unreadable, so a build that works stays quiet
EeveeModRow *EeveeSigningWarningRow(void);          // nil while the signature is sound
void EeveeCheckSigningOnce(void);
void EeveeShowSigningFixIfPending(void);   // the sheet the tour held back, if any

// Backup.m: the settings out to a JSON file through the share sheet, and back in from one, replacing
// what is set and restarting.
void EeveeExportSettings(void);
void EeveeImportSettings(void);

UIViewController *EeveeAboutPage(void);   // the Mod page
