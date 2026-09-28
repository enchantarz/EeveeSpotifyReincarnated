// Speed and Pitch (SpeedPitchMenu.x draws them), both done on Spotify's audio, under either look.
//
// Spotify's player takes a speed only for podcasts: for songs its restrictions refuse it (device test,
// 2026-09-18: the slider read "Unavailable here"), its own music speed being a per track setting kept on
// playlist items. So speed, like pitch, is done to the sound, by EeveeTimePitch between Spotify's mixer and
// its speaker unit.
//
// Spotify's audio (AudioUnitDriver2 in the binary) is a chain of units it wires with MakeConnection:
// converter (fed by its decoder through a render callback), EQ, mixer, RemoteIO. Its import of
// AudioUnitSetProperty is rebound (Core/EeveeRebind.h), and the one call connecting the mixer to the RemoteIO
// unit's input is answered by a render callback of this file's instead, which pulls the mixer itself. At
// normal speed and pitch the callback passes the mixer's sound straight through. Otherwise it renders the
// time and pitch unit, which pulls the mixer for rate times the frames it hands back, so Spotify's decoder
// is drained that much faster: the song plays faster or slower, at its own pitch unless Pitch moves it.
// Switching the unit in or out skips or repeats its 93 ms, so it stays in for a moment after both return
// to normal, and a finger dragging across normal does not switch it back and forth.
//
// Spotify's clock keeps running at its own speed between the player's reports: -[SPTPlayerState position]
// is positionAsOfTimestamp minus timeIntervalSinceNow times [self playbackSpeed] (disassembly,
// 0x1057735ec), so playbackSpeed is hooked to include this speed, and the scrubber, the lyrics and the lock
// screen move with the sound. That bets the player's reported positions follow what the decoder handed
// over, which is what it counts.
//
// When the connection is never seen, pitch falls back to the way it first shipped: a render notify on the
// RemoteIO unit (after Music Haptics' own rebinding of AudioOutputUnitStart) runs each finished buffer
// through a unit working in place; speed is then unavailable. Those buffers are in the unit's output format,
// the hardware's, not the one Spotify hands the unit (harness/jamesdsp/sim), so the fallback's unit is made
// for that one.
//
// Speed and pitch last until Spotify quits.
//
// Threading: the render callback and the notify run on the render thread and touch only atomics and the
// units; Spotify sets its properties and starts its unit on its audio thread; everything else is main
// thread.
#import <AudioToolbox/AudioToolbox.h>
#import <pthread.h>
#import <stdatomic.h>
#import "Core/EeveeCore.h"
#import "Core/EeveeRebind.h"
#import "Headers/SPTPlayer.h"
#import "SpeedPitch.h"
#import "EeveeTimePitch.h"

// The unit stays in this long after speed and pitch both came back to normal.
static const double kOffAfter = 1.5;

#pragma mark - shared between the threads

static float eevee_speed = 1, eevee_semitones;     // main thread
static atomic_uint eevee_speedBits;             // eevee_speed for SPTPlayerState, read on any thread

// The chain as Spotify wired it: the unit and bus feeding its RemoteIO unit (NULL until the
// connection was taken over), pulled in chunks no larger than Spotify's own maximum slice.
static _Atomic(AudioUnit) eevee_source;
static UInt32 eevee_sourceBus;
static atomic_uint eevee_chunk = 1024;
static Float64 eevee_sourceTime;                // render thread only

// The unit in use and whether the render thread runs it: in the chain (pull), else in place (pitch only).
static _Atomic(EeveeTimePitch *) eevee_pull, eevee_inPlace;
static atomic_bool eevee_engaged, eevee_busy;
static pthread_mutex_t eevee_buildLock = PTHREAD_MUTEX_INITIALIZER;

// The formats when Spotify started its output: the one it hands the RemoteIO unit, which the chain's unit
// feeds, and the unit's output side, the hardware's, which the in place fallback's notify gets.
typedef struct {
    atomic_uint_fast64_t rateBits;
    atomic_uint flags, channels, bytes;
} Format;
static Format eevee_client, eevee_hardware;

