// The saved composition of the bar, as NSUserDefaults property lists.
#import "Navbar.h"

NSString *const EeveeNavbarID = @"id";
NSString *const EeveeNavbarTitle = @"title";
NSString *const EeveeNavbarURI = @"uri";
NSString *const EeveeNavbarIcon = @"icon";
NSString *const EeveeNavbarHidden = @"hidden";

static NSString *const kNavbarLayout = @"EeveeSpotify.navbar.layout";
static NSString *const kNavbarStock = @"EeveeSpotify.navbar.stock";

// Only property list types go in, so a corrupt read cannot be anything but an array of dictionaries.
static NSArray *listOfKind(NSString *key, Class kind) {
    NSArray *list = [NSUserDefaults.standardUserDefaults arrayForKey:key];
    for (id item in list) if (![item isKindOfClass:kind]) return @[];
    return list ?: @[];
}

NSArray<NSDictionary *> *EeveeNavbarLayout(void) {
    return listOfKind(kNavbarLayout, NSDictionary.class);
}

void EeveeSetNavbarLayout(NSArray<NSDictionary *> *layout) {
    [NSUserDefaults.standardUserDefaults setObject:layout ?: @[] forKey:kNavbarLayout];
}

NSArray<NSString *> *EeveeNavbarStock(void) {
    return listOfKind(kNavbarStock, NSString.class);
}

void EeveeSetNavbarStock(NSArray<NSString *> *stock) {
    [NSUserDefaults.standardUserDefaults setObject:stock ?: @[] forKey:kNavbarStock];
}
