import SwiftUI
import UIKit
// The ported tree's page model — EeveeModPage, EeveeModSection, EeveeModRow — and the preference and
// flag accessors a row reads, all through include/EeveeSpotipw.h.
import EeveeSpotifyC

/// A ported spoti.pw page, drawn with SwiftUI's own `List` the way EeveeSpotify's own settings are.
///
/// The ported tree describes its pages as data: an `EeveeModPage` holds a title, the note it opens
/// with, its sections and the note under them; an `EeveeModSection` holds `EeveeModRow`s; and a row
/// says what it *is* — a key to switch, a page to open, a number to read out, a list to pick from.
/// That is the shape a SwiftUI section already has, so the page is drawn from it rather than hosted as
/// the `UITableView` it was written to be a subclass of.
///
/// Hosting it was what made the ported options read as a second, older settings screen inside
/// EeveeSpotify's own menu. A table view draws what the ported pages were styled to draw — a 13pt
/// bold title over an 11pt subtitle, `.uppercaseString` section headers, chevrons and switches built
/// by hand — where SwiftUI's `List` draws a 17pt body title over a 13pt footnote subtitle, the
/// section title it was given, `.tertiaryLabel` chevrons and a tinted `Toggle`. Same menu, same rows,
/// two different systems; this is the one of them EeveeSpotify is built on.
///
/// What is deliberately *not* drawn here are the ported pages whose controls SwiftUI has no honest
/// shape for — the Navbar editor's drag-to-reorder list, All flags' searchable 2,483-row table, the
/// Audio effects curve editors, the Artist block list. Those are `EeveePage`s, not `EeveeModPage`s,
/// and a row that opens one pushes it as it is (`open()`, below).
struct EeveeModPageView: View {
    let page: EeveeModPage
    let navigationController: UINavigationController

    /// Bumped when a switch is flipped and when the page comes back, so the rows a `visible` block
    /// hides or shows are worked out again and a `value` block is read again. That is what the hosted
    /// page did by reloading its table on a switch and in `viewWillAppear`.
    @State private var revision = 0

    var body: some View {
        List {
            if let intro = page.introText, !intro.isEmpty {
                Section {
                    Text(intro)
                        .font(.footnote)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
            }

            ForEach(page.sections, id: \.self) { section in
                Section {
                    ForEach(rows(of: section), id: \.self) { row in
                        EeveeModRowView(
                            row: row,
                            navigationController: navigationController,
                            reload: { withAnimation(.default) { revision += 1 } }
                        )
                    }
                } header: {
                    if let title = section.title { Text(title) }
                } footer: {
                    if let footer = section.footer { Text(footer) }
                }
            }

            if let footer = page.footerText, !footer.isEmpty {
                Section { EmptyView() } footer: { Text(footer) }
            }

            SpacerView()
        }
        .listStyle(GroupedListStyle())
        // The equivalent of the table's viewWillAppear reload: a page row's value is read when the
        // page appears, so coming back from the page it opened shows what was picked there.
        .onAppear { revision += 1 }
    }

    /// A section's rows that show now. `visible` is the ported way for a row to come and go under the
    /// switch above it — Music Haptics' strength and Follows under its own switch — and it is asked
    /// again on every pass, which is what the reload did.
    private func rows(of section: EeveeModSection) -> [EeveeModRow] {
        _ = revision
        return (section.rows ?? []).filter { $0.visible?() ?? true }
    }
}

/// One row of a ported page, drawn the way SwiftUI draws the equivalent row of EeveeSpotify's own.
///
/// The ported row types map onto SwiftUI one for one: a key is a `Toggle`, a page is a `Button` with
/// a chevron, a number is a `Slider` under its title, a list of names is a `Picker`-shaped page of
/// its own, and everything else is `Text` with a value on the right.
private struct EeveeModRowView: View {
    let row: EeveeModRow
    let navigationController: UINavigationController
    let reload: () -> Void

    @State private var sliderValue: Double = 0
    @State private var showsInfo = false
    @State private var showsLock = false

    init(row: EeveeModRow, navigationController: UINavigationController, reload: @escaping () -> Void) {
        self.row = row
        self.navigationController = navigationController
        self.reload = reload
        // A slider reads its number out of storage once, then keeps its own while it is dragged.
        _sliderValue = State(initialValue: row.number?() ?? 0)
    }

