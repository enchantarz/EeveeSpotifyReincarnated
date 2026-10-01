// Vibrations (Mod Settings > Player > Vibrations), under either look: the Taptic Engine answering
// what a finger does to playback (Controls), and playing along with the music (Music Haptics).
//
//     EeveeFeedback.m         which tap each kind of control gets, played while Controls is on
//     ControlHaptics.x     the player's and the now playing bar's controls, the scrubber, the cover swipes, the gestures
//     MusicHaptics.x       Spotify's audio output listened to, and Core Haptics played along with it
//     EeveeMusicAnalyzer.m    the listening: taps and a rumble out of the samples
//     HapticsSettings.m    the Vibrations cards, with each switch's strength and what Music Haptics follows
//
// Everything on them applies at once, without a restart. Everything hooked is Spotify's own (its controls
// by accessibility identifier, its scrubber, its cover and title lists, its audio unit), so all of it
// works on Spotify's own screens.
// Threading: main thread only.
#import <UIKit/UIKit.h>

#define EeveeKeyControlHaptics @"EeveeSpotify.haptics.controls"
#define EeveeKeyMusicHaptics @"EeveeSpotify.haptics.music"
// How hard the taps are, a percentage within the range below; 100 is the feel each shipped with.
#define EeveeKeyControlStrength @"EeveeSpotify.haptics.controls.strength"
#define EeveeKeyMusicStrength @"EeveeSpotify.haptics.music.strength"
// What Music Haptics plays along with, an EeveeMusicFollows.
#define EeveeKeyMusicFollows @"EeveeSpotify.haptics.music.follows"
// What the keys were called while this was the redesign's alone; the %ctors move them over.
#define EeveeKeyControlHapticsWas @"EeveeSpotify.redesign.haptics.controls"
#define EeveeKeyMusicHapticsWas @"EeveeSpotify.redesign.haptics.music"
#define EeveeKeyControlStrengthWas @"EeveeSpotify.redesign.haptics.controls.strength"
#define EeveeKeyMusicStrengthWas @"EeveeSpotify.redesign.haptics.music.strength"
#define EeveeKeyMusicFollowsWas @"EeveeSpotify.redesign.haptics.music.follows"

// Controls go softer only: most of their taps are UIKit's at full intensity already. Music Haptics goes
// either way: at 200% the rumble reaches 0.7 of the Taptic Engine's most, and most taps their most.
enum {
    EeveeControlStrengthMin = 10, EeveeControlStrengthMax = 100,
    EeveeMusicStrengthMin = 20, EeveeMusicStrengthMax = 200,
    EeveeStrengthStep = 10,
};

typedef NS_ENUM(NSInteger, EeveeMusicFollows) {
    EeveeMusicFollowsEverything,   // a tap on each kick and snare, and the rumble under the bass
    EeveeMusicFollowsBeat,         // a tap on each kick and snare, no rumble
    EeveeMusicFollowsBass,         // a tap on each kick, and the rumble
};

typedef NS_ENUM(NSInteger, EeveeFeedback) {
    EeveeFeedbackPlay,      // playback starts
    EeveeFeedbackPause,     // playback stops
    EeveeFeedbackSkip,      // previous, next, a jump in the song (a double tap, a lyric line)
    EeveeFeedbackToggle,    // shuffle, repeat
    EeveeFeedbackAdd,       // the add button: liked songs, a playlist
    EeveeFeedbackGrab,      // a finger takes the scrubber
    EeveeFeedbackDetent,    // the scrubber passing a tenth of the song, a cover swipe passing halfway
    EeveeFeedbackEdge,      // the scrubber reaching the start or the end
    EeveeFeedbackRelease,   // the scrubber let go
};

// Plays `feedback` while Controls is on.
void EeveePlayFeedback(EeveeFeedback feedback);
// Wakes the Taptic Engine for feedback about to follow quickly (a finger on the scrubber).
void EeveePrepareFeedback(EeveeFeedback feedback);

// From the Music Haptics switch: starts or stops listening at once.
void EeveeSetMusicHapticsEnabled(BOOL on);
// From its strength and its choice of what to follow: reads them again, for the next tap.
void EeveeMusicHapticsSettingsChanged(void);

// A strength key's percentage as a factor, 1 for 100%, kept within its range.
double EeveeHapticsStrength(NSString *key);
EeveeMusicFollows EeveeMusicHapticsFollows(void);

@class EeveeModSection;
// The Vibrations sections of the Player page: a card for Controls and one for Music Haptics, each opening
// out into its settings while its switch is on.
NSArray<EeveeModSection *> *EeveeVibrationsSections(void);
