import SwiftUI

/// Decided in advance, on purpose.
///
/// The craving arrives at the moment your judgement is least available, so the
/// choosing has to happen before that. This screen is the written-down version
/// of a decision you already made while you were fine.
struct DopamineMenuView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.dismiss) private var dismiss

    @State private var newItem = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.stackGap) {
                    Card(tint: Theme.amber) {
                        Text("Understimulation isn't mild boredom for an ADHD brain — it's urgent, and if you don't answer it deliberately it gets answered by whatever's nearest. Which is usually a phone designed by people who are very good at their jobs.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Card(tint: Theme.amber) {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeading(title: "Take one", systemImage: "hand.tap")
                            ForEach(store.data.dopamineMenu, id: \.self) { item in
                                HStack(spacing: 10) {
                                    Image(systemName: "circle.fill")
                                        .font(.system(size: 5))
                                        .foregroundStyle(Theme.amber)
                                    Text(item)
                                        .font(.subheadline)
                                    Spacer(minLength: 0)
                                    Button {
                                        store.data.dopamineMenu.removeAll { $0 == item }
                                    } label: {
                                        Image(systemName: "minus.circle")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.vertical, 3)
                            }

                            HStack(spacing: 8) {
                                TextField("Add your own", text: $newItem)
                                    .textFieldStyle(.plain)
                                    .padding(10)
                                    .background(Theme.bg, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                Button {
                                    let trimmed = newItem.trimmingCharacters(in: .whitespacesAndNewlines)
                                    guard !trimmed.isEmpty else { return }
                                    store.data.dopamineMenu.append(trimmed)
                                    newItem = ""
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(Theme.amber)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    DisclaimerNote(text: "Games and scrolling aren't banned — they're the dessert course. The problem was never that you wanted them, it's that they were the only thing on the menu.")
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Dopamine menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
