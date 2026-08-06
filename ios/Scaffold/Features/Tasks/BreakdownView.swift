import SwiftUI

/// Turns a dread-object into a first physical movement.
///
/// The failure mode this targets: "do the taxes" is not a task, it's a category.
/// Nothing in it can be started because none of it is an action. The prompts
/// push toward physical, observable first moves — the level at which starting
/// is actually possible.
struct BreakdownView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.dismiss) private var dismiss

    let taskID: UUID

    @State private var drafts: [String] = [""]
    @State private var promptIndex = 0
    @FocusState private var focusedField: Int?

    private var task: FocusTask? {
        store.data.tasks.first { $0.id == taskID }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.stackGap) {
                    if let task {
                        Card(tint: Theme.violet) {
                            Text(task.title)
                                .font(.headline)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    promptCard
                    stepsEditor
                    patternsCard

                    BigButton(title: "Save steps", systemImage: "checkmark", tint: Theme.violet) {
                        save()
                    }
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Break it down")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var promptCard: some View {
        Card(tint: Theme.sky) {
            VStack(alignment: .leading, spacing: 10) {
                Text(BreakdownPrompts.questions[promptIndex])
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    withAnimation {
                        promptIndex = (promptIndex + 1) % BreakdownPrompts.questions.count
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Another prompt")
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.sky)
                }
            }
        }
    }

    private var stepsEditor: some View {
        Card(tint: Theme.violet) {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeading(
                    title: "The steps",
                    subtitle: "Small enough that you'd be slightly embarrassed to call them steps."
                )

                ForEach(drafts.indices, id: \.self) { i in
                    HStack(spacing: 8) {
                        Text("\(i + 1)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                            .frame(width: 18)
                        TextField("e.g. open the folder", text: Binding(
                            get: { drafts.indices.contains(i) ? drafts[i] : "" },
                            set: { if drafts.indices.contains(i) { drafts[i] = $0 } }
                        ))
                        .focused($focusedField, equals: i)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(Theme.bg, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                        if drafts.count > 1 {
                            Button {
                                drafts.remove(at: i)
                            } label: {
                                Image(systemName: "minus.circle")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Button {
                    drafts.append("")
                    focusedField = drafts.count - 1
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "plus.circle.fill")
                        Text("Another step")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.violet)
                }
            }
        }
    }

    private var patternsCard: some View {
        Card(tint: Theme.amber) {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeading(
                    title: "Or start from a shape",
                    subtitle: "Adjust it after — a rough starting point beats a blank box.",
                    systemImage: "square.on.square"
                )
                ForEach(BreakdownPrompts.patterns, id: \.0) { pattern in
                    Button {
                        drafts = pattern.1
                        Haptics.tap()
                    } label: {
                        HStack {
                            Text(pattern.0)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            Image(systemName: "arrow.down.circle")
                                .foregroundStyle(Theme.amber)
                        }
                        .padding(.vertical, 6)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func save() {
        guard var task else { return }
        let cleaned = drafts
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !cleaned.isEmpty else {
            dismiss()
            return
        }
        task.steps = cleaned.map { MicroStep(text: $0) }
        store.update(task)
        Haptics.success()
        dismiss()
    }
}
