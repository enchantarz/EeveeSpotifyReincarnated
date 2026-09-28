// Vibrations > Music Haptics: the Taptic Engine playing along with the song, taps on the drums and a
// rumble under the bass, the way Apple Music's Music Haptics feels, worked out live from the sound.
//
// Spotify plays through Core Audio units of its own (AudioUnitDriver2 in the binary: converter, EQ, mixer
// and a RemoteIO output unit, started with AudioOutputUnitStart(_outputUnit)), with no Objective-C
// method between it and the unit. So Spotify's import of AudioOutputUnitStart is rebound
// (Core/EeveeRebind.h), and every RemoteIO unit it starts gets a render notify: after each render, the
// buffer bound for the speaker is mixed to mono and handed to the analyzer (EeveeMusicAnalyzer.h) on
// the render thread, which puts what it hears into a ring of events. That buffer is in the unit's output
// format, the hardware's, not the one Spotify hands the unit (in the simulator 48 kHz float with a buffer
// per channel, whatever the client: harness/jamesdsp/sim, harness/haptics/sim), so the analyzer runs at
// the hardware's rate, and a listener on the format follows it to a new one. The render timestamp says when
// that buffer reaches the output; AVAudioSession's output latency (large over Bluetooth) is added, so
// a tap lands when its drum is heard. A thread of this file's own takes the events off the ring and
// schedules them with Core Haptics at those times: each hit a transient, the rumble one looping
// continuous event whose intensity follows the level. The strength scales both as they are played, and
// what Music Haptics follows leaves out the snares' taps (Bass) or the rumble (Beat) there too, so a change
// applies to the next event.
//
// The rebinding and the notify are in place under either look, so the switch works at once;
// with the switch off the notify returns straight away. Nothing listens while Spotify is not the active
// app, since iOS plays no haptics for an app in the background. Sound that is not Spotify's own
// output (Connect, AirPlay to another device, video) never passes the unit, and plays no haptics.
//
// Threading: the notify runs on the render thread and only touches atomics, the analyzer and the
// ring; the Core Haptics objects belong to the player thread; the switch, its settings and the app's
// state are set on the main thread.
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreHaptics/CoreHaptics.h>
#import <mach/mach_time.h>
#import <os/lock.h>
#import <pthread.h>
#import <stdatomic.h>
#import "Core/EeveeCore.h"
#import "Core/EeveeRebind.h"
#import "Haptics.h"
#import "EeveeMusicAnalyzer.h"

// Core Haptics takes about this long from a scheduled time to the Taptic Engine's peak.
static const double kHapticLead = 0.012;
// A tap this late is left out rather than played off the beat.
static const double kLatestTap = 0.05;
// Taps are this strong at most, and the rumble this strong at its level's most, at a strength of 100%.
static const float kTapGain = 1, kRumbleGain = 1;
// The rumble starts over this level and stops once it has stayed under the other this long.
static const float kRumbleStart = 0.05f, kRumbleStop = 0.02f;
static const double kRumbleStopAfter = 0.3;
// A level closer than this to the last one sent is skipped, unless it moved by more than kRumbleStep.
static const double kRumbleInterval = 0.025;
static const float kRumbleStep = 0.08f;
static const NSTimeInterval kRumbleLength = 30;
// Without events for this long, or for this many IO buffers if that is longer, the rumble goes quiet (the
// output stopped rendering), and after the longer wait the engine is stopped.
static const double kQuietAfter = 0.1, kQuietAfterBuffers = 2.5, kEngineStopAfter = 5;
// An engine that would not start is not asked again for this long.
static const double kStartRetryAfter = 2;

enum { kRingSize = 1024, kMonoFrames = 4096 };

#pragma mark - shared between the threads

static atomic_bool eevee_enabled, eevee_active, eevee_listening;
static atomic_uint eevee_generation;
static atomic_uint_fast64_t eevee_latencyBits;
static atomic_uint eevee_lastFrames;
// The format of the buffers the notify gets: the rate, and the layout packed into one word so the render
// thread never reads half of a change (flags in the low 32 bits, then channels, then bytes per sample).
static atomic_uint_fast64_t eevee_sampleRateBits, eevee_layout;
static atomic_uint_fast64_t eevee_skipped;   // renders whose buffers were not laid out as the format says
// The strength's factor and what is followed, set on the main thread, read on the player thread.
static atomic_uint_fast64_t eevee_strengthBits;
static atomic_int eevee_follows;

