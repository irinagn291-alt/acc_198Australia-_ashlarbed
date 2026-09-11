import Foundation

/// Role: Set. Family Workout-set. Tonnage is weight × reps and is never stored.
struct LoggedSet: Equatable, Sendable, Identifiable {
    var id: UUID
    var liftID: UUID
    var weightKilograms: Double
    var reps: Int
    var loggedUnix: Double

    var tonnage: Double {
        StoreyFold.tonnage(weight: weightKilograms, reps: reps)
    }

    var epley1RM: Double {
        StoreyFold.epley1RM(weight: weightKilograms, reps: reps)
    }
}
