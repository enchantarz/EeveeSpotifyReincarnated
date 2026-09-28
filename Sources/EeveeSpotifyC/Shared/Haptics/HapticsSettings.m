// The Vibrations sections of the Player page, under either look (App/Pages.m puts them there): a card
// per switch, the way the Audio effects page has one per effect, each opening out into its settings while
// its switch is on. Controls has its strength; Music Haptics its strength and what it follows, a choice
// that also says whether the rumble plays, rather than a switch of its own that one choice would leave
// with nothing to do.
#import "Core/EeveeCore.h"
#import "Settings/EeveeModPage.h"
#import "Haptics.h"

static NSString *const kMusicHapticsInfo = @"The iPhone taps along with the drums and rumbles under the bass of whatever Spotify is playing, worked out from the sound as it plays, much like Music Haptics in Apple Music.\n\nIt follows the sound this iPhone plays, through its speaker or headphones, while Spotify is open: iOS plays no haptics for an app in the background, and a song playing on another device through Connect has no sound here to follow.";

static NSArray<NSString *> *followsNames(void) {
    return @[@"Everything", @"Beat", @"Bass"];
}

static NSArray<NSString *> *followsNotes(void) {
    return @[@"A tap on each kick and snare, and a rumble under the bass",
             @"A tap on each kick and snare, no rumble",
             @"A tap on each kick, and a rumble under the bass"];
}

static void strengthRange(NSString *key, NSInteger *minimum, NSInteger *maximum) {
    BOOL music = [key isEqualToString:EeveeKeyMusicStrength];
    *minimum = music ? EeveeMusicStrengthMin : EeveeControlStrengthMin;
    *maximum = music ? EeveeMusicStrengthMax : EeveeControlStrengthMax;
}

double EeveeHapticsStrength(NSString *key) {
    NSInteger minimum, maximum;
    strengthRange(key, &minimum, &maximum);
    return MAX(minimum, MIN(maximum, EeveeInt(key, 100))) / 100.0;
}

EeveeMusicFollows EeveeMusicHapticsFollows(void) {
    NSInteger follows = EeveeInt(EeveeKeyMusicFollows, EeveeMusicFollowsEverything);
    return follows >= EeveeMusicFollowsEverything && follows <= EeveeMusicFollowsBass ? (EeveeMusicFollows)follows : EeveeMusicFollowsEverything;
}

// A percentage slider over a strength key, telling `changed` each step it stores.
static EeveeModRow *strengthRow(NSString *key, void (^changed)(void)) {
    NSInteger minimum, maximum;
    strengthRange(key, &minimum, &maximum);
    return EeveeSliderRow(@"Strength", nil, minimum, maximum, EeveeStrengthStep,
        ^double { return EeveeHapticsStrength(key) * 100; },
        ^(double value) {
            EeveeSetInt(key, lround(value));
            if (changed) changed();
        },
        ^NSString *(double value) { return [NSString stringWithFormat:@"%ld%%", lround(value)]; });
}

NSArray<EeveeModSection *> *EeveeVibrationsSections(void) {
    EeveeModRow *controls = EeveeSwitchRow(@"Controls", nil, EeveeKeyControlHaptics);
    EeveeModRow *controlStrength = strengthRow(EeveeKeyControlStrength, ^{
        // Felt as it is set: a tap at the new strength with each step.
        EeveePlayFeedback(EeveeFeedbackAdd);
    });
    controlStrength.visible = ^BOOL { return EeveeEnabled(EeveeKeyControlHaptics); };

    EeveeModRow *music = EeveeOptionRow(@"Music Haptics", nil, EeveeKeyMusicHaptics);
    music.info = kMusicHapticsInfo;
    music.changed = ^(BOOL on) { EeveeSetMusicHapticsEnabled(on); };
    BOOL (^musicOn)(void) = ^BOOL { return EeveeFlag(EeveeKeyMusicHaptics, NO); };
    EeveeModRow *musicStrength = strengthRow(EeveeKeyMusicStrength, ^{ EeveeMusicHapticsSettingsChanged(); });
    musicStrength.visible = musicOn;
    EeveeModRow *follows = EeveeChoiceRow(@"Follows", nil, EeveeKeyMusicFollows, followsNames(), EeveeMusicFollowsEverything);
    follows.choiceNotes = followsNotes();
    follows.chosen = ^(NSInteger index) { EeveeMusicHapticsSettingsChanged(); };
    follows.visible = musicOn;

    return @[
        EeveeSection(@"Vibrations", @[EeveeWithSymbol(controls, @"hand.tap"), controlStrength]),
        EeveeSection(nil, @[EeveeWithSymbol(music, @"waveform"), musicStrength, follows]),
    ];
}
