// JamesDSP's file libraries: Documents/EeveeSpotify/JamesDSP/<Convolver|DDC|Liveprog>, where the file effects
// find their files by name. Documents, which the app's backups keep.
//
// The first time a library is made it gets the files JamesDSP ships (RootlessJamesDSP's Liveprog scripts
// and DDC presets, compiled into the tweak by vendor/libjamesdsp/embed-assets.pl); a file deleted after
// that stays deleted. The convolver's impulse responses are the user's own: RootlessJamesDSP's samples
// are 7 MB.
//
// Threading: any thread (the engine's queue reads the paths too); a library is made once.
#import <os/lock.h>
#import "Core/EeveeCore.h"
#import "JamesDSP.h"
#import "JamesDSPEngine.h"
#import "EeveeDSPEngine.h"

static NSString *const EeveeDSPFileErrorDomain = @"EeveeSpotify.dsp.files";

static NSString *libraryName(EeveeDSPFileKind kind) {
    switch (kind) {
    case EeveeDSPFileImpulseResponse: return @"Convolver";
    case EeveeDSPFileDDC: return @"DDC";
    case EeveeDSPFileLiveprog: return @"Liveprog";
    }
    return @"Other";
}

// The key naming the file an effect uses, and its switch, for a library.
static NSString *fileKey(EeveeDSPFileKind kind) {
    switch (kind) {
    case EeveeDSPFileImpulseResponse: return EeveeKeyDSPConvolverFile;
    case EeveeDSPFileDDC: return EeveeKeyDSPDDCFile;
    case EeveeDSPFileLiveprog: return EeveeKeyDSPLiveprogFile;
    }
    return nil;
}

NSArray<NSString *> *EeveeDSPFileExtensions(EeveeDSPFileKind kind) {
    switch (kind) {
    case EeveeDSPFileImpulseResponse: return @[@"wav", @"flac", @"irs"];
    case EeveeDSPFileDDC: return @[@"vdc"];
    case EeveeDSPFileLiveprog: return @[@"eel"];
    }
    return @[];
}

// The bundled files of the library's kind written into it, none replacing a file already there.
static void installBundled(EeveeDSPFileKind kind, NSString *directory) {
    NSString *wanted = libraryName(kind);
    NSUInteger installed = 0;
    const char *bundledKind, *name;
    const void *data;
    size_t length;
    for (unsigned i = 0; EeveeDSPEngineBundledFile(i, &bundledKind, &name, &data, &length); i++) {
        if (![wanted isEqualToString:@(bundledKind)]) continue;
        NSString *path = [directory stringByAppendingPathComponent:@(name)];
        if ([NSFileManager.defaultManager fileExistsAtPath:path]) continue;
        if ([[NSData dataWithBytes:data length:length] writeToFile:path atomically:YES]) installed++;
    }
    if (installed) EeveeLog(@"jamesdsp: the %@ library holds the %lu files JamesDSP ships", wanted, (unsigned long)installed);
}

NSString *EeveeDSPLibraryDirectory(EeveeDSPFileKind kind) {
    static os_unfair_lock lock = OS_UNFAIR_LOCK_INIT;
    NSString *documents = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *directory = [[documents stringByAppendingPathComponent:@"EeveeSpotify/JamesDSP"] stringByAppendingPathComponent:libraryName(kind)];
    os_unfair_lock_lock(&lock);
    BOOL isDirectory = NO;
    if (![NSFileManager.defaultManager fileExistsAtPath:directory isDirectory:&isDirectory] || !isDirectory) {
        NSError *error = nil;
        if ([NSFileManager.defaultManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:&error]) {
            installBundled(kind, directory);
        } else {
            EeveeLog(@"jamesdsp: the %@ library could not be made: %@", libraryName(kind), error);
        }
    }
    os_unfair_lock_unlock(&lock);
    return directory;
}