static EeveeMusicEvent eevee_ring[kRingSize];
static atomic_uint eevee_head, eevee_tail;   // head moved by the render thread, tail by the player thread
static dispatch_semaphore_t eevee_wake;

static double eevee_secondsPerTick;

static void storeDouble(atomic_uint_fast64_t *slot, double value) {
    uint64_t bits;
    memcpy(&bits, &value, sizeof bits);
    atomic_store(slot, bits);
}

static double loadDouble(atomic_uint_fast64_t *slot) {
    uint64_t bits = atomic_load(slot);
    double value;
    memcpy(&value, &bits, sizeof value);
    return value;
}

#pragma mark - the render thread

static EeveeMusicAnalyzer eevee_analyzer;
static float eevee_mono[kMonoFrames];

static void pushEvent(const EeveeMusicEvent *event, void *context) {
    unsigned head = atomic_load_explicit(&eevee_head, memory_order_relaxed);
    unsigned tail = atomic_load_explicit(&eevee_tail, memory_order_relaxed);
    if (head - tail >= kRingSize) return;
    eevee_ring[head & (kRingSize - 1)] = *event;
    atomic_store_explicit(&eevee_head, head + 1, memory_order_relaxed);
}

static inline float sampleAt(const void *data, UInt32 index, UInt32 bytes, BOOL isFloat, UInt32 fraction) {
    if (bytes == 4) {
        if (isFloat) return ((const float *)data)[index];
        int32_t value = ((const int32_t *)data)[index];
        return fraction ? (float)((double)value / (double)(1u << fraction)) : (float)(value / 2147483648.0);
    }
    return ((const int16_t *)data)[index] / 32768.0f;
}

// The hardware's format is float with a buffer per channel, but it is read rather than assumed (readFormat),
// and buffers not laid out the way it says are left alone rather than read as noise: the format read at the
// start can be a moment old.
static OSStatus rendered(void *refCon, AudioUnitRenderActionFlags *flags, const AudioTimeStamp *timestamp, UInt32 bus,
                         UInt32 frames, AudioBufferList *data) {
    if (!(*flags & kAudioUnitRenderAction_PostRender) || bus != 0 || !data || !data->mNumberBuffers || !frames) return noErr;
    if (!atomic_load_explicit(&eevee_listening, memory_order_relaxed)) return noErr;
    if (*flags & kAudioUnitRenderAction_OutputIsSilence) return noErr;

    uint64_t layout = atomic_load_explicit(&eevee_layout, memory_order_relaxed);
    UInt32 formatFlags = (UInt32)layout, channels = (UInt32)(layout >> 32) & 0xffff, bytes = (UInt32)(layout >> 48);
    BOOL isFloat = (formatFlags & kAudioFormatFlagIsFloat) != 0;
    BOOL split = (formatFlags & kAudioFormatFlagIsNonInterleaved) != 0;
    UInt32 fraction = (formatFlags & kLinearPCMFormatFlagsSampleFractionMask) >> kLinearPCMFormatFlagsSampleFractionShift;
    if ((bytes != 2 && bytes != 4) || channels < 1) return noErr;
    BOOL fits = split ? data->mNumberBuffers == channels : data->mNumberBuffers == 1 && data->mBuffers[0].mNumberChannels == channels;
    for (UInt32 b = 0; fits && b < data->mNumberBuffers; b++) {
        fits = data->mBuffers[b].mData && data->mBuffers[b].mDataByteSize == frames * bytes * (split ? 1 : channels);
    }
    if (!fits) {
        atomic_fetch_add_explicit(&eevee_skipped, 1, memory_order_relaxed);
        return noErr;
    }

    double sampleRate = loadDouble(&eevee_sampleRateBits);
    static double analyzedRate;
    static unsigned analyzedGeneration;
    unsigned generation = atomic_load_explicit(&eevee_generation, memory_order_relaxed);
    if (sampleRate <= 0) return noErr;
    if (sampleRate != analyzedRate || generation != analyzedGeneration) {
        EeveeMusicAnalyzerReset(&eevee_analyzer, sampleRate, 1 / eevee_secondsPerTick);
        analyzedRate = sampleRate;
        analyzedGeneration = generation;
    }
    atomic_store_explicit(&eevee_lastFrames, frames, memory_order_relaxed);

    // The first two channels; a mono output is both.
    const void *left = data->mBuffers[0].mData, *right = split && channels > 1 ? data->mBuffers[1].mData : left;
    UInt32 stride = split ? 1 : channels, rightOffset = !split && channels > 1 ? 1 : 0;

    uint64_t hostTime = (timestamp->mFlags & kAudioTimeStampHostTimeValid) ? timestamp->mHostTime : mach_absolute_time();
    unsigned headBefore = atomic_load_explicit(&eevee_head, memory_order_relaxed);
    for (UInt32 done = 0; done < frames;) {
        UInt32 count = MIN(frames - done, (UInt32)kMonoFrames);
        for (UInt32 i = 0; i < count; i++) {
            UInt32 at = (done + i) * stride;
            eevee_mono[i] = 0.5f * (sampleAt(left, at, bytes, isFloat, fraction) + sampleAt(right, at + rightOffset, bytes, isFloat, fraction));
        }
        uint64_t chunkTime = hostTime + (uint64_t)(done / sampleRate / eevee_secondsPerTick);
        EeveeMusicAnalyzerProcess(&eevee_analyzer, eevee_mono, count, chunkTime, pushEvent, NULL);
        done += count;
    }
    if (atomic_load_explicit(&eevee_head, memory_order_relaxed) != headBefore) dispatch_semaphore_signal(eevee_wake);
    return noErr;
}