static BOOL tapped(void) {
    return atomic_load(&eevee_source) != NULL;
}

static float loadFloat(atomic_uint *slot) {
    uint32_t bits = atomic_load(slot);
    float value;
    memcpy(&value, &bits, sizeof value);
    return value;
}

static void storeFloat(atomic_uint *slot, float value) {
    uint32_t bits;
    memcpy(&bits, &value, sizeof bits);
    atomic_store(slot, bits);
}

#pragma mark - the render thread: the chain

// The source's next `frames` frames into `data`, in chunks of at most eevee_chunk frames, each with a sample
// time of its own, so Spotify's units never see a time twice (an AU renders a time it has seen from cache).
static OSStatus pullSource(AudioUnit source, const AudioTimeStamp *outputTime, UInt32 frames, AudioBufferList *data) {
    enum { kMaxBuffers = 8 };
    UInt32 chunk = atomic_load_explicit(&eevee_chunk, memory_order_relaxed);
    if (data->mNumberBuffers > kMaxBuffers) chunk = frames;
    for (UInt32 b = 0; b < data->mNumberBuffers; b++) if (!data->mBuffers[b].mData) chunk = frames;
    UInt32 bytesPerFrame[kMaxBuffers];
    for (UInt32 b = 0; b < data->mNumberBuffers && b < kMaxBuffers; b++) bytesPerFrame[b] = data->mBuffers[b].mDataByteSize / frames;

    for (UInt32 done = 0; done < frames;) {
        UInt32 count = MIN(chunk, frames - done);
        struct { AudioBufferList list; AudioBuffer more[kMaxBuffers - 1]; } part;
        AudioBufferList *target = data;
        if (count != frames) {
            part.list.mNumberBuffers = data->mNumberBuffers;
            for (UInt32 b = 0; b < data->mNumberBuffers; b++) {
                part.list.mBuffers[b] = (AudioBuffer){data->mBuffers[b].mNumberChannels, count * bytesPerFrame[b],
                                                      (char *)data->mBuffers[b].mData + done * bytesPerFrame[b]};
            }
            target = &part.list;
        }
        AudioTimeStamp time = outputTime ? *outputTime : (AudioTimeStamp){0};
        time.mSampleTime = eevee_sourceTime;
        time.mFlags |= kAudioTimeStampSampleTimeValid;
        AudioUnitRenderActionFlags flags = 0;
        OSStatus status = AudioUnitRender(source, &flags, &time, eevee_sourceBus, count, target);
        eevee_sourceTime += count;
        if (status != noErr) return status;
        done += count;
    }
    return noErr;
}

static OSStatus pullForUnit(void *context, UInt32 frames, AudioBufferList *data) {
    AudioUnit source = atomic_load(&eevee_source);
    if (!source) {
        for (UInt32 b = 0; b < data->mNumberBuffers; b++) if (data->mBuffers[b].mData) memset(data->mBuffers[b].mData, 0, data->mBuffers[b].mDataByteSize);
        return noErr;
    }
    return pullSource(source, NULL, frames, data);
}

static BOOL fitsUnit(const AudioBufferList *data, UInt32 frames, EeveeTimePitch *unit) {
    if (data->mNumberBuffers != EeveeTimePitchChannels(unit) || frames > kEeveeTimePitchMaxFrames) return NO;
    for (UInt32 b = 0; b < data->mNumberBuffers; b++) {
        if (!data->mBuffers[b].mData || data->mBuffers[b].mDataByteSize < frames * sizeof(float)) return NO;
    }
    return YES;
}

