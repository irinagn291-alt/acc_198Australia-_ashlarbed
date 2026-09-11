import Foundation

/// Role: Scaffold. Family Workout: today's laying. Sets write tonnage here; they never become a Storey.
struct OpenScaffold: Equatable, Sendable {
    var day: SteepleDay
    var sets: [LoggedSet]
    var stubKilograms: Double

    var liveTonnage: Double {
        stubKilograms + sets.reduce(0) { $0 + $1.tonnage }
    }
}

/// Role: Scaffold. Folded day's sets plus the storeys Bed wrote. Remainder under 500 kg left the day as carry.
struct BeddedBand: Equatable, Sendable {
    var day: SteepleDay
    var sets: [LoggedSet]
    var storeys: [Storey]
    var remainderCarried: Double
}

/// Role: Scaffold. ADT Open | Bedded | Rest. The steeple is the fold of this type over Sets.
enum Scaffold: Equatable, Sendable {
    case open(OpenScaffold)
    case bedded(BeddedBand)
    case rest(RestBand)

    var day: SteepleDay {
        switch self {
        case .open(let open): open.day
        case .bedded(let band): band.day
        case .rest(let band): band.day
        }
    }

    var isOpen: Bool {
        if case .open = self { return true }
        return false
    }

    var loggedSets: [LoggedSet] {
        switch self {
        case .open(let open): open.sets
        case .bedded(let band): band.sets
        case .rest: []
        }
    }

    var storeys: [Storey] {
        switch self {
        case .bedded(let band): band.storeys
        case .open, .rest: []
        }
    }
}