#pragma mark - the output unit

static OSStatus (*eevee_startOutput)(AudioUnit unit);

static NSString *fourCC(UInt32 code) {
    char text[5] = {(char)(code >> 24), (char)(code >> 16), (char)(code >> 8), (char)code, 0};
    return @(text);
}

static NSString *formatText(AudioStreamBasicDescription format) {
    if (format.mFormatID != kAudioFormatLinearPCM) return [NSString stringWithFormat:@"'%@'", fourCC(format.mFormatID)];
    return [NSString stringWithFormat:@"%.0f Hz, %u channels, %u-bit %@%@", format.mSampleRate, (unsigned)format.mChannelsPerFrame,
            (unsigned)format.mBitsPerChannel, (format.mFormatFlags & kAudioFormatFlagIsFloat) ? @"float" : @"integer",
            (format.mFormatFlags & kAudioFormatFlagIsNonInterleaved) ? @", a buffer per channel" : @", interleaved"];
}

// The format the notify's buffers are in: the RemoteIO unit's output side (element 0, output scope), the
// hardware's, not the one Spotify hands the unit (the input scope). A format the analyzer cannot read
// leaves the buffers alone.
static void readFormat(AudioUnit unit) {
    AudioStreamBasicDescription format = {0}, client = {0};
    UInt32 size = sizeof format;
    OSStatus status = AudioUnitGetProperty(unit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &format, &size);
    size = sizeof client;
    AudioUnitGetProperty(unit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &client, &size);
    UInt32 bytes = format.mBitsPerChannel / 8;
    BOOL takes = status == noErr && format.mFormatID == kAudioFormatLinearPCM && format.mSampleRate > 0 && format.mChannelsPerFrame >= 1
                 && (bytes == 2 || bytes == 4) && ((format.mFormatFlags & kAudioFormatFlagIsFloat) || (format.mFormatFlags & kAudioFormatFlagIsSignedInteger));
    // Spotify starts its output again after every pause; the format is logged when it is not the last one.
    // Spotify's thread and a format change's may both be here.
    static os_unfair_lock lock = OS_UNFAIR_LOCK_INIT;
    static NSString *logged;
    NSString *text = [NSString stringWithFormat:@"music haptics: listening to Spotify's output at %@, from %@ Spotify hands it%@", formatText(format),
                      formatText(client), takes ? @"" : [NSString stringWithFormat:@"; not a format the analyzer reads (status %d), nothing plays", (int)status]];
    os_unfair_lock_lock(&lock);
    BOOL changed = ![text isEqualToString:logged];
    logged = text;
    os_unfair_lock_unlock(&lock);
    if (changed) EeveeLog(@"%@", text);
    if (!takes) {
        atomic_store(&eevee_layout, 0);
        return;
    }
    storeDouble(&eevee_sampleRateBits, format.mSampleRate);
    atomic_store(&eevee_layout, (uint64_t)format.mFormatFlags | (uint64_t)(format.mChannelsPerFrame & 0xffff) << 32 | (uint64_t)bytes << 48);
}

