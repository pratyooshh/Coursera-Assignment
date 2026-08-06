import Foundation
import Combine

/// Countdown driven by wall-clock dates rather than accumulated ticks.
///
/// This matters more than it looks. Tick-counting drifts and, worse, stops
/// entirely when the app is backgrounded — so someone who switches apps mid-
/// session comes back to a timer that quietly lied to them. Storing the end date
/// and deriving the remainder means the timer is correct regardless of what
/// happened in between.
final class FocusTimer: ObservableObject {

    @Published private(set) var remaining: TimeInterval = 0
    @Published private(set) var isRunning = false
    @Published private(set) var isFinished = false

    private(set) var total: TimeInterval = 0
    private var endDate: Date?
    private var pausedRemaining: TimeInterval?
    private var ticker: AnyCancellable?

    /// Fires once when the countdown reaches zero.
    var onFinish: (() -> Void)?

    var progress: Double {
        guard total > 0 else { return 0 }
        return max(0, min(1, 1 - remaining / total))
    }

    var display: String {
        let t = max(0, Int(remaining.rounded()))
        return String(format: "%d:%02d", t / 60, t % 60)
    }

    func start(minutes: Int) {
        start(seconds: minutes * 60)
    }

    /// Toolbox steps are often shorter than a minute, so seconds is the real
    /// entry point and `start(minutes:)` just wraps it.
    func start(seconds: Int) {
        total = TimeInterval(max(1, seconds))
        remaining = total
        endDate = Date().addingTimeInterval(total)
        pausedRemaining = nil
        isFinished = false
        isRunning = true
        startTicking()
    }

    func pause() {
        guard isRunning, let endDate else { return }
        pausedRemaining = max(0, endDate.timeIntervalSinceNow)
        isRunning = false
        ticker?.cancel()
    }

    func resume() {
        guard !isRunning, let paused = pausedRemaining else { return }
        endDate = Date().addingTimeInterval(paused)
        pausedRemaining = nil
        isRunning = true
        startTicking()
    }

    func stop() {
        isRunning = false
        ticker?.cancel()
        ticker = nil
        endDate = nil
        pausedRemaining = nil
        remaining = 0
    }

    /// Extends an in-flight session without resetting progress.
    func addMinutes(_ minutes: Int) {
        total += TimeInterval(minutes * 60)
        if let endDate {
            self.endDate = endDate.addingTimeInterval(TimeInterval(minutes * 60))
        } else if let paused = pausedRemaining {
            pausedRemaining = paused + TimeInterval(minutes * 60)
        }
        refresh()
    }

    private func startTicking() {
        ticker?.cancel()
        ticker = Timer.publish(every: 0.25, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.refresh() }
        refresh()
    }

    private func refresh() {
        guard let endDate else { return }
        let left = endDate.timeIntervalSinceNow
        remaining = max(0, left)
        if left <= 0 && !isFinished {
            isFinished = true
            isRunning = false
            ticker?.cancel()
            Haptics.success()
            onFinish?()
        }
    }
}
