# Deployment target is 16.0, not 14.0. The merge forces it three ways: the ported spoti.pw sources
# came from a tweak built at iphone:clang:latest:16.0 and use iOS 15+ API (UIButtonConfiguration) on
# unguarded paths; modules/libjamesdsp is compiled for arm64-apple-ios16.0 and linking it into a
# 14.0 dylib is a min-version mismatch; and the Spotify builds this targets need iOS 16.1 or newer
# anyway (Spotify 9.1.86 declares MinimumOSVersion 16.1), so nothing below 16.0 could load it.
TARGET := iphone:clang:latest:16.0
INSTALL_TARGET_PROCESSES = Spotify
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = EeveeSpotify

REPO_SLUG ?= $(shell git remote get-url origin 2>/dev/null | sed -E 's|.*github\.com[:/]([^/]+/[^/.]+)(\.git)?$$|\1|')
REPO_SLUG_FINAL := $(if $(REPO_SLUG),$(REPO_SLUG),jaydenjcpy/EeveeSpotifyReincarnated)

BRANCH_NAME ?= $(shell git rev-parse --abbrev-ref HEAD 2>/dev/null)
BRANCH_NAME_FINAL := $(if $(BRANCH_NAME),$(BRANCH_NAME),Master)

$(shell mkdir -p Sources/EeveeSpotify/Generated)
$(shell printf 'enum GeneratedConfig {\n    static let repoSlug = "%s"\n    static let branchName = "%s"\n}\n' "$(REPO_SLUG_FINAL)" "$(BRANCH_NAME_FINAL)" > Sources/EeveeSpotify/Generated/RepoSlug.swift)

# spoti.pw sources were merged into Sources/EeveeSpotifyC (Objective-C/Logos) and
# Sources/EeveeSpotify (Swift) at tag v0.21.1, the last GPL-3.0 release. Its own version
# number is kept so the ported settings page can still show what it came from.
EEVEE_SPOTIPW_VERSION := 0.21.1
EEVEE_SPOTIPW_DEFS = -DEEVEE_SPOTIPW_VERSION=\"$(EEVEE_SPOTIPW_VERSION)\"

EeveeSpotify_FILES = $(shell find Sources/EeveeSpotify -name '*.swift') $(shell find Sources/EeveeSpotifyC -name '*.m' -o -name '*.c' -o -name '*.mm' -o -name '*.cpp' -o -name '*.x' | sort)
# Sources/EeveeSpotifyC itself is on the Swift path as well as its include/: the SwiftUI renderer of
# the ported pages (Settings/Sections/Spotipw/Views/EeveeModPageView.swift) reads the row model out
# of Settings/EeveeModPage.h, which the tree reaches as "Settings/EeveePage.h" and "Core/...".
EeveeSpotify_SWIFTFLAGS = -ISources/EeveeSpotifyC/include -ISources/EeveeSpotifyC -Osize
EeveeSpotify_EXTRA_FRAMEWORKS = EeveeSwiftProtobuf
# The ported sources reach their headers as "Core/EeveeCore.h", "Settings/EeveePage.h" and so
# on, so Sources/EeveeSpotifyC has to be on the include path as well as its include/ dir.
EeveeSpotify_CFLAGS = -fobjc-arc -ISources/EeveeSpotifyC/include -ISources/EeveeSpotifyC $(EEVEE_SPOTIPW_DEFS) -Os
# Frameworks the ported UI needs (spoti.pw's tweak/Makefile list).
EeveeSpotify_EXTRA_FRAMEWORKS += UIKit QuartzCore UniformTypeIdentifiers MediaPlayer CoreImage AudioToolbox AVFoundation CoreHaptics
# ActivityKit + AppIntents back the ported Live Activity (Sources/EeveeSpotify/LiveActivity); the
# widget half of it is the appex under LiveActivityExtension/, built by `make liveactivity`.
EeveeSpotify_EXTRA_FRAMEWORKS += ActivityKit AppIntents

# RootHide's compatibility implementation of libroot resolves jailbreak paths
# through libroothide at runtime. Rootless builds continue to use libroot.
ifeq ($(THEOS_PACKAGE_SCHEME),roothide)
EeveeSpotify_SWIFTFLAGS += -D ROOTHIDE
EeveeSpotify_LDFLAGS += -lroothide -Xlinker -rpath -Xlinker @loader_path/.jbroot/Library/Frameworks
else
EeveeSpotify_LDFLAGS += -lroot
endif

# Sideload compatibility (keychain redirect, group containers, CloudKit) is
# handled out-of-process by modules/zxPluginsInject — LC-injected via ipapatch
# in Scripts/build-merged-ipa.sh and the GitHub workflow. No flags needed here.

