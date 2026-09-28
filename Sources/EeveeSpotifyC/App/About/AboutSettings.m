#import "Core/EeveeCore.h"
#import "Settings/EeveePageStyle.h"
#import "About.h"
#import "App/Onboarding/Onboarding.h"

// Every key of the mod's is under one prefix, so a reset is a sweep of the defaults with the stock
// marker of EeveePrefs.h left behind; the hooks read them at launch, so it ends in a restart.
static void resetAll(void) {
    NSUserDefaults *store = NSUserDefaults.standardUserDefaults;
    NSUInteger removed = 0;
    for (NSString *key in [store persistentDomainForName:NSBundle.mainBundle.bundleIdentifier].allKeys) {
        if (![key hasPrefix:@"EeveeSpotify."]) continue;
        [store removeObjectForKey:key];
        removed++;
    }
    [store setBool:YES forKey:EeveeKeyStock];
    EeveeLog(@"reset: removed %lu keys", (unsigned long)removed);
    EeveeRestartSpotify();
}

static void confirmReset(void) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Reset all settings?"
                                                                  message:@"Every switch goes off, flag overrides and the tab bar layout are cleared, and Spotify restarts as it came, with the mod doing nothing until asked. Spotify's own settings are untouched."
                                                           preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Reset and restart" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) { resetAll(); }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [EeveeTopController() presentViewController:alert animated:YES completion:nil];
}

static EeveeModRow *withSymbol(EeveeModRow *row, NSString *symbol) {
    row.symbol = symbol;
    return row;
}

// Which build this is and where to reach the mod.
UIViewController *EeveeAboutPage(void) {
    EeveeModRow *reset = withSymbol(EeveeActionRow(@"Reset all settings", nil, ^{ confirmReset(); }), @"trash");
    reset.color = EeveeRed();
    NSString *spotify = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"unknown";
    return [[EeveeModPage alloc] initWithTitle:@"Mod" intro:nil sections:@[
        EeveeSection(nil, @[
            EeveeStatRow(@"Version", ^NSString *{ return @(EEVEE_SPOTIPW_VERSION); }),
            EeveeStatRow(@"Spotify", ^NSString *{ return spotify; }),
        ]),
        EeveeSection(nil, @[
            withSymbol(EeveeLinkRow(@"Website", nil, EeveeSiteURL), @"safari"),
            withSymbol(EeveeLinkRow(@"GitHub", nil, EeveeRepoURL), @"chevron.left.forwardslash.chevron.right"),
            withSymbol(EeveeActionRow(@"Welcome tour", nil, ^{ EeveeShowOnboarding(); }), @"map"),
        ]),
        EeveeSection(nil, @[
            withSymbol(EeveeActionRow(@"Export settings", nil, ^{ EeveeExportSettings(); }), @"square.and.arrow.up"),
            withSymbol(EeveeActionRow(@"Import settings", nil, ^{ EeveeImportSettings(); }), @"square.and.arrow.down"),
        ]),
        EeveeSection(nil, @[reset]),
    ] footer:nil];
}
