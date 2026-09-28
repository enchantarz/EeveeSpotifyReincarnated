// The native look's player: Spotify's full screen player with the artwork background and glass header
// buttons (Player.x), the gestures' hookup (PlayerGestures.x) and the parts of it to hide
// (PlayerDeclutter.x). spoti.pw's glass lyrics card and lyrics page, and the key they shared, were
// dropped in the merge along with its lyrics engine.
#import <UIKit/UIKit.h>

#define EeveeKeyPlayer @"EeveeSpotify.player"
#define EeveeKeyPlayerBackdrop @"EeveeSpotify.playerBackdrop"

// Parts of the player to hide, one switch each (PlayerDeclutter.x). An unset switch is off.
#define EeveeHideShuffle @"EeveeSpotify.hide.shuffle"
#define EeveeHideRepeat @"EeveeSpotify.hide.repeat"
#define EeveeHideConnect @"EeveeSpotify.hide.connect"
#define EeveeHideShare @"EeveeSpotify.hide.share"
#define EeveeHideQueue @"EeveeSpotify.hide.queue"
#define EeveeHideAddTo @"EeveeSpotify.hide.addTo"
#define EeveeHideLyricsInline @"EeveeSpotify.hide.lyricsInline"
#define EeveeHideLyricsCard @"EeveeSpotify.hide.lyricsCard"
#define EeveeHideAboutArtist @"EeveeSpotify.hide.aboutArtist"
#define EeveeHideRelatedVideos @"EeveeSpotify.hide.relatedVideos"
#define EeveeHideSongDNA @"EeveeSpotify.hide.songDNA"
#define EeveeHideLiveEvents @"EeveeSpotify.hide.liveEvents"
#define EeveeHideExploreArtist @"EeveeSpotify.hide.exploreArtist"
#define EeveeHideCredits @"EeveeSpotify.hide.credits"
#define EeveeHideMerch @"EeveeSpotify.hide.merch"
#define EeveeHideRecommendations @"EeveeSpotify.hide.recommendations"

// The welcome tour's one switch for the player: on hides every card under the player, off shows them
// again. The player's buttons are not its business. Only the tour reads it; the hooks read the keys
// above.
#define EeveeKeyPlayerLyricsOnly @"EeveeSpotify.hide.playerCardsOnly"
void EeveeSetPlayerLyricsOnly(BOOL on);

@class EeveeModRow, EeveeModSection;
// PlayerSettings.m: the player screen's sections of the Player page and the Queue & devices page.
NSArray<EeveeModSection *> *EeveeNativePlayerScreenSections(void);
UIViewController *EeveeQueueSettingsPage(void);
EeveeModRow *EeveeGlassLyricsRow(void);
