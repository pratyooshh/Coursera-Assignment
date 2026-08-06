import SwiftUI

struct TaskDetailView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.dismiss) private var dismiss

    let taskID: UUID
    @State private var newStep = ""
    @State private var showingBreakdown = false
    @State private var showingFinish = false

    private var task: FocusTask? {
        store.data.tasks.first { $0.id == taskID }
    }

    var body: some View {
        ScrollView {
            if let task {
                VStack(spacing: Theme.stackGap) {
                    header(task)
                    if task.activationCost == .wall { wallCard }
                    stepsCard(task)
                    estimateCard(task)
                    actionsCard(task)
                }
                .padding(16)
            } else {
                SoftEmptyState(title: "Gone", message: "This task no longer exists.", systemImage: "questionmark")
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Task")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingBreakdown) {
            BreakdownView(taskID: taskID)
        }
        .sheet(isPresented: $showingFinish) {
            if let task { FinishTaskSheet(task: task) { dismiss() } }
        }
    }

    // MARK: - Sections

    private func header(_ task: FocusTask) -> some View {
        Card(tint: Theme.violet) {
            VStack(alignment: .leading, spacing: 10) {
                Text(task.title)
                    .font(.title3.bold())
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 8) {
                    Chip(text: task.activationCost.shortLabel + " to start", tint: Theme.violet)
                    if task.isOnToday {
                        Chip(text: "Today", tint: Theme.amber, filled: true)
                    }
                }
            }
        }
    }

    private var wallCard: some View {
        Card(tint: Theme.coral) {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeading(
                    title: "You marked this a wall",
                    subtitle: "Then the obstacle probably isn't the work.",
                    systemImage: "shield.lefthalf.filled"
                )
                Text("Tasks that are objectively small and still undoable usually have something emotional stacked in front of them. Productivity techniques bounce off that. The guided script does something different.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                NavigationLink {
                    InterventionRunnerView(interventionID: "cant-start")
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("Work through it")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.coral)
                }
            }
        }
    }

    private func stepsCard(_ task: FocusTask) -> some View {
        Card(tint: Theme.violet) {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeading(
                    title: "Steps",
                    subtitle: task.steps.isEmpty ? "A task with no steps is a task you'll stare at." : nil,
                    systemImage: "list.bullet.indent"
                )

                if task.steps.isEmpty {
                    BigButton(title: "Break it down", systemImage: "wand.and.stars", tint: Theme.violet, style: .tonal) {
                        showingBreakdown = true
                    }
                } else {
                    ForEach(task.steps) { step in
                        Button {
                            store.toggleStep(taskID: task.id, stepID: step.id)
                        } label: {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: step.isDone ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(step.isDone ? Theme.mint : Theme.violet.opacity(0.5))
                                Text(step.text)
                                    .font(.subheadline)
                                    .strikethrough(step.isDone, color: .secondary)
                                    .foregroundStyle(step.isDone ? .secondary : .primary)
                                    .multilineTextAlignment(.leading)
                                Spacer(minLength: 0)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }

                    if let next = task.firstUndoneStep {
                        Divider().padding(.vertical, 2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Only this one matters right now")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(next.text)
                                .font(.headline)
                                .foregroundStyle(Theme.violet)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    HStack(spacing: 8) {
                        TextField("Add a step", text: $newStep)
                            .textFieldStyle(.plain)
                            .padding(10)
                            .background(Theme.bg, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        Button {
                            addStep(to: task)
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Theme.violet)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func estimateCard(_ task: FocusTask) -> some View {
        Card(tint: Theme.sky) {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeading(
                    title: "Time",
                    subtitle: "Guess before you start. That's how the multiplier gets built.",
                    systemImage: "clock"
                )

                HStack(spacing: 10) {
                    ForEach([5, 15, 30, 60, 120], id: \.self) { m in
                        Button {
                            var t = task
                            t.predictedMinutes = m
                            store.update(t)
                            Haptics.tap()
                        } label: {
                            Text(m >= 60 ? "\(m / 60)h" : "\(m)m")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .foregroundStyle(task.predictedMinutes == m ? .white : Theme.sky)
                                .background(
                                    task.predictedMinutes == m ? AnyShapeStyle(Theme.sky) : AnyShapeStyle(Theme.sky.opacity(0.14)),
                                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }

                if let predicted = task.predictedMinutes, let mult = store.timeMultiplier {
                    let realistic = Int((Double(predicted) * mult).rounded())
                    Text("Your history says this is more likely \(realistic) minutes — you run about \(String(format: "%.1f", mult))× your estimates.")
                        .font(.footnote)
                        .foregroundStyle(Theme.sky)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func actionsCard(_ task: FocusTask) -> some View {
        VStack(spacing: 10) {
            NavigationLink {
                FocusSessionView(
                    presetTask: task.title,
                    predicted: task.predictedMinutes
                )
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "timer")
                    Text("Start a focus block")
                }
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(minHeight: 52)
                .foregroundStyle(.white)
                .background(Theme.violet, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            BigButton(title: "Mark it done", systemImage: "checkmark", tint: Theme.mint, style: .tonal) {
                showingFinish = true
            }

            BigButton(title: task.isOnToday ? "Take it off today" : "Put it on today", systemImage: "sun.horizon", tint: Theme.amber, style: .tonal) {
                var t = task
                t.isOnToday.toggle()
                store.update(t)
            }

            Button(role: .destructive) {
                store.deleteTask(task)
                dismiss()
            } label: {
                Text("Delete")
                    .font(.footnote)
            }
            .padding(.top, 4)
        }
    }

    private func addStep(to task: FocusTask) {
        let trimmed = newStep.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var t = task
        t.steps.append(MicroStep(text: trimmed))
        store.update(t)
        newStep = ""
    }
}

// MARK: - Finish sheet (captures actual time)

struct FinishTaskSheet: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.dismiss) private var dismiss

    let task: FocusTask
    let onDone: () -> Void

    @State private var actual: Int?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Done. How long did it actually take?")
                        .font(.title3.bold())

                    if let p = task.predictedMinutes {
                        Text("You guessed \(p) minutes.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Text("This is the only way the app learns your real multiplier. A rough answer is fine — precision isn't the point, the ratio is.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    let options = [5, 10, 15, 30, 45, 60, 90, 120, 180]
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 8)], spacing: 8) {
                        ForEach(options, id: \.self) { m in
                            Button {
                                actual = m
                                Haptics.tap()
                            } label: {
                                Text(m >= 60 ? "\(m / 60)h\(m % 60 == 0 ? "" : "30")" : "\(m)m")
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .foregroundStyle(actual == m ? .white : Theme.mint)
                                    .background(
                                        actual == m ? AnyShapeStyle(Theme.mint) : AnyShapeStyle(Theme.mint.opacity(0.14)),
                                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    BigButton(title: "Log it", systemImage: "checkmark", tint: Theme.mint) {
                        var t = task
                        t.actualMinutes = actual
                        store.update(t)
                        store.complete(t)
                        dismiss()
                        onDone()
                    }

                    Button("Skip — just mark it done") {
                        store.complete(task)
                        dismiss()
                        onDone()
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Nice one")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
