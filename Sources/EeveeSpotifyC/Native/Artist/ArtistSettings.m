#import "Core/EeveeCore.h"
#import "Settings/EeveeModPage.h"
#import "Artist.h"

UIViewController *EeveeArtistSettingsPage(void) {
    NSArray<EeveeModSection *> *sections = @[
        EeveeSection(@"Photo", @[
            EeveeOptionRow(@"Fade into a blur", nil, EeveeKeyArtistPhotoFade),
        ]),
        EeveeSection(@"Hide in the header", @[
            EeveeHideRow(@"Explore (video deck)", nil, EeveeHideArtistExplore),
            EeveeHideRow(@"Follow", nil, EeveeHideArtistFollow),
            EeveeHideRow(@"More options", nil, EeveeHideArtistMore),
            EeveeHideRow(@"Shuffle", nil, EeveeHideArtistShuffle),
            EeveeHideRow(@"Verified badge", nil, EeveeHideArtistVerified),
            EeveeHideRow(@"Monthly listeners", nil, EeveeHideArtistListeners),
        ]),
        EeveeSection(@"Tabs", @[
            EeveeHideRow(@"Hide the tab bar", nil, EeveeHideArtistTabBar),
        ]),
        EeveeNotedSection(@"Hide on the page", @[
            EeveeHideRow(@"Songs you liked", nil, EeveeHideArtistLikedSongs),
            EeveeHideRow(@"Popular", nil, EeveeHideArtistPopular),
            EeveeHideRow(@"Artist pick", nil, EeveeHideArtistPick),
            EeveeHideRow(@"Popular releases", nil, EeveeHideArtistReleases),
            EeveeHideRow(@"Featuring", nil, EeveeHideArtistFeaturing),
            EeveeHideRow(@"Music videos", nil, EeveeHideArtistVideos),
            EeveeHideRow(@"About", nil, EeveeHideArtistAbout),
            EeveeHideRow(@"Artist playlists", nil, EeveeHideArtistPlaylists),
            EeveeHideRow(@"Fans also like", nil, EeveeHideArtistFansAlsoLike),
            EeveeHideRow(@"Appears on", nil, EeveeHideArtistAppearsOn),
            EeveeHideRow(@"Discovered on", nil, EeveeHideArtistDiscoveredOn),
        ], @"Works only with Spotify in English."),
        EeveeSection(@"Spotify's own", @[
            EeveeFlagRow(@"Share button in the header", @"ios-creator-impl.share_in_action_row_enabled_artist"),
            EeveeFlagRow(@"More options in the navigation bar", @"ios-creator-impl.context_menu_in_navigation_bar_enabled_artist"),
            EeveeFlagRow(@"Top collaborators", @"ios-creator-impl.is_top_collaborators_enabled"),
            EeveeFlagRow(@"Artist facts", @"ios-creator-impl.is_artist_facts_enabled"),
        ]),
    ];
    return [[EeveeModPage alloc] initWithTitle:@"Artist" intro:nil sections:sections footer:nil];
}
