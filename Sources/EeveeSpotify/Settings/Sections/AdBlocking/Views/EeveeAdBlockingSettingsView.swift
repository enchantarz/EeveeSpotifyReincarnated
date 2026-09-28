import SwiftUI

/// Ad Blocking & Statistics: the running count of everything the ad blocking has stopped, and where
/// it came from.
///
/// The number is `EeveeAdsBlocked.count`, persisted under `kEeveeAdsBlockedCount` and incremented at
/// the interception points themselves — a blocked response in `SpotifyResponsePatcher`, a suppressed
/// service in `UpsellServiceBlocker`, and every component `HubsAdBlocker` takes out of a Hub JSON
/// body. It is read again whenever this page appears rather than only at launch.
struct EeveeAdBlockingSettingsView: View {
    @State private var total = EeveeAdsBlocked.count
    @State private var byKind: [EeveeAdsBlockedKind: Int] = Dictionary(
        uniqueKeysWithValues: EeveeAdsBlockedKind.allCases.map { ($0, EeveeAdsBlocked.count(of: $0)) }
    )

    private func reload() {
        total = EeveeAdsBlocked.count
        byKind = Dictionary(
            uniqueKeysWithValues: EeveeAdsBlockedKind.allCases.map { ($0, EeveeAdsBlocked.count(of: $0)) }
        )
    }

    var body: some View {
        List {
            Section(header: Text("Ads blocked so far")) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(total)")
                        .font(.system(size: 46, weight: .bold, design: .rounded))
                        .foregroundColor(EeveeSettingsView.spotifyAccentColor)
                        .accessibilityLabel("\(total) ads blocked")
                    Text(total == 1
                         ? "request intercepted or dropped"
                         : "requests intercepted or dropped")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)

                ForEach(EeveeAdsBlockedKind.allCases, id: \.self) { kind in
                    HStack {
                        Text(kind.title.capitalized)
                        Spacer()
                        Text("\(byKind[kind] ?? 0)")
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                }
            }

            Section(footer: Text(
                "Counted at the point each request is dropped, so it only moves while ad blocking is "
                + "on. It survives restarts."
            )) {
                Button(role: .destructive) {
                    EeveeAdsBlocked.reset()
                    reload()
                } label: {
                    Text("Reset counter")
                }
            }

            SpacerView()
        }
        .listStyle(GroupedListStyle())
        .onAppear(perform: reload)
    }
}
