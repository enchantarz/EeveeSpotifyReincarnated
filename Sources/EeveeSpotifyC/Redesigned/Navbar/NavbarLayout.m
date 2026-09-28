// The saved composition of the redesign's bar, as NSUserDefaults property lists, apart from the native look's.
#import "Navbar.h"
#import "Shared/Navigation/Links.h"

NSString *const EeveeRNavbarID = @"id";
NSString *const EeveeRNavbarTitle = @"title";
NSString *const EeveeRNavbarURI = @"uri";
NSString *const EeveeRNavbarIcon = @"icon";
NSString *const EeveeRNavbarHidden = @"hidden";

static NSString *const kNavbarLayout = @"EeveeSpotify.redesign.navbar.layout";
static NSString *const kNavbarStock = @"EeveeSpotify.redesign.navbar.stock";

// Only property list types go in, so a corrupt read cannot be anything but an array of dictionaries.
static NSArray *listOfKind(NSString *key, Class kind) {
    NSArray *list = [NSUserDefaults.standardUserDefaults arrayForKey:key];
    for (id item in list) if (![item isKindOfClass:kind]) return @[];
    return list ?: @[];
}

NSArray<NSDictionary *> *EeveeRNavbarLayout(void) {
    return listOfKind(kNavbarLayout, NSDictionary.class);
}

void EeveeRSetNavbarLayout(NSArray<NSDictionary *> *layout) {
    [NSUserDefaults.standardUserDefaults setObject:layout ?: @[] forKey:kNavbarLayout];
}

NSArray<NSString *> *EeveeRNavbarStock(void) {
    return listOfKind(kNavbarStock, NSString.class);
}

void EeveeRSetNavbarStock(NSArray<NSString *> *stock) {
    [NSUserDefaults.standardUserDefaults setObject:stock ?: @[] forKey:kNavbarStock];
}

NSURL *EeveeRNavbarTabURL(NSString *uri) {
    NSURL *url = EeveeSpotifyURIFromText(uri);
    if ([url.absoluteString isEqualToString:@"spotify:collection:playlists"]) return [NSURL URLWithString:@"spotify:playlists"];
    return url;
}
