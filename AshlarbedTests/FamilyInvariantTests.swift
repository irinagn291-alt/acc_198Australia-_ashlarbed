import XCTest
@testable import Ashlarbed

final class FamilyInvariantTests: XCTestCase {
    func test_familyInvariant_tonnageWeightTimesReps_epley_500kgFloor_goalExperienceTimesAim() {
        XCTAssertEqual(StoreyFold.tonnage(weight: 80, reps: 5), 400)
        XCTAssertEqual(StoreyFold.tonnage(weight: 100, reps: 1), 100)
        XCTAssertEqual(StoreyFold.tonnage(weight: 140, reps: 5), 700)

        XCTAssertEqual(StoreyFold.epley1RM(weight: 100, reps: 5), 100 * (1 + 5.0 / 30), accuracy: 0.000_000_1)
        XCTAssertEqual(StoreyFold.epley1RM(weight: 60, reps: 10), 60 * (1 + 10.0 / 30), accuracy: 0.000_000_1)
        XCTAssertEqual(StoreyFold.epley1RM(weight: 200, reps: 1), 200 * (1 + 1.0 / 30), accuracy: 0.000_000_1)

        XCTAssertEqual(StoreyFold.kilogramsPerStorey, 500)
        let even = StoreyFold.floorsAndRemainder(tonnage: 500)
        XCTAssertEqual(even.floors, 1)
        XCTAssertEqual(even.remainder, 0)
        let split = StoreyFold.floorsAndRemainder(tonnage: 1_200)
        XCTAssertEqual(split.floors, 2)
        XCTAssertEqual(split.remainder, 200, accuracy: 0.000_000_1)
        let short = StoreyFold.floorsAndRemainder(tonnage: 499)
        XCTAssertEqual(short.floors, 0)
        XCTAssertEqual(short.remainder, 499, accuracy: 0.000_000_1)
        let triple = StoreyFold.floorsAndRemainder(tonnage: 1_500)
        XCTAssertEqual(triple.floors, 3)
        XCTAssertEqual(triple.remainder, 0)

        XCTAssertEqual(StoreyFold.dailyFloorGoal(experience: 2, aim: 3), 6)
        XCTAssertEqual(StoreyFold.dailyFloorGoal(experience: 1, aim: 1), 1)
        XCTAssertEqual(StoreyFold.dailyFloorGoal(experience: 4, aim: 5), 20)
        XCTAssertEqual(Steeple.empty.dailyFloorGoal, 2 * 2)

        let set = LoggedSet(
            id: UUID(),
            liftID: MasonryLift.squat.id,
            weightKilograms: 100,
            reps: 5,
            loggedUnix: 0
        )
        XCTAssertEqual(set.tonnage, 500)
        XCTAssertEqual(set.epley1RM, StoreyFold.epley1RM(weight: 100, reps: 5), accuracy: 0.000_000_1)
        XCTAssertEqual(StoreyFold.tonnage(weight: 80, reps: 5), 80 * 5)
    }

    /// Needles OLS and COSC are the watch_rate desk. This family is lift_tower: Epley, tonnage, 500 kg floors.
    func test_familyInvariant_OLS_COSC_areWatchRate_thisFamilyIsEpleyTonnageAnd500kgFloor() {
        XCTAssertEqual(StoreyFold.tonnage(weight: 100, reps: 5), 500)
        XCTAssertEqual(StoreyFold.epley1RM(weight: 100, reps: 5), 100 * (1 + 5.0 / 30), accuracy: 0.000_000_1)
        XCTAssertEqual(StoreyFold.kilogramsPerStorey, 500)
        XCTAssertEqual(StoreyFold.dailyFloorGoal(experience: 2, aim: 3), 6)
    }
}