// The hardware's format changing under a running unit (a route to a device at another rate).
static void formatChanged(void *refCon, AudioUnit unit, AudioUnitPropertyID property, AudioUnitScope scope, AudioUnitElement element) {
    if (property == kAudioUnitProperty_StreamFormat && scope == kAudioUnitScope_Output && element == 0) readFormat(unit);
}

static void listenTo(AudioUnit unit) {
    AudioComponentDescription description = {0};
    if (AudioComponentGetDescription(AudioComponentInstanceGetComponent(unit), &description) != noErr) return;
    if (description.componentType != kAudioUnitType_Output || description.componentSubType != kAudioUnitSubType_RemoteIO) {
        static int logged;
        if (logged++ < 8) EeveeLog(@"music haptics: a started unit is not RemoteIO ('%@' '%@'), not listened to", fourCC(description.componentType), fourCC(description.componentSubType));
        return;
    }
    AudioUnitRemoveRenderNotify(unit, rendered, NULL);
    AudioUnitRemovePropertyListenerWithUserData(unit, kAudioUnitProperty_StreamFormat, formatChanged, NULL);
    AudioUnitAddPropertyListener(unit, kAudioUnitProperty_StreamFormat, formatChanged, NULL);
    readFormat(unit);
    OSStatus status = AudioUnitAddRenderNotify(unit, rendered, NULL);
    if (status != noErr) EeveeLog(@"music haptics: the render notify could not be added (%d)", (int)status);
}

static OSStatus startOutput(AudioUnit unit) {
    if (unit) listenTo(unit);
    return eevee_startOutput(unit);
}

#pragma mark - the player thread

static CHHapticEngine *eevee_engine;
static BOOL eevee_engineRunning;
static atomic_bool eevee_engineStopped;
static id<CHHapticAdvancedPatternPlayer> eevee_rumble;
static BOOL eevee_rumbling;
static double eevee_rumbleSentAt, eevee_quietSince;
static float eevee_rumbleSent;

typedef struct {
    NSUInteger taps, late, levels;
    double leadSum, leadMin;
} Stats;
static Stats eevee_stats;

static double hostSeconds(uint64_t ticks) {
    return ticks * eevee_secondsPerTick;
}

static float strength(void) {
    return (float)loadDouble(&eevee_strengthBits);
}

static BOOL startEngine(void) {
    static BOOL supported, checked;
    static double retryAt;
    if (!checked) {
        checked = YES;
        supported = CHHapticEngine.capabilitiesForHardware.supportsHaptics;
        if (!supported) EeveeLog(@"music haptics: this device has no Taptic Engine for Core Haptics");
    }
    if (!supported) return NO;
    NSError *error = nil;
    if (!eevee_engine) {
        // Spotify's own session rather than a new one, and haptics only, so nothing touches its audio.
        eevee_engine = [[CHHapticEngine alloc] initWithAudioSession:AVAudioSession.sharedInstance error:&error];
        if (!eevee_engine) {
            EeveeLog(@"music haptics: no haptic engine: %@", error);
            return NO;
        }
        eevee_engine.playsHapticsOnly = YES;
        eevee_engine.autoShutdownEnabled = NO;
        eevee_engine.stoppedHandler = ^(CHHapticEngineStoppedReason reason) {
            atomic_store(&eevee_engineStopped, true);
            EeveeLog(@"music haptics: the engine stopped (reason %ld)", (long)reason);
        };
        eevee_engine.resetHandler = ^{
            atomic_store(&eevee_engineStopped, true);
            EeveeLog(@"music haptics: the engine was reset");
        };
    }
    if (atomic_exchange(&eevee_engineStopped, false)) {
        eevee_engineRunning = NO;
        eevee_rumble = nil;
        eevee_rumbling = NO;
    }
    if (eevee_engineRunning) return YES;
    double now = hostSeconds(mach_absolute_time());
    if (now < retryAt) return NO;
    if (![eevee_engine startAndReturnError:&error]) {
        retryAt = now + kStartRetryAfter;
        static int logged;
        if (logged++ < 3) EeveeLog(@"music haptics: the engine did not start: %@", error);
        return NO;
    }
    eevee_engineRunning = YES;
    return YES;
}