    var body: some View {
        Group {
            if row.number != nil {
                sliderRow
            } else if row.key != nil {
                switchRow
            } else if row.choiceNames != nil {
                choiceRow
            } else if row.page != nil {
                pageRow
            } else if row.action != nil {
                actionRow
            } else if row.value != nil {
                readoutRow
            } else {
                rowContent
            }
        }
        .alert(Text("About this switch"), isPresented: $showsInfo) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(row.info ?? "")
        }
        .alert(Text("Overridden by another setting"), isPresented: $showsLock) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Another switch is forcing this flag, so the row shows what it forces instead of taking a value of its own.")
        }
    }

    // MARK: - the row's own content

    /// What the row is called on screen. A preference row — one with a key or a number — carries
    /// " (from spoti.pw)", the marker that says which options came over in the merge, applied to all
    /// of them at once rather than at the ~180 places the rows are built (Settings/EeveeModPage.m).
    /// Page rows, readouts and plain actions keep their titles.
    private var title: String {
        let title = row.title ?? ""
        guard row.key != nil || row.number != nil, !title.isEmpty else { return title }
        return title.hasSuffix(EeveeSpotipwRowSuffix) ? title : title + EeveeSpotipwRowSuffix
    }

    private var titleColor: Color {
        guard let color = row.color else { return .primary }
        return Color(uiColor: color)
    }

    private var subtitleColor: Color {
        guard let color = row.color else { return Color(UIColor.secondaryLabel) }
        return Color(uiColor: color)
    }

    /// The ported row's leading symbol. A coloured row draws it plain in its colour; any other draws
    /// it white on the rounded grey tile the ported rows share — the same tile the top of
    /// EeveeSpotify's own menu uses, which is why the symbols are kept rather than dropped.
    @ViewBuilder private var symbolView: some View {
        if let symbol = row.symbol, !symbol.isEmpty {
            if let color = row.color {
                Image(systemName: symbol)
                    .font(.system(size: 15))
                    .foregroundColor(Color(uiColor: color))
                    .frame(width: 28, alignment: .leading)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Color.white.opacity(0.12))
                    Image(systemName: symbol)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
                .frame(width: 28, height: 28)
            }
        }
    }

    private var rowContent: some View {
        HStack(spacing: 12) {
            symbolView
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundColor(titleColor)
                if let subtitle = row.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundColor(subtitleColor)
                }
            }
        }
    }

    /// A trailing readout, in the size and colour SwiftUI's own right-hand labels are in. Monospaced
    /// digit by digit, so a number that climbs does not shift the text around it.
    @ViewBuilder private func valueText(_ text: String) -> some View {
        Text(text)
            .foregroundColor(Color(UIColor.secondaryLabel))
            .monospacedDigit()
    }

    // MARK: - a switch row

    /// The flags something of the mod's forces win, an override from the All flags page comes next,
    /// and a row a forcer answers for shows that value and takes no touch — the order
    /// Settings/EeveeModPage.m wrote, read here through the same three accessors.
    private var isLocked: Bool {
        guard row.flag, let key = row.key else { return false }
        return EeveeLockedFlagValue(key, nil) != nil
    }

    /// A lock that beats an override shows over one; the others give way to it.
    private var showsLockedValue: Bool {
        guard isLocked, let key = row.key else { return false }
        var beats = ObjCBool(false)
        EeveeLockedFlagValue(key, &beats)
        return beats.boolValue || EeveeFlagOverride(key) == nil
    }

    /// On means the row's own override is in place; anything else, including the opposite override
    /// somebody set from the All flags page, reads as off. A forceOff row reads the other way round.
    private func flagIsOn(_ key: String) -> Bool {
        guard let value = EeveeFlagOverride(key) as? NSNumber else { return false }
        return value.boolValue != row.forceOff
    }

    private var isOn: Bool {
        guard let key = row.key else { return false }
        // `defaultOn` is what the ported row builder decided the switch means when it has never been
        // touched: on for something the mod takes away (EeveeSwitchRow), off for something it adds
        // (EeveeHideRow, EeveeOptionRow) — which is EeveeEnabled only in the first case.
        guard row.flag else { return EeveeFlag(key, row.defaultOn) }
        guard isLocked else { return flagIsOn(key) }
        guard showsLockedValue, let forced = EeveeLockedFlagValue(key, nil) as? NSNumber else { return flagIsOn(key) }
        return forced.boolValue != row.forceOff
    }

    private var isOnBinding: Binding<Bool> {
        Binding(get: { isOn }, set: { setOn($0) })
    }

    private func setOn(_ on: Bool) {
        guard let key = row.key else { return }
        if row.flag {
            // Off is no override rather than an override of NO: that is what leaves Spotify's own
            // value in place instead of forcing the flag the other way.
            let value: Any? = on ? NSNumber(value: !row.forceOff) : nil
            EeveeSetFlagOverride(key, value)
        } else {
            EeveeSetEnabled(key, on)
        }
        row.changed?(on)
        reload()
    }

    private var switchRow: some View {
        HStack(spacing: 12) {
            Toggle(isOn: isOnBinding) { rowContent }
                .tint(accent)
                // A locked row takes no touch; the tap is let through to the row instead, which is
                // what says why (EeveeModPage.m's explainLock).
                .disabled(isLocked)
                .allowsHitTesting(!isLocked)
                .accessibilityLabel(title)

            if let info = row.info, !info.isEmpty {
                Button { showsInfo = true } label: {
                    Image(systemName: "info.circle")
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("About this switch")
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { if isLocked { showsLock = true } }
    }

    // MARK: - a row that opens a page

    private var pageRow: some View {
        Button { open() } label: {
            HStack(spacing: 12) {
                rowContent
                Spacer(minLength: 8)
                if let value = row.value?() { valueText(value) }
                ChevronRightView()
            }
        }
        .accessibilityLabel(title)
        .accessibilityValue(row.value?() ?? "")
    }

    /// A ported page that is a `ModPage` is drawn here like this one; anything else is a page of its
    /// own and goes on the stack as it is, which is how the ported tree navigates its sub-pages.
    private func open() {
        guard let make = row.page, let target = make() else { return }
        if let modPage = target as? EeveeModPage {
            push(EeveeModPageView(page: modPage, navigationController: navigationController), title: modPage.titleText ?? "")
        } else {
            navigationController.pushViewController(target, animated: true)
        }
    }

    private func push<Content: View>(_ view: Content, title: String) {
        let controller = EeveeSettingsViewController(
            navigationController.view.frame,
            settingsView: AnyView(view),
            navigationTitle: title
        )
        navigationController.pushViewController(controller, animated: true)
    }

    // MARK: - a row that picks from a list

    private var choiceRow: some View {
        Button { openChoice() } label: {
            HStack(spacing: 12) {
                rowContent
                Spacer(minLength: 8)
                if let value = row.value?() { valueText(value) }
                ChevronRightView()
            }
        }
        .accessibilityLabel(title)
        .accessibilityValue(row.value?() ?? "")
    }

    private func openChoice() {
        let view = EeveeModChoiceView(row: row, navigationController: navigationController) { index in
            row.chosen?(index)
        }
        push(view, title: row.title ?? "")
    }

    // MARK: - a row that runs something

    private var actionRow: some View {
        Button {
            row.action?()
            reload()
        } label: {
            HStack(spacing: 12) {
                rowContent
                Spacer(minLength: 8)
                // An action row that reads a value out as well — the Updates row, the accent colour —
                // shows it here and is asked again on every pass.
                if let value = row.value?() { valueText(value) }
            }
        }
        .accessibilityLabel(title)
    }

    // MARK: - a row that only reads out

    // The numbers that climb on their own — the telemetry counters — are read again every second
    // while the page is open, which is the ticker the hosted page kept running for rows like these.
    private var readoutRow: some View {
        HStack(spacing: 12) {
            rowContent
            Spacer(minLength: 8)
            TimelineView(.periodic(from: .now, by: 1)) { _ in
                valueText(row.value?() ?? "")
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - a row with a number

    private var sliderRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                rowContent
                Spacer(minLength: 8)
                valueText(formatted(sliderValue))
            }
            slider
        }
    }

    @ViewBuilder private var slider: some View {
        if row.step > 0 {
            Slider(value: sliderBinding, in: row.minimum...row.maximum, step: row.step)
        } else {
            Slider(value: sliderBinding, in: row.minimum...row.maximum)
        }
    }

    /// Each step is stored as the thumb reaches it — the ported slider wrote every step too — so a
    /// setting that applies as it changes applies while it is dragged, not only when it is let go.
    private var sliderBinding: Binding<Double> {
        Binding(
            get: { sliderValue },
            set: { value in
                let snapped = min(max(value, row.minimum), row.maximum)
                sliderValue = snapped
                row.setNumber?(snapped)
            }
        )
    }

    private func formatted(_ value: Double) -> String {
        guard let format = row.format, let text = format(value) else { return String(format: "%g", value) }
        return text
    }

    private var accent: Color { Color(uiColor: EeveeGreen()) }
}

/// A choice row's list, drawn here rather than as a page of its own: the names, the note under each
/// and the green tick against the one set, in the `List` SwiftUI would have drawn.
private struct EeveeModChoiceView: View {
    let row: EeveeModRow
    let navigationController: UINavigationController
    let picked: (Int) -> Void

    private var names: [String] { row.choiceNames ?? [] }

    var body: some View {
        List {
            ForEach(Array(names.enumerated()), id: \.offset) { index, name in
                Button { choose(index) } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(name)
                                .foregroundColor(.primary)
                            if let note = note(index) {
                                Text(note)
                                    .font(.footnote)
                                    .foregroundColor(Color(UIColor.secondaryLabel))
                            }
                        }
                        Spacer(minLength: 8)
                        if index == selected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(uiColor: EeveeGreen()))
                        }
                    }
                }
            }

            if let footer = row.choiceFooter, !footer.isEmpty {
                Section { EmptyView() } footer: { Text(footer) }
            }

            SpacerView()
        }
        .listStyle(GroupedListStyle())
    }

    private var selected: Int {
        EeveeInt(row.choiceKey ?? "", row.choiceFallback)
    }

    private func note(_ index: Int) -> String? {
        guard let notes = row.choiceNotes, index < notes.count else { return nil }
        let note = notes[index]
        return note.isEmpty ? nil : note
    }

    private func choose(_ index: Int) {
        EeveeSetInt(row.choiceKey ?? "", index)
        picked(index)
        // Popped rather than dismissed: the list is pushed on EeveeSpotify's own stack, not presented.
        navigationController.popViewController(animated: true)
    }
}
