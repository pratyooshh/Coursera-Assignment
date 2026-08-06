import SwiftUI

/// Visual language for Scaffold.
///
/// Design constraints come straight from what the ADHD literature says about
/// interface friction:
///   - Low visual clutter. Every extra element is another thing to filter out.
///   - High contrast, generous tap targets.
///   - Never use red for "you're behind." Overdue-red is a shame trigger and
///     it makes people avoid the app entirely, which is the opposite of useful.
///   - Colour carries meaning consistently: warm = energy/action, cool = calm.
enum Theme {

    // MARK: - Palette

    static let plum = Color(hex: 0x2A1B3D)
    static let ink = Color(hex: 0x150E1F)

    static let amber = Color(hex: 0xF2A65A)
    static let coral = Color(hex: 0xE8697D)
    static let violet = Color(hex: 0x8B6BE0)
    static let mint = Color(hex: 0x5BC8A0)
    static let sky = Color(hex: 0x5AA9E6)

    /// Backgrounds adapt to light/dark rather than forcing one look.
    static let bg = Color(.systemGroupedBackground)
    static let card = Color(.secondarySystemGroupedBackground)

    // MARK: - Semantic accents

    /// Focus / doing.
    static let focus = violet
    /// Capture / offload.
    static let capture = sky
    /// Feelings.
    static let feeling = coral
    /// Energy & wins.
    static let energy = amber
    /// Calm / regulation.
    static let calm = mint

    // MARK: - Metrics

    static let radius: CGFloat = 18
    static let cardPadding: CGFloat = 16
    static let stackGap: CGFloat = 14

    static let gradientWarm = LinearGradient(
        colors: [amber, coral],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let gradientCool = LinearGradient(
        colors: [violet, sky],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
