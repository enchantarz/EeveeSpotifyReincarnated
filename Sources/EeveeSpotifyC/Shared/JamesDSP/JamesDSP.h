// JamesDSP on Spotify's sound: the effects engine of JamesDSP Manager, RootlessJamesDSP and JamesDSP for
// Linux (libjamesdsp, vendor/libjamesdsp), run on every buffer Spotify's output unit finishes, before the
// speaker. Either look: it draws nothing on Spotify's screens. Mod Settings > Audio effects is its page.
//
// What it offers is RootlessJamesDSP's list: output gain and limiter, dynamic range compressor, dynamic bass
// boost, the 15 band multimodal equalizer, the arbitrary response (graphic) equalizer, the convolver
// (impulse responses), ViPER DDC, Liveprog (EEL scripts), reverb, stereo widening, crossfeed and analog
// modelling. Each effect has a switch and its own values, kept under its own keys.
//
// Unlike the mod's other switches these apply as they change, not at launch: every setter below stores the
// value and hands the effect it belongs to to the engine, which re-reads that effect's keys off the main
// thread. The engine is made the first time Spotify starts its output with the master switch on.
//
// Threading: everything here is main thread, except EeveeDSPStatus and EeveeDSPError, which any thread may call.
#import <Foundation/Foundation.h>

#pragma mark - keys

// The master switch, off until asked for. Off, Spotify's sound is left exactly as it was.
#define EeveeKeyDSP                        @"EeveeSpotify.dsp"

// Output control, always applied while the master switch is on.
#define EeveeKeyDSPPostGain                @"EeveeSpotify.dsp.postGain"            // dB
#define EeveeKeyDSPLimiterThreshold        @"EeveeSpotify.dsp.limiterThreshold"    // dB
#define EeveeKeyDSPLimiterRelease          @"EeveeSpotify.dsp.limiterRelease"      // ms

#define EeveeKeyDSPCompander               @"EeveeSpotify.dsp.compander"
#define EeveeKeyDSPCompanderTime           @"EeveeSpotify.dsp.compander.time"      // s, the time constant
#define EeveeKeyDSPCompanderGranularity    @"EeveeSpotify.dsp.compander.granularity"
#define EeveeKeyDSPCompanderTransform      @"EeveeSpotify.dsp.compander.transform" // EeveeDSPCompanderTransformNames index
// Seven gains, "g;g;g;g;g;g;g", at EeveeDSPCompanderFrequencies, each within EeveeDSPCompanderGainLimit.
#define EeveeKeyDSPCompanderGains          @"EeveeSpotify.dsp.compander.gains"

#define EeveeKeyDSPBass                    @"EeveeSpotify.dsp.bass"
#define EeveeKeyDSPBassGain                @"EeveeSpotify.dsp.bass.gain"           // dB, the most it lifts

#define EeveeKeyDSPEqualizer               @"EeveeSpotify.dsp.eq"
#define EeveeKeyDSPEqualizerFilter         @"EeveeSpotify.dsp.eq.filter"           // EeveeDSPEqualizerFilterNames index
#define EeveeKeyDSPEqualizerInterpolation  @"EeveeSpotify.dsp.eq.interpolation"    // EeveeDSPEqualizerInterpolationNames index
// Fifteen gains in dB, "g;g;...;g", at EeveeDSPEqualizerFrequencies, each within EeveeDSPEqualizerGainLimit.
#define EeveeKeyDSPEqualizerGains          @"EeveeSpotify.dsp.eq.gains"

// The arbitrary response equalizer, in AutoEq's GraphicEQ format: "GraphicEQ: 20 -1.2; 21 -1.1; ...".
#define EeveeKeyDSPGraphicEq               @"EeveeSpotify.dsp.geq"
#define EeveeKeyDSPGraphicEqNodes          @"EeveeSpotify.dsp.geq.nodes"

// File effects name a file in their library (EeveeDSPLibraryFiles), by its name alone: the app's container
// moves on every reinstall, the name does not.
#define EeveeKeyDSPConvolver               @"EeveeSpotify.dsp.convolver"
#define EeveeKeyDSPConvolverFile           @"EeveeSpotify.dsp.convolver.file"
#define EeveeKeyDSPConvolverMode           @"EeveeSpotify.dsp.convolver.mode"      // EeveeDSPConvolverModeNames index
// "-80;-100;0;0;0;0", JamesDSP's advanced waveform editing of the impulse response; no page edits it yet.
#define EeveeKeyDSPConvolverWaveEdit       @"EeveeSpotify.dsp.convolver.waveEdit"

#define EeveeKeyDSPDDC                     @"EeveeSpotify.dsp.ddc"
#define EeveeKeyDSPDDCFile                 @"EeveeSpotify.dsp.ddc.file"

#define EeveeKeyDSPLiveprog                @"EeveeSpotify.dsp.liveprog"
#define EeveeKeyDSPLiveprogFile            @"EeveeSpotify.dsp.liveprog.file"

#define EeveeKeyDSPReverb                  @"EeveeSpotify.dsp.reverb"
#define EeveeKeyDSPReverbPreset            @"EeveeSpotify.dsp.reverb.preset"       // EeveeDSPReverbPresets index

