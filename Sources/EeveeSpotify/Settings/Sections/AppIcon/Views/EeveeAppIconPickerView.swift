import SwiftUI
import UIKit

private let primaryIconKey = "__primary__"
private let selectedKeyDefault = "EeveeSelectedAppIconName"

/// Where an icon's files live. `.appBundle` icons are registered as CFBundleAlternateIcons on the
/// app's own Info.plist — Tools/alt-icons.sh does that for every built IPA — so iOS's own switcher
/// applies them. `.tweakBundle` icons are the same files as the deb stages inside the tweak bundle
/// (the Makefile copies Assets/AppIcon there): a stock App Store install has no
/// CFBundleAlternateIcons, so nothing can apply an icon to it — the Home Screen icon is part of the
/// app's signed bundle and compiled Assets.car — and they are listed to look at, with a tap
/// explaining that instead of pretending.
private enum IconSource {
    case appBundle
    case tweakBundle
}

private struct AppIconEntry: Identifiable, Hashable {
    let id: String
    let title: String
    let alternateName: String?
    let iconFiles: [String]
    let source: IconSource
}

struct EeveeAppIconPickerView: View {
    @State private var icons: [AppIconEntry] = []
    @State private var selectedKey: String = primaryIconKey
    @State private var errorMessage: String?
    @State private var prettifyNames: Bool = UserDefaults.iconNamePrettify

    var body: some View {
        List {
            Section(
                header: Text("appIconTitle".localized),
                footer: Text("appIconSubtitle".localized)
            ) {
                ForEach(icons) { icon in
                    Button { apply(icon) } label: { row(icon) }
                        .buttonStyle(PlainButtonStyle())
                }
            }

            Section {
                Toggle(isOn: Binding(
                    get: { prettifyNames },
                    set: { newValue in
                        prettifyNames = newValue
                        UserDefaults.iconNamePrettify = newValue
                        load()
                    }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("prettifyIconNames".localized)
                            .font(.system(size: 16, weight: .semibold))
                        Text("prettifyIconNamesDescription".localized)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
            }

            SpacerView()
        }
        .listStyle(InsetGroupedListStyle())
        .onAppear(perform: load)
        .alert(item: Binding<AlertWrapper?>(
            get: { errorMessage.map(AlertWrapper.init) },
            set: { errorMessage = $0?.message }
        )) { wrapped in
            Alert(title: Text("appIcon".localized),
                  message: Text(wrapped.message),
                  dismissButton: .default(Text("OK".uiKitLocalized)))
        }
    }

    private func row(_ icon: AppIconEntry) -> some View {
        HStack(spacing: 14) {
            preview(icon)
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(icon.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                Text(icon.id == selectedKey ? "iconSelected".localized : "iconTapToApply".localized)
                    .font(.system(size: 13))
                    .foregroundColor(icon.id == selectedKey
                                     ? EeveeSettingsView.spotifyAccentColor
                                     : .secondary)
            }
            Spacer()
            if icon.id == selectedKey {
                Image(systemName: "checkmark")
                    .foregroundColor(EeveeSettingsView.spotifyAccentColor)
            }
        }
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func preview(_ icon: AppIconEntry) -> some View {
        if let image = Self.image(for: icon) {
            Image(uiImage: image).resizable().aspectRatio(contentMode: .fill)
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous).fill(Color(white: 0.18))
                Image(systemName: "app.fill").foregroundColor(.secondary)
            }
        }
    }

    private func load() {
        let bundleIcons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any]
        let primary = bundleIcons?["CFBundlePrimaryIcon"] as? [String: Any]
        let primaryFiles = primary?["CFBundleIconFiles"] as? [String] ?? ["AppIcon60x60"]

        var entries: [AppIconEntry] = [
            AppIconEntry(id: primaryIconKey,
                         title: "Default",
                         alternateName: nil,
                         iconFiles: primaryFiles,
                         source: .appBundle)
        ]
        let alternates = bundleIcons?["CFBundleAlternateIcons"] as? [String: Any] ?? [:]
        if alternates.isEmpty {
            // Nothing registered on the app itself — a stock App Store install, i.e. the deb's
            // case. The deb ships the icons inside the tweak bundle; list them from there, where
            // applying is refused with an explanation rather than a system error.
            entries.append(contentsOf: Self.tweakBundleIcons(prettify: prettifyNames))
        } else {
            for key in alternates.keys.sorted(by: { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }) {
                let info = alternates[key] as? [String: Any]
                let files = info?["CFBundleIconFiles"] as? [String] ?? [key]
                // Use the plist key as the display title but convert underscores,
                // hyphens, camelCase boundaries, and parentheses to readable spaces.
                let displayTitle = Self.prettifyIconKey(key, prettify: prettifyNames)
                // Use the first CFBundleIconFiles entry as the alternateName passed to
                // setAlternateIconName. iOS resolves icons by the plist key — but on
                // sideloaded/jailbroken builds, keys with spaces or parentheses can fail.
                // Using the actual icon filename stem is a reliable fallback; if files is
                // empty we fall back to the raw key.
                let alternateName = files.first ?? key
                entries.append(AppIconEntry(id: key, title: displayTitle, alternateName: alternateName, iconFiles: files, source: .appBundle))
            }
        }
        icons = entries
        selectedKey = currentSelectedKey()
    }