static void stopEngine(void) {
    [eevee_rumble stopAtTime:CHHapticTimeImmediate error:nil];
    eevee_rumble = nil;
    eevee_rumbling = NO;
    if (eevee_engineRunning) [eevee_engine stopWithCompletionHandler:nil];
    eevee_engineRunning = NO;
}

// When `hostTime`'s sound is heard, in the engine's clock; `lead` is how far ahead of now that is.
static NSTimeInterval engineTime(uint64_t hostTime, double *lead) {
    double now = hostSeconds(mach_absolute_time());
    double heard = hostSeconds(hostTime) + loadDouble(&eevee_latencyBits) - kHapticLead;
    *lead = heard - now;
    return eevee_engine.currentTime + MAX(0, *lead);
}

static CHHapticEventParameter *parameter(CHHapticEventParameterID identifier, float value) {
    return [[CHHapticEventParameter alloc] initWithParameterID:identifier value:value];
}

static void playTap(const EeveeMusicEvent *event) {
    double lead;
    NSTimeInterval at = engineTime(event->hostTime, &lead);
    if (lead < -kLatestTap) {
        eevee_stats.late++;
        return;
    }
    CHHapticEvent *hit = [[CHHapticEvent alloc] initWithEventType:CHHapticEventTypeHapticTransient parameters:@[
        parameter(CHHapticEventParameterIDHapticIntensity, MIN(1, event->intensity * kTapGain * strength())),
        parameter(CHHapticEventParameterIDHapticSharpness, event->sharpness),
    ] relativeTime:0];
    NSError *error = nil;
    CHHapticPattern *pattern = [[CHHapticPattern alloc] initWithEvents:@[hit] parameters:@[] error:&error];
    id<CHHapticPatternPlayer> player = pattern ? [eevee_engine createPlayerWithPattern:pattern error:&error] : nil;
    if (!player || ![player startAtTime:at error:&error]) {
        static int logged;
        if (logged++ < 3) EeveeLog(@"music haptics: a tap did not play: %@", error);
        if (error.code == CHHapticErrorCodeEngineNotRunning || error.code == CHHapticErrorCodeServerInterrupted) atomic_store(&eevee_engineStopped, true);
        return;
    }
    eevee_stats.taps++;
    eevee_stats.leadSum += lead;
    eevee_stats.leadMin = eevee_stats.taps == 1 ? lead : MIN(eevee_stats.leadMin, lead);
}

static void stopRumble(NSTimeInterval at) {
    if (!eevee_rumbling) return;
    [eevee_rumble stopAtTime:at error:nil];
    eevee_rumbling = NO;
}

