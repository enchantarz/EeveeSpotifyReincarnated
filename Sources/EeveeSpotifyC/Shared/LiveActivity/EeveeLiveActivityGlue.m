#import "EeveeLiveActivityGlue.h"
#import "Core/EeveeCore.h"
#import "Shared/Player/PlayerState.h"

id<SPTPlayer> EeveeLiveActivityPlayer(void) {
    return EeveePlayerInstance();
}

NSString *EeveeLiveActivityPlayingTrack(void) {
    SPTPlayerState *state = EeveePlayerState();
    SPTPlayerTrack *track = state.track;
    return track ? EeveeURIString(track.URI) : nil;
}

NSInteger EeveeLiveActivityPositionMs(void) {
    SPTPlayerState *state = EeveePlayerState();
    if (!state) return -1;
    return (NSInteger)state.position;
}

NSString *EeveeLiveActivityLyricsLine(NSString *trackURI, NSString **next) {
    // Deliberately empty: spoti.pw's lyrics engine, which answered this, was removed in the merge.
    // See the header for what belongs here — the timed line EeveeSpotify's own engine is singing.
    // The track is named so a reader of the log can tell "no lyrics engine wired" from "no track".
    if (next) *next = @"";
    (void)trackURI;
    return @"";
}
