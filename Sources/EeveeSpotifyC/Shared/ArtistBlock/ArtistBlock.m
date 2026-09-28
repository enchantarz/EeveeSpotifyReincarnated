#import "ArtistBlock.h"
#import "Headers/SPTPlayer.h"

NSString *const EeveeArtistURI = @"uri";
NSString *const EeveeArtistName = @"name";

static const NSInteger kMaxCredits = 32;

NSArray<NSDictionary *> *EeveeBlockedArtists(void) {
    NSArray *list = [NSUserDefaults.standardUserDefaults arrayForKey:EeveeKeyArtistBlockList];
    return list ?: @[];
}

static void save(NSArray<NSDictionary *> *list) {
    [NSUserDefaults.standardUserDefaults setObject:list forKey:EeveeKeyArtistBlockList];
}

BOOL EeveeArtistBlocked(NSString *uri) {
    if (!uri.length) return NO;
    for (NSDictionary *artist in EeveeBlockedArtists()) {
        if ([artist[EeveeArtistURI] isEqualToString:uri]) return YES;
    }
    return NO;
}

void EeveeBlockArtist(NSDictionary *artist) {
    if (EeveeArtistBlocked(artist[EeveeArtistURI])) return;
    save([EeveeBlockedArtists() arrayByAddingObject:artist]);
}

void EeveeUnblockArtist(NSString *uri) {
    NSPredicate *other = [NSPredicate predicateWithBlock:^BOOL(NSDictionary *artist, NSDictionary *bindings) {
        return ![artist[EeveeArtistURI] isEqualToString:uri];
    }];
    save([EeveeBlockedArtists() filteredArrayUsingPredicate:other]);
}

static NSString *uriString(id value) {
    if ([value isKindOfClass:NSURL.class]) return ((NSURL *)value).absoluteString;
    return [value isKindOfClass:NSString.class] ? value : nil;
}

static void addArtist(NSMutableArray<NSDictionary *> *artists, NSString *uri, NSString *name) {
    if (![uri hasPrefix:@"spotify:artist:"]) return;
    for (NSDictionary *artist in artists) {
        if ([artist[EeveeArtistURI] isEqualToString:uri]) return;
    }
    [artists addObject:@{EeveeArtistURI: uri, EeveeArtistName: name.length ? name : uri}];
}

static NSString *nameString(id value) {
    return [value isKindOfClass:NSString.class] ? value : nil;
}

NSArray<NSDictionary *> *EeveeArtistsOfTrack(id object) {
    if (![object respondsToSelector:@selector(artistURI)] || ![object respondsToSelector:@selector(metadata)]) return @[];
    SPTPlayerTrack *track = object;
    NSDictionary *metadata = [track.metadata isKindOfClass:NSDictionary.class] ? track.metadata : nil;
    NSMutableArray<NSDictionary *> *artists = [NSMutableArray array];
    addArtist(artists, uriString(track.artistURI), nameString(track.artistName));
    addArtist(artists, uriString(metadata[@"artist_uri"]), nameString(metadata[@"artist_name"]));
    for (NSInteger i = 1; i < kMaxCredits; i++) {
        NSString *uri = uriString(metadata[[NSString stringWithFormat:@"artist_uri:%ld", (long)i]]);
        if (!uri) break;
        addArtist(artists, uri, nameString(metadata[[NSString stringWithFormat:@"artist_name:%ld", (long)i]]));
    }
    return artists;
}