static void playLevel(const EeveeMusicEvent *event) {
    eevee_stats.levels++;
    double lead;
    NSTimeInterval at = engineTime(event->hostTime, &lead);
    double heard = hostSeconds(event->hostTime);
    // Whether it rumbles is decided at 100%, so the strength changes how hard, not how often.
    float level = MIN(1, event->intensity * kRumbleGain);
    float played = MIN(1, level * strength());

    if (level < kRumbleStop) {
        if (!eevee_quietSince) eevee_quietSince = heard;
        if (heard - eevee_quietSince >= kRumbleStopAfter) stopRumble(at);
    } else {
        eevee_quietSince = 0;
    }
    if (!eevee_rumbling && level < kRumbleStart) return;
    if (eevee_rumbling && heard - eevee_rumbleSentAt < kRumbleInterval && fabsf(level - eevee_rumbleSent) < kRumbleStep) return;

    NSError *error = nil;
    if (!eevee_rumble) {
        // Sharpness 0 under a control that adds the level's own.
        CHHapticEvent *hum = [[CHHapticEvent alloc] initWithEventType:CHHapticEventTypeHapticContinuous parameters:@[
            parameter(CHHapticEventParameterIDHapticIntensity, 1),
            parameter(CHHapticEventParameterIDHapticSharpness, 0),
        ] relativeTime:0 duration:kRumbleLength];
        CHHapticPattern *pattern = [[CHHapticPattern alloc] initWithEvents:@[hum] parameters:@[] error:&error];
        eevee_rumble = pattern ? [eevee_engine createAdvancedPlayerWithPattern:pattern error:&error] : nil;
        eevee_rumble.loopEnabled = YES;
        if (!eevee_rumble) {
            static int logged;
            if (logged++ < 3) EeveeLog(@"music haptics: no rumble: %@", error);
            return;
        }
    }
    NSArray<CHHapticDynamicParameter *> *controls = @[
        [[CHHapticDynamicParameter alloc] initWithParameterID:CHHapticDynamicParameterIDHapticIntensityControl value:played relativeTime:0],
        [[CHHapticDynamicParameter alloc] initWithParameterID:CHHapticDynamicParameterIDHapticSharpnessControl value:event->sharpness relativeTime:0],
    ];
    if (!eevee_rumbling) {
        [eevee_rumble sendParameters:controls atTime:CHHapticTimeImmediate error:nil];
        if (![eevee_rumble startAtTime:at error:&error]) {
            static int logged;
            if (logged++ < 3) EeveeLog(@"music haptics: the rumble did not start: %@", error);
            eevee_rumble = nil;
            return;
        }
        eevee_rumbling = YES;
    } else {
        [eevee_rumble sendParameters:controls atTime:at error:nil];
    }
    eevee_rumbleSentAt = heard;
    eevee_rumbleSent = level;
}

static void report(void) {
    static double lastReport;
    static int reports;
    double now = hostSeconds(mach_absolute_time());
    if (!lastReport) lastReport = now;
    if (now - lastReport < 30 || reports >= 4 || !eevee_stats.levels) return;
    lastReport = now;
    reports++;
    EeveeLog(@"music haptics: %lu taps (%lu too late), lead %.0f ms on average and %.0f ms at the least, %lu levels, rumble %@, buffers of %u frames at %.0f Hz (%llu skipped), output latency %.0f ms, strength %.0f%%, follows %d",
          (unsigned long)eevee_stats.taps, (unsigned long)eevee_stats.late, eevee_stats.taps ? eevee_stats.leadSum / eevee_stats.taps * 1000 : 0, eevee_stats.leadMin * 1000,
          (unsigned long)eevee_stats.levels, eevee_rumbling ? @"on" : @"off", atomic_load(&eevee_lastFrames), loadDouble(&eevee_sampleRateBits),
          (unsigned long long)atomic_load(&eevee_skipped), loadDouble(&eevee_latencyBits) * 1000, strength() * 100, atomic_load(&eevee_follows));
    eevee_stats = (Stats){0};
}

static double quietAfter(void) {
    double rate = loadDouble(&eevee_sampleRateBits);
    double buffer = rate > 0 ? atomic_load(&eevee_lastFrames) / rate : 0;
    return MAX(kQuietAfter, kQuietAfterBuffers * buffer);
}

static void *playerLoop(void *unused) {
    pthread_setname_np("EeveeSpotify.music-haptics");
    double lastEvent = 0;
    BOOL idle = YES;
    for (;;) {
        dispatch_time_t wait = idle ? DISPATCH_TIME_FOREVER : dispatch_time(DISPATCH_TIME_NOW, (int64_t)(quietAfter() * NSEC_PER_SEC));
        dispatch_semaphore_wait(eevee_wake, wait);
        @autoreleasepool {
            double now = hostSeconds(mach_absolute_time());
            if (!atomic_load(&eevee_listening)) {
                atomic_store(&eevee_tail, atomic_load(&eevee_head));
                stopEngine();
                idle = YES;
                continue;
            }
            EeveeMusicFollows follows = (EeveeMusicFollows)atomic_load(&eevee_follows);
            BOOL rumbles = follows != EeveeMusicFollowsBeat, snares = follows != EeveeMusicFollowsBass;
            if (!rumbles) stopRumble(CHHapticTimeImmediate);
            BOOL any = NO;
            unsigned head = atomic_load(&eevee_head), tail = atomic_load(&eevee_tail);
            if (tail != head && startEngine()) {
                for (; tail != head; tail++) {
                    EeveeMusicEvent event = eevee_ring[tail & (kRingSize - 1)];
                    if (event.kind == EeveeMusicEventLevel) {
                        if (rumbles) playLevel(&event);
                    } else if (event.kind == EeveeMusicEventKick || snares) {
                        playTap(&event);
                    }
                }
                any = YES;
            }
            atomic_store(&eevee_tail, head);
            if (any) {
                lastEvent = now;
                idle = NO;
                report();
                continue;
            }
            if (now - lastEvent >= quietAfter()) stopRumble(CHHapticTimeImmediate);
            if (now - lastEvent >= kEngineStopAfter) {
                stopEngine();
                idle = YES;
            }
        }
    }
    return NULL;
}

