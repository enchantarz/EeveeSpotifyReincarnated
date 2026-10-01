// The flags something of the mod's forces, gathered in one place so that the flag provider
// (Shared/Flags/Flags.x) and the flag rows of the settings pages ask here rather than knowing every
// feature that forces one. Nothing registers a forcer in this build — the redesign's went with it —
// so the provider reads only the All flags page's own overrides.
//
// A forcer answers a flag key with the value it forces, or nil. `atLaunch` answers for the running
// app, from the switches as they were at launch; `locked`, which may be nil, answers for a settings
// row, from the switches as they are stored now, and a row it answers for shows that value and takes
// no touch. A forcer that `beatsOverride` is asked before an override from the All flags page, the
// rest after it; within each group in the order they were registered.
// Threading: register from a %ctor or a constructor, before Spotify reads a flag; ask from any thread.
#import <Foundation/Foundation.h>

typedef id (^EeveeFlagForcer)(NSString *key);

void EeveeRegisterFlagForcer(BOOL beatsOverride, EeveeFlagForcer atLaunch, EeveeFlagForcer locked);

// The value the provider hands Spotify: forcers that beat an override, the override, then the rest.
id EeveeForcedFlagValue(NSString *key);
// The value a settings row is locked at, nil when none; `beatsOverride` says whether an override
// from the All flags page gives way to it.
id EeveeLockedFlagValue(NSString *key, BOOL *beatsOverride);
