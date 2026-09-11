import Foundation
import Observation

/// Role: Steeple. Presentation fold over SteepleStoring. Views observe this; they never touch UserDefaults.
@MainActor
@Observable
final class SteepleWatch {
    private(set) var steeple: Steeple
    private(set) var warning: SteepleWarning?
    private(set) var fault: String?
    private(set) var isHauling = false
    private(set) var isCommitting = false
    private(set) var commitTick = 0
    private(set) var bedTick = 0
    private(set) var dayAnchor: Date

    var tab: SteepleTab = .tower

    let store: any SteepleStoring
    private let calendar: Calendar
    private let now: @Sendable () -> Date
    private let shouldLoad: Bool
    private var appeared = false
    private var reviewConsumed = false
    private var reviewPane: ReviewPane?
    private var haulToken: UUID?

    init(
        store: any SteepleStoring,
        calendar: Calendar = .current,
        now: @escaping @Sendable () -> Date = { Date() },
        steeple: Steeple = .empty,
        warning: SteepleWarning? = nil,
        shouldLoad: Bool = true
    ) {
        self.store = store
        self.calendar = calendar
        self.now = now
        self.steeple = steeple
        self.warning = warning
        self.shouldLoad = shouldLoad
        self.dayAnchor = calendar.startOfDay(for: now())
    }

    var today: SteepleDay {
        SteepleDay.from(dayAnchor, calendar: calendar)
    }

    var onboardingComplete: Bool {
        steeple.onboardingComplete
    }

    var loadFailed: Bool {
        warning == .startedEmpty
    }

    var isFreshTower: Bool {
        steeple.beddedFloorCount == 0
            && steeple.orderedScaffolds.isEmpty
            && (steeple.openScaffold(on: today)?.sets.isEmpty ?? true)
            && steeple.remainderKilograms == 0
    }

    var openToday: OpenScaffold? {
        steeple.openScaffold(on: today)
    }

    var canWriteSet: Bool {
        steeple.canWriteSet(on: today)
    }

    var canBedSession: Bool {
        steeple.canBedSession(on: today)
    }

    var liveTonnage: Double {
        if let open = openToday {
            return open.liveTonnage
        }
        return steeple.remainderKilograms
    }

    var waitingFold: (floors: Int, remainder: Double) {
        StoreyFold.floorsAndRemainder(tonnage: liveTonnage)
    }

    var hasOpenSets: Bool {
        !(openToday?.sets.isEmpty ?? true)
    }

    var jobTitle: String {
        if !canBedSession {
            return "Today is bedded"
        }
        if hasOpenSets {
            return "Bed the session"
        }
        return "Log a set, then bed"
    }

    var jobLine: String {
        if !canBedSession {
            return "Floors stay in the steeple. Tomorrow the remainder becomes the next scaffold."
        }
        if hasOpenSets {
            let floors = AshlarFigure.count(waitingFold.floors)
            if waitingFold.floors == 0 {
                return "Scaffold is up. Bed carries the remainder — a floor needs 500 kg."
            }
            return "Scaffold is up. Tap Bed the session to write \(floors) floors."
        }
        return "Write weight and reps onto today’s scaffold, then bed."
    }

    var bedDetail: String {
        if !canBedSession {
            return "Today already folded."
        }
        if !hasOpenSets {
            return "No sets today. Bed writes a rest band, not a floor."
        }
        if waitingFold.floors == 0 {
            return "Under 500 kg — remainder waits for tomorrow."
        }
        let floors = AshlarFigure.count(waitingFold.floors)
        let carry = AshlarFigure.kilogramsWithUnit(waitingFold.remainder)
        return "Write \(floors) floors. Carry \(carry)."
    }

    func liftName(_ id: UUID) -> String {
        steeple.lifts.first { $0.id == id }?.name ?? "—"
    }

    func bestEpley(liftID: UUID) -> Double? {
        steeple.allBeddedSets.filter { $0.liftID == liftID }.map(\.epley1RM).max()
    }

    func bestWeight(liftID: UUID) -> Double? {
        steeple.allBeddedSets.filter { $0.liftID == liftID }.map(\.weightKilograms).max()
    }

    func volume(liftID: UUID) -> Double {
        steeple.allBeddedSets.filter { $0.liftID == liftID }.reduce(0) { $0 + $1.tonnage }
    }

