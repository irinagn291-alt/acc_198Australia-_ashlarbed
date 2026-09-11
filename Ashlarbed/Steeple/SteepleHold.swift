import Foundation

/// Role: Steeple. In-memory steeple for previews and tests. Views never see this type.
actor SteepleHold: SteepleStoring {
    private var latest: Steeple
    private var warning: SteepleWarning?

    init(steeple: Steeple = .empty, warning: SteepleWarning? = nil) {
        self.latest = steeple
        self.warning = warning
    }

    func load() async -> (steeple: Steeple, warning: SteepleWarning?) {
        (latest, warning)
    }

    func snapshot() async -> Steeple {
        latest
    }

    func writeSet(
        day: SteepleDay,
        liftID: UUID,
        weight: Double,
        reps: Int,
        now: Date
    ) async throws -> Steeple {
        latest = try latest.writeSet(day: day, liftID: liftID, weight: weight, reps: reps, loggedAt: now)
        return latest
    }

    func bedSession(day: SteepleDay, now: Date, calendar: Calendar) async throws -> Steeple {
        _ = now
        latest = try latest.bedSession(day: day, calendar: calendar)
        return latest
    }

    func setExperience(_ value: Int) async throws -> Steeple {
        latest = try latest.settingExperience(value)
        return latest
    }

    func setAim(_ value: Int) async throws -> Steeple {
        latest = try latest.settingAim(value)
        return latest
    }

    func setLifts(_ lifts: [MasonryLift]) async throws -> Steeple {
        latest = try latest.settingLifts(lifts)
        return latest
    }

    func setOnboardingComplete(_ flag: Bool) async -> Steeple {
        if flag {
            latest = latest.completingOnboarding()
        } else {
            latest.onboardingComplete = false
        }
        return latest
    }

    func flush() async throws {}

    func resetAllData() async throws {
        latest = .empty
        warning = nil
    }

    func seedDemoIfNeeded(now: Date, calendar: Calendar) async throws -> Steeple? {
        _ = now
        _ = calendar
        return nil
    }
}
