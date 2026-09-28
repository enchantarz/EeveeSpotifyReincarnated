// PlayerState.h names the hooks and why they are the ones.
#import "Core/EeveeCore.h"
#import "PlayerState.h"

NSString *EeveeURIString(id uri) {
    if ([uri isKindOfClass:NSString.class]) return uri;
    if ([uri isKindOfClass:NSURL.class]) return ((NSURL *)uri).absoluteString;
    return nil;
}

static NSHashTable<id<EeveePlayerStateObserver>> *eevee_stateObservers;
static SPTPlayerState *eevee_playerState;
static NSString *eevee_stateKey;
// Set once the now playing platform has reported; the mod's own observer on the player stands down.
static BOOL eevee_platformReported = NO;

void EeveeAddPlayerStateObserver(id<EeveePlayerStateObserver> observer) {
    if (!observer) return;
    if (!eevee_stateObservers) eevee_stateObservers = [NSHashTable weakObjectsHashTable];
    [eevee_stateObservers addObject:observer];
}

SPTPlayerState *EeveePlayerState(void) {
    return eevee_playerState;
}

// What an observer is told about; the state object itself is new with every position report.
static NSString *keyOf(SPTPlayerState *state) {
    SPTPlayerOptions *options = [state respondsToSelector:@selector(options)] ? state.options : nil;
    BOOL shuffling = [options respondsToSelector:@selector(shufflingContext)] && options.shufflingContext;
    return [NSString stringWithFormat:@"%@|%@|%d%d%d%d", EeveeURIString(state.track.URI), EeveeURIString(state.contextURI),
            state.isPaused, state.isPlaying, [state respondsToSelector:@selector(isLoading)] && state.isLoading, shuffling];
}

static void publish(SPTPlayerState *state) {
    eevee_playerState = state;
    NSString *key = keyOf(state);
    if ([key isEqualToString:eevee_stateKey]) return;
    eevee_stateKey = key;
    for (id<EeveePlayerStateObserver> observer in eevee_stateObservers.allObjects) [observer playerStateDidChange:state];
}

static void report(id state, BOOL platform) {
    if (![state isKindOfClass:objc_getClass("SPTPlayerState")]) return;
    dispatch_block_t apply = ^{
        if (platform) eevee_platformReported = YES;
        else if (eevee_platformReported) return;
        publish(state);
    };
    if (NSThread.isMainThread) apply();
    else dispatch_async(dispatch_get_main_queue(), apply);
}

@interface EeveePlayerObserver : NSObject
@end

@implementation EeveePlayerObserver
- (void)player:(id)player stateDidChange:(id)state {
    report(state, NO);
}
@end

static EeveePlayerObserver *eevee_ownObserver;
// The same player eevee_ownObserver is attached to, kept for features that have to act on it (the
// Live Activity's controls). Weak: the app owns it.
static __weak id<SPTPlayer> eevee_playerInstance;

id<SPTPlayer> EeveePlayerInstance(void) {
    return eevee_playerInstance;
}

%hook _TtC23NowPlaying_PlatformImpl28StatefulPlayerImplementation
- (void)player:(id)player stateDidChange:(id)state {
    %orig;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        EeveeLog(@"player state: from %@, a %@, on the main thread %d", [player class], [state class], NSThread.isMainThread);
    });
    report(state, YES);
}
%end

// Observers are added from several threads as the app starts; the first player seen is the one
// watched, the way KaraokeSource.x takes the first player the app asks.
%hook SPTEsperantoPlayer
- (void)addPlayerObserver:(id)observer {
    %orig;
    id player = self;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        eevee_playerInstance = (id<SPTPlayer>)player;
        dispatch_async(dispatch_get_main_queue(), ^{
            eevee_ownObserver = [EeveePlayerObserver new];
            [(id<SPTPlayer>)player addPlayerObserver:eevee_ownObserver];
            id state = [player respondsToSelector:@selector(state)] ? [(id<SPTPlayer>)player state] : nil;
            if (state) report(state, NO);
        });
    });
}
%end

%ctor {
    %init;
    EeveeRequireClasses(@[@"_TtC23NowPlaying_PlatformImpl28StatefulPlayerImplementation", @"SPTEsperantoPlayer", @"SPTPlayerState"]);
}
