import SwiftUI

struct MoodSheet: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.dismiss) private var dismiss

    @State private var valence = 3
    @State private var energy = 3
    @State private var selected: Set<String> = []
    @State private var note = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.stackGap) {
                    scale(
                        title: "How's it going?",
                        subtitle: "Rough on the left, good on the right.",
                        value: $valence,
                        tint: Theme.coral,
                        labels: ["Rough", "Low", "OK", "Good", "Great"]
                    )

                    scale(
                        title: "Energy",
                        subtitle: "Flat and empty, or wired and can't settle. Both ends are hard.",
                        value: $energy,
                        tint: Theme.amber,
                        labels: ["Flat", "Low", "Steady", "Busy", "Wired"]
                    )

                    Card(tint: Theme.violet) {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeading(
                                title: "Any of these?",
                                subtitle: "Specific words help. \"Bad\" doesn't point anywhere; \"resentful\" does."
                            )
                            FlowChips(options: Feelings.options, selected: $selected)
                        }
                    }

                    Card(tint: Theme.sky) {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeading(title: "Anything else?", subtitle: "Optional.")
                            TextField("What's going on", text: $note, axis: .vertical)
                                .textFieldStyle(.plain)
                                .lineLimit(3...6)
                                .padding(10)
                                .background(Theme.bg, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }

                    if valence <= 2 {
                        lowMoodCard
                    }

                    BigButton(title: "Log it", systemImage: "checkmark", tint: Theme.coral) {
                        store.logMood(
                            MoodEntry(
                                valence: valence,
                                energy: energy,
                                feelings: Array(selected),
                                note: note.trimmingCharacters(in: .whitespacesAndNewlines),
                                wasRejectionEpisode: selected.contains("Rejected")
                            )
                        )
                        Haptics.success()
                        dismiss()
                    }
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Check in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var lowMoodCard: some View {
        Card(tint: Theme.mint) {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeading(title: "That sounds like a hard one", systemImage: "heart")
                Text("Nothing here is a fix, and it isn't pretending to be. But if it's a spiral, catching it early is worth more than reasoning with it later.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                NavigationLink {
                    InterventionRunnerView(interventionID: "overwhelmed")
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "cross.case.fill")
                        Text("Work through the overwhelm")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.mint)
                }
                NavigationLink {
                    CrisisView()
                } label: {
                    Text("If it's worse than that — crisis support")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(Theme.coral)
                }
            }
        }
    }

    private func scale(title: String, subtitle: String, value: Binding<Int>, tint: Color, labels: [String]) -> some View {
        Card(tint: tint) {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeading(title: title, subtitle: subtitle)
                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { i in
                        Button {
                            value.wrappedValue = i
                            Haptics.tap()
                        } label: {
                            VStack(spacing: 5) {
                                Circle()
                                    .fill(value.wrappedValue == i ? tint : tint.opacity(0.16))
                                    .frame(height: 34)
                                Text(labels[i - 1])
                                    .font(.caption2)
                                    .foregroundStyle(value.wrappedValue == i ? tint : .secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

/// Wrapping chip layout. Uses SwiftUI's native `Layout` so it reflows
/// correctly at any width and accessibility text size.
struct FlowChips: View {
    let options: [String]
    @Binding var selected: Set<String>

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(options, id: \.self) { option in
                Button {
                    if selected.contains(option) {
                        selected.remove(option)
                    } else {
                        selected.insert(option)
                    }
                    Haptics.tap()
                } label: {
                    Chip(text: option, tint: Theme.violet, filled: selected.contains(option))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth == .infinity ? x : maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
