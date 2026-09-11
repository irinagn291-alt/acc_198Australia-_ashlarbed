import Foundation

/// Role: Storey. Family PR. Earned only when bed writes a storey and the number is strictly beaten.
enum StampKind: String, Equatable, Sendable {
    case epley
    case rawWeight
}

/// Role: Storey. A stamp on a climbable storey. Decorative fanfare without a beaten number is not this type.
struct PRStamp: Equatable, Sendable, Identifiable {
    var id: UUID
    var liftID: UUID
    var kind: StampKind
    var value: Double
    var setID: UUID
}
