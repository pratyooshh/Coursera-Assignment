import SwiftUI

/// Concrete, dated examples — the currency of an adult assessment.
///
/// "I'm disorganised" is an adjective and a clinician can't do anything with it.
/// "I've paid three late fees since January and my partner took over the bills
/// because I stopped opening post" is assessable. This screen exists to make
/// people write the second kind, over time, while it's still fresh.
struct EvidenceView: View {
    @EnvironmentObject private var store: DataStore
    @State private var showingAdd = false

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.stackGap) {
                Card(tint: Theme.amber) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Why bother with this")
                            .font(.headline)
                        Text("You will forget the specifics. Not might — will. Then you'll sit in a 45-minute appointment trying to summarise 30 years from memory, with a clinician who needs examples, and you'll produce adjectives instead.\n\nWrite them down as they happen. Two lines is plenty.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                BigButton(title: "Add an example", systemImage: "plus", tint: Theme.amber) {
                    showingAdd = true
                }

                if store.data.evidence.isEmpty {
                    SoftEmptyState(
                        title: "Nothing logged yet",
                        message: "Next time something happens that's part of the pattern, put it here.",
                        systemImage: "doc.text"
                    )
                } else {
                    ForEach(LifeDomain.allCases) { domain in
                        let notes = store.data.evidence.filter { $0.domain == domain }
                        if !notes.isEmpty {
                            Card(tint: Theme.amber) {
                                VStack(alignment: .leading, spacing: 10) {
                                    SectionHeading(title: domain.title, systemImage: domain.symbol)
                                    ForEach(notes) { note in
                                        VStack(alignment: .leading, spacing: 3) {
                                            HStack(spacing: 6) {
                                                if note.isChildhood {
                                                    Chip(text: "Childhood", tint: Theme.violet)
                                                }
                                                Text(note.date, style: .date)
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                                Spacer()
                                                Button {
                                                    store.deleteEvidence(note)
                                                } label: {
                                                    Image(systemName: "minus.circle")
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                }
                                                .buttonStyle(.plain)
                                            }
                                            Text(note.text)
                                                .font(.subheadline)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                        .padding(.vertical, 3)
                                    }
                                }
                            }
                        }
                    }
                }

                promptsCard
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Evidence")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAdd) { AddEvidenceSheet() }
    }

    private var promptsCard: some View {
        Card(tint: Theme.violet) {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeading(
                    title: "Things they'll ask about",
                    subtitle: "Worth thinking through before you're in the room",
                    systemImage: "questionmark.bubble"
                )

                group("Childhood", prompts: ContextQuestions.childhood)
                group("Impact", prompts: ContextQuestions.impairment)
                group("The differential", prompts: ContextQuestions.differential)
            }
        }
    }

    private func group(_ title: String, prompts: [ContextQuestions.Prompt]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.footnote.weight(.bold))
                .foregroundStyle(Theme.violet)
            ForEach(prompts) { prompt in
                VStack(alignment: .leading, spacing: 3) {
                    Text(prompt.question)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(prompt.why)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

// MARK: - Add

struct AddEvidenceSheet: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.dismiss) private var dismiss

    @State private var domain: LifeDomain = .work
    @State private var text = ""
    @State private var isChildhood = false
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeading(
                            title: "What happened?",
                            subtitle: "Specific and concrete. Numbers and names if you have them."
                        )
                        TextField("e.g. Missed the dentist twice this month despite two reminders", text: $text, axis: .vertical)
                            .focused($focused)
                            .textFieldStyle(.plain)
                            .lineLimit(3...8)
                            .padding(12)
                            .background(Theme.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeading(title: "Which part of life?")
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 8)], spacing: 8) {
                            ForEach(LifeDomain.allCases) { d in
                                Button {
                                    domain = d
                                    Haptics.tap()
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: d.symbol)
                                        Text(d.title)
                                            .font(.footnote)
                                            .multilineTextAlignment(.leading)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(10)
                                    .foregroundStyle(domain == d ? .white : Theme.amber)
                                    .background(
                                        domain == d ? AnyShapeStyle(Theme.amber) : AnyShapeStyle(Theme.amber.opacity(0.14)),
                                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Toggle("This is from before I was 12", isOn: $isChildhood)
                        .tint(Theme.violet)
                    Text("Childhood examples carry disproportionate weight — the criteria require the pattern to predate age 12, and that's often the hardest part to evidence.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    BigButton(title: "Save", systemImage: "checkmark", tint: Theme.amber) {
                        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        store.addEvidence(
                            EvidenceNote(domain: domain, text: trimmed, isChildhood: isChildhood)
                        )
                        Haptics.success()
                        dismiss()
                    }
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("New example")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { focused = true }
        }
    }
}
