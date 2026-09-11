import XCTest
@testable import Ashlarbed

@MainActor
final class SteepleWatchTests: XCTestCase {
    func test_writeSetDoesNotInsertStorey_bedSessionDoes() async throws {
        let watch = SteepleWatch(
            store: SteepleHold(steeple: .empty),
            steeple: .empty,
            shouldLoad: false
        )
        await watch.finishOnboarding(skipped: true)
        XCTAssertEqual(watch.steeple.beddedFloorCount, 0)
        await watch.writeSet(liftID: MasonryLift.squat.id, weight: 100, reps: 5)
        XCTAssertNil(watch.fault)
        XCTAssertEqual(watch.steeple.beddedFloorCount, 0)
        XCTAssertEqual(watch.openToday?.sets.count, 1)
        XCTAssertTrue(watch.canBedSession)
        await watch.bedSession()
        XCTAssertNil(watch.fault)
        XCTAssertEqual(watch.steeple.beddedFloorCount, 1)
        XCTAssertFalse(watch.canBedSession)
    }

    func test_invalidWriteSetsFault_emptyBedWritesRest() async throws {
        let watch = SteepleWatch(
            store: SteepleHold(steeple: .empty.completingOnboarding()),
            steeple: .empty.completingOnboarding(),
            shouldLoad: false
        )
        await watch.writeSet(liftID: MasonryLift.squat.id, weight: -1, reps: 5)
        XCTAssertEqual(watch.fault, "Weight must be greater than zero, and reps at least one.")
        XCTAssertEqual(watch.steeple.beddedFloorCount, 0)
        await watch.bedSession()
        if case .rest = watch.steeple.scaffold(on: watch.today) {
            // Rest band, not a floor.
        } else {
            XCTFail("bedding with no sets must write a RestBand")
        }
        XCTAssertEqual(watch.steeple.beddedFloorCount, 0)
    }

    func test_applyReviewThreeKeys_afterOnboarding() {
        let steeple = Steeple.empty.completingOnboarding()
        let watch = SteepleWatch(
            store: SteepleHold(steeple: steeple),
            steeple: steeple,
            shouldLoad: false
        )
        watch.applyReview(arguments: ["-ReviewScreen", "today"])
        XCTAssertEqual(watch.tab, .tower)
        watch.applyReview(arguments: ["-ReviewScreen", "log"])
        XCTAssertEqual(watch.tab, .tower, "consume once")

        let second = SteepleWatch(
            store: SteepleHold(steeple: steeple),
            steeple: steeple,
            shouldLoad: false
        )
        second.applyReview(arguments: ["-ReviewScreen", "log"])
        XCTAssertEqual(second.tab, .analytics)

        let third = SteepleWatch(
            store: SteepleHold(steeple: steeple),
            steeple: steeple,
            shouldLoad: false
        )
        third.applyReview(arguments: ["-ReviewScreen", "goals"])
        XCTAssertEqual(third.tab, .settings)

        third.tab = .tower
        third.applyReview(arguments: ["-ReviewScreen", "log"])
        XCTAssertEqual(third.tab, .settings, "stored pane reapplies after chrome mounts")
    }

    func test_applyReviewIgnoredUntilOnboarding() {
        let watch = SteepleWatch(
            store: SteepleHold(steeple: .empty),
            steeple: .empty,
            shouldLoad: false
        )
        watch.applyReview(arguments: ["-ReviewScreen", "log"])
        XCTAssertEqual(watch.tab, .tower)
        XCTAssertFalse(watch.onboardingComplete)
    }

    func test_seededHomeNamesTheJobAndEnablesBed() throws {
        let steeple = try SteepleSeed.steeple()
        let watch = SteepleWatch(
            store: SteepleHold(steeple: steeple),
            steeple: steeple,
            shouldLoad: false
        )
        XCTAssertTrue(watch.onboardingComplete)
        XCTAssertTrue(watch.canBedSession)
        XCTAssertTrue(watch.hasOpenSets)
        XCTAssertEqual(watch.jobTitle, "Bed the session")
        XCTAssertTrue(watch.jobLine.contains("Bed the session"))
        XCTAssertTrue(watch.canWriteSet)
        XCTAssertGreaterThan(watch.waitingFold.floors, 0)
        XCTAssertFalse(watch.isFreshTower)
        XCTAssertEqual(watch.tab, .tower)
    }

    func test_figureParseRejectsNonPositive() {
        XCTAssertNil(AshlarFigure.parseDecimal("-2"))
        XCTAssertNil(AshlarFigure.parseDecimal("abc"))
        XCTAssertNil(AshlarFigure.parseCount("0"))
        let separator = Locale.current.decimalSeparator ?? "."
        XCTAssertEqual(AshlarFigure.parseDecimal("80\(separator)5"), 80.5)
        XCTAssertEqual(AshlarFigure.parseCount("5"), 5)
        XCTAssertEqual(AshlarFigure.sanitizeCount("12a3"), "123")
        XCTAssertNotEqual(AshlarFigure.kilograms(1_200), "—")
        XCTAssertFalse(AshlarFigure.kilograms(1_200).isEmpty)
    }
}
