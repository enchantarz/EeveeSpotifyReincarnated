import SwiftUI
import UIKit
import EeveeSpotifyC

struct EeveeSettingsView: View {
    let navigationController: UINavigationController
    static let spotifyAccentColor = Color(hex: "#1ed760")
    
    @State private var hasShownCommonIssuesTip = UserDefaults.hasShownCommonIssuesTip
    @State private var isClearingData = false
    @State private var isPresentingDevNoteSheet = false


    private func confirmDestructive(
        title: String,
        message: String,
        confirmTitle: String,
        onConfirm: @escaping () -> Void
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel".uiKitLocalized, style: .cancel))
        alert.addAction(UIAlertAction(title: confirmTitle, style: .destructive) { _ in
            onConfirm()
        })
        WindowHelper.shared.present(alert)
    }

    private func pushSettingsController(with view: any View, title: String) {
        let viewController = EeveeSettingsViewController(
            navigationController.view.frame,
            settingsView: AnyView(view),
            navigationTitle: title
        )
        navigationController.pushViewController(viewController, animated: true)
    }

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        UIView.appearance().tintColor = UIColor(EeveeSettingsView.spotifyAccentColor)
    }

    var body: some View {
        List {
            EeveeSettingsVersionView()
            
            if !hasShownCommonIssuesTip {
                CommonIssuesTipView(
                    onDismiss: {
                        hasShownCommonIssuesTip = true
                        UserDefaults.hasShownCommonIssuesTip = true
                    }
                )
            }

            // MARK: - 1. EeveeSpotify Features
            // Premium interception, data overrides and the patching that backs them, plus the rest of
            // what EeveeSpotify adds on its own.
            Section(header: Text("EeveeSpotify Features")) {
                Button {
                    pushSettingsController(
                        with: EeveePatchingSettingsView(),
                        title: "patching".localized
                    )
                } label: {
                    NavigationSectionView(
                        color: .orange,
                        title: "patching".localized,
                        imageSystemName: "hammer.fill"
                    )
                }

                Button {
                    pushSettingsController(
                        with: SponsorBlockSettingsView(),
                        title: "sponsorblock".localized
                    )
                } label: {
                    NavigationSectionView(
                        color: .red,
                        title: "sponsorblock".localized,
                        imageSystemName: "forward.end.fill"
                    )
                }

                Button {
                    pushSettingsController(
                        with: EeveeExperimentsSettingsView(),
                        title: "experiments".localized
                    )
                } label: {
                    NavigationSectionView(
                        color: .purple,
                        title: "experiments".localized,
                        imageSystemName: "sparkle"
                    )
                }

                Button {
                    pushSettingsController(
                        with: EeveeMiscellaneousSettingsView(),
                        title: "miscellaneous".localized
                    )
                } label: {
                    NavigationSectionView(
                        color: .gray,
                        title: "miscellaneous".localized,
                        imageSystemName: "ellipsis.circle.fill"
                    )
                }
            }

            // MARK: - 2. UI & Liquid Glass Adjustments
            // EeveeSpotify's own customisation, then the ported spoti.pw tree: its layout pages
            // (Navbar, Player, Home & Library, audio effects) and the app icon.
            Section(header: Text("UI & Liquid Glass Adjustments")) {
                Button {
                    pushSettingsController(
                        with: EeveeUISettingsView(),
                        title: "customization".localized
                    )
                } label: {
                    NavigationSectionView(
                        color: Color(hex: "#64D2FF"),
                        title: "customization".localized,
                        imageSystemName: "paintpalette.fill"
                    )
                }

                // The ported page is drawn by EeveeModPageView in SwiftUI, from the same kind of
                // data EeveeSpotify's own pages are written as; only the ported pages whose
                // controls SwiftUI has no shape for stay UIKit, and those are pushed as they are.
                // Its sub-pages push onto this same navigation stack. The row is named for where its
                // options came from rather than for a look: the Liquid Glass redesign it was written
                // for is not part of this build, so its pages are the native look's
                // (EeveeSpotifyC/Core/EeveeUIMode.h).
                Button {
                    pushSettingsController(
                        with: EeveeSpotipwSettingsView(navigationController: navigationController),
                        title: "spoti.pw features"
                    )
                } label: {
                    NavigationSectionView(
                        color: Color(hex: "#64D2FF"),
                        title: "spoti.pw features",
                        imageSystemName: "sparkles"
                    )
                }

                Button {
                    pushSettingsController(
                        with: EeveeAppIconPickerView(),
                        title: "appIcon".localized
                    )
                } label: {
                    NavigationSectionView(
                        color: .pink,
                        title: "appIcon".localized,
                        imageSystemName: "app.badge.fill"
                    )
                }
            }

            // MARK: - 3. Lyrics Settings
            // EeveeSpotify's own engine only: LRCLIB, Genius, Musixmatch and PetitLyrics. The
            // lyrics engine spoti.pw shipped was removed in the merge.
            Section(header: Text("Lyrics Settings")) {
                Button {
                    pushSettingsController(
                        with: EeveeLyricsSettingsView(),
                        title: "lyrics".localized
                    )
                } label: {
                    NavigationSectionView(
                        color: .blue,
                        title: "lyrics".localized,
                        imageSystemName: "quote.bubble.fill"
                    )
                }
            }

            // MARK: - 4. Ad Blocking & Statistics
            Section(header: Text("Ad Blocking & Statistics")) {
                Button {
                    pushSettingsController(
                        with: EeveeAdBlockingSettingsView(),
                        title: "Ad Blocking"
                    )
                } label: {
                    NavigationSectionView(
                        color: .green,
                        title: "Ads Blocked So Far",
                        imageSystemName: "hand.raised.fill"
                    )
                }
            }

            // MARK: - Help

            Section {
                Button {
                    isPresentingDevNoteSheet = true
                } label: {
                    HStack {
                        Image(systemName: "person.fill.questionmark")
                        Text("developer_note".localized)
                    }
                }
            }
            .sheet(isPresented: $isPresentingDevNoteSheet) {
                EeveeDevNoteView()
            }

            // The donation easter egg (a toast on the 5th launch) is gone; this is the same joke,
            // where it can be found on purpose. Hysan's crush on Elsa funds the mod, allegedly.
            Section {
                Button {
                    if let url = URL(string: "https://ko-fi.com/jaydenjcpy") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "cup.and.saucer.fill")
                            .foregroundColor(Color(hex: "#FF99CC"))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("hysan_recovery_fund".localized)
                            Text("hysan_recovery_fund_description".localized)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }

            Section(header: Text("debug_title".localized), footer: Text("debug_section_footer".localized)) {
                Button {
                    let logPath = NSTemporaryDirectory() + "eeveespotify_debug.log"
                    guard FileManager.default.fileExists(atPath: logPath),
                          let logData = FileManager.default.contents(atPath: logPath),
                          logData.count > 0 else {
                        PopUpHelper.showPopUp(message: "no_debug_log_found".localized, buttonText: "no_debug_log_found_ok".localized)
                        return
                    }
                    let logURL = URL(fileURLWithPath: logPath)
                    let activityVC = UIActivityViewController(activityItems: [logURL], applicationActivities: nil)
                    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootVC = scene.windows.first?.rootViewController {
                        var topVC = rootVC
                        while let presented = topVC.presentedViewController { topVC = presented }
                        if let popover = activityVC.popoverPresentationController {
                            popover.sourceView = topVC.view
                            popover.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
                        }
                        topVC.present(activityVC, animated: true)
                    }
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("export_debug_log".localized)
                    }
                }
                
                Button {
                    let logPath = NSTemporaryDirectory() + "eeveespotify_debug.log"
                    try? "".write(toFile: logPath, atomically: true, encoding: .utf8)
                    writeDebugLog("Log cleared by user")
                    PopUpHelper.showPopUp(message: "debug_log_cleared".localized, buttonText: "debug_log_cleared_ok".localized)
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("clear_debug_log".localized)
                    }
                    .foregroundColor(.red)
                }
            }
            
            Section(footer: Text("reset_data_description".localized)) {
                Button {
                    confirmDestructive(
                        title: "reset_data".localized,
                        message: "reset_data_description".localized,
                        confirmTitle: "reset_data".localized
                    ) {
                        isClearingData = true

                        DispatchQueue.global(qos: .userInitiated).async {
                            OfflineHelper.resetData(clearCaches: true)

                            DispatchQueue.main.async {
                                exitApplication()
                            }
                        }
                    }
                } label: {
                    if isClearingData {
                        ProgressView()
                    }
                    else {
                        Text("reset_data".localized)
                    }
                }
            }

            Section(footer: Text("resetFooter".localized)) {
                Button {
                    confirmDestructive(
                        title: "resetButtonTitle".localized,
                        message: "resetSubtitle".localized,
                        confirmTitle: "resetButtonTitle".localized
                    ) {
                        isClearingData = true
                        DispatchQueue.global(qos: .userInitiated).async {
                            FullResetHelper.wipeSpotifyState()
                            DispatchQueue.main.async {
                                exitApplication()
                            }
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("resetButtonTitle".localized)
                    }
                    .foregroundColor(.red)
                }
            }

            Section {
                Color.clear
                    .frame(height: 90)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
            }
        }
        .listStyle(GroupedListStyle())
        
        .animation(.default, value: isClearingData)
        .animation(.default, value: hasShownCommonIssuesTip)

        .onAppear {
            WindowHelper.shared.overrideUserInterfaceStyle(.dark)
        }
    }
}