#define EeveeKeyDSPStereoWide              @"EeveeSpotify.dsp.wide"
#define EeveeKeyDSPStereoWideLevel         @"EeveeSpotify.dsp.wide.level"          // percent

#define EeveeKeyDSPCrossfeed               @"EeveeSpotify.dsp.crossfeed"
#define EeveeKeyDSPCrossfeedMode           @"EeveeSpotify.dsp.crossfeed.mode"      // EeveeDSPCrossfeedModeNames index

#define EeveeKeyDSPTube                    @"EeveeSpotify.dsp.tube"
#define EeveeKeyDSPTubeDrive               @"EeveeSpotify.dsp.tube.drive"          // dB

#pragma mark - values

// A number setting's bounds, the value it has until set, and the step a slider moves it by. Ranges are
// RootlessJamesDSP's.
typedef struct {
    double min, max, fallback, step;
} EeveeDSPRange;

EeveeDSPRange EeveeDSPRangeFor(NSString *key);

// Switches, numbers (clamped to their range) and strings. Setting one applies it.
BOOL EeveeDSPSwitch(NSString *key);
void EeveeDSPSetSwitch(NSString *key, BOOL on);
double EeveeDSPNumber(NSString *key);
void EeveeDSPSetNumber(NSString *key, double value);
NSString *EeveeDSPString(NSString *key);
void EeveeDSPSetString(NSString *key, NSString *value);

// The equalizer's and the compressor's gains as numbers (15 and 7 of them), from and to their keys.
NSArray<NSNumber *> *EeveeDSPGains(NSString *key);
void EeveeDSPSetGains(NSString *key, NSArray<NSNumber *> *gains);

// Every key above back to its value until set; the master switch stays as it is.
void EeveeDSPResetAll(void);

#pragma mark - the lists the choices pick from

extern const double EeveeDSPEqualizerFrequencies[15];     // Hz, 25 ... 16000
extern const double EeveeDSPEqualizerGainLimit;           // ±12 dB
extern const double EeveeDSPCompanderFrequencies[7];      // Hz, 95 ... 7500
extern const double EeveeDSPCompanderGainLimit;           // ±1.2

NSArray<NSString *> *EeveeDSPEqualizerFilterNames(void);
NSArray<NSString *> *EeveeDSPEqualizerInterpolationNames(void);
NSArray<NSString *> *EeveeDSPCompanderTransformNames(void);
NSArray<NSString *> *EeveeDSPConvolverModeNames(void);
NSArray<NSString *> *EeveeDSPCrossfeedModeNames(void);
NSArray<NSString *> *EeveeDSPReverbPresetNames(void);
// The equalizer presets of JamesDSP (Acoustic, Bass, ... Vocal Booster), names and their 15 gains.
NSArray<NSString *> *EeveeDSPEqualizerPresetNames(void);
NSArray<NSNumber *> *EeveeDSPEqualizerPreset(NSInteger index);

#pragma mark - file libraries

typedef NS_ENUM(NSInteger, EeveeDSPFileKind) {
    EeveeDSPFileImpulseResponse,   // the convolver's: .wav .flac .irs (a WAV by another name)
    EeveeDSPFileDDC,               // ViPER DDC's .vdc
    EeveeDSPFileLiveprog,          // Liveprog's .eel
};

// Documents/EeveeSpotify/JamesDSP/<Convolver|DDC|Liveprog>, made on first use and holding the files JamesDSP
// ships (Liveprog scripts, DDC presets) the first time it is made.
NSString *EeveeDSPLibraryDirectory(EeveeDSPFileKind kind);
NSArray<NSString *> *EeveeDSPLibraryFiles(EeveeDSPFileKind kind);   // names, sorted
NSArray<NSString *> *EeveeDSPFileExtensions(EeveeDSPFileKind kind); // lowercase, without the dot
// Copies a picked file into the library, replacing one of the same name; answers its name, nil and an
// error when it is not a file of that kind.
NSString *EeveeDSPImportFile(EeveeDSPFileKind kind, NSURL *url, NSError **error);
BOOL EeveeDSPDeleteFile(EeveeDSPFileKind kind, NSString *name);

#pragma mark - what the engine is doing

// One line for the page: off, waiting for Spotify to play, or running (sample rate, load).
NSString *EeveeDSPStatus(void);
// Why an effect's last change did not take, nil when it did: a script that did not compile (with the
// line), an impulse response that could not be read, a DDC file that was not one. Keyed by the effect's
// switch key (EeveeKeyDSPLiveprog, EeveeKeyDSPConvolver, EeveeKeyDSPDDC, EeveeKeyDSPGraphicEq).
NSString *EeveeDSPError(NSString *switchKey);

// The equalizer's magnitude response for the stored filter and the given gains, for drawing the curve:
// `count` points log-spaced from 20 Hz to 20 kHz into `frequencies` and `decibels`.
void EeveeDSPEqualizerResponse(NSArray<NSNumber *> *gains, NSInteger count, double *frequencies, double *decibels);
// The compressor's response curve for the given gains, the same way.
void EeveeDSPCompanderResponse(NSArray<NSNumber *> *gains, NSInteger count, double *frequencies, double *values);
