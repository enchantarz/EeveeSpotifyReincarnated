#import "EeveeUIMode.h"
#import "EeveeLog.h"

// spoti.pw picked between its redesign and Spotify's own look once per launch. The merge dropped the
// redesign, so there is nothing left to pick and the answer is the native look, always. See
// EeveeUIMode.h for why the functions stayed rather than being folded away.
BOOL EeveeRedesignedUI(void) {
    // Called from every Native/ and Redesigned/ constructor, so the line is said once. It is worth
    // saying: a phone that had the switch on has a stored "EeveeSpotify.redesign" this build no
    // longer reads, and this is how a log says so rather than leaving it to be inferred.
    static dispatch_once_t once;
    dispatch_once(&once, ^{ EeveeLog(@"ui: native (this build does not carry the redesign)"); });
    return NO;
}

BOOL EeveeNativeUI(void) {
    return !EeveeRedesignedUI();
}