NSArray<NSString *> *EeveeDSPLibraryFiles(EeveeDSPFileKind kind) {
    NSString *directory = EeveeDSPLibraryDirectory(kind);
    NSArray<NSString *> *extensions = EeveeDSPFileExtensions(kind);
    NSMutableArray<NSString *> *names = [NSMutableArray array];
    for (NSString *name in [NSFileManager.defaultManager contentsOfDirectoryAtPath:directory error:nil]) {
        if ([name hasPrefix:@"."] || ![extensions containsObject:name.pathExtension.lowercaseString]) continue;
        BOOL isDirectory = NO;
        if ([NSFileManager.defaultManager fileExistsAtPath:[directory stringByAppendingPathComponent:name] isDirectory:&isDirectory] && !isDirectory) {
            [names addObject:name];
        }
    }
    return [names sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
}

static NSError *fileError(NSString *message) {
    return [NSError errorWithDomain:EeveeDSPFileErrorDomain code:1 userInfo:@{NSLocalizedDescriptionKey: message}];
}

// Whether the bytes look like a file of the kind, before it goes into the library: a WAV (RIFF, RF64) or
// FLAC stream, a DDC file's two rates, a Liveprog script's @sample section.
static BOOL looksLike(EeveeDSPFileKind kind, NSData *data) {
    if (kind == EeveeDSPFileImpulseResponse) {
        if (data.length < 12) return NO;
        const char *bytes = data.bytes;
        return !memcmp(bytes, "RIFF", 4) || !memcmp(bytes, "RF64", 4) || !memcmp(bytes, "fLaC", 4);
    }
    NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]
                     ?: [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];
    if (kind == EeveeDSPFileDDC) return [text containsString:@"SR_44100"] && [text containsString:@"SR_48000"];
    return [text containsString:@"@sample"];
}

NSString *EeveeDSPImportFile(EeveeDSPFileKind kind, NSURL *url, NSError **error) {
    NSString *name = url.lastPathComponent;
    NSArray<NSString *> *extensions = EeveeDSPFileExtensions(kind);
    NSString *kindName = kind == EeveeDSPFileImpulseResponse ? @"an impulse response" : kind == EeveeDSPFileDDC ? @"a DDC file" : @"a Liveprog script";
    if (!name.length || [name hasPrefix:@"."] || ![extensions containsObject:name.pathExtension.lowercaseString]) {
        if (error) *error = fileError([NSString stringWithFormat:@"%@ is not %@ (.%@)", name ?: @"The file", kindName,
                                       [extensions componentsJoinedByString:@", ."]]);
        return nil;
    }
    BOOL scoped = [url startAccessingSecurityScopedResource];
    NSError *readError = nil;
    NSData *data = [NSData dataWithContentsOfURL:url options:NSDataReadingMappedIfSafe error:&readError];
    if (scoped) [url stopAccessingSecurityScopedResource];
    if (!data) {
        if (error) *error = readError ?: fileError([NSString stringWithFormat:@"%@ could not be read", name]);
        return nil;
    }
    if (!looksLike(kind, data)) {
        if (error) *error = fileError([NSString stringWithFormat:@"%@ is not %@", name, kindName]);
        return nil;
    }
    NSString *path = [EeveeDSPLibraryDirectory(kind) stringByAppendingPathComponent:name];
    NSError *writeError = nil;
    if (![data writeToFile:path options:NSDataWritingAtomic error:&writeError]) {
        if (error) *error = writeError;
        return nil;
    }
    EeveeLog(@"jamesdsp: %@ added to the %@ library (%lu bytes)", name, libraryName(kind), (unsigned long)data.length);
    // A file replaced while an effect uses it is read again.
    if ([EeveeDSPString(fileKey(kind)) isEqualToString:name]) EeveeDSPApply(EeveeDSPEffectOf(fileKey(kind)));
    return name;
}

BOOL EeveeDSPDeleteFile(EeveeDSPFileKind kind, NSString *name) {
    if (!name.length || ![name.lastPathComponent isEqualToString:name] || [name hasPrefix:@"."]) return NO;
    NSString *path = [EeveeDSPLibraryDirectory(kind) stringByAppendingPathComponent:name];
    NSError *error = nil;
    if (![NSFileManager.defaultManager removeItemAtPath:path error:&error]) {
        EeveeLog(@"jamesdsp: %@ could not be deleted: %@", name, error);
        return NO;
    }
    EeveeLog(@"jamesdsp: %@ deleted from the %@ library", name, libraryName(kind));
    // The effect using it lets it go (and says the file is gone).
    if ([EeveeDSPString(fileKey(kind)) isEqualToString:name]) EeveeDSPApply(EeveeDSPEffectOf(fileKey(kind)));
    return YES;
}
