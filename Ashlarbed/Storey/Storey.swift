import Foundation

/// Role: Storey. One climbable floor of 500 kg. Only `bedSession` writes this; `writeSet` never inserts one.
struct Storey: Equatable, Sendable, Identifiable {
    var id: UUID
    var day: SteepleDay
    var ordinal: Int
    var kilograms: Double
    var stamps: [PRStamp]
}