// The RemoteIO unit's input, in place of Spotify's connection from the mixer.
static OSStatus feed(void *refCon, AudioUnitRenderActionFlags *flags, const AudioTimeStamp *timestamp, UInt32 bus,
                     UInt32 frames, AudioBufferList *data) {
    AudioUnit source = atomic_load(&eevee_source);
    if (!source) {
        for (UInt32 b = 0; b < data->mNumberBuffers; b++) if (data->mBuffers[b].mData) memset(data->mBuffers[b].mData, 0, data->mBuffers[b].mDataByteSize);
        *flags |= kAudioUnitRenderAction_OutputIsSilence;
        return noErr;
    }
    atomic_store(&eevee_busy, true);
    OSStatus status = -1;
    EeveeTimePitch *unit = atomic_load(&eevee_pull);
    if (atomic_load(&eevee_engaged) && unit && fitsUnit(data, frames, unit)) status = EeveeTimePitchRender(unit, frames, data);
    if (status != noErr) status = pullSource(source, timestamp, frames, data);
    atomic_store(&eevee_busy, false);
    return status;
}

#pragma mark - the render thread: in place, the fallback

static float eevee_scratch[kEeveeTimePitchMaxChannels][kEeveeTimePitchMaxFrames];

static inline float readSample(const void *data, UInt32 index, UInt32 bytes, BOOL isFloat, UInt32 fraction) {
    if (bytes == 4) {
        if (isFloat) return ((const float *)data)[index];
        int32_t value = ((const int32_t *)data)[index];
        return fraction ? (float)((double)value / (double)(1u << fraction)) : (float)(value / 2147483648.0);
    }
    return ((const int16_t *)data)[index] / 32768.0f;
}

static inline void writeSample(void *data, UInt32 index, float value, UInt32 bytes, BOOL isFloat, UInt32 fraction) {
    if (bytes == 4 && isFloat) {
        ((float *)data)[index] = value;
        return;
    }
    value = fmaxf(-1, fminf(value, 1));
    if (bytes == 4) {
        double scale = fraction ? (double)(1u << fraction) : 2147483647.0;
        ((int32_t *)data)[index] = (int32_t)(value * scale);
    } else {
        ((int16_t *)data)[index] = (int16_t)(value * 32767);
    }
}

static void shiftInPlace(EeveeTimePitch *unit, AudioUnitRenderActionFlags *flags, UInt32 frames, AudioBufferList *data) {
    UInt32 formatFlags = atomic_load_explicit(&eevee_hardware.flags, memory_order_relaxed);
    UInt32 bytes = atomic_load_explicit(&eevee_hardware.bytes, memory_order_relaxed);
    UInt32 channels = EeveeTimePitchChannels(unit);
    BOOL isFloat = (formatFlags & kAudioFormatFlagIsFloat) != 0;
    BOOL split = (formatFlags & kAudioFormatFlagIsNonInterleaved) != 0;
    UInt32 fraction = (formatFlags & kLinearPCMFormatFlagsSampleFractionMask) >> kLinearPCMFormatFlagsSampleFractionShift;
    if (frames > kEeveeTimePitchMaxFrames || (bytes != 2 && bytes != 4)) return;
    if (split ? data->mNumberBuffers != channels : data->mNumberBuffers != 1 || data->mBuffers[0].mNumberChannels != channels) return;
    for (UInt32 b = 0; b < data->mNumberBuffers; b++) {
        if (!data->mBuffers[b].mData || data->mBuffers[b].mDataByteSize < frames * bytes * (split ? 1 : channels)) return;
    }
    // Silence still goes through, so the sound the unit holds plays out rather than coming back later.
    BOOL silent = (*flags & kAudioUnitRenderAction_OutputIsSilence) != 0;

    float *lanes[kEeveeTimePitchMaxChannels];
    BOOL direct = split && isFloat && bytes == 4 && !silent;
    for (UInt32 c = 0; c < channels; c++) {
        if (direct) {
            lanes[c] = data->mBuffers[c].mData;
            continue;
        }
        lanes[c] = eevee_scratch[c];
        const void *source = data->mBuffers[split ? c : 0].mData;
        for (UInt32 i = 0; i < frames; i++) {
            lanes[c][i] = silent ? 0 : readSample(source, split ? i : i * channels + c, bytes, isFloat, fraction);
        }
    }
    if (!EeveeTimePitchProcess(unit, lanes, frames) || direct) return;
    for (UInt32 c = 0; c < channels; c++) {
        void *target = data->mBuffers[split ? c : 0].mData;
        for (UInt32 i = 0; i < frames; i++) writeSample(target, split ? i : i * channels + c, lanes[c][i], bytes, isFloat, fraction);
    }
    *flags &= ~kAudioUnitRenderAction_OutputIsSilence;
}

