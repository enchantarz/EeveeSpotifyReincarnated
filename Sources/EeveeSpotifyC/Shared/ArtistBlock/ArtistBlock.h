// Artist block: tracks by artists on the list are skipped as they come up (ArtistSkip.x). An artist
// is kept by URI, with the name it had when it was blocked, so a rename or a namesake changes nothing.
#import <UIKit/UIKit.h>

#define EeveeKeyArtistBlock @"EeveeSpotify.artistBlock"
#define EeveeKeyArtistBlockFeatured @"EeveeSpotify.artistBlock.featured"   // off: the main artist only
#define EeveeKeyArtistBlockList @"EeveeSpotify.artistBlock.list"

extern NSString *const EeveeArtistURI;    // NSString, spotify:artist:…
extern NSString *const EeveeArtistName;   // NSString

NSArray<NSDictionary *> *EeveeBlockedArtists(void);
void EeveeBlockArtist(NSDictionary *artist);
void EeveeUnblockArtist(NSString *uri);
BOOL EeveeArtistBlocked(NSString *uri);

// The artists of a track, the main one first, as dictionaries of the keys above.
NSArray<NSDictionary *> *EeveeArtistsOfTrack(id track);
// ArtistSkip.x: the artists of the track playing now, empty before the player has reported one.
NSArray<NSDictionary *> *EeveePlayingArtists(void);

UIViewController *EeveeArtistBlockSettingsPage(void);
