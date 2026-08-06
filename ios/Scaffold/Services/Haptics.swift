import UIKit

/// Small, immediate physical feedback.
///
/// This is not decoration. An interest-based nervous system needs the reward to
/// arrive *now*; a delayed or invisible confirmation does nothing. Haptics are
/// the cheapest immediate-feedback channel we have.
enum Haptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func thud() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
