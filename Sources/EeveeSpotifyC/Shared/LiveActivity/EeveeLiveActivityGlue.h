// What LiveActivity.x used to reach in spoti.pw's Shared/Lyrics*, reduced to the two things that are
// not lyrics: the player and its clock.
//
// Those files were removed in the merge, so the synced line has nowhere to come from yet and
// EeveeLiveActivityLyricsLine answers nothing; the activity's Lyrics view falls back to the ♪
// placeholder it already draws before the first line and between lines. The Queue and Control menu
// views only ever needed the player, so those work exactly as they did.
//
// The line is the one thing left to wire, and this is where it goes: EeveeSpotify's lyrics engine
// (Sources/EeveeSpotify/Lyrics) holds timed lines for the playing track but exposes no "which line
// is being sung at position N", so it needs one before this can answer.
//
// What the removed engine also carried, and belongs with that work: which line is being sung and
// which comes next, the two voices of a duet (the first in, the one over it as the next), and the
// 4s gap past a line's sung end after which the card shows its \u266a rather than a line nobody is
// singing. Timing was per line and per word, so a line timed only by the line has to be treated as
// already over at its end rather than swept.
#import <Foundation/Foundation.h>
#import "Headers/SPTPlayer.h"

// The first player the app handed to PlayerState.x, which is the app's own; nil before it has.
id<SPTPlayer> EeveeLiveActivityPlayer(void);
// The playing track's URI as a string, nil when nothing is playing.
NSString *EeveeLiveActivityPlayingTrack(void);
// Playback position in milliseconds from the start of the track, -1 when unknown. Spotify reports
// SPTPlayerState.position in the same unit the timed lyrics use, which is why the card can compare
// the two, and why the sleep-timer check can compare it against a duration in seconds times 1000.
NSInteger EeveeLiveActivityPositionMs(void);

// The line being sung and the one after it; `next` is always written. Both are empty until the line
// is wired to EeveeSpotify's engine, which is what makes the Lyrics view show its placeholder.
NSString *EeveeLiveActivityLyricsLine(NSString *trackURI, NSString **next);
