import SwiftUI
import UIKit
// EeveeSpotipwSettingsPage() is declared in Sources/EeveeSpotifyC/include/EeveeSpotipw.h, which the
// umbrella module exports to Swift.
import EeveeSpotifyC

/// The ported spoti.pw settings page, as a SwiftUI row's destination.
///
/// `EeveeSpotipwSettingsPage()` is a UITableViewController, so it is hosted rather than rebuilt: it
/// is pushed onto EeveeSpotify's own navigation stack, which is also the stack its sub-pages
/// (Navbar, Player, Audio effects, Labs, All flags) push onto, so the whole ported tree navigates
/// normally underneath EeveeSpotify's settings.
struct EeveeSpotipwPageHost: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        EeveeSpotipwSettingsPage()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