static OSStatus rendered(void *refCon, AudioUnitRenderActionFlags *flags, const AudioTimeStamp *timestamp, UInt32 bus,
                         UInt32 frames, AudioBufferList *data) {
    if (!(*flags & kAudioUnitRenderAction_PostRender) || bus != 0 || !data || !data->mNumberBuffers || !frames) return noErr;
    if (tapped() || !atomic_load(&eevee_engaged)) return noErr;
    atomic_store(&eevee_busy, true);
    EeveeTimePitch *unit = atomic_load(&eevee_inPlace);
    if (atomic_load(&eevee_engaged) && unit) shiftInPlace(unit, flags, frames, data);
    atomic_store(&eevee_busy, false);
    return noErr;
}

#pragma mark - Spotify's audio thread

static BOOL isRemoteIO(AudioUnit unit) {
    AudioComponentDescription description = {0};
    if (!unit || AudioComponentGetDescription(AudioComponentInstanceGetComponent(unit), &description) != noErr) return NO;
    return description.componentType == kAudioUnitType_Output && description.componentSubType == kAudioUnitSubType_RemoteIO;
}

static OSStatus (*eevee_setProperty)(AudioUnit, AudioUnitPropertyID, AudioUnitScope, AudioUnitElement, const void *, UInt32);

static OSStatus setProperty(AudioUnit unit, AudioUnitPropertyID property, AudioUnitScope scope, AudioUnitElement element,
                            const void *data, UInt32 size) {
    if (property == kAudioUnitProperty_MaximumFramesPerSlice && data && size >= sizeof(UInt32)) {
        UInt32 frames = *(const UInt32 *)data;
        if (frames >= 256) atomic_store(&eevee_chunk, frames);
    }
    if (property != kAudioUnitProperty_MakeConnection || scope != kAudioUnitScope_Input || element != 0 || !data
        || size < sizeof(AudioUnitConnection) || !isRemoteIO(unit)) {
        return eevee_setProperty(unit, property, scope, element, data, size);
    }
    const AudioUnitConnection *connection = data;
    if (!connection->sourceAudioUnit) {
        atomic_store(&eevee_source, NULL);
        AURenderCallbackStruct none = {0};
        eevee_setProperty(unit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &none, sizeof none);
        EeveeLog(@"redesign speed: Spotify disconnected its output");
        return eevee_setProperty(unit, property, scope, element, data, size);
    }
    eevee_sourceBus = connection->sourceOutputNumber;
    atomic_store(&eevee_source, connection->sourceAudioUnit);
    AURenderCallbackStruct callback = {feed, NULL};
    OSStatus status = eevee_setProperty(unit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &callback, sizeof callback);
    EeveeLog(@"redesign speed: Spotify's mixer feeds its output through the menu's unit now (status %d)", (int)status);
    if (status == noErr) return noErr;
    atomic_store(&eevee_source, NULL);
    return eevee_setProperty(unit, property, scope, element, data, size);
}

static OSStatus (*eevee_startOutput)(AudioUnit unit);

// One side of the RemoteIO unit's element 0 into `into`; a side that is not linear PCM is left as it was.
static BOOL readScope(AudioUnit unit, AudioUnitScope scope, Format *into, AudioStreamBasicDescription *format) {
    UInt32 size = sizeof *format;
    OSStatus status = AudioUnitGetProperty(unit, kAudioUnitProperty_StreamFormat, scope, 0, format, &size);
    if (status != noErr || format->mFormatID != kAudioFormatLinearPCM || format->mSampleRate <= 0) return NO;
    uint64_t bits;
    memcpy(&bits, &format->mSampleRate, sizeof bits);
    atomic_store(&into->rateBits, bits);
    atomic_store(&into->flags, format->mFormatFlags);
    atomic_store(&into->channels, format->mChannelsPerFrame);
    atomic_store(&into->bytes, format->mBitsPerChannel / 8);
    return YES;
}

