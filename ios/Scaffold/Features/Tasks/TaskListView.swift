import SwiftUI

struct TaskListView: View {
    @EnvironmentObject private var store: DataStore
    @State private var showingNew = false

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.stackGap) {
                if store.openTasks.isEmpty {
                    SoftEmptyState(
                        title: "Nothing here",
                        message: "Add something, or pull it through from your inbox.",
                        systemImage: "checklist"
                    )
                } else {
                    section("On today", tasks: store.openTasks.filter(\.isOnToday), tint: Theme.violet)
                    section("Later", tasks: store.openTasks.filter { !$0.isOnToday }, tint: Theme.sky)
                }

                let done = store.data.tasks.filter(\.isDone)
                if !done.isEmpty {
                    Card(tint: Theme.mint) {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeading(title: "Done", subtitle: "\(done.count) finished", systemImage: "checkmark.seal")
                            ForEach(done.prefix(8)) { task in
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Theme.mint)
                                        .font(.subheadline)
                                    Text(task.title)
                                        .font(.subheadline)
                                        .strikethrough(color: .secondary)
                                        .foregroundStyle(.secondary)
                                    Spacer(minLength: 0)
                                }
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Tasks")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingNew = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingNew) { NewTaskSheet() }
    }

    @ViewBuilder
    private func section(_ title: String, tasks: [FocusTask], tint: Color) -> some View {
        if !tasks.isEmpty {
            Card(tint: tint) {
                VStack(alignment: .leading, spacing: 6) {
                    SectionHeading(title: title)
                    ForEach(tasks) { task in
                        NavigationLink {
                            TaskDetailView(taskID: task.id)
                        } label: {
                            TaskRow(task: task)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - New task

struct NewTaskSheet: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var cost: ActivationCost = .medium
    @State private var onToday = true
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What is it?")
                            .font(.headline)
                        TextField("The thing", text: $title, axis: .vertical)
                            .focused($focused)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(Theme.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeading(
                            title: "How hard is it to start?",
                            subtitle: "Starting, not doing. These are different things and only one of them predicts avoidance."
                        )
                        ForEach(ActivationCost.allCases) { option in
                            OptionRow(label: option.label, isSelected: cost == option, tint: Theme.violet) {
                                cost = option
                            }
                        }
                    }

                    Toggle("Put it on today", isOn: $onToday)
                        .tint(Theme.violet)
                        .padding(.horizontal, 4)

                    BigButton(title: "Add it", systemImage: "plus", tint: Theme.violet) {
                        var task = FocusTask(title: title.trimmingCharacters(in: .whitespacesAndNewlines))
                        guard !task.title.isEmpty else { return }
                        task.activationCost = cost
                        task.isOnToday = onToday
                        store.addTask(task)
                        dismiss()
                    }
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("New task")
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
