import Foundation

/// Role: Steeple. The only persistence seam. Views observe the steeple; they never touch UserDefaults or files.
protocol SteepleStoring: Sendable {
    func load() async -> (steeple: Steeple, warning: SteepleWarning?)
    func snapshot() async -> Steeple
    func writeSet(day: SteepleDay, liftID: UUID, weight: Double, reps: Int, now: Date) async throws -> Steeple
    func bedSession(day: SteepleDay, now: Date, calendar: Calendar) async throws -> Steeple
    func setExperience(_ value: Int) async throws -> Steeple
    func setAim(_ value: Int) async throws -> Steeple
    func setLifts(_ lifts: [MasonryLift]) async throws -> Steeple
    func setOnboardingComplete(_ flag: Bool) async -> Steeple
    func flush() async throws
    func resetAllData() async throws
    func seedDemoIfNeeded(now: Date, calendar: Calendar) async throws -> Steeple?
}

/// Role: Steeple. Memory is the source of truth. UserDefaults asb.steeple.v1 plus an Application Support file are projections.
actor SteepleStore: SteepleStoring {
    private let directory: URL
    private let defaultsSuiteName: String?
    private let fileManager: FileManager
    private let writeDelayNanoseconds: UInt64

    private var latest: Steeple = .empty
    private var dirty = false
    private var writeTask: Task<Void, Never>?
    private(set) var warning: SteepleWarning?
    private(set) var lastWriteError: String?

    init(
        directory: URL,
        defaultsSuiteName: String? = nil,
        fileManager: FileManager = .default,
        writeDelayNanoseconds: UInt64 = 300_000_000
    ) {
        self.directory = directory
        self.defaultsSuiteName = defaultsSuiteName
        self.fileManager = fileManager
        self.writeDelayNanoseconds = writeDelayNanoseconds
    }

    static func applicationSupportDirectory(fileManager: FileManager = .default) throws -> URL {
        let root = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return root.appendingPathComponent("Ashlarbed", isDirectory: true)
    }

    func load() async -> (steeple: Steeple, warning: SteepleWarning?) {
        warning = nil
        latest = .empty
        dirty = false
        let defaults = preferenceDefaults()
        if let data = defaults.data(forKey: SteepleKey.snapshot), let steeple = decode(data) {
            latest = steeple
            return (latest, nil)
        }
        if let steeple = decodeFile(fileURL) {
            latest = steeple
            return (latest, nil)
        }
        if let data = defaults.data(forKey: SteepleKey.backup), let steeple = decode(data) {
            latest = steeple
            warning = .recoveredFromBackup
            return (latest, warning)
        }
        if let steeple = decodeFile(backupURL) {
            latest = steeple
            warning = .recoveredFromBackup
            return (latest, warning)
        }
        let hadPayload = defaults.data(forKey: SteepleKey.snapshot) != nil
            || fileManager.fileExists(atPath: fileURL.path)
        if hadPayload {
            warning = .startedEmpty
        }
        return (latest, warning)
    }

    func snapshot() async -> Steeple {
        latest
    }

    func writeSet(
        day: SteepleDay,
        liftID: UUID,
        weight: Double,
        reps: Int,
        now: Date = Date()
    ) async throws -> Steeple {
        try Task.checkCancellation()
        latest = try latest.writeSet(day: day, liftID: liftID, weight: weight, reps: reps, loggedAt: now)
        try persistCommitted()
        return latest
    }

    func bedSession(
        day: SteepleDay,
        now: Date = Date(),
        calendar: Calendar = .current
    ) async throws -> Steeple {
        try Task.checkCancellation()
        _ = now
        latest = try latest.bedSession(day: day, calendar: calendar)
        try persistCommitted()
        return latest
    }

    func setExperience(_ value: Int) async throws -> Steeple {
        latest = try latest.settingExperience(value)
        dirty = true
        scheduleFlush()
        return latest
    }

    func setAim(_ value: Int) async throws -> Steeple {
        latest = try latest.settingAim(value)
        dirty = true
        scheduleFlush()
        return latest
    }

    func setLifts(_ lifts: [MasonryLift]) async throws -> Steeple {
        latest = try latest.settingLifts(lifts)
        dirty = true
        scheduleFlush()
        return latest
    }

    func setOnboardingComplete(_ flag: Bool) async -> Steeple {
        if flag {
            latest = latest.completingOnboarding()
        } else {
            latest.onboardingComplete = false
        }
        dirty = true
        scheduleFlush()
        return latest
    }

    func flush() async throws {
        writeTask?.cancel()
        writeTask = nil
        if dirty {
            try persistCommitted()
        }
    }

    func resetAllData() async throws {
        writeTask?.cancel()
        writeTask = nil
        latest = .empty
        dirty = false
        warning = nil
        lastWriteError = nil
        let defaults = preferenceDefaults()
        defaults.removeObject(forKey: SteepleKey.snapshot)
        defaults.removeObject(forKey: SteepleKey.backup)
        if fileManager.fileExists(atPath: directory.path) {
            try fileManager.removeItem(at: directory)
        }
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func seedDemoIfNeeded(now: Date = Date(), calendar: Calendar = .current) async throws -> Steeple? {
        #if targetEnvironment(simulator)
        let defaults = preferenceDefaults()
        guard defaults.object(forKey: SteepleKey.demo) == nil else { return nil }
        latest = try SteepleSeed.steeple(now: now, calendar: calendar)
        try persistCommitted()
        defaults.set(true, forKey: SteepleKey.demo)
        return latest
        #else
        _ = now
        _ = calendar
        return nil
        #endif
    }

    /// File IO stays on this actor, which is not MainActor — the main thread never waits on disk.
    private func persistCommitted() throws {
        let ledger = SteepleCodec.committed(from: latest)
        let data = try SteepleCodec.encode(ledger)
        let defaults = preferenceDefaults()
        if let previous = defaults.data(forKey: SteepleKey.snapshot) {
            defaults.set(previous, forKey: SteepleKey.backup)
        }
        defaults.set(data, forKey: SteepleKey.snapshot)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        if fileManager.fileExists(atPath: fileURL.path) {
            if fileManager.fileExists(atPath: backupURL.path) {
                try? fileManager.removeItem(at: backupURL)
            }
            try? fileManager.copyItem(at: fileURL, to: backupURL)
        }
        try data.write(to: fileURL, options: .atomic)
        dirty = false
        lastWriteError = nil
    }

    private func scheduleFlush() {
        writeTask?.cancel()
        let delay = writeDelayNanoseconds
        writeTask = Task { [weak self] in
            if delay > 0 {
                try? await Task.sleep(nanoseconds: delay)
            }
            guard !Task.isCancelled else { return }
            await self?.flushIfNeeded()
        }
    }

    private func flushIfNeeded() async {
        writeTask = nil
        do {
            if dirty {
                try persistCommitted()
            }
        } catch {
            lastWriteError = String(describing: error)
        }
    }

    private func decode(_ data: Data) -> Steeple? {
        guard let ledger = try? SteepleCodec.decode(data) else { return nil }
        return ledger.steeple
    }

    private func decodeFile(_ url: URL) -> Steeple? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return decode(data)
    }

    private var fileURL: URL {
        directory.appendingPathComponent("steeple.json")
    }

    private var backupURL: URL {
        directory.appendingPathComponent("steeple.json.backup")
    }

    private func preferenceDefaults() -> UserDefaults {
        if let defaultsSuiteName {
            return UserDefaults(suiteName: defaultsSuiteName) ?? .standard
        }
        return .standard
    }
}
