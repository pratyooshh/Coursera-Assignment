import SwiftUI

/// One step on screen at a time.
///
/// Showing the whole routine at once reliably produces "that's a lot" and the
/// routine doesn't happen. Showing step 2 of 4 produces step 2.
struct RoutineRunnerView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.dismiss) private var dismiss

    let routineID: UUID
    @State private var index = 0
    @State private var done = false

    private var routine: Routine? {
        store.data.routines.first { $0.id == routineID }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.stackGap) {
                if let routine {
                    if done {
                        completion(routine)
                    } else if routine.steps.indices.contains(index) {
                        step(routine, routine.steps[index])
                    } else {
                        SoftEmptyState(
                            title: "Nothing in here yet",
                            message: "Add a couple of steps and this becomes usable.",
                            systemImage: "list.bullet"
                        )
                    }
                }
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(routine?.name ?? "Routine")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func step(_ routine: Routine, _ current: RoutineStep) -> some View {
        VStack(spacing: Theme.stackGap) {
            HStack {
                Text("Step \(index + 1) of \(routine.steps.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("~\(current.minutes) min")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ThinProgressBar(value: Double(index) / Double(max(1, routine.steps.count)), tint: Theme.mint)

            Card(tint: Theme.mint) {
                Text(current.text)
                    .font(.title3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 20)
            }

            BigButton(title: "Done — next", systemImage: "arrow.right", tint: Theme.mint) {
                advance(routine)
            }

            Button("Skip this one") {
                advance(routine)
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }

    private func completion(_ routine: Routine) -> some View {
        VStack(spacing: Theme.stackGap) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 52))
                .foregroundStyle(Theme.mint)
                .padding(.top, 30)
            Text("\(routine.name) done")
                .font(.title2.bold())
            Text("Logged as a win. Partial counts — skipping steps doesn't cancel it.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            BigButton(title: "Close", systemImage: "checkmark", tint: Theme.mint) {
                dismiss()
            }
            .padding(.top, 10)
        }
    }

    private func advance(_ routine: Routine) {
        if index + 1 < routine.steps.count {
            withAnimation { index += 1 }
            Haptics.tap()
        } else {
            store.logWin("\(routine.name) routine", source: "routine")
            withAnimation { done = true }
        }
    }
}

// MARK: - Editor

struct RoutinesEditorView: View {
    @EnvironmentObject private var store: DataStore
    @State private var newRoutineName = ""

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.stackGap) {
                DisclaimerNote(text: "Keep these short. A four-step routine survives a bad week; an eleven-step routine gets abandoned and then becomes another thing to feel bad about.")

                ForEach(store.data.routines) { routine in
                    RoutineEditorCard(routine: routine)
                }

                Card(tint: Theme.violet) {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeading(title: "New anchor")
                        HStack(spacing: 8) {
                            TextField("Name", text: $newRoutineName)
                                .textFieldStyle(.plain)
                                .padding(10)
                                .background(Theme.bg, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            Button {
                                let trimmed = newRoutineName.trimmingCharacters(in: .whitespacesAndNewlines)
                                guard !trimmed.isEmpty else { return }
                                store.addRoutine(Routine(name: trimmed, symbol: "circle", steps: []))
                                newRoutineName = ""
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
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Anchors")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct RoutineEditorCard: View {
    @EnvironmentObject private var store: DataStore
    let routine: Routine

    @State private var newStep = ""

    var body: some View {
        Card(tint: Theme.mint) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: routine.symbol)
                        .foregroundStyle(Theme.mint)
                    Text(routine.name)
                        .font(.headline)
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { routine.isEnabled },
                        set: { on in
                            var r = routine
                            r.isEnabled = on
                            store.updateRoutine(r)
                            Notifications.syncRoutineReminders(store.data.routines)
                        }
                    ))
                    .labelsHidden()
                    .tint(Theme.mint)
                }

                ForEach(routine.steps) { step in
                    HStack(spacing: 8) {
                        Circle().fill(Theme.mint.opacity(0.4)).frame(width: 6, height: 6)
                        Text(step.text)
                            .font(.subheadline)
                        Spacer()
                        Button {
                            var r = routine
                            r.steps.removeAll { $0.id == step.id }
                            store.updateRoutine(r)
                        } label: {
                            Image(systemName: "minus.circle")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }

                HStack(spacing: 8) {
                    TextField("Add a step", text: $newStep)
                        .textFieldStyle(.plain)
                        .padding(8)
                        .background(Theme.bg, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    Button {
                        let trimmed = newStep.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        var r = routine
                        r.steps.append(RoutineStep(text: trimmed))
                        store.updateRoutine(r)
                        newStep = ""
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Theme.mint)
                    }
                    .buttonStyle(.plain)
                }

                reminderPicker
            }
        }
    }

    private var reminderPicker: some View {
        HStack {
            Text("Nudge")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer()
            DatePicker(
                "",
                selection: Binding(
                    get: {
                        let mins = routine.reminderMinutes ?? 9 * 60
                        return Calendar.current.date(
                            bySettingHour: mins / 60, minute: mins % 60, second: 0, of: Date()
                        ) ?? Date()
                    },
                    set: { newDate in
                        let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                        var r = routine
                        r.reminderMinutes = (comps.hour ?? 9) * 60 + (comps.minute ?? 0)
                        store.updateRoutine(r)
                        Notifications.syncRoutineReminders(store.data.routines)
                    }
                ),
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()

            Button {
                var r = routine
                r.reminderMinutes = nil
                store.updateRoutine(r)
                Notifications.syncRoutineReminders(store.data.routines)
            } label: {
                Image(systemName: routine.reminderMinutes == nil ? "bell.slash" : "bell.fill")
                    .font(.footnote)
                    .foregroundStyle(routine.reminderMinutes == nil ? .secondary : Theme.mint)
            }
            .buttonStyle(.plain)
        }
    }
}
