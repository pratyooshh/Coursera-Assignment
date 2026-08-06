import SwiftUI

/// One item at a time, four possible answers.
///
/// A scrollable list of 40 captured thoughts is a wall. A single card with a
/// small number of choices is a decision you can actually make.
struct TriageView: View {
    @EnvironmentObject private var store: DataStore

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.stackGap) {
                if let item = store.untriagedCaptures.first {
                    card(for: item)
                    Text("\(store.untriagedCaptures.count) left")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    SoftEmptyState(
                        title: "Inbox clear",
                        message: "Nothing waiting. Genuinely a good place to be.",
                        systemImage: "tray"
                    )
                }
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Sort it out")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func card(for item: CaptureItem) -> some View {
        VStack(spacing: Theme.stackGap) {
            Card(tint: Theme.sky) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.text)
                        .font(.title3)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(item.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(spacing: 10) {
                BigButton(title: "It's a task — add it", systemImage: "checklist", tint: Theme.violet) {
                    store.promoteToTask(item)
                }
                BigButton(title: "Already done it", systemImage: "trophy", tint: Theme.amber, style: .tonal) {
                    store.logWin(item.text, source: "capture")
                    store.markTriaged(item)
                    Haptics.success()
                }
                BigButton(title: "Keep it, no action", systemImage: "archivebox", tint: Theme.mint, style: .tonal) {
                    store.markTriaged(item)
                }
                BigButton(title: "Bin it", systemImage: "trash", tint: Theme.coral, style: .tonal) {
                    store.deleteCapture(item)
                }
            }

            DisclaimerNote(text: "Binning things is allowed and it isn't failure. A thought you had at 1am is not a commitment you signed.")
        }
    }
}
