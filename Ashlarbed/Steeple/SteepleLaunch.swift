import Foundation

/// Role: Steeple. Tab chrome. Tower holds the steeple and fused set log; Analytics and Settings are siblings. No Game tab.
enum SteepleTab: String, Hashable, Sendable, CaseIterable {
    case tower
    case analytics
    case settings
}

/// Role: Steeple. Launch keys for live shots. today, log, and goals open three different screens.
enum ReviewPane: String, Equatable, Sendable {
    case today
    case log
    case goals

    var tab: SteepleTab {
        switch self {
        case .today: .tower
        case .log: .analytics
        case .goals: .settings
        }
    }
}

/// Role: Steeple. Reads `-ReviewScreen today|log|goals` once, only after onboarding. Never hosts a View.
enum SteepleLaunch {
    static func consume(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        onboardingComplete: Bool,
        consumed: inout Bool
    ) -> ReviewPane? {
        guard onboardingComplete, !consumed else { return nil }
        consumed = true
        guard let index = arguments.firstIndex(of: "-ReviewScreen") else { return nil }
        let next = arguments.index(after: index)
        guard arguments.indices.contains(next) else { return nil }
        return ReviewPane(rawValue: arguments[next])
    }
}
