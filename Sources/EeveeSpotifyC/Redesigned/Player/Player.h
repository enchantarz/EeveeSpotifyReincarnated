// The player redesign (screen key "player"): Spotify's full screen player kept, with its controller,
// units, controls and card list, and restyled from the Kit. Every control stays Spotify's own, so its
// action, state and accessibility do too; the redesign adds the artwork field behind it, glass behind
// the header buttons, bare glyphs for previous, play and next, and one screen with nothing under it:
// every card is collapsed and the player does not scroll.
//
//     PlayerField.x      the switch's flags and rows, the field in the background plane, the cover it reads
//     PlayerArtwork.x    the cover's corners, shadow and paused shrink, the lyric preview under it hidden
//     PlayerHeader.x     glass behind the close and more buttons
//     PlayerControls.x   previous, play and next as bare glyphs, monospaced times
//     PlayerFooter.x     share gone, lyrics, Connect and queue as one row of three glyphs
//     PlayerCards.x      every card under the player collapsed, so the list closes up
//     PlayerScroll.x     the list pinned to the top, so the player is one screen and cannot be scrolled
//     PlayerGestures.x   the gestures' hookup
//     PlayerMorph.x      the open and close grown out of the now playing bar's card, the cover flown
//
// Speed and pitch, once the redesign's own, are Shared/Player/SpeedPitch.h's; PlayerHeader.x still hands
// the more button over, so a menu opened from it is taken for the player's.
//
// Every hook installs only while Redesigned UI is on (EeveeRedesignedUI); the native look's do not then.
// Threading: main thread only.
#import <UIKit/UIKit.h>

@class EeveeRArtworkField;

// The artwork's colours moving behind the player (on until switched off), or the blurred artwork held
// still; the row is on the Now playing page (Redesigned/NowPlayingBar/NowPlayingBarSettings.m).
#define EeveeRKeyPlayerMotion @"EeveeSpotify.redesign.player.movingBackground"

// The field behind the player, nil until the player has laid out once (PlayerField.x).
EeveeRArtworkField *EeveeRPlayerField(void);

#pragma mark - the cover (PlayerArtwork.x)

// The sideways list of covers behind the player, nil until one has laid out.
UIView *EeveeRPlayerCoverList(void);
// The cover on screen as it is drawn, its paused shrink included, in `host`'s coordinates; CGRectNull
// when no cover has laid out.
CGRect EeveeRPlayerCoverFrameIn(UIView *host);
// The band that cover sits in -- the room the player gives its artwork, between the header row and the
// title -- in `host`'s coordinates; CGRectNull when no cover has laid out.
CGRect EeveeRPlayerArtworkAreaIn(UIView *host);
// Hides the cover on screen and its shadow, or shows them again, for a stand-in to fly in its place
// (PlayerMorph.x).
void EeveeRPlayerSetCoverHidden(BOOL hidden);

// spoti.pw's lyrics in the player (PlayerLyrics.x), and the footer glyph that opened them, were
// dropped in the merge along with its lyrics engine.

// Alpha 0, no touches, hidden from accessibility, set again on every call: for Spotify's Swift views,
// which EeveeRSuppress cannot keep (PlayerControls.x).
void EeveeRPlayerVanish(UIView *view);
