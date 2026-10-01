import SwiftUI
import UIKit
// EeveeSpotipwSettingsPage() is declared in Sources/EeveeSpotifyC/include/EeveeSpotipw.h, which the
// umbrella module exports to Swift, along with the EeveeModPage it hands back.
import EeveeSpotifyC

/// The ported spoti.pw settings page, as a SwiftUI row's destination.
///
/// The page comes back as an `EeveeModPage` — the page as data: its sections, the rows in them and
/// what each row is — so it is drawn by `EeveeModPageView` in SwiftUI, the same way EeveeSpotify's own
/// pages are. It used to be hosted instead, as the `UITableViewController` it was written to be, which
/// is why its rows drew at a different size and in a different style from the menu that opened it.
struct EeveeSpotipwSettingsView: View {
    let navigationController: UINavigationController

    /// Built once: the ported page reads its sections out of the stored switches as it is made, and a
    /// fresh one per redraw would rebuild them. Its sub-pages go through the same renderer.
    @State private var page = EeveeSpotipwSettingsPage()

    var body: some View {
        EeveeModPageView(page: page, navigationController: navigationController)
    }
}
