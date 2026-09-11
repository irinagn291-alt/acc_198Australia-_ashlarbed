import Foundation

/// Role: Steeple. Simulator demo steeple. Device never writes this. Key: asb.demo.v1.
enum SteepleSeed {
    private static func fixed(_ value: String) -> UUID {
        UUID(uuidString: value) ?? UUID()
    }

    static func steeple(now: Date = Date(), calendar: Calendar = .current) throws -> Steeple {
        let today = SteepleDay.from(now, calendar: calendar)
        var next = Steeple.empty.completingOnboarding()
        next.experience = 2
        next.aim = 3

        let history: [(offset: Int, rest: Bool, loads: [(lift: MasonryLift, weight: Double, reps: Int, id: String)])] = [
            (
                -6,
                true,
                []
            ),
            (
                -5,
                false,
                [
                    (MasonryLift.squat, 100, 5, "CCCCCCCC-0001-4000-8000-000000000001"),
                    (MasonryLift.bench, 80, 5, "CCCCCCCC-0001-4000-8000-000000000002"),
                    (MasonryLift.deadlift, 140, 5, "CCCCCCCC-0001-4000-8000-000000000003"),
                ]
            ),
            (
                -4,
                false,
                [
                    (MasonryLift.squat, 110, 5, "CCCCCCCC-0001-4000-8000-000000000004"),
                    (MasonryLift.bench, 80, 5, "CCCCCCCC-0001-4000-8000-000000000005"),
                ]
            ),
            (
                -3,
                true,
                []
            ),
            (
                -2,
                false,
                [
                    (MasonryLift.deadlift, 150, 5, "CCCCCCCC-0001-4000-8000-000000000006"),
                    (MasonryLift.press, 50, 8, "CCCCCCCC-0001-4000-8000-000000000007"),
                ]
            ),
            (
                -1,
                false,
                [
                    (MasonryLift.squat, 100, 6, "CCCCCCCC-0001-4000-8000-000000000008"),
                    (MasonryLift.bench, 85, 5, "CCCCCCCC-0001-4000-8000-000000000009"),
                ]
            ),
        ]

        for entry in history {
            let day = today.adding(days: entry.offset, calendar: calendar)
            let loggedAt = now.addingTimeInterval(Double(entry.offset) * 86_400)
            if entry.rest {
                next = try next.bedSession(day: day, calendar: calendar)
                continue
            }
            for load in entry.loads {
                next = try next.writeSet(
                    day: day,
                    liftID: load.lift.id,
                    weight: load.weight,
                    reps: load.reps,
                    id: fixed(load.id),
                    loggedAt: loggedAt
                )
            }
            next = try next.bedSession(day: day, calendar: calendar)
        }

        let liveLoads: [(MasonryLift, Double, Int, String)] = [
            (MasonryLift.squat, 120, 4, "CCCCCCCC-0001-4000-8000-000000000010"),
            (MasonryLift.bench, 90, 3, "CCCCCCCC-0001-4000-8000-000000000011"),
            (MasonryLift.deadlift, 145, 3, "CCCCCCCC-0001-4000-8000-000000000012"),
        ]
        for load in liveLoads {
            next = try next.writeSet(
                day: today,
                liftID: load.0.id,
                weight: load.1,
                reps: load.2,
                id: fixed(load.3),
                loggedAt: now
            )
        }
        return next
    }
}
