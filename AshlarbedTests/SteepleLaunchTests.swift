import XCTest
@testable import Ashlarbed

final class SteepleLaunchTests: XCTestCase {
    func test_readsOnceAfterOnboarding() {
        var consumed = false
        XCTAssertNil(
            SteepleLaunch.consume(
                arguments: ["-ReviewScreen", "log"],
                onboardingComplete: false,
                consumed: &consumed
            )
        )
        XCTAssertFalse(consumed)

        let first = SteepleLaunch.consume(
            arguments: ["app", "-ReviewScreen", "log"],
            onboardingComplete: true,
            consumed: &consumed
        )
        XCTAssertEqual(first, .log)
        XCTAssertEqual(first?.tab, .analytics)
        XCTAssertTrue(consumed)
        XCTAssertNil(
            SteepleLaunch.consume(
                arguments: ["-ReviewScreen", "goals"],
                onboardingComplete: true,
                consumed: &consumed
            )
        )
    }

    func test_threeKeysAreDistinctScreens() {
        XCTAssertEqual(ReviewPane.today.rawValue, "today")
        XCTAssertEqual(ReviewPane.log.rawValue, "log")
        XCTAssertEqual(ReviewPane.goals.rawValue, "goals")
        XCTAssertNotEqual(ReviewPane.today, ReviewPane.log)
        XCTAssertNotEqual(ReviewPane.log, ReviewPane.goals)
        XCTAssertNotEqual(ReviewPane.today, ReviewPane.goals)
        XCTAssertEqual(ReviewPane.today.tab, .tower)
        XCTAssertEqual(ReviewPane.log.tab, .analytics)
        XCTAssertEqual(ReviewPane.goals.tab, .settings)
        XCTAssertNotEqual(ReviewPane.today.tab, ReviewPane.log.tab)
        XCTAssertNotEqual(ReviewPane.log.tab, ReviewPane.goals.tab)
        XCTAssertNotEqual(ReviewPane.today.tab, ReviewPane.goals.tab)

        var consumed = false
        XCTAssertEqual(
            SteepleLaunch.consume(
                arguments: ["-ReviewScreen", "today"],
                onboardingComplete: true,
                consumed: &consumed
            ),
            .today
        )
        consumed = false
        XCTAssertEqual(
            SteepleLaunch.consume(
                arguments: ["-ReviewScreen", "goals"],
                onboardingComplete: true,
                consumed: &consumed
            ),
            .goals
        )
    }

    func test_unknownKeyIsIgnored() {
        var consumed = false
        XCTAssertNil(
            SteepleLaunch.consume(
                arguments: ["-ReviewScreen", "aura"],
                onboardingComplete: true,
                consumed: &consumed
            )
        )
        XCTAssertTrue(consumed)
    }
}
