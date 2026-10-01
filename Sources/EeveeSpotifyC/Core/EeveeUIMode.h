// Whether the mod's native-look hooks install. spoti.pw shipped two looks and picked between them
// once per launch; the merge kept only Spotify's own screens with the mod's tweaks on them, so this
// is always YES. Every Native/ hook opens its %ctor with `if (!EeveeNativeUI()) return;`: the gate is
// kept as the one place that answer lives rather than being deleted from every file.
#import <Foundation/Foundation.h>

BOOL EeveeNativeUI(void);   // Always YES: Spotify's own screens, with the mod's tweaks on them.