static void readFormat(AudioUnit unit) {
    AudioStreamBasicDescription client = {0}, hardware = {0};
    BOOL clientRead = readScope(unit, kAudioUnitScope_Input, &eevee_client, &client);
    BOOL hardwareRead = readScope(unit, kAudioUnitScope_Output, &eevee_hardware, &hardware);
    static int logged;
    if (!clientRead || !hardwareRead) {
        if (logged++ < 6) EeveeLog(@"redesign speed: the output is not linear PCM (Spotify's side %@, the hardware's %@)", clientRead ? @"is" : @"is not", hardwareRead ? @"is" : @"is not");
        if (!clientRead) return;
    }
    if (logged++ < 6) EeveeLog(@"redesign speed: Spotify's output is %.0f Hz, %u channels, %u bits, flags 0x%x, into the hardware's %.0f Hz, %u channels, %u bits, flags 0x%x, slices of %u, %@",
                            client.mSampleRate, (unsigned)client.mChannelsPerFrame, (unsigned)client.mBitsPerChannel, (unsigned)client.mFormatFlags,
                            hardware.mSampleRate, (unsigned)hardware.mChannelsPerFrame, (unsigned)hardware.mBitsPerChannel, (unsigned)hardware.mFormatFlags,
                            atomic_load(&eevee_chunk), tapped() ? @"fed through the menu's unit" : @"not taken over");
}

static void apply(void);

static OSStatus startOutput(AudioUnit unit) {
    if (unit && isRemoteIO(unit)) {
        readFormat(unit);
        AudioUnitRemoveRenderNotify(unit, rendered, NULL);
        AudioUnitAddRenderNotify(unit, rendered, NULL);
        // A speed or pitch chosen before the output started, or kept across a new format, applies now.
        dispatch_async(dispatch_get_main_queue(), ^{
            if (eevee_speed != 1 || eevee_semitones != 0) apply();
        });
    }
    return eevee_startOutput(unit);
}

#pragma mark - engaging the unit

// Stops the render thread using a unit, and returns once it no longer is.
static void disengage(void) {
    atomic_store(&eevee_engaged, false);
    for (int i = 0; i < 200 && atomic_load(&eevee_busy); i++) usleep(250);
}

// The unit for the output's format and the way in use, made when there is none or the format changed. A
// replaced one is never freed: the render thread may still hold it, and a format change is rare.
static EeveeTimePitch *unitForFormat(void) {
    BOOL pull = tapped();
    Format *format = pull ? &eevee_client : &eevee_hardware;
    double rate;
    uint64_t bits = atomic_load(&format->rateBits);
    memcpy(&rate, &bits, sizeof rate);
    UInt32 channels = atomic_load(&format->channels);
    if (pull) {
        // In the chain the unit hands its buffers to the RemoteIO unit as they are: float, one per channel.
        UInt32 flags = atomic_load(&format->flags);
        BOOL canonical = (flags & kAudioFormatFlagIsFloat) && (flags & kAudioFormatFlagIsNonInterleaved) && atomic_load(&format->bytes) == 4;
        if (!canonical) {
            static int logged;
            if (logged++ < 3) EeveeLog(@"redesign speed: the output is not float per channel (flags 0x%x), speed cannot apply", (unsigned)flags);
            return NULL;
        }
    }
    if (rate <= 0 || channels < 1 || channels > kEeveeTimePitchMaxChannels) return NULL;
    _Atomic(EeveeTimePitch *) *slot = pull ? &eevee_pull : &eevee_inPlace;
    pthread_mutex_lock(&eevee_buildLock);
    EeveeTimePitch *unit = atomic_load(slot);
    if (!unit || EeveeTimePitchSampleRate(unit) != rate || EeveeTimePitchChannels(unit) != channels) {
        BOOL wasEngaged = atomic_load(&eevee_engaged);
        disengage();
        unit = EeveeTimePitchCreate(rate, channels, pull ? pullForUnit : NULL, NULL);
        if (unit) {
            EeveeTimePitchSetRate(unit, pull ? eevee_speed : 1);
            EeveeTimePitchSetSemitones(unit, eevee_semitones);
        }
        atomic_store(slot, unit);
        EeveeLog(@"redesign speed: %@ %@ for %.0f Hz, %u channels", unit ? @"a unit" : @"no unit", pull ? @"in the chain" : @"in place", rate, (unsigned)channels);
        if (unit && wasEngaged) atomic_store(&eevee_engaged, true);
    }
    pthread_mutex_unlock(&eevee_buildLock);
    return unit;
}

