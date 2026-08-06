import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var store: DataStore
    @Binding var showingCapture: Bool

    @State private var showingMood = false
    @State private var showingMenu = false
    @State private var showingTasks = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.stackGap) {
                    greeting
                    captureCard
                    oneThingCard
                    if !store.untriagedCaptures.isEmpty { inboxCard }
                    routinesCard
                    quickRow
                    winsCard
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(dayLabel)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCapture = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .accessibilityLabel("Capture a thought")
                }
            }
            .sheet(isPresented: $showingMood) { MoodSheet() }
            .sheet(isPresented: $showingMenu) { DopamineMenuView() }
            .navigationDestination(isPresented: $showingTasks) { TaskListView() }
        }
    }

    // MARK: - Pieces

    private var dayLabel: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        return f.string(from: Date())
    }

    private var greeting: some View {
        Card(tint: Theme.amber) {
            VStack(alignment: .leading, spacing: 6) {
                Text(timeGreeting)
                    .font(.title2.bold())
                Text(subline)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var timeGreeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        switch h {
        case 5..<12: return "Morning."
        case 12..<17: return "Afternoon."
        case 17..<22: return "Evening."
        default: return "It's late."
        }
    }

    private var subline: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h >= 22 || h < 5 {
            return "No judgement. If you're winding down, there's a script for that in the Toolbox."
        }
        let mins = store.focusMinutesToday
        if mins > 0 {
            return "\(mins) minutes of focus logged today. That's real."
        }
        return "Nothing logged yet. That's a neutral fact, not a verdict."
    }

    private var captureCard: some View {
        Button {
            showingCapture = true
        } label: {
            Card(tint: Theme.sky) {
                HStack(spacing: 14) {
                    Image(systemName: "brain.head.profile")
                        .font(.title2)
                        .foregroundStyle(Theme.sky)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Get it out of your head")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("Don't organise it. Just put it down.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var oneThingCard: some View {
        let tasks = store.todayTasks
        Card(tint: Theme.violet) {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeading(
                    title: "Today",
                    subtitle: tasks.isEmpty ? nil : "One at a time. The rest can wait.",
                    systemImage: "target"
                )

                if tasks.isEmpty {
                    Text("Nothing on today's list.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    BigButton(title: "Pick something", systemImage: "plus", tint: Theme.violet, style: .tonal) {
                        showingTasks = true
                    }
                } else {
                    ForEach(tasks.prefix(3)) { task in
                        NavigationLink {
                            TaskDetailView(taskID: task.id)
                        } label: {
                            TaskRow(task: task)
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        showingTasks = true
                    } label: {
                        HStack(spacing: 4) {
                            Text(tasks.count > 3 ? "All \(tasks.count) tasks" : "All tasks")
                            Image(systemName: "chevron.right").font(.caption2)
                        }
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(Theme.violet)
                    }
                    .padding(.top, 2)
                }
            }
        }
    }

    private var inboxCard: some View {
        NavigationLink {
            TriageView()
        } label: {
            Card(tint: Theme.sky) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(Theme.sky.opacity(0.15)).frame(width: 40, height: 40)
                        Text("\(store.untriagedCaptures.count)")
                            .font(.headline)
                            .foregroundStyle(Theme.sky)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("In your inbox")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("Sort them when you've got the capacity")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var routinesCard: some View {
        Card(tint: Theme.mint) {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeading(title: "Anchors", subtitle: "Short on purpose", systemImage: "repeat")
                ForEach(store.data.routines.filter(\.isEnabled)) { routine in
                    NavigationLink {
                        RoutineRunnerView(routineID: routine.id)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: routine.symbol)
                                .font(.subheadline)
                                .foregroundStyle(Theme.mint)
                                .frame(width: 24)
                            Text(routine.name)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            Spacer()
                            Text("\(routine.totalMinutes) min")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                NavigationLink {
                    RoutinesEditorView()
                } label: {
                    Text("Edit anchors")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(Theme.mint)
                }
                .padding(.top, 2)
            }
        }
    }

    private var quickRow: some View {
        HStack(spacing: 10) {
            QuickTile(title: "How am I?", symbol: "heart.text.square", tint: Theme.coral) {
                showingMood = true
            }
            QuickTile(title: "Dopamine menu", symbol: "list.clipboard", tint: Theme.amber) {
                showingMenu = true
            }
        }
    }

    private var winsCard: some View {
        NavigationLink {
            WinsView()
        } label: {
            Card(tint: Theme.amber) {
                VStack(alignment: .leading, spacing: 8) {
                    SectionHeading(
                        title: "Wins",
                        subtitle: "No streaks here. This number only goes up.",
                        systemImage: "trophy"
                    )
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(store.lifetimeWinCount)")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.amber)
                        Text("logged")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if !store.winsToday.isEmpty {
                            Chip(text: "\(store.winsToday.count) today", tint: Theme.amber, filled: true)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sub-views

struct TaskRow: View {
    @EnvironmentObject private var store: DataStore
    let task: FocusTask

    var body: some View {
        HStack(spacing: 12) {
            Button {
                store.complete(task)
            } label: {
                Image(systemName: "circle")
                    .font(.title3)
                    .foregroundStyle(Theme.violet.opacity(0.6))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                if !task.steps.isEmpty {
                    HStack(spacing: 6) {
                        ThinProgressBar(value: task.stepProgress, tint: Theme.violet)
                            .frame(width: 60)
                        Text("\(task.steps.filter(\.isDone).count)/\(task.steps.count)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                } else if task.activationCost == .wall {
                    Text("There's a wall on this one")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

struct QuickTile: View {
    let title: String
    let symbol: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            Haptics.tap()
            action()
        }) {
            VStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.title2)
                    .foregroundStyle(tint)
                Text(title)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                    .stroke(tint.opacity(0.18), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
