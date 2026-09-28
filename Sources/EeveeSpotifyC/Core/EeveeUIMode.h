// Which of the two looks runs: spoti.pw's Liquid Glass redesign (Redesigned/), or Spotify's own
// screens with the mod's tweaks on them (Native/, and Shared/, which draws on neither). The merge
// dropped the redesign, so this build draws Spotify's own and the redesign is linked but never
// entered. Its settings entry, its switch and the restart prompt the switch put up went with it.
//
// The two answers below are therefore constants, and they are kept as functions rather than removed
// because every hook file of Native/ opens its %ctor with `if (!EeveeNativeUI()) return;` and every
// one of Redesigned/ with `if (!EeveeRedesignedUI()) return;`. That gate is what keeps the ported
// redesign from hooking the same Spotify classes as the native look, so both trees can stay in the
// build with the native one winning. The old Redesigned UI switch ("EeveeSpotify.redesign") is no
// longer read, so a stored one is ignored rather than honoured.
// Threading: safe from any thread.
#import <Foundation/Foundation.h>

BOOL EeveeRedesignedUI(void);   // Always NO: the redesign is not part of this build.
BOOL EeveeNativeUI(void);       // Always YES: Spotify's own screens, with the mod's tweaks on them.
