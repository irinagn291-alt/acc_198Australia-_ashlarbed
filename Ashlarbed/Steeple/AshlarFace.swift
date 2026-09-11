import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Role: Steeple. SF Pro scale, 8 pt spacing, 22 / 14 radii, one shadow. Views never pick a second radius.
enum AshlarFace {
    static let unit: CGFloat = 8
    static let tap: CGFloat = 44
    static let cardRadius: CGFloat = 22
    static let chipRadius: CGFloat = 14
    static let motion = Animation.easeInOut(duration: 0.28)
    static let fade = Animation.easeInOut(duration: 0.22)

    static func space(_ steps: Int) -> CGFloat {
        unit * CGFloat(steps)
    }

    enum Step: CaseIterable {
        case spire
        case title
        case body
        case callout
        case caption
        case figure

        var font: Font {
            switch self {
            case .spire:
                .system(.title).weight(.semibold)
            case .title:
                .system(.title3).weight(.semibold)
            case .body:
                .system(.body)
            case .callout:
                .system(.callout)
            case .caption:
                .system(.caption)
            case .figure:
                .system(.title2).weight(.semibold).monospacedDigit()
            }
        }
    }

    static func font(_ step: Step) -> Font {
        step.font
    }

    static var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cardRadius, style: .continuous)
    }

    static var chipShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: chipRadius, style: .continuous)
    }
}

/// Role: Steeple. Dismisses the decimal pad. Scroll and Done also resign.
enum AshlarKeyboard {
    @MainActor
    static func dismiss() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
        #endif
    }
}

/// Role: Steeple. Pressed scale. Reduce Motion fades. Disabled is faded, not identical.
struct AshlarPressStyle: ButtonStyle {
    var enabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        AshlarPressBody(configuration: configuration, enabled: enabled)
    }
}

private struct AshlarPressBody: View {
    var configuration: ButtonStyle.Configuration
    var enabled: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        configuration.label
            .scaleEffect(!reduceMotion && configuration.isPressed && enabled ? 0.97 : 1)
            .opacity(enabled ? (configuration.isPressed ? 0.88 : 1) : 0.45)
            .animation(reduceMotion ? AshlarFace.fade : AshlarFace.motion, value: configuration.isPressed)
    }
}

private struct AshlarElevation: ViewModifier {
    func body(content: Content) -> some View {
        content.shadow(
            color: AshlarSwatch.ink.opacity(0.10),
            radius: 10,
            x: 0,
            y: 5
        )
    }
}

extension View {
    func ashlarInk(_ step: AshlarFace.Step) -> some View {
        font(AshlarFace.font(step))
            .foregroundStyle(AshlarSwatch.ink)
    }

    func ashlarRaised() -> some View {
        modifier(AshlarElevation())
    }

    func ashlarCardFill() -> some View {
        background(AshlarSwatch.surface)
            .clipShape(AshlarFace.cardShape)
            .ashlarRaised()
    }
}

/// Role: Steeple. Soft-card control. The fill is the target. Accent is a ring, never the only signal.
struct AshlarChromeButton: View {
    var title: String
    var detail: String? = nil
    var artwork: String? = nil
    var fills: Bool = true
    var emphasized: Bool = false
    var enabled: Bool = true
    var busy: Bool = false
    var hint: String? = nil
    var action: () -> Void

    private var active: Bool { enabled && !busy }

    var body: some View {
        Button(action: action) {
            HStack(spacing: AshlarFace.space(2)) {
                if let artwork {
                    Image(artwork)
                        .resizable()
                        .scaledToFit()
                        .frame(width: AshlarFace.space(4), height: AshlarFace.space(4))
                        .accessibilityHidden(true)
                }
                VStack(spacing: 0) {
                    Text(title)
                        .ashlarInk(.title)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    if let detail {
                        Text(detail)
                            .font(AshlarFace.font(.caption))
                            .foregroundStyle(AshlarSwatch.ink)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                    }
                }
                .frame(maxWidth: fills ? .infinity : nil)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, AshlarFace.space(2))
            .padding(.vertical, AshlarFace.space(1))
            .frame(maxWidth: fills ? .infinity : nil, minHeight: AshlarFace.tap)
            .background(AshlarSwatch.surface)
            .clipShape(AshlarFace.cardShape)
            .overlay {
                AshlarFace.cardShape.stroke(
                    emphasized && active ? AshlarSwatch.accent : AshlarSwatch.muted.opacity(0.35),
                    lineWidth: emphasized && active ? 3 : 1
                )
            }
            .ashlarRaised()
            .contentShape(AshlarFace.cardShape)
        }
        .buttonStyle(AshlarPressStyle(enabled: active))
        .disabled(!active)
        .accessibilityLabel(detail.map { "\(title). \($0)" } ?? title)
        .accessibilityHint(hint ?? "")
    }
}

