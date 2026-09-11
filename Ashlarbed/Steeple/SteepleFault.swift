import Foundation

/// Role: Steeple. Typed faults of writeSet and bedSession. Views map these; they never mutate the fold.
enum SteepleFault: Error, Equatable, Sendable {
    case invalidLoad
    case unknownLift
    case alreadyFolded
    case emptyRack
    case invalidAim
}

/// Role: Steeple. Recoverable load outcome. Never crash on a corrupt snapshot.
enum SteepleWarning: Equatable, Sendable {
    case recoveredFromBackup
    case startedEmpty
}
