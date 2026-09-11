import XCTest
@testable import Ashlarbed

final class ScaffoldFoldTests: XCTestCase {
    private var calendar = Calendar(identifier: .gregorian)
    private var now = Date(timeIntervalSince1970: 0)
    private var today = SteepleDay(rawValue: 19700101)

    override func setUp() {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        utc.locale = Locale(identifier: "en_US_POSIX")
        calendar = utc
        now = instant(2026, 9, 3)
        today = SteepleDay.from(now, calendar: calendar)
    }

    func test_architecture_writeSetNeverInsertsStorey_bedSessionIsTheOnlyFold() throws {
        var steeple = Steeple.empty
        XCTAssertEqual(steeple.beddedFloorCount, 0)
        steeple = try steeple.writeSet(
            day: today,
            liftID: MasonryLift.squat.id,
            weight: 100,
            reps: 5,
            loggedAt: now
        )
        steeple = try steeple.writeSet(
            day: today,
            liftID: MasonryLift.bench.id,
            weight: 80,
            reps: 5,
            loggedAt: now
        )
        XCTAssertEqual(steeple.beddedFloorCount, 0)
        XCTAssertEqual(steeple.openScaffold(on: today)?.sets.count, 2)
        if case .open = steeple.scaffold(on: today) {
            // Open after writeSet — no Storey yet.
        } else {
            XCTFail("writeSet must leave today Open")
        }

        steeple = try steeple.bedSession(day: today, calendar: calendar)
        if case .bedded(let band) = steeple.scaffold(on: today) {
            XCTAssertEqual(band.storeys.count, 1)
            XCTAssertEqual(band.storeys.first?.kilograms, 500)
            XCTAssertEqual(band.remainderCarried, 400, accuracy: 0.000_000_1)
        } else {
            XCTFail("bedSession with sets must write a Bedded band")
        }
        XCTAssertEqual(steeple.beddedFloorCount, 1)
        XCTAssertEqual(steeple.remainderKilograms, 400, accuracy: 0.000_000_1)
    }

    func test_primaryVerb_emptyWritesRestBand_populatedWritesStoreys_invalidAlreadyFolded() throws {
        XCTAssertTrue(Steeple.empty.canBedSession(on: today))
        let rested = try Steeple.empty.bedSession(day: today, calendar: calendar)
        if case .rest(let band) = rested.scaffold(on: today) {
            XCTAssertEqual(band.day, today)
        } else {
            XCTFail("bedding Open with no sets must write a RestBand")
        }
        XCTAssertEqual(rested.beddedFloorCount, 0)
        XCTAssertThrowsError(try rested.bedSession(day: today, calendar: calendar)) { error in
            XCTAssertEqual(error as? SteepleFault, .alreadyFolded)
        }
        XCTAssertThrowsError(
            try rested.writeSet(day: today, liftID: MasonryLift.squat.id, weight: 100, reps: 5, loggedAt: now)
        ) { error in
            XCTAssertEqual(error as? SteepleFault, .alreadyFolded)
        }

        var populated = Steeple.empty
        populated = try populated.writeSet(
            day: today,
            liftID: MasonryLift.squat.id,
            weight: 100,
            reps: 6,
            loggedAt: now
        )
        XCTAssertTrue(populated.canBedSession(on: today))
        populated = try populated.bedSession(day: today, calendar: calendar)
        XCTAssertEqual(populated.beddedFloorCount, 1)
        XCTAssertEqual(populated.remainderKilograms, 100, accuracy: 0.000_000_1)
        XCTAssertThrowsError(try populated.bedSession(day: today, calendar: calendar)) { error in
            XCTAssertEqual(error as? SteepleFault, .alreadyFolded)
        }

        XCTAssertThrowsError(
            try Steeple.empty.writeSet(day: today, liftID: MasonryLift.squat.id, weight: -1, reps: 5, loggedAt: now)
        ) { error in
            XCTAssertEqual(error as? SteepleFault, .invalidLoad)
        }
        XCTAssertThrowsError(
            try Steeple.empty.writeSet(day: today, liftID: MasonryLift.squat.id, weight: 100, reps: 0, loggedAt: now)
        ) { error in
            XCTAssertEqual(error as? SteepleFault, .invalidLoad)
        }
        XCTAssertThrowsError(
            try Steeple.empty.writeSet(day: today, liftID: UUID(), weight: 100, reps: 5, loggedAt: now)
        ) { error in
            XCTAssertEqual(error as? SteepleFault, .unknownLift)
        }
    }

