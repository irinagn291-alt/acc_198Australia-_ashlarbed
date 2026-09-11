import Foundation

/// Role: Steeple. A named lift on the rack. Settings edits this list; historical sets keep the id.
struct MasonryLift: Equatable, Sendable, Identifiable {
    var id: UUID
    var name: String

    /// Programmer constants; these strings are valid UUID v4 and cannot fail.
    static let squat = MasonryLift(
        id: UUID(uuidString: "A5B1A5B1-0001-4000-8000-000000000001")!,
        name: "Back squat"
    )
    static let bench = MasonryLift(
        id: UUID(uuidString: "A5B1A5B1-0001-4000-8000-000000000002")!,
        name: "Bench press"
    )
    static let deadlift = MasonryLift(
        id: UUID(uuidString: "A5B1A5B1-0001-4000-8000-000000000003")!,
        name: "Deadlift"
    )
    static let press = MasonryLift(
        id: UUID(uuidString: "A5B1A5B1-0001-4000-8000-000000000004")!,
        name: "Overhead press"
    )

    static let stock: [MasonryLift] = [squat, bench, deadlift, press]
}
