#import "Settings/EeveeModPage.h"
#import "Playlist.h"

UIViewController *EeveePlaylistSettingsPage(void) {
    return [[EeveeModPage alloc] initWithTitle:@"Playlists" intro:nil sections:@[
        EeveeSection(@"Header", @[
            EeveeOptionRow(@"Artwork background", nil, EeveeKeyPlaylistBackdrop),
        ]),
        EeveeSection(@"Hide in the playlist header", @[
            EeveeHideRow(@"Cover artwork", nil, EeveeHidePlaylistArtwork),
            EeveeHideRow(@"Description", nil, EeveeHidePlaylistDescription),
            EeveeHideRow(@"Creator and collaborators", nil, EeveeHidePlaylistCreator),
            EeveeHideRow(@"Length and saves", nil, EeveeHidePlaylistLength),
        ]),
        EeveeSection(@"Hide playlist buttons", @[
            EeveeHideRow(@"Video", nil, EeveeHidePlaylistVideo),
            EeveeHideRow(@"Add to library", nil, EeveeHidePlaylistAddTo),
            EeveeHideRow(@"Download", nil, EeveeHidePlaylistDownload),
            EeveeHideRow(@"Share", nil, EeveeHidePlaylistShare),
            EeveeHideRow(@"More", nil, EeveeHidePlaylistMore),
        ]),
        EeveeSection(@"Hide above the tracks", @[
            EeveeHideRow(@"Curation pills", nil, EeveeHidePlaylistPills),
            EeveeHideRow(@"Find and sort bar", nil, EeveeHidePlaylistFind),
        ]),
    ] footer:nil];
}
