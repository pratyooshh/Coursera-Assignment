import SwiftUI

/// A depleting ring, not a digital readout.
///
/// The whole point is that the remaining time has a *shape*. A number requires
/// you to read it, subtract, and hold the result — three working-memory
/// operations. A visibly shrinking arc requires none, which is why analogue
/// visual timers keep coming up in the time-blindness literature as the
/// intervention that actually works.
struct TimerRing: View {
    let progress: Double      // 0 = full, 1 = spent
    let label: String
    var caption: String? = nil
    var tint: Color = Theme.violet

    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.14), lineWidth: 18)

            Circle()
                .trim(from: 0, to: max(0.0001, 1 - progress))
                .stroke(
                    AngularGradient(
                        colors: [tint, tint.opacity(0.6), tint],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 18, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.25), value: progress)

            VStack(spacing: 4) {
                Text(label)
                    .font(.system(size: 52, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                if let caption {
                    Text(caption)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(28)
        }
        .frame(width: 250, height: 250)
    }
}
