import Foundation

/// Role: Steeple. The fold of Scaffold over Sets. writeSet never inserts a Storey; bedSession is the only write that does.
struct Steeple: Equatable, Sendable {
    var onboardingComplete: Bool
    var lifts: [MasonryLift]
    var experience: Int
    var aim: Int
    var remainderKilograms: Double
    var scaffolds: [SteepleDay: Scaffold]

    static let empty = Steeple(
        onboardingComplete: false,
        lifts: MasonryLift.stock,
        experience: 2,
        aim: 2,
        remainderKilograms: 0,
        scaffolds: [:]
    )

    var dailyFloorGoal: Int {
        StoreyFold.dailyFloorGoal(experience: experience, aim: aim)
    }

    var allBeddedSets: [LoggedSet] {
        orderedScaffolds.compactMap { scaffold -> [LoggedSet]? in
            if case .bedded(let band) = scaffold { return band.sets }
            return nil
        }.flatMap { $0 }
    }

    var beddedStoreys: [Storey] {
        orderedScaffolds.flatMap(\.storeys)
    }

    var beddedFloorCount: Int { beddedStoreys.count }

    var beddedVolume: Double {
        allBeddedSets.reduce(0) { $0 + $1.tonnage }
    }

    var earnedStamps: [PRStamp] {
        beddedStoreys.flatMap(\.stamps)
    }

    var orderedScaffolds: [Scaffold] {
        scaffolds.values.sorted { $0.day < $1.day }
    }

    func scaffold(on day: SteepleDay) -> Scaffold? {
        scaffolds[day]
    }

    func openScaffold(on day: SteepleDay) -> OpenScaffold? {
        if case .open(let open) = scaffolds[day] { return open }
        return nil
    }

    func canWriteSet(on day: SteepleDay) -> Bool {
        switch scaffolds[day] {
        case .none, .open: true
        case .bedded, .rest: false
        }
    }

    func canBedSession(on day: SteepleDay) -> Bool {
        switch scaffolds[day] {
        case .none, .open: true
        case .bedded, .rest: false
        }
    }

    func completingOnboarding() -> Steeple {
        var next = self
        next.onboardingComplete = true
        if next.lifts.isEmpty {
            next.lifts = MasonryLift.stock
        }
        if !StoreyFold.experienceSpan.contains(next.experience) {
            next.experience = 2
        }
        if !StoreyFold.aimSpan.contains(next.aim) {
            next.aim = 2
        }
        return next
    }

    func settingExperience(_ value: Int) throws -> Steeple {
        guard StoreyFold.experienceSpan.contains(value) else { throw SteepleFault.invalidAim }
        var next = self
        next.experience = value
        return next
    }

    func settingAim(_ value: Int) throws -> Steeple {
        guard StoreyFold.aimSpan.contains(value) else { throw SteepleFault.invalidAim }
        var next = self
        next.aim = value
        return next
    }

    func settingLifts(_ lifts: [MasonryLift]) throws -> Steeple {
        let trimmed = lifts.map {
            MasonryLift(id: $0.id, name: $0.name.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        guard !trimmed.isEmpty else { throw SteepleFault.emptyRack }
        guard trimmed.allSatisfy({ !$0.name.isEmpty }) else { throw SteepleFault.emptyRack }
        var next = self
        next.lifts = trimmed
        return next
    }

    /// Appends a set to today's Open scaffold and adds tonnage. Never inserts a Storey.
    func writeSet(
        day: SteepleDay,
        liftID: UUID,
        weight: Double,
        reps: Int,
        id: UUID = UUID(),
        loggedAt: Date = Date()
    ) throws -> Steeple {
        guard weight.isFinite, weight > 0, reps > 0 else { throw SteepleFault.invalidLoad }
        guard lifts.contains(where: { $0.id == liftID }) else { throw SteepleFault.unknownLift }
        var next = self
        let logged = LoggedSet(
            id: id,
            liftID: liftID,
            weightKilograms: weight,
            reps: reps,
            loggedUnix: loggedAt.timeIntervalSince1970
        )
        switch next.scaffolds[day] {
        case .none:
            let stub = next.remainderKilograms
            next.remainderKilograms = 0
            next.scaffolds[day] = .open(OpenScaffold(day: day, sets: [logged], stubKilograms: stub))
        case .open(var open):
            open.sets.append(logged)
            next.scaffolds[day] = .open(open)
        case .bedded, .rest:
            throw SteepleFault.alreadyFolded
        }
        return next
    }

    /// The only fold that writes Storeys: 500 kg floors, remainder carry, earned PR stamps, or a RestBand.
    func bedSession(
        day: SteepleDay,
        calendar: Calendar,
        storeyIDs: [UUID] = [],
        stampIDs: [UUID] = []
    ) throws -> Steeple {
        _ = calendar
        var next = self
        let open: OpenScaffold
        switch next.scaffolds[day] {
        case .none:
            open = OpenScaffold(day: day, sets: [], stubKilograms: next.remainderKilograms)
            next.remainderKilograms = 0
        case .open(let existing):
            open = existing
        case .bedded, .rest:
            throw SteepleFault.alreadyFolded
        }

        if open.sets.isEmpty {
            next.scaffolds[day] = .rest(RestBand(day: day))
            next.remainderKilograms += open.stubKilograms
            return next
        }

        let split = StoreyFold.floorsAndRemainder(tonnage: open.liveTonnage)
        let stamps = StoreyFold.earnedStamps(
            session: open.sets,
            prior: next.allBeddedSets,
            ids: stampIDs
        )
        let base = next.beddedFloorCount
        var storeys: [Storey] = []
        storeys.reserveCapacity(split.floors)
        for index in 0 ..< split.floors {
            let id = storeyIDs.indices.contains(index) ? storeyIDs[index] : UUID()
            var storey = Storey(
                id: id,
                day: day,
                ordinal: base + index + 1,
                kilograms: StoreyFold.kilogramsPerStorey,
                stamps: []
            )
            if index == split.floors - 1 {
                storey.stamps = stamps
            }
            storeys.append(storey)
        }
        next.scaffolds[day] = .bedded(
            BeddedBand(
                day: day,
                sets: open.sets,
                storeys: storeys,
                remainderCarried: split.remainder
            )
        )
        next.remainderKilograms = split.remainder
        return next
    }
}
