// The native player's settings: Spotify's own player screen and the parts of it to hide, and the queue
// and devices flags. The Player page that holds them is App/Pages.m's.
#import "Core/EeveeCore.h"
#import "Settings/EeveeModPage.h"
#import "NowPlaying.h"

NSArray<EeveeModSection *> *EeveeNativePlayerScreenSections(void) {
    return @[
        EeveeSection(@"Player screen", @[
            EeveeOptionRow(@"Artwork background", nil, EeveeKeyPlayerBackdrop),
            EeveeOptionRow(@"Glass header buttons", nil, EeveeKeyPlayer),
            EeveeKillRow(@"Disable Canvas", @"ios-feature-canvas.canvas_enabled"),
            EeveeFlagRow(@"Sheet style player", @"ios-feature-nowplaying.sheet_style_npv"),
            EeveeFlagRow(@"Redesigned header", @"ios-feature-nowplaying.new_redesign_header_with_context_menu_enabled"),
            EeveeFlagRow(@"New progress slider", @"ios-feature-encoreexperiments.new_npv_slider_enabled"),
            EeveeFlagRow(@"Expand the sticky header on tap", @"ios-feature-nowplaying.expand_sticky_header_on_tap"),
        ]),
        EeveeSection(@"Hide cards below the player", @[
            EeveeHideRow(@"Lyrics", nil, EeveeHideLyricsCard),
            EeveeHideRow(@"About the artist", nil, EeveeHideAboutArtist),
            EeveeHideRow(@"Related videos", nil, EeveeHideRelatedVideos),
            EeveeHideRow(@"SongDNA", nil, EeveeHideSongDNA),
            EeveeHideRow(@"Live events", nil, EeveeHideLiveEvents),
            EeveeHideRow(@"Explore the artist", nil, EeveeHideExploreArtist),
            EeveeHideRow(@"Credits", nil, EeveeHideCredits),
            EeveeHideRow(@"Merch", nil, EeveeHideMerch),
            EeveeHideRow(@"Recommendations", nil, EeveeHideRecommendations),
        ]),
        EeveeSection(@"Hide on the player", @[
            EeveeHideRow(@"Lyrics preview", nil, EeveeHideLyricsInline),
            EeveeHideRow(@"Shuffle", nil, EeveeHideShuffle),
            EeveeHideRow(@"Repeat", nil, EeveeHideRepeat),
            EeveeHideRow(@"Add to playlist", nil, EeveeHideAddTo),
            EeveeHideRow(@"Queue", nil, EeveeHideQueue),
            EeveeHideRow(@"Share", nil, EeveeHideShare),
            EeveeHideRow(@"Connect to a device", nil, EeveeHideConnect),
        ]),
    ];
}

UIViewController *EeveeQueueSettingsPage(void) {
    return [[EeveeModPage alloc] initWithTitle:@"Queue & devices" intro:EeveeRestartNote sections:@[
        EeveeSection(@"Bottom sheets", @[
            EeveeFlagRow(@"Queue as a bottom sheet", @"ios-feature-nowplaying.bottom_sheet_queue_enabled"),
            EeveeFlagRow(@"Connect as a bottom sheet", @"ios-feature-nowplaying-elements.enable_connect_bottom_sheet"),
            EeveeFlagRow(@"Connect sheet from the video switcher", @"ios-playbackcontrol-audiovideoswitcher-impl.enable_connect_bottom_sheet"),
        ]),
        EeveeSection(@"Queue", @[
            EeveeFlagRow(@"Queue flip transition", @"ios-feature-nowplaying.queue_flip_transition_enabled"),
            EeveeFlagRow(@"Play next in the context menu", @"ios-feature-queue.is_play_next_context_menu_enabled"),
        ]),
    ] footer:nil];
}