# The ported JamesDSP engine (Shared/JamesDSP) is third-party C of its own: it builds into a
# static library with its own flags out of modules/libjamesdsp, and is linked in as an object
# file. Only Shared/JamesDSP/EeveeDSPEngine.m sees its headers.
EEVEE_JDSP := modules/libjamesdsp
EeveeSpotify_OBJ_FILES := $(EEVEE_JDSP)/build/ios/libjamesdsp.a
Sources/EeveeSpotifyC/Shared/JamesDSP/EeveeDSPEngine.m_CFLAGS := \
	-isystem $(EEVEE_JDSP)/subtree/Main/libjamesdsp/jni/jamesdsp/jdsp -isystem $(EEVEE_JDSP)

# Spotify reads its remote-config flags by key; EeveeFlagList.m is the table of every one of them,
# recovered from the decrypted IPA. It is not committed — run this once before the first build, and
# again when the IPA changes.
.PHONY: flags
flags:
	Scripts/extract-flags.py $(firstword $(wildcard ipa/*.ipa))

# The Live Activity widget extension. It is a separate process WidgetKit only launches from inside
# the host app's bundle, so it cannot ride in the .deb — `make ipa` puts it in the IPA.
IPA ?= $(firstword $(wildcard ipa/*.ipa))

.PHONY: liveactivity
# The host Info.plist is unpacked to a file rather than handed over with a process substitution:
# make runs recipes with /bin/sh, which has none.
liveactivity:
	@mkdir -p out
	unzip -p $(IPA) 'Payload/Spotify.app/Info.plist' > out/host-Info.plist
	Scripts/build-liveactivity.sh out/host-Info.plist out/liveactivity

# The tweak and the widget in one decrypted IPA: out/EeveeSpotify-Merged.ipa, unsigned.
.PHONY: ipa
ipa:
	Scripts/build-merged-ipa.sh $(IPA) out/EeveeSpotify-Merged.ipa

include $(THEOS_MAKE_PATH)/tweak.mk

# The library is brought up to date before the tweak builds, so the link finds it current.
EeveeSpotify.all.tweak.variables: eevee-libjamesdsp
.PHONY: eevee-libjamesdsp
# You have to agree to the GPL-2 engine's terms to build it: see modules/libjamesdsp/LICENSE.
eevee-libjamesdsp:
	@$(MAKE) --no-print-directory -C $(EEVEE_JDSP) JDSP_PLATFORM=ios

internal-stage::
	# Bundle EeveeSwiftProtobuf.framework into the package. Renamed from
	# SwiftProtobuf so the @objc class names don't collide with the
	# SwiftProtobuf statically embedded in SpotifyShared.framework.
	mkdir -p $(THEOS_STAGING_DIR)/Library/Frameworks
	cp -r $(THEOS)/lib/iphone/$(or $(THEOS_PACKAGE_SCHEME),rootless)/EeveeSwiftProtobuf.framework $(THEOS_STAGING_DIR)/Library/Frameworks/
	# Compile the karaoke background Metal shader into a .metallib and
	# stage it next to the tweak binary so device.makeLibrary(filepath:)
	# can load it at runtime (Theos's tweak.mk has no built-in Metal
	# shader compilation step the way an Xcode app target's build phases
	# do, so this is done by hand here — UNTESTED, no Theos/Metal
	# toolchain was available to verify this actually produces a working
	# .metallib or that the staged path is correct; if `make package`
	# fails at this step or the shader doesn't load at runtime, check
	# this block first).
	xcrun -sdk iphoneos metal -c Sources/EeveeSpotify/Karaoke/KaraokeBackgroundShader.metal \
		-o $(THEOS_OBJ_DIR)/KaraokeBackgroundShader.air
	xcrun -sdk iphoneos metallib $(THEOS_OBJ_DIR)/KaraokeBackgroundShader.air \
		-o $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries/KaraokeBackgroundShader.metallib
	# The alternate app icons ride in the tweak bundle: on a jailbreak install the app bundle is
	# stock (its Info.plist has no CFBundleAlternateIcons), so the icon picker reaches for the
	# choices here. Tools/alt-icons.sh is what registers them into a built IPA, where iOS's own
	# alternate-icon switcher can use them (see Scripts/build-merged-ipa.sh).
	mkdir -p "$(THEOS_STAGING_DIR)/Library/Application Support/EeveeSpotify.bundle/AppIcons"
	cp -f Assets/AppIcon/*.png "$(THEOS_STAGING_DIR)/Library/Application Support/EeveeSpotify.bundle/AppIcons/"

# Build EeveeSwiftProtobuf.framework from apple/swift-protobuf source. Run
# this once before `make package`. Re-run if SWIFTPROTOBUF_VERSION changes
# or `swift --version` jumps a major.
build-eeveeswiftprotobuf:
	Tools/SwiftProtobufBuild/build-eeveeswiftprotobuf.sh