#pragma mark - the switch and the app

static void readLatency(void) {
    AVAudioSession *session = AVAudioSession.sharedInstance;
    storeDouble(&eevee_latencyBits, session.outputLatency);
    static int logged;
    if (logged++ < 6) EeveeLog(@"music haptics: output latency %.0f ms, IO buffer %.0f ms, route %@", session.outputLatency * 1000, session.IOBufferDuration * 1000, session.currentRoute.outputs.firstObject.portType);
}

static void updateListening(void) {
    BOOL listening = atomic_load(&eevee_enabled) && atomic_load(&eevee_active);
    if (atomic_exchange(&eevee_listening, listening) == listening) return;
    if (listening) {
        atomic_fetch_add(&eevee_generation, 1);
        readLatency();
        static dispatch_once_t once;
        dispatch_once(&once, ^{
            pthread_attr_t attributes;
            pthread_attr_init(&attributes);
            pthread_attr_set_qos_class_np(&attributes, QOS_CLASS_USER_INTERACTIVE, 0);
            pthread_t thread;
            pthread_create(&thread, &attributes, playerLoop, NULL);
            pthread_attr_destroy(&attributes);
        });
    }
    dispatch_semaphore_signal(eevee_wake);
}

void EeveeSetMusicHapticsEnabled(BOOL on) {
    if (!eevee_wake) return;
    atomic_store(&eevee_enabled, on);
    updateListening();
}

static void readSettings(void) {
    storeDouble(&eevee_strengthBits, EeveeHapticsStrength(EeveeKeyMusicStrength));
    atomic_store(&eevee_follows, (int)EeveeMusicHapticsFollows());
}

void EeveeMusicHapticsSettingsChanged(void) {
    if (!eevee_wake) return;
    readSettings();
    // A rumble that is not to play any more stops now rather than with the next event.
    dispatch_semaphore_signal(eevee_wake);
}

%ctor {
    EeveeMigrateKey(EeveeKeyMusicHapticsWas, EeveeKeyMusicHaptics);
    EeveeMigrateKey(EeveeKeyMusicStrengthWas, EeveeKeyMusicStrength);
    EeveeMigrateKey(EeveeKeyMusicFollowsWas, EeveeKeyMusicFollows);
    mach_timebase_info_data_t timebase;
    mach_timebase_info(&timebase);
    eevee_secondsPerTick = (double)timebase.numer / timebase.denom / 1e9;
    if (!EeveeRebindImport("AudioOutputUnitStart", startOutput, (void **)&eevee_startOutput) || !eevee_startOutput) {
        EeveeLog(@"music haptics: Spotify does not import AudioOutputUnitStart, Music Haptics is inactive");
        return;
    }
    eevee_wake = dispatch_semaphore_create(0);
    readSettings();
    atomic_store(&eevee_enabled, EeveeFlag(EeveeKeyMusicHaptics, NO));
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    [center addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note) {
        atomic_store(&eevee_active, true);
        updateListening();
    }];
    [center addObserverForName:UIApplicationWillResignActiveNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note) {
        atomic_store(&eevee_active, false);
        updateListening();
    }];
    [center addObserverForName:AVAudioSessionRouteChangeNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note) {
        if (atomic_load(&eevee_listening)) readLatency();
    }];
}
