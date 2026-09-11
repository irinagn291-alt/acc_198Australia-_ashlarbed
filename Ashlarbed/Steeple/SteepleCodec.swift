import Foundation

/// Role: Steeple. Preference keys. Snapshot is JSON Data under asb.steeple.v1. Demo is Simulator-only.
enum SteepleKey {
    static let snapshot = "asb.steeple.v1"
    static let backup = "asb.steeple.v1.backup"
    static let demo = "asb.demo.v1"
}

/// Role: Steeple. Codable root document. schemaVersion from 1. Domain types never encode themselves.
struct SteepleLedger: Equatable, Sendable {
    var schemaVersion: Int
    var steeple: Steeple
}

/// Role: Steeple. schemaVersion switch and steeple ↔ JSON mapping. UserDefaults never sees Scaffold raw.
enum SteepleCodec {
    static let currentSchema = 1

    enum Failure: Error, Equatable {
        case unsupportedSchema(Int)
        case corrupt
    }

    static func encode(_ ledger: SteepleLedger) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(RootDocument.from(ledger))
    }

    static func decode(_ data: Data) throws -> SteepleLedger {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        let probe: SchemaProbe
        do {
            probe = try decoder.decode(SchemaProbe.self, from: data)
        } catch {
            throw Failure.corrupt
        }
        switch probe.schemaVersion {
        case 1:
            do {
                return try decoder.decode(RootDocument.self, from: data).asLedger()
            } catch let failure as Failure {
                throw failure
            } catch {
                throw Failure.corrupt
            }
        default:
            throw Failure.unsupportedSchema(probe.schemaVersion)
        }
    }

    static func committed(from steeple: Steeple) -> SteepleLedger {
        SteepleLedger(schemaVersion: currentSchema, steeple: steeple)
    }
}

private struct SchemaProbe: Decodable {
    var schemaVersion: Int
}

private struct RootDocument: Codable {
    var schemaVersion: Int
    var onboardingComplete: Bool
    var experience: Int
    var aim: Int
    var remainderKilograms: Double
    var lifts: [LiftDocument]
    var days: [DayDocument]

    static func from(_ ledger: SteepleLedger) -> RootDocument {
        RootDocument(
            schemaVersion: SteepleCodec.currentSchema,
            onboardingComplete: ledger.steeple.onboardingComplete,
            experience: ledger.steeple.experience,
            aim: ledger.steeple.aim,
            remainderKilograms: ledger.steeple.remainderKilograms,
            lifts: ledger.steeple.lifts.map(LiftDocument.init(lift:)),
            days: ledger.steeple.orderedScaffolds.map(DayDocument.init(scaffold:))
        )
    }

    func asLedger() throws -> SteepleLedger {
        var scaffolds: [SteepleDay: Scaffold] = [:]
        for day in days {
            let scaffold = try day.asScaffold()
            scaffolds[scaffold.day] = scaffold
        }
        return SteepleLedger(
            schemaVersion: schemaVersion,
            steeple: Steeple(
                onboardingComplete: onboardingComplete,
                lifts: try lifts.map { try $0.asLift() },
                experience: experience,
                aim: aim,
                remainderKilograms: remainderKilograms,
                scaffolds: scaffolds
            )
        )
    }
}

private struct LiftDocument: Codable {
    var id: UUID
    var name: String

    init(lift: MasonryLift) {
        id = lift.id
        name = lift.name
    }

    func asLift() throws -> MasonryLift {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw SteepleCodec.Failure.corrupt }
        return MasonryLift(id: id, name: trimmed)
    }
}

private struct DayDocument: Codable {
    var day: Int
    var kind: String
    var stubKilograms: Double?
    var remainderCarried: Double?
    var sets: [SetDocument]?
    var storeys: [StoreyDocument]?

    init(scaffold: Scaffold) {
        day = scaffold.day.rawValue
        switch scaffold {
        case .open(let open):
            kind = "open"
            stubKilograms = open.stubKilograms
            sets = open.sets.map(SetDocument.init(set:))
            remainderCarried = nil
            storeys = nil
        case .bedded(let band):
            kind = "bedded"
            remainderCarried = band.remainderCarried
            sets = band.sets.map(SetDocument.init(set:))
            storeys = band.storeys.map(StoreyDocument.init(storey:))
            stubKilograms = nil
        case .rest:
            kind = "rest"
            stubKilograms = nil
            remainderCarried = nil
            sets = nil
            storeys = nil
        }
    }

    func asScaffold() throws -> Scaffold {
        let steepleDay = SteepleDay(rawValue: day)
        switch kind {
        case "open":
            return .open(
                OpenScaffold(
                    day: steepleDay,
                    sets: try (sets ?? []).map { try $0.asSet() },
                    stubKilograms: stubKilograms ?? 0
                )
            )
        case "bedded":
            return .bedded(
                BeddedBand(
                    day: steepleDay,
                    sets: try (sets ?? []).map { try $0.asSet() },
                    storeys: try (storeys ?? []).map { try $0.asStorey(day: steepleDay) },
                    remainderCarried: remainderCarried ?? 0
                )
            )
        case "rest":
            return .rest(RestBand(day: steepleDay))
        default:
            throw SteepleCodec.Failure.corrupt
        }
    }
}

private struct SetDocument: Codable {
    var id: UUID
    var liftID: UUID
    var weightKilograms: Double
    var reps: Int
    var loggedUnix: Double

    init(set: LoggedSet) {
        id = set.id
        liftID = set.liftID
        weightKilograms = set.weightKilograms
        reps = set.reps
        loggedUnix = set.loggedUnix
    }

    func asSet() throws -> LoggedSet {
        guard weightKilograms.isFinite, weightKilograms > 0, reps > 0 else {
            throw SteepleCodec.Failure.corrupt
        }
        return LoggedSet(
            id: id,
            liftID: liftID,
            weightKilograms: weightKilograms,
            reps: reps,
            loggedUnix: loggedUnix
        )
    }
}

private struct StoreyDocument: Codable {
    var id: UUID
    var ordinal: Int
    var kilograms: Double
    var stamps: [StampDocument]

    init(storey: Storey) {
        id = storey.id
        ordinal = storey.ordinal
        kilograms = storey.kilograms
        stamps = storey.stamps.map(StampDocument.init(stamp:))
    }

    func asStorey(day: SteepleDay) throws -> Storey {
        guard kilograms.isFinite, kilograms > 0, ordinal > 0 else {
            throw SteepleCodec.Failure.corrupt
        }
        return Storey(
            id: id,
            day: day,
            ordinal: ordinal,
            kilograms: kilograms,
            stamps: try stamps.map { try $0.asStamp() }
        )
    }
}

private struct StampDocument: Codable {
    var id: UUID
    var liftID: UUID
    var kind: String
    var value: Double
    var setID: UUID

    init(stamp: PRStamp) {
        id = stamp.id
        liftID = stamp.liftID
        kind = stamp.kind.rawValue
        value = stamp.value
        setID = stamp.setID
    }

    func asStamp() throws -> PRStamp {
        guard let kind = StampKind(rawValue: kind), value.isFinite, value > 0 else {
            throw SteepleCodec.Failure.corrupt
        }
        return PRStamp(id: id, liftID: liftID, kind: kind, value: value, setID: setID)
    }
}
