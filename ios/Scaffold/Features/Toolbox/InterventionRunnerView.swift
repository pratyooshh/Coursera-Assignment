import SwiftUI

/// One step, full screen, no scrolling past it.
///
/// Someone opening this is depleted. Showing all five steps at once means
/// reading and choosing, which is exactly the capacity that isn't available.
struct InterventionRunnerView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.dismiss) private var dismiss

    let interventionID: String

    @State private var index = 0
    @State private var responses: [String] = []
    @State private var draft = ""
    @State private var finished = false

    @StateObject private var timer = FocusTimer()
    @State private var timingStep = false

    private var tool: Intervention? { Toolbox.intervention(id: interventionID) }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.stackGap) {
                if let tool {
                    if finished {
                        completion(tool)
                    } else if tool.steps.indices.contains(index) {
                        stepView(tool, tool.steps[index])
                    }
                }
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(tool?.trigger ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { timer.stop() }
    }

    // MARK: - Step

    private func stepView(_ tool: Intervention, _ step: ToolStep) -> some View {
        VStack(spacing: Theme.stackGap) {
            HStack {
                Text("\(index + 1) of \(tool.steps.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            ThinProgressBar(value: Double(index) / Double(max(1, tool.steps.count)), tint: tool.tint)

            Card(tint: tool.tint) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(step.title)
                        .font(.title3.bold())
                        .fixedSize(horizontal: false, vertical: true)
                    Text(step.detail)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let prompt = step.prompt {
                Card(tint: tool.tint) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(prompt)
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(.secondary)
                        TextField("", text: $draft, axis: .vertical)
                            .textFieldStyle(.plain)
                            .lineLimit(3...8)
                            .padding(10)
                            .background(Theme.bg, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
            }

            if let seconds = step.seconds {
                timerSection(tool: tool, seconds: seconds)
            }

            BigButton(
                title: index + 1 < tool.steps.count ? "Next" : "Finish",
                systemImage: index + 1 < tool.steps.count ? "arrow.right" : "checkmark",
                tint: tool.tint
            ) {
                advance(tool, step: step)
            }

            if step.seconds != nil && timingStep {
                Button("Skip the timer") { advance(tool, step: step) }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func timerSection(tool: Intervention, seconds: Int) -> some View {
        VStack(spacing: 10) {
            if timingStep {
                TimerRing(
                    progress: timer.progress,
                    label: timer.display,
                    caption: timer.isFinished ? "Done" : nil,
                    tint: tool.tint
                )
                .scaleEffect(0.8)
                .frame(height: 210)
            } else {
                BigButton(
                    title: seconds >= 60 ? "Start \(seconds / 60) min" : "Start \(seconds) sec",
                    systemImage: "timer",
                    tint: tool.tint,
                    style: .tonal
                ) {
                    timingStep = true
                    timer.start(seconds: seconds)
                }
            }
        }
    }

    // MARK: - Completion

    private func completion(_ tool: Intervention) -> some View {
        VStack(spacing: Theme.stackGap) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(tool.tint)
                .padding(.top, 24)

            Text("You worked through it")
                .font(.title3.bold())

            Text("That's the win, whether or not the thing itself got done. Following a script while depleted is harder than it sounds.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let note = tool.closingNote {
                DisclaimerNote(text: note)
            }

            if !responses.filter({ !$0.isEmpty }).isEmpty {
                Card(tint: tool.tint) {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeading(title: "What you wrote")
                        ForEach(responses.filter { !$0.isEmpty }, id: \.self) { r in
                            Text("• " + r)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

            BigButton(title: "Save to my notes", systemImage: "tray.and.arrow.down", tint: tool.tint, style: .tonal) {
                for r in responses where !r.isEmpty {
                    store.capture(r)
                }
                Haptics.success()
                dismiss()
            }

            if tool.id == "spiralling" {
                BigButton(title: "Log this as a rejection episode", systemImage: "heart.slash", tint: Theme.coral, style: .tonal) {
                    store.logMood(
                        MoodEntry(
                            valence: 2,
                            energy: 3,
                            feelings: ["Rejected"],
                            note: responses.filter { !$0.isEmpty }.joined(separator: " / "),
                            wasRejectionEpisode: true
                        )
                    )
                    dismiss()
                }
            }

            BigButton(title: "Close", systemImage: "xmark", tint: tool.tint, style: .tonal) {
                dismiss()
            }

            Spacer(minLength: 20)
        }
    }

    // MARK: - Flow

    private func advance(_ tool: Intervention, step: ToolStep) {
        if step.prompt != nil {
            responses.append(draft.trimmingCharacters(in: .whitespacesAndNewlines))
            draft = ""
        }
        timer.stop()
        timingStep = false

        if index + 1 < tool.steps.count {
            withAnimation { index += 1 }
            Haptics.tap()
        } else {
            store.logWin("Worked through: \(tool.trigger)", source: "toolbox")
            withAnimation { finished = true }
            Haptics.success()
        }
    }
}
