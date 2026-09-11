import Foundation

/// Role: Steeple. The only hex and face-name accessor. Presentation maps these tokens; views never write a raw hex.
enum AshlarWash: Sendable {
    /// SF Pro via `.system` only. Size steps live in presentation.
    static let face = "SF Pro"

    enum Hex: Sendable {
        static let background = "#FAF4F6"
        static let surface = "#FEFDFE"
        static let ink = "#391821"
        static let accent = "#C3224B"
        static let muted = "#8D5E6A"
    }
}
