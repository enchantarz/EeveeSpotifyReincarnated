#import "Core/EeveeCore.h"
#import "Settings/EeveeModPage.h"
#import "Settings/EeveePageStyle.h"
#import "EeveeRAccent.h"

// Going back to Spotify's green is offered only once a colour of the mod's is set, so a stray tap
// cannot wipe it.
static void chooseAccent(void) {
    if (!EeveeRAccentColor()) {
        EeveeRPickAccent();
        return;
    }
    UIViewController *top = EeveeTopController();
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"Accent colour" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Pick a colour" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) { EeveeRPickAccent(); }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Spotify's green" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) { EeveeSetInt(EeveeRKeyAccent, -1); }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    sheet.popoverPresentationController.sourceView = top.view;
    sheet.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(top.view.bounds), CGRectGetMidY(top.view.bounds), 0, 0);
    sheet.popoverPresentationController.permittedArrowDirections = 0;
    [top presentViewController:sheet animated:YES completion:nil];
}

// The redesign's rows of the Appearance card (App/Pages.m). AMOLED has no row: the redesign is always black.
NSArray<EeveeModRow *> *EeveeRAppearanceRows(void) {
    return @[
        EeveeWithSymbol(EeveeStatActionRow(@"Accent colour", nil, ^NSString *{ return EeveeRAccentLabel(); }, ^{ chooseAccent(); }), @"paintpalette"),
    ];
}
