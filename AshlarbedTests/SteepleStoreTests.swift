import XCTest
@testable import Ashlarbed

final class SteepleStoreTests: XCTestCase {
    private var directory = FileManager.default.temporaryDirectory
    private var suiteName = ""
    private var defaults = UserDefaults.standard
    private var calendar = Calendar(identifier: .gregorian)
    private var now = Date(timeIntervalSince1970: 0)
    private var today = SteepleDay(rawValue: 19700101)

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        suiteName = "asb.test.\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        utc.locale = Locale(identifier: "en_US_POSIX")
        calendar = utc
        now = instant(2026, 9, 3)
        today = SteepleDay.from(now, calendar: calendar)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
        if !suiteName.isEmpty {
            defaults.removePersistentDomain(forName: suiteName)
        }
    }

    func test_roundTrip_reloadPreservesOpenSetsAndBeddedStoreys() async throws {
        let store = makeStore()
        _ = await store.load()
        _ = await store.setOnboardingComplete(true)
        try await store.flush()
        var steeple = try await store.writeSet(
            day: today,
            liftID: MasonryLift.squat.id,
            weight: 100,
            reps: 5,
            now: now
        )
        XCTAssertEqual(steeple.openScaffold(on: today)?.sets.count, 1)
        steeple = try await store.bedSession(day: today, now: now, calendar: calendar)
        XCTAssertEqual(steeple.beddedFloorCount, 1)

        let relaunched = makeStore()
        let loaded = await relaunched.load()
        XCTAssertNil(loaded.warning)
        XCTAssertEqual(loaded.steeple.beddedFloorCount, 1)
        XCTAssertEqual(loaded.steeple.remainderKilograms, 0)
        XCTAssertTrue(loaded.steeple.onboardingComplete)
        if case .bedded(let band) = loaded.steeple.scaffold(on: today) {
            XCTAssertEqual(band.sets.first?.weightKilograms, 100)
        } else {
            XCTFail("relaunch must restore the Bedded band")
        }
    }

    func test_corruptSnapshotFallsBackToBackup() async throws {
        let store = makeStore()
        _ = await store.load()
        _ = try await store.writeSet(
            day: today,
            liftID: MasonryLift.bench.id,
            weight: 80,
            reps: 5,
            now: now
        )
        try await store.flush()
        if let good = defaults.data(forKey: SteepleKey.snapshot) {
            defaults.set(good, forKey: SteepleKey.backup)
        }
        let file = directory.appendingPathComponent("steeple.json")
        let backup = directory.appendingPathComponent("steeple.json.backup")
        if FileManager.default.fileExists(atPath: file.path) {
            try? FileManager.default.removeItem(at: backup)
            try FileManager.default.copyItem(at: file, to: backup)
        }
        defaults.set(Data("{not-json".utf8), forKey: SteepleKey.snapshot)
        try Data("{not-json".utf8).write(to: file)

        let loaded = await makeStore().load()
        XCTAssertEqual(loaded.warning, .recoveredFromBackup)
        XCTAssertEqual(loaded.steeple.openScaffold(on: today)?.sets.count, 1)
    }

    func test_corruptSnapshotWithoutBackupStartsEmpty() async throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defaults.set(Data("nope".utf8), forKey: SteepleKey.snapshot)
        try Data("nope".utf8).write(to: directory.appendingPathComponent("steeple.json"))
        let loaded = await makeStore().load()
        XCTAssertEqual(loaded.warning, .startedEmpty)
        XCTAssertEqual(loaded.steeple.beddedFloorCount, 0)
        XCTAssertFalse(loaded.steeple.onboardingComplete)
    }

    func test_roundTrip_remainderCarryBecomesTomorrowStub() async throws {
        let store = makeStore()
        _ = await store.load()
        _ = try await store.writeSet(
            day: today,
            liftID: MasonryLift.squat.id,
            weight: 100,
            reps: 6,
            now: now
        )
        _ = try await store.bedSession(day: today, now: now, calendar: calendar)
        let tomorrow = today.adding(days: 1, calendar: calendar)
        _ = try await store.writeSet(
            day: tomorrow,
            liftID: MasonryLift.bench.id,
            weight: 80,
            reps: 5,
            now: now.addingTimeInterval(86_400)
        )

        let loaded = await makeStore().load()
        XCTAssertNil(loaded.warning)
        XCTAssertEqual(loaded.steeple.beddedFloorCount, 1)
        XCTAssertEqual(loaded.steeple.remainderKilograms, 0)
        let open = try XCTUnwrap(loaded.steeple.openScaffold(on: tomorrow))
        XCTAssertEqual(open.stubKilograms, 100, accuracy: 0.000_000_1)
        XCTAssertEqual(open.liveTonnage, 500, accuracy: 0.000_000_1)
        XCTAssertNotNil(defaults.data(forKey: SteepleKey.snapshot))
    }

    func test_codecSwitchesOnSchemaVersion() throws {
        let steeple = try SteepleSeed.steeple(now: now, calendar: calendar)
        let ledger = SteepleCodec.committed(from: steeple)
        let data = try SteepleCodec.encode(ledger)
        let decoded = try SteepleCodec.decode(data)
        XCTAssertEqual(decoded.schemaVersion, 1)
        XCTAssertEqual(decoded.steeple.beddedFloorCount, steeple.beddedFloorCount)
        XCTAssertEqual(decoded.steeple.openScaffold(on: today)?.sets.count, steeple.openScaffold(on: today)?.sets.count)
        XCTAssertEqual(decoded.steeple.remainderKilograms, steeple.remainderKilograms)
        XCTAssertEqual(
            decoded.steeple.orderedScaffolds.filter { if case .rest = $0 { return true }; return false }.count,
            steeple.orderedScaffolds.filter { if case .rest = $0 { return true }; return false }.count
        )

        let future = Data("{\"schemaVersion\":99}".utf8)
        XCTAssertThrowsError(try SteepleCodec.decode(future)) { error in
            XCTAssertEqual(error as? SteepleCodec.Failure, .unsupportedSchema(99))
        }
        XCTAssertThrowsError(try SteepleCodec.decode(Data("[]".utf8))) { error in
            XCTAssertEqual(error as? SteepleCodec.Failure, .corrupt)
        }
    }

    func test_resetAllDataClearsSnapshotAndFiles() async throws {
        let store = makeStore()
        _ = await store.load()
        _ = try await store.writeSet(
            day: today,
            liftID: MasonryLift.squat.id,
            weight: 100,
            reps: 5,
            now: now
        )
        try await store.resetAllData()
        let loaded = await store.load()
        XCTAssertEqual(loaded.steeple.beddedFloorCount, 0)
        XCTAssertFalse(loaded.steeple.onboardingComplete)
        XCTAssertNil(defaults.data(forKey: SteepleKey.snapshot))
        XCTAssertNil(defaults.data(forKey: SteepleKey.backup))
        let leftovers = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        XCTAssertTrue(leftovers.filter { $0.pathExtension == "json" }.isEmpty)
    }

    func test_onboardingFlagDebouncesUntilFlush() async throws {
        let store = makeStore()
        _ = await store.load()
        _ = await store.setOnboardingComplete(true)
        try await store.flush()
        let loaded = await makeStore().load()
        XCTAssertTrue(loaded.steeple.onboardingComplete)
    }

    #if targetEnvironment(simulator)
    func test_simulatorSeedWritesOnceAndEnablesBed() async throws {
        let store = makeStore()
        let first = try await store.seedDemoIfNeeded(now: now, calendar: calendar)
        let second = try await store.seedDemoIfNeeded(now: now, calendar: calendar)
        XCTAssertNil(second)
        XCTAssertEqual(first?.onboardingComplete, true)
        XCTAssertEqual(first?.canBedSession(on: today), true)
        XCTAssertGreaterThanOrEqual(first?.openScaffold(on: today)?.sets.count ?? 0, 2)
        XCTAssertGreaterThanOrEqual(first?.beddedFloorCount ?? 0, 6)
        XCTAssertTrue(defaults.bool(forKey: SteepleKey.demo))
        XCTAssertNotNil(defaults.data(forKey: SteepleKey.snapshot))
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.appendingPathComponent("steeple.json").path))
    }
    #endif

    private func makeStore() -> SteepleStore {
        SteepleStore(
            directory: directory,
            defaultsSuiteName: suiteName,
            writeDelayNanoseconds: 0
        )
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