static void report(void) {
    EeveeTimePitch *unit = atomic_load(tapped() ? &eevee_pull : &eevee_inPlace);
    if (!unit) return;
    EeveeLog(@"redesign speed: %.2fx, %+.0f st, %u underruns, %u failures, largest pull %u, %.1f s of input", eevee_speed, eevee_semitones,
          EeveeTimePitchUnderruns(unit), EeveeTimePitchFailures(unit), EeveeTimePitchLargestPull(unit),
          EeveeTimePitchConsumed(unit) / EeveeTimePitchSampleRate(unit));
}

// Puts the unit in or takes it out for the current speed and pitch.
static void apply(void) {
    BOOL normal = eevee_speed == 1 && eevee_semitones == 0;
    static NSUInteger change;
    NSUInteger thisChange = ++change;
    if (normal) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kOffAfter * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (thisChange != change || eevee_speed != 1 || eevee_semitones != 0 || !atomic_load(&eevee_engaged)) return;
            report();
            disengage();
        });
    }
    EeveeTimePitch *unit = unitForFormat();
    if (!unit) {
        static int logged;
        if (!normal && logged++ < 3) EeveeLog(@"redesign speed: Spotify's output has not started, nothing to change yet");
        return;
    }
    EeveeTimePitchSetRate(unit, tapped() ? eevee_speed : 1);
    EeveeTimePitchSetSemitones(unit, eevee_semitones);
    if (!normal && !atomic_load(&eevee_engaged)) {
        disengage();
        EeveeTimePitchReset(unit);
        atomic_store(&eevee_engaged, true);
    }
}

#pragma mark - the menu's calls

double EeveePlayerSpeed(void) {
    return eevee_speed;
}

BOOL EeveePlayerSpeedAllowed(void) {
    return tapped();
}

void EeveeSetPlayerSpeed(double speed) {
    if (!tapped()) return;
    eevee_speed = (float)speed;
    storeFloat(&eevee_speedBits, eevee_speed);
    apply();
}

float EeveePlayerPitch(void) {
    return eevee_semitones;
}

void EeveeSetPlayerPitch(float semitones) {
    if (!eevee_startOutput && !tapped()) return;
    eevee_semitones = semitones;
    apply();
}

BOOL EeveePlayerPitchAvailable(void) {
    return eevee_startOutput != NULL || tapped();
}

#pragma mark - Spotify's clock

%hook SPTPlayerState
- (double)playbackSpeed {
    double speed = %orig;
    float ours = loadFloat(&eevee_speedBits);
    return ours > 0 && ours != 1 ? speed * ours : speed;
}
%end

%ctor {
    storeFloat(&eevee_speedBits, 1);
    if (!EeveeRebindImport("AudioUnitSetProperty", setProperty, (void **)&eevee_setProperty) || !eevee_setProperty) {
        eevee_setProperty = NULL;
        EeveeLog(@"redesign speed: Spotify does not import AudioUnitSetProperty, the menu offers pitch only");
    }
    if (!EeveeRebindImport("AudioOutputUnitStart", startOutput, (void **)&eevee_startOutput) || !eevee_startOutput) {
        eevee_startOutput = NULL;
        EeveeLog(@"redesign speed: Spotify does not import AudioOutputUnitStart");
    }
    %init;
    EeveeRequireClasses(@[@"SPTPlayerState"]);
}