    func test_twist_remainderCarry_epley_prOnlyWhenBeaten_dailyFloorGoal() throws {
        var steeple = Steeple.empty
        steeple = try steeple.settingExperience(3)
        steeple = try steeple.settingAim(4)
        XCTAssertEqual(steeple.dailyFloorGoal, 12)

        let day1 = today
        steeple = try steeple.writeSet(
            day: day1,
            liftID: MasonryLift.squat.id,
            weight: 100,
            reps: 7,
            id: UUID(uuidString: "11111111-0001-4000-8000-000000000001")!,
            loggedAt: now
        )
        steeple = try steeple.bedSession(day: day1, calendar: calendar)
        XCTAssertEqual(steeple.beddedFloorCount, 1)
        XCTAssertEqual(steeple.remainderKilograms, 200, accuracy: 0.000_000_1)
        let firstStamps = steeple.earnedStamps
        XCTAssertTrue(firstStamps.contains { $0.kind == .rawWeight && $0.value == 100 })
        XCTAssertTrue(firstStamps.contains { $0.kind == .epley })
        let firstEpley = StoreyFold.epley1RM(weight: 100, reps: 7)
        XCTAssertEqual(
            firstStamps.first { $0.kind == .epley }?.value ?? 0,
            firstEpley,
            accuracy: 0.000_000_1
        )

        let day2 = today.adding(days: 1, calendar: calendar)
        steeple = try steeple.writeSet(
            day: day2,
            liftID: MasonryLift.squat.id,
            weight: 100,
            reps: 2,
            loggedAt: now.addingTimeInterval(86_400)
        )
        let day2Open = try XCTUnwrap(steeple.openScaffold(on: day2))
        XCTAssertEqual(day2Open.stubKilograms, 200, accuracy: 0.000_000_1)
        XCTAssertEqual(day2Open.liveTonnage, 400, accuracy: 0.000_000_1)
        steeple = try steeple.bedSession(day: day2, calendar: calendar)
        XCTAssertEqual(steeple.beddedFloorCount, 1)
        XCTAssertEqual(steeple.remainderKilograms, 400, accuracy: 0.000_000_1)
        if case .bedded(let band) = steeple.scaffold(on: day2) {
            XCTAssertTrue(band.storeys.isEmpty)
            XCTAssertTrue(band.storeys.flatMap(\.stamps).isEmpty)
        } else {
            XCTFail("400 kg must bed with zero storeys")
        }
        XCTAssertEqual(steeple.earnedStamps.count, firstStamps.count)

        let day3 = today.adding(days: 2, calendar: calendar)
        steeple = try steeple.writeSet(
            day: day3,
            liftID: MasonryLift.squat.id,
            weight: 100,
            reps: 1,
            loggedAt: now.addingTimeInterval(172_800)
        )
        XCTAssertEqual(try XCTUnwrap(steeple.openScaffold(on: day3)).liveTonnage, 500, accuracy: 0.000_000_1)
        steeple = try steeple.bedSession(day: day3, calendar: calendar)
        XCTAssertEqual(steeple.beddedFloorCount, 2)
        XCTAssertEqual(steeple.remainderKilograms, 0)
        let newStamps = steeple.scaffold(on: day3)?.storeys.flatMap(\.stamps) ?? []
        XCTAssertTrue(newStamps.isEmpty, "equal weight and a weaker Epley must not stamp")

        let day4 = today.adding(days: 3, calendar: calendar)
        steeple = try steeple.writeSet(
            day: day4,
            liftID: MasonryLift.squat.id,
            weight: 120,
            reps: 5,
            loggedAt: now.addingTimeInterval(259_200)
        )
        steeple = try steeple.bedSession(day: day4, calendar: calendar)
        let day4Stamps = steeple.scaffold(on: day4)?.storeys.flatMap(\.stamps) ?? []
        XCTAssertTrue(day4Stamps.contains { $0.kind == .rawWeight && $0.value == 120 })
        XCTAssertTrue(day4Stamps.contains { $0.kind == .epley })
        XCTAssertFalse(
            day4Stamps.contains { $0.kind == .rawWeight && $0.value == 100 },
            "a beaten number is not restamped"
        )
    }