    func appear() async {
        guard shouldLoad else {
            applyReview()
            return
        }
        if appeared {
            applyReview()
            return
        }
        appeared = true
        let token = UUID()
        haulToken = token
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 150_000_000)
            guard let self, self.haulToken == token else { return }
            self.isHauling = true
        }
        let loaded = await store.load()
        steeple = loaded.steeple
        warning = loaded.warning
        do {
            if let seeded = try await store.seedDemoIfNeeded(now: now(), calendar: calendar) {
                steeple = seeded
                warning = nil
            }
        } catch {
            fault = "The steeple could not be opened."
        }
        applyWarning()
        applyReview()
        haulToken = nil
        isHauling = false
    }

    func retry() async {
        fault = nil
        appeared = false
        await appear()
    }

    func flush() async {
        do {
            try await store.flush()
        } catch {
            fault = "The steeple could not be written."
        }
    }

    func markDay() {
        dayAnchor = calendar.startOfDay(for: now())
    }

    func writeSet(liftID: UUID, weight: Double, reps: Int) async {
        await run {
            self.steeple = try await self.store.writeSet(
                day: self.today,
                liftID: liftID,
                weight: weight,
                reps: reps,
                now: self.now()
            )
            self.commitTick += 1
        }
    }

    func bedSession() async {
        await run {
            self.steeple = try await self.store.bedSession(
                day: self.today,
                now: self.now(),
                calendar: self.calendar
            )
            self.commitTick += 1
            self.bedTick += 1
        }
    }

    func setExperience(_ value: Int) async {
        await run {
            self.steeple = try await self.store.setExperience(value)
        }
    }

    func setAim(_ value: Int) async {
        await run {
            self.steeple = try await self.store.setAim(value)
        }
    }

    func setLifts(_ lifts: [MasonryLift]) async {
        await run {
            self.steeple = try await self.store.setLifts(lifts)
        }
    }

    func finishOnboarding(skipped: Bool) async {
        if skipped {
            do {
                steeple = try await store.setExperience(2)
                steeple = try await store.setAim(2)
                if steeple.lifts.isEmpty {
                    steeple = try await store.setLifts(MasonryLift.stock)
                }
            } catch {
                fault = Self.copy((error as? SteepleFault) ?? .invalidAim)
            }
        }
        steeple = await store.setOnboardingComplete(true)
        do {
            try await store.flush()
        } catch {
            fault = "The steeple could not be written."
        }
        applyReview()
    }

    func reopenOnboarding() async {
        steeple = await store.setOnboardingComplete(false)
    }

    func resetAll() async {
        await run {
            try await self.store.resetAllData()
            self.steeple = .empty
            self.warning = nil
            self.tab = .tower
        }
    }

    func applyReview(arguments: [String] = ProcessInfo.processInfo.arguments) {
        if let pane = SteepleLaunch.consume(
            arguments: arguments,
            onboardingComplete: steeple.onboardingComplete,
            consumed: &reviewConsumed
        ) {
            reviewPane = pane
        }
        if let pane = reviewPane {
            tab = pane.tab
        }
    }

    static func live() -> SteepleWatch {
        let directory: URL
        do {
            directory = try SteepleStore.applicationSupportDirectory()
        } catch {
            directory = FileManager.default.temporaryDirectory.appendingPathComponent(
                "Ashlarbed",
                isDirectory: true
            )
        }
        return SteepleWatch(store: SteepleStore(directory: directory))
    }

    static func previewPopulated() -> SteepleWatch {
        let steeple = (try? SteepleSeed.steeple()) ?? Steeple.empty.completingOnboarding()
        return SteepleWatch(
            store: SteepleHold(steeple: steeple),
            steeple: steeple,
            shouldLoad: false
        )
    }

    static func previewEmpty() -> SteepleWatch {
        let steeple = Steeple.empty.completingOnboarding()
        return SteepleWatch(
            store: SteepleHold(steeple: steeple),
            steeple: steeple,
            shouldLoad: false
        )
    }

    static func previewError() -> SteepleWatch {
        let steeple = Steeple.empty.completingOnboarding()
        return SteepleWatch(
            store: SteepleHold(steeple: steeple, warning: .startedEmpty),
            steeple: steeple,
            warning: .startedEmpty,
            shouldLoad: false
        )
    }

    private func applyWarning() {
        if warning == .startedEmpty {
            fault = "The steeple could not be read. The tower is empty."
        } else if warning == .recoveredFromBackup {
            fault = "Recovered the last good steeple."
        }
    }

    private func run(_ work: () async throws -> Void) async {
        guard !isCommitting else { return }
        isCommitting = true
        defer { isCommitting = false }
        do {
            fault = nil
            try await work()
        } catch let fold as SteepleFault {
            fault = Self.copy(fold)
        } catch {
            fault = "Something went wrong. Try again."
        }
    }

    private static func copy(_ fault: SteepleFault) -> String {
        switch fault {
        case .invalidLoad:
            "Weight must be greater than zero, and reps at least one."
        case .unknownLift:
            "Pick a lift from the rack."
        case .alreadyFolded:
            "Today is already bedded."
        case .emptyRack:
            "Keep at least one named lift."
        case .invalidAim:
            "Experience and aim stay between 1 and 99."
        }
    }
}
