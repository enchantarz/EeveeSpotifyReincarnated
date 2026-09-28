// Labs: Spotify's flags for features it built and did not ship; every row forces one flag.
#import "Settings/EeveeModPage.h"
#import "Flags.h"

static UIViewController *martiniPage(void) {
    return [[EeveeModPage alloc] initWithTitle:@"AI Chat (Martini)" intro:EeveeRestartNote sections:@[
        EeveeSection(@"On Home", @[
            EeveeFlagRow(@"Chat entry point", @"ios-home-evopage-impl.interactive_entrypoint_enabled"),
            EeveeFlagRow(@"Martini behind it", @"ios-home-evopage-impl.interactive_entrypoint_martini_enabled"),
            EeveeFlagRow(@"Floating chat", @"ios-home-evopage-impl.interactive_entrypoint_floating_chat_enabled"),
            EeveeFlagRow(@"Microphone", @"ios-home-evopage-impl.interactive_entrypoint_mic_enabled"),
            EeveeFlagRow(@"Glowing pill", @"ios-home-evopage-impl.interactive_entrypoint_pill_glow_enabled"),
        ]),
        EeveeSection(@"The chat", @[
            EeveeFlagRow(@"Intent pills", @"ios-martini-floatingchat-impl.intent_pills_enabled"),
            EeveeFlagRow(@"Thinking states", @"ios-martini-floatingchat-impl.thinking_states_enabled"),
            EeveeFlagRow(@"Voice recording", @"ios-martini-floatingchat-impl.voice_recording_enabled"),
        ]),
        EeveeSection(@"In the player", @[
            EeveeFlagRow(@"Chat entry point", @"ios-martini-npvcardprovider-impl.floating_chat_entry_point_enabled"),
        ]),
    ] footer:nil];
}

UIViewController *EeveeLabsPage(void) {
    return [[EeveeModPage alloc] initWithTitle:@"Labs" intro:@"Unreleased features; some do nothing on your version. Changes apply after you restart Spotify." sections:@[
        EeveeSection(nil, @[
            EeveeWithSymbol(EeveePageRow(@"AI Chat (Martini)", ^UIViewController *{ return martiniPage(); }), @"bubble.left.and.bubble.right"),
        ]),
        EeveeSection(@"Library", @[
            EeveeFlagRow(@"Local files from the Files app", @"ios-feature-localfiles.documents_enabled"),
        ]),
        EeveeSection(@"Home screen widget", @[
            EeveeFlagRow(@"Progress bar", @"ios-widgets-widgetremoteconfig-impl.progress_bar_enabled"),
        ]),
        // The note that stood here said the options sheet was always on in the redesign, which used
        // to force the flag (EeveeRGlassDesign.x). The redesign is not part of this build, so nothing
        // forces it and the row is an ordinary one.
        EeveeSection(@"Sleep timer", @[
            EeveeFlagRow(@"Fade out", @"ios-feature-sleeptimer.enable_fade_out"),
            EeveeFlagRow(@"One minute option", @"ios-feature-sleeptimer.enable_one_minute_option"),
            EeveeFlagRow(@"Options sheet", @"ios-feature-sleeptimer.use_options_sheet"),
        ]),
        EeveeSection(@"Player", @[
            EeveeFlagRow(@"Snake on the cover art", @"ios-feature-cover-art-snake.enabled"),
        ]),
        EeveeSection(@"Podcast comments", @[
            EeveeFlagRow(@"Comments card", @"ios-feature-comments.enable_comments_card"),
            EeveeFlagRow(@"Pinned comments", @"ios-feature-comments.enable_pinned_comments"),
            EeveeFlagRow(@"Several reactions", @"ios-feature-comments.enable_multi_reactions"),
        ]),
    ] footer:nil];
}