    func test_seedLeavesBedEnabledAndFillsStoreys() throws {
        let steeple = try SteepleSeed.steeple(now: now, calendar: calendar)
        XCTAssertTrue(steeple.onboardingComplete)
        XCTAssertTrue(steeple.canBedSession(on: today))
        XCTAssertGreaterThanOrEqual(steeple.openScaffold(on: today)?.sets.count ?? 0, 2)
        XCTAssertGreaterThanOrEqual(steeple.beddedFloorCount, 6)
        XCTAssertTrue(steeple.orderedScaffolds.contains { if case .rest = $0 { return true }; return false })
        XCTAssertFalse(steeple.earnedStamps.isEmpty)
        XCTAssertEqual(steeple.dailyFloorGoal, 6)
        XCTAssertGreaterThan(steeple.beddedVolume, 3_000)
    }

    func test_riseCourses_writeSetIsScaffoldOnly_bedAddsStoreys_idsAreStable() throws {
        XCTAssertFalse(SteepleRise.courses(steeple: .empty, today: today).isEmpty)
        let empty = SteepleRise.courses(steeple: .empty, today: today)
        XCTAssertEqual(empty.count, 1)
        if case .scaffold(let tonnage, let day) = empty[0].kind {
            XCTAssertEqual(tonnage, 0)
            XCTAssertEqual(day, today)
        } else {
            XCTFail("empty today must still show an open scaffold course")
        }
        XCTAssertEqual(
            SteepleRise.courses(steeple: .empty, today: today).map(\.id),
            empty.map(\.id)
        )

        var steeple = Steeple.empty
        steeple = try steeple.writeSet(
            day: today,
            liftID: MasonryLift.squat.id,
            weight: 100,
            reps: 5,
            loggedAt: now
        )
        let open = SteepleRise.courses(steeple: steeple, today: today)
        XCTAssertEqual(open.count, 1)
        if case .scaffold(let tonnage, _) = open[0].kind {
            XCTAssertEqual(tonnage, 500, accuracy: 0.000_000_1)
        } else {
            XCTFail("writeSet must expose a scaffold course, not a storey")
        }

        steeple = try steeple.bedSession(day: today, calendar: calendar)
        let bedded = SteepleRise.courses(steeple: steeple, today: today)
        XCTAssertTrue(bedded.contains { if case .storey = $0.kind { return true }; return false })
        XCTAssertFalse(bedded.contains { if case .scaffold = $0.kind { return true }; return false })
        XCTAssertEqual(bedded.map(\.id), SteepleRise.courses(steeple: steeple, today: today).map(\.id))

        let rested = try Steeple.empty.bedSession(day: today, calendar: calendar)
        let restRows = SteepleRise.courses(steeple: rested, today: today)
        XCTAssertEqual(restRows.count, 1)
        if case .rest(let day) = restRows[0].kind {
            XCTAssertEqual(day, today)
        } else {
            XCTFail("a rest day must be a rest course")
        }
        XCTAssertGreaterThanOrEqual(SteepleRise.height(for: empty[0]), AshlarFace.tap)
        XCTAssertGreaterThanOrEqual(SteepleRise.height(for: bedded[0]), AshlarFace.tap)
    }

    private func instant(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var parts = DateComponents()
        parts.year = year
        parts.month = month
        parts.day = day
        parts.hour = 12
        return calendar.date(from: parts) ?? Date(timeIntervalSince1970: 0)
    }
}
