#import "Core/EeveeCore.h"
#import "Settings/EeveeModPage.h"
#import "Album.h"

UIViewController *EeveeAlbumSettingsPage(void) {
    NSArray<EeveeModSection *> *sections = @[
        EeveeSection(@"Header", @[
            EeveeOptionRow(@"Artwork background", nil, EeveeKeyAlbumBackdrop),
        ]),
        EeveeSection(@"Hide in the header", @[
            EeveeHideRow(@"Explore (video deck)", nil, EeveeHideAlbumExplore),
            EeveeHideRow(@"Add to library", nil, EeveeHideAlbumAddTo),
            EeveeHideRow(@"Download", nil, EeveeHideAlbumDownload),
            EeveeHideRow(@"More options", nil, EeveeHideAlbumMore),
        ]),
        EeveeNotedSection(@"Hide on the page", @[
            EeveeHideRow(@"More by the artist", nil, EeveeHideAlbumMoreBy),
            EeveeHideRow(@"Related music videos", nil, EeveeHideAlbumVideos),
            EeveeHideRow(@"Concerts", nil, EeveeHideAlbumConcerts),
            EeveeHideRow(@"Merch", nil, EeveeHideAlbumMerch),
            EeveeHideRow(@"You might also like", nil, EeveeHideAlbumYouMightLike),
        ], @"Works only with Spotify in English."),
    ];
    return [[EeveeModPage alloc] initWithTitle:@"Album" intro:nil sections:sections footer:nil];
}
