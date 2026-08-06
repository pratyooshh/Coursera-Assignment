import SwiftUI

// MARK: - Card

struct Card<Content: View>: View {
    var tint: Color = Theme.violet
    @ViewBuilder var content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.cardPadding)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                    .stroke(tint.opacity(0.18), lineWidth: 1)
            )
    }
}

// MARK: - Section heading

struct SectionHeading: View {
    let title: String
    var subtitle: String? = nil
    var systemImage: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 7) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                Text(title)
                    .font(.headline)
            }
            if let subtitle {
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Big friendly button

struct BigButton: View {
    let title: String
    var systemImage: String? = nil
    var tint: Color = Theme.violet
    var style: Style = .filled
    let action: () -> Void

    enum Style { case filled, tonal }

    var body: some View {
        Button(action: {
            Haptics.tap()
            action()
        }) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .font(.body.weight(.semibold))
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .foregroundStyle(style == .filled ? Color.white : tint)
            .background(
                style == .filled ? AnyShapeStyle(tint) : AnyShapeStyle(tint.opacity(0.15)),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Chip

struct Chip: View {
    let text: String
    var tint: Color = Theme.violet
    var filled: Bool = false

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .foregroundStyle(filled ? Color.white : tint)
            .background(filled ? tint : tint.opacity(0.15), in: Capsule())
    }
}

// MARK: - Selectable option row

struct OptionRow: View {
    let label: String
    var detail: String? = nil
    let isSelected: Bool
    var tint: Color = Theme.violet
    let action: () -> Void

    var body: some View {
        Button(action: {
            Haptics.tap()
            action()
        }) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? tint : Color.secondary.opacity(0.5))
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                    if let detail {
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                isSelected ? tint.opacity(0.10) : Color.clear,
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
    }
}

// MARK: - Empty state

struct SoftEmptyState: View {
    let title: String
    let message: String
    var systemImage: String = "sparkles"

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 34))
                .foregroundStyle(Theme.violet.opacity(0.65))
            Text(title)
                .font(.headline)
            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

// MARK: - Disclaimer

struct DisclaimerNote: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(.secondary)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Progress bar

struct ThinProgressBar: View {
    let value: Double  // 0...1
    var tint: Color = Theme.violet

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(tint.opacity(0.18))
                Capsule()
                    .fill(tint)
                    .frame(width: max(0, min(1, value)) * geo.size.width)
            }
        }
        .frame(height: 8)
    }
}
