import SwiftUI

/// Counter-evidence, stored externally.
///
/// Memory for your own competence is unreliable — a day with six things done and
/// one forgotten gets encoded as a day you forgot something. This is a record
/// that doesn't participate in that.
struct WinsView: View {
    @EnvironmentObject private var store: DataStore
    @State private var newWin = ""

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.stackGap) {
                Card(tint: Theme.amber) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("\(store.lifetimeWinCount)")
                                .font(.system(size: 44, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.amber)
                            Text("things you did")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                        Text("There's no streak to break. Miss a week and this number doesn't move — it certainly doesn't reset.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Card(tint: Theme.amber) {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeading(title: "Add one", subtitle: "Counts if it was hard for you. That's the only bar.")
                        HStack(spacing: 8) {
                            TextField("What you did", text: $newWin)
                                .textFieldStyle(.plain)
                                .padding(10)
                                .background(Theme.bg, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            Button {
                                store.logWin(newWin)
                                newWin = ""
                                Haptics.success()
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(Theme.amber)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if store.data.wins.isEmpty {
                    SoftEmptyState(
                        title: "Nothing logged yet",
                        message: "Made a call you'd been avoiding? Got out of bed on a bad day? That's the level.",
                        systemImage: "trophy"
                    )
                } else {
                    ForEach(groupedWins, id: \.0) { day, wins in
                        Card(tint: Theme.amber) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(day)
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                ForEach(wins) { win in
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.footnote)
                                            .foregroundStyle(Theme.amber)
                                        Text(win.text)
                                            .font(.subheadline)
                                            .fixedSize(horizontal: false, vertical: true)
                                        Spacer(minLength: 0)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Wins")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var groupedWins: [(String, [WinEntry])] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let grouped = Dictionary(grouping: store.data.wins) { win -> String in
            if Calendar.current.isDateInToday(win.date) { return "Today" }
            if Calendar.current.isDateInYesterday(win.date) { return "Yesterday" }
            return formatter.string(from: win.date)
        }
        // Preserve the newest-first ordering the store already maintains.
        var seen: [String] = []
        for win in store.data.wins {
            let key: String
            if Calendar.current.isDateInToday(win.date) { key = "Today" }
            else if Calendar.current.isDateInYesterday(win.date) { key = "Yesterday" }
            else { key = formatter.string(from: win.date) }
            if !seen.contains(key) { seen.append(key) }
        }
        return seen.compactMap { key in
            guard let wins = grouped[key] else { return nil }
            return (key, wins)
        }
    }
}