    // The Makefile stages Assets/AppIcon into the tweak bundle's AppIcons/ directory; the stems
    // are its @2x files, the same set Tools/alt-icons.sh registers into a built IPA.
    private static func tweakBundleIcons(prettify: Bool) -> [AppIconEntry] {
        guard let dir = BundleHelper.shared.appIconsDirectoryURL,
              let names = try? FileManager.default.contentsOfDirectory(atPath: dir.path) else { return [] }
        let stems = names
            .filter { $0.hasSuffix("@2x.png") && !$0.contains("~ipad") }
            .map { String($0.dropLast("@2x.png".count)) }
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        return stems.map { stem in
            AppIconEntry(id: stem,
                         title: prettifyIconKey(stem, prettify: prettify),
                         alternateName: stem,
                         iconFiles: [stem],
                         source: .tweakBundle)
        }
    }

    // iOS's alternateIconName getter returns nil on resigned bundles even after a successful set — trust our pref.
    private func currentSelectedKey() -> String {
        if let saved = UserDefaults.standard.string(forKey: selectedKeyDefault), !saved.isEmpty {
            return saved
        }
        if let current = UIApplication.shared.alternateIconName, !current.isEmpty {
            return current
        }
        return primaryIconKey
    }

    private func apply(_ icon: AppIconEntry) {
        guard icon.source == .appBundle, UIApplication.shared.supportsAlternateIcons else {
            // A stock App Store install (the deb's case): iOS keeps the Home Screen icon inside
            // the app's signed bundle — the compiled Assets.car — and refuses setAlternateIconName
            // without CFBundleAlternateIcons, which only the build can add. The patched IPAs do.
            errorMessage = "appIconUnavailableMessage".localized
            return
        }
        let previous = selectedKey
        selectedKey = icon.id
        UserDefaults.standard.set(icon.id, forKey: selectedKeyDefault)

        UIApplication.shared.setAlternateIconName(icon.alternateName) { error in
            DispatchQueue.main.async {
                guard let error = error else { return }
                NSLog("[EeveeSpotify][AppIcon] setAlternateIconName(%@) failed: %@",
                      icon.alternateName ?? "nil", error.localizedDescription)
                selectedKey = previous
                UserDefaults.standard.set(previous, forKey: selectedKeyDefault)
                errorMessage = error.localizedDescription
            }
        }
    }

    /// Converts a raw plist key into a readable display title.
    /// When `prettify` is false, returns the key unchanged.
    /// When true:
    /// - Replaces underscores and hyphens with spaces.
    /// - Inserts a space before `(` when not already preceded by a space.
    /// - Inserts spaces at camelCase/PascalCase word boundaries.
    /// - Inserts a space between a letter and a digit (and vice versa) when
    ///   no space is already present — e.g. "EeveeV2" → "Eevee V2".
    /// - Collapses multiple spaces and trims.
    static func prettifyIconKey(_ key: String, prettify: Bool = true) -> String {
        guard prettify else { return key }

        var result = key
        // Replace underscores and hyphens with spaces.
        result = result.replacingOccurrences(of: "_", with: " ")
        result = result.replacingOccurrences(of: "-", with: " ")
        // Ensure a space before `(`.
        result = result.replacingOccurrences(of: "(", with: " (")

        // Walk character by character inserting spaces at boundaries.
        var spaced = ""
        let chars = Array(result)
        for i in chars.indices {
            let c = chars[i]
            if i > 0 {
                let prev = chars[i - 1]
                let prevIsSpace = prev == " "

                // camelCase / PascalCase: lowercase/digit → uppercase
                if c.isUppercase && !prevIsSpace {
                    if prev.isLowercase || prev.isNumber {
                        spaced.append(" ")
                    } else if c.isUppercase, prev.isUppercase,
                              i + 1 < chars.count, chars[i + 1].isLowercase {
                        // Acronym boundary: "NPVScroll" → "NPV Scroll"
                        spaced.append(" ")
                    }
                }

                // Letter → digit boundary: "Eevee2" → "Eevee 2"
                if c.isNumber && prev.isLetter && !prevIsSpace {
                    spaced.append(" ")
                }

                // Digit → letter boundary: "2Eevee" → "2 Eevee"
                if c.isLetter && prev.isNumber && !prevIsSpace {
                    spaced.append(" ")
                }
            }
            spaced.append(c)
        }

        // Collapse multiple spaces and trim.
        let components = spaced.components(separatedBy: " ").filter { !$0.isEmpty }
        return components.joined(separator: " ")
    }

    private static func image(for icon: AppIconEntry) -> UIImage? {
        let scale = Int(UIScreen.main.scale)
        let stems = icon.iconFiles + [icon.alternateName].compactMap { $0 }
        let bundlePath = Bundle.main.bundlePath as NSString

        for stem in stems {
            let candidates = [
                "\(stem)@\(scale)x.png",
                "\(stem)@3x.png",
                "\(stem)@2x.png",
                "\(stem).png"
            ]
            for c in candidates {
                let path = bundlePath.appendingPathComponent(c)
                if FileManager.default.fileExists(atPath: path),
                   let img = UIImage(contentsOfFile: path) {
                    return img
                }
            }
        }
        // The tweak bundle's copy of the same icons — where a stock install's picker previews from.
        for stem in stems {
            for suffix in ["@\(scale)x", "@3x", "@2x", ""] {
                if let img = BundleHelper.shared.appIconImage(named: stem + suffix) {
                    return img
                }
            }
        }
        return nil
    }
}

private struct AlertWrapper: Identifiable {
    let message: String
    var id: String { message }
}
