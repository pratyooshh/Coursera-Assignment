import SwiftUI

struct FocusSessionView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.dismiss) private var dismiss

    var mode: FocusMode = .sprint
    var presetTask: String? = nil
    var predicted: Int? = nil

    @StateObject private var timer = FocusTimer()
    @State private var minutes: Int = 25
    @State private var taskText: String = ""
    @State private var sessionID: UUID?
    @State private var hasStarted = false
    @State private var checkInIndex = 0
    @State private var showingCheckIn = false

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.stackGap) {
                if hasStarted {
                    running
                } else {
                    setup
                }
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(mode.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            taskText = presetTask ?? ""
            minutes = defaultMinutes
            timer.onFinish = handleFinish
        }
        .onDisappear {
            if hasStarted, let id = sessionID, !timer.isFinished {
                store.finishSession(id, completedFully: false)
            }
            timer.stop()
        }
        .sheet(isPresented: $showingCheckIn) {
            checkInSheet
        }
    }

    private var defaultMinutes: Int {
        switch mode {
        case .sprint: return 25
        case .bodyDouble: return 45
        case .hyperfocusGuard: return 90
        }
    }

    private var tint: Color {
        switch mode {
        case .sprint: return Theme.violet
        case .bodyDouble: return Theme.sky
        case .hyperfocusGuard: return Theme.amber
        }
    }

    // MARK: - Setup

    private var setup: some View {
        VStack(spacing: Theme.stackGap) {
            Card(tint: tint) {
                Text(mode.blurb)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Card(tint: tint) {
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeading(
                        title: "What are you doing?",
                        subtitle: "Naming it out loud is doing real work — it's the same mechanism body doubling runs on."
                    )
                    TextField("The thing", text: $taskText)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Theme.bg, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }

            Card(tint: tint) {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeading(title: "How long?")
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 8)], spacing: 8) {
                        ForEach(lengthOptions, id: \.self) { m in
                            Button {
                                minutes = m
                                Haptics.tap()
                            } label: {
                                Text(m >= 60 ? "\(m / 60)h" : "\(m)m")
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .foregroundStyle(minutes == m ? .white : tint)
                                    .background(
                                        minutes == m ? AnyShapeStyle(tint) : AnyShapeStyle(tint.opacity(0.14)),
                                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if mode == .sprint {
                        Text("Shorter than feels right is usually the correct call. A block you finish is worth more than one you abandon at minute nine.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            if mode == .hyperfocusGuard {
                Card(tint: Theme.amber) {
                    VStack(alignment: .leading, spacing: 6) {
                        SectionHeading(title: "You'll be interrupted", systemImage: "bell.badge")
                        Text("Every 25 minutes this will break in to ask about water, food, posture and eyes. That's the point of the mode — once you're in, you won't think to check any of it yourself.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            BigButton(title: "Start", systemImage: "play.fill", tint: tint) {
                begin()
            }
        }
    }

    private var lengthOptions: [Int] {
        switch mode {
        case .sprint: return [5, 10, 15, 25, 45]
        case .bodyDouble: return [25, 45, 60, 90]
        case .hyperfocusGuard: return [60, 90, 120, 180]
        }
    }

    // MARK: - Running

    private var running: some View {
        VStack(spacing: 20) {
            if !taskText.isEmpty {
                Text(taskText)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            TimerRing(
                progress: timer.progress,
                label: timer.display,
                caption: timer.isFinished ? "Done" : (timer.isRunning ? nil : "Paused"),
                tint: tint
            )
            .padding(.vertical, 8)

            if mode == .bodyDouble && !timer.isFinished {
                Card(tint: Theme.sky) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(bodyDoublePrompt)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("A real person is better than this. If you have someone, put them on a silent call and work alongside them.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            if timer.isFinished {
                finishedActions
            } else {
                HStack(spacing: 10) {
                    BigButton(
                        title: timer.isRunning ? "Pause" : "Resume",
                        systemImage: timer.isRunning ? "pause.fill" : "play.fill",
                        tint: tint,
                        style: .tonal
                    ) {
                        timer.isRunning ? timer.pause() : timer.resume()
                    }
                    BigButton(title: "Stop", systemImage: "stop.fill", tint: Theme.coral, style: .tonal) {
                        end(fully: false)
                    }
                }

                Button {
                    timer.addMinutes(5)
                    Haptics.tap()
                } label: {
                    Text("+5 minutes")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(tint)
                }
            }
        }
    }

    private var bodyDoublePrompt: String {
        let prompts = [
            "You said what you're doing. Now do it — no need to check in with anyone.",
            "Still here, still working alongside you.",
            "Nothing to report. Keep going.",
        ]
        return prompts[checkInIndex % prompts.count]
    }

    private var finishedActions: some View {
        VStack(spacing: 10) {
            Text("Block finished.")
                .font(.title3.bold())
            BigButton(title: "Log it and stop", systemImage: "checkmark", tint: Theme.mint) {
                end(fully: true)
            }
            BigButton(title: "Another 15 minutes", systemImage: "arrow.clockwise", tint: tint, style: .tonal) {
                timer.start(minutes: 15)
            }
        }
    }

    // MARK: - Check-in

    private var checkInSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Body check")
                        .font(.title2.bold())
                    Text("You've been at this a while. Quick pass, then straight back in.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ForEach([
                        ("drop", "Have some water"),
                        ("fork.knife", "When did you last eat?"),
                        ("figure.stand", "Stand up and stretch"),
                        ("eye", "Look at something 6 metres away for 20 seconds"),
                    ], id: \.1) { item in
                        HStack(spacing: 12) {
                            Image(systemName: item.0)
                                .foregroundStyle(Theme.amber)
                                .frame(width: 26)
                            Text(item.1)
                                .font(.body)
                            Spacer()
                        }
                    }

                    BigButton(title: "Done — back to it", systemImage: "arrow.right", tint: Theme.amber) {
                        showingCheckIn = false
                    }
                    .padding(.top, 8)
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
        }
    }

    // MARK: - Lifecycle

    private func begin() {
        let session = store.startSession(
            mode: mode,
            minutes: minutes,
            taskTitle: taskText.isEmpty ? nil : taskText,
            predicted: predicted
        )
        sessionID = session.id
        hasStarted = true
        timer.start(minutes: minutes)
        Notifications.scheduleSessionEnd(in: minutes, mode: mode)
        if mode == .hyperfocusGuard {
            Notifications.scheduleBodyChecks(totalMinutes: minutes, every: 25)
        }
        Haptics.thud()
    }

    private func handleFinish() {
        if mode == .hyperfocusGuard {
            checkInIndex += 1
            showingCheckIn = true
        }
    }

    private func end(fully: Bool) {
        if let id = sessionID {
            store.finishSession(id, completedFully: fully)
        }
        timer.stop()
        Notifications.cancelSessionNotifications()
        dismiss()
    }
}
