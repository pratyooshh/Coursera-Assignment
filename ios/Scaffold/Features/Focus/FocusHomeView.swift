import SwiftUI

struct FocusHomeView: View {
    @EnvironmentObject private var store: DataStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.stackGap) {
                    ForEach(FocusMode.allCases) { mode in
                        NavigationLink {
                            FocusSessionView(mode: mode)
                        } label: {
                            Card(tint: tint(for: mode)) {
                                HStack(spacing: 14) {
                                    Image(systemName: mode.symbol)
                                        .font(.title2)
                                        .foregroundStyle(tint(for: mode))
                                        .frame(width: 32)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(mode.title)
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        Text(mode.blurb)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .multilineTextAlignment(.leading)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    Spacer(minLength: 0)
                                    Image(systemName: "chevron.right")
                                        .font(.footnote)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    calibrationCard
                    todayCard
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Focus")
        }
    }

    private func tint(for mode: FocusMode) -> Color {
        switch mode {
        case .sprint: return Theme.violet
        case .bodyDouble: return Theme.sky
        case .hyperfocusGuard: return Theme.amber
        }
    }

    private var calibrationCard: some View {
        Card(tint: Theme.sky) {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeading(
                    title: "Your time multiplier",
                    subtitle: "How far your estimates sit from reality",
                    systemImage: "chart.line.uptrend.xyaxis"
                )

                if let mult = store.timeMultiplier {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(String(format: "%.1f×", mult))
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.sky)
                        Text("from \(store.calibrationSampleCount) tasks")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(explanation(for: mult))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    let n = store.calibrationSampleCount
                    Text("Needs \(max(0, 3 - n)) more timed task\(3 - n == 1 ? "" : "s") before it means anything.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Guess before you start, log what it actually took, and the ratio does the rest. Estimating better isn't the goal — knowing your error is.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func explanation(for mult: Double) -> String {
        if mult < 1.2 {
            return "Your estimates are close to reality, which is genuinely unusual. Keep logging — a few more samples will confirm it."
        } else if mult < 1.8 {
            return "You run moderately over. Multiply your gut estimate by this before you commit to anything and you'll stop overpromising."
        } else {
            return "You run well over — which is common and not a character flaw. Plan with this number instead of the number in your head, and days start fitting."
        }
    }

    private var todayCard: some View {
        Card(tint: Theme.violet) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Focused today")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(store.focusMinutesToday) min")
                        .font(.title2.bold())
                }
                Spacer()
                Image(systemName: "timer")
                    .font(.title)
                    .foregroundStyle(Theme.violet.opacity(0.4))
            }
        }
    }
}
