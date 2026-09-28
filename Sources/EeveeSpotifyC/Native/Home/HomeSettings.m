#import "Core/EeveeCore.h"
#import "Settings/EeveeModPage.h"
#import "Home.h"
#import "Native/Playlist/Playlist.h"
#import "Native/Artist/Artist.h"
#import "Native/Album/Album.h"

static EeveeModRow *choiceRow(NSString *title, NSString *subtitle, EeveeHomeChoice choice) {
    return EeveeChoiceRow(title, subtitle, EeveeHomeChoiceKey(choice), EeveeHomeChoiceNames(choice),
                       EeveeHomeChoiceDefault(choice));
}

UIViewController *EeveeHomeGradientPage(void) {
    return [[EeveeModPage alloc] initWithTitle:@"Gradient"
                                      intro:@"Turning it on or off applies after you restart Spotify."
                                   sections:@[
        EeveeSection(@"Gradient", @[
            EeveeOptionRow(@"Show", nil, EeveeKeyHomeGradient),
            choiceRow(@"Colour", nil, EeveeHomeChoiceTint),
            choiceRow(@"Strength", nil, EeveeHomeChoiceStrength),
            choiceRow(@"Height", nil, EeveeHomeChoiceHeight),
        ]),
    ] footer:nil];
}

static UIViewController *libraryPage(void) {
    return [[EeveeModPage alloc] initWithTitle:@"Library" intro:nil sections:@[
        EeveeSection(@"Library", @[
            EeveeFlagRow(@"Denser rows", @"ios-feature-yourlibaryx.denser_rows_enabled"),
            EeveeFlagRow(@"Sort playlists by recently updated", @"ios-feature-yourlibaryx.recently_updated_playlists_sort_enabled"),
            EeveeFlagRow(@"Sort artists by recently updated", @"ios-feature-yourlibaryx.recently_updated_artists_sort_enabled"),
            EeveeFlagRow(@"Recents", @"ios-feature-yourlibaryx.recents_enabled"),
            EeveeFlagRow(@"Recents sort order", @"ios-feature-yourlibaryx.recents_sort_order_enabled"),
            EeveeFlagRow(@"Library settings", @"ios-feature-yourlibaryx.library_settings_enabled"),
            EeveeFlagRow(@"Library Pro", @"ios-feature-yourlibaryx.your_library_pro_enabled"),
        ]),
    ] footer:nil];
}

UIViewController *EeveeHomeSettingsPage(void) {
    // The row reads its own state out, so the section says which colour is set without being opened.
    EeveeModRow *gradient = EeveePageRow(@"Gradient", ^UIViewController *{ return EeveeHomeGradientPage(); });
    gradient.value = ^NSString *{
        if (!EeveeFlag(EeveeKeyHomeGradient, NO)) return @"Off";
        return EeveeHomeChoiceNames(EeveeHomeChoiceTint)[(NSUInteger)EeveeHomeChoiceValue(EeveeHomeChoiceTint)];
    };

    NSArray<EeveeModSection *> *sections = @[
        EeveeSection(nil, @[
            EeveeWithSymbol(EeveePageRow(@"Playlists", ^UIViewController *{ return EeveePlaylistSettingsPage(); }), @"music.note.list"),
            EeveeWithSymbol(EeveePageRow(@"Library", ^UIViewController *{ return libraryPage(); }), @"books.vertical"),
            EeveeWithSymbol(EeveePageRow(@"Album", ^UIViewController *{ return EeveeAlbumSettingsPage(); }), @"square.stack"),
            EeveeWithSymbol(EeveePageRow(@"Artist", ^UIViewController *{ return EeveeArtistSettingsPage(); }), @"music.mic"),
        ]),
        EeveeSection(@"Home", @[
            EeveeWithSymbol(gradient, @"rectangle.tophalf.inset.filled"),
            EeveeFlagRow(@"Pull to refresh", @"ios-home-evopage-impl.pull_to_refresh_enabled"),
        ]),
        EeveeSection(@"Hide on Home", @[
            EeveeHideRow(@"Filter pills", nil, EeveeHideHomePills),
            EeveeHideRow(@"Shortcuts grid", nil, EeveeHideHomeShortcuts),
            EeveeHideRow(@"Promo cards", nil, EeveeHideHomePromo),
            EeveeHideRow(@"Preview cards", nil, EeveeHideHomePreviews),
            EeveeHideRow(@"DJ card", nil, EeveeHideHomeDJ),
            EeveeKillRow(@"DJ button", @"ios-home-evopage-impl.idj_show_dj_button"),
            EeveeKillRow(@"DJ beta badge", @"ios-home-evopage-impl.dj_mdc_beta_badge_enabled"),
        ]),
    ];
    return [[EeveeModPage alloc] initWithTitle:@"Home & Library" intro:nil sections:sections footer:nil];
}