/// Role: Steeple. Recoverable fault with a retry control.
struct AshlarBanner: View {
    var text: String
    var retryTitle: String = "Retry"
    var retry: () -> Void

    var body: some View {
        HStack(spacing: AshlarFace.space(1)) {
            Text(text)
                .font(AshlarFace.font(.callout))
                .foregroundStyle(AshlarSwatch.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: retry) {
                Text(retryTitle)
                    .font(AshlarFace.font(.callout).weight(.semibold))
                    .foregroundStyle(AshlarSwatch.ink)
                    .frame(minWidth: AshlarFace.tap, minHeight: AshlarFace.tap)
                    .padding(.horizontal, AshlarFace.space(1))
                    .background(AshlarSwatch.surface)
                    .clipShape(AshlarFace.chipShape)
                    .contentShape(AshlarFace.chipShape)
            }
            .buttonStyle(AshlarPressStyle(enabled: true))
            .accessibilityLabel(retryTitle)
        }
        .padding(.horizontal, AshlarFace.space(2))
        .padding(.vertical, AshlarFace.space(1))
        .frame(maxWidth: .infinity, minHeight: AshlarFace.tap, alignment: .leading)
        .background(AshlarSwatch.surface)
        .clipShape(AshlarFace.cardShape)
        .ashlarRaised()
    }
}

/// Role: Steeple. Sheet header with a dismiss that always works.
struct AshlarSheetBar: View {
    var title: String
    var onClose: () -> Void

    var body: some View {
        HStack(spacing: AshlarFace.space(1)) {
            Text(title)
                .ashlarInk(.title)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Spacer(minLength: 0)
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(AshlarFace.font(.body).weight(.semibold))
                    .foregroundStyle(AshlarSwatch.ink)
                    .frame(width: AshlarFace.tap, height: AshlarFace.tap)
                    .contentShape(Rectangle())
            }
            .buttonStyle(AshlarPressStyle(enabled: true))
            .accessibilityLabel("Close")
        }
        .frame(maxWidth: .infinity, minHeight: AshlarFace.tap)
    }
}

/// Role: Steeple. Icon control. SF Symbol is the affordance, not the brand.
struct AshlarGlyphButton: View {
    var systemName: String
    var label: String
    var enabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(AshlarFace.font(.body).weight(.semibold))
                .foregroundStyle(AshlarSwatch.ink)
                .frame(width: AshlarFace.tap, height: AshlarFace.tap)
                .background(AshlarSwatch.surface)
                .clipShape(AshlarFace.chipShape)
                .ashlarRaised()
                .contentShape(AshlarFace.chipShape)
        }
        .buttonStyle(AshlarPressStyle(enabled: enabled))
        .disabled(!enabled)
        .accessibilityLabel(label)
    }
}

/// Role: Steeple. Full-page empty or error. Art, headline, line, bottom CTA.
struct AshlarVacancy: View {
    var image: String
    var headline: String
    var line: String
    var actionTitle: String
    var enabled: Bool = true
    var action: () -> Void

    var body: some View {
        VStack(spacing: AshlarFace.space(2)) {
            VStack(spacing: AshlarFace.space(2)) {
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 220, maxHeight: 220)
                    .accessibilityHidden(true)
                Text(headline)
                    .ashlarInk(.title)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                Text(line)
                    .font(AshlarFace.font(.body))
                    .foregroundStyle(AshlarSwatch.ink)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            AshlarChromeButton(
                title: actionTitle,
                fills: true,
                emphasized: true,
                enabled: enabled,
                action: action
            )
        }
        .padding(.horizontal, AshlarFace.space(2))
        .padding(.bottom, AshlarFace.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AshlarSwatch.background)
    }
}

/// Role: Steeple. Pill chip. 14 pt radius only.
struct AshlarChip: View {
    var title: String

    var body: some View {
        Text(title)
            .font(AshlarFace.font(.caption).weight(.semibold))
            .foregroundStyle(AshlarSwatch.ink)
            .padding(.horizontal, AshlarFace.space(2))
            .frame(minHeight: AshlarFace.space(4))
            .background(AshlarSwatch.background)
            .clipShape(AshlarFace.chipShape)
            .overlay {
                AshlarFace.chipShape.stroke(AshlarSwatch.muted.opacity(0.35), lineWidth: 1)
            }
    }
}
