// Album: parts of the album page hidden one switch each, and the cover behind its header (Album.x).
// An unset switch is off.
#import <UIKit/UIKit.h>

#define EeveeKeyAlbumBackdrop @"EeveeSpotify.albumBackdrop"

#define EeveeHideAlbumExplore @"EeveeSpotify.hide.albumExplore"
#define EeveeHideAlbumAddTo @"EeveeSpotify.hide.albumAddTo"
#define EeveeHideAlbumDownload @"EeveeSpotify.hide.albumDownload"
#define EeveeHideAlbumMore @"EeveeSpotify.hide.albumMore"

#define EeveeHideAlbumMoreBy @"EeveeSpotify.hide.albumMoreBy"
#define EeveeHideAlbumVideos @"EeveeSpotify.hide.albumVideos"
#define EeveeHideAlbumConcerts @"EeveeSpotify.hide.albumConcerts"
#define EeveeHideAlbumMerch @"EeveeSpotify.hide.albumMerch"
#define EeveeHideAlbumYouMightLike @"EeveeSpotify.hide.albumYouMightLike"

UIViewController *EeveeAlbumSettingsPage(void);   // opened from the Home & Library page
