import XCTest
@testable import Ashlarbed

/// Smoke for the app module. Domain cases live in the other test files.
final class AshlarbedTests: XCTestCase {
    func test_appModuleImports() {
        XCTAssertEqual(String(describing: AshlarbedApp.self), "AshlarbedApp")
        XCTAssertEqual(SteepleClient.userAgent, "Ashlarbed/1.0 (iOS; +https://ashlarbed-steeple.pro)")
        XCTAssertEqual(SteepleClient.contactURL.absoluteString, "https://ashlarbed-steeple.pro/contact-us")
        XCTAssertEqual(SteepleTab.allCases.count, 3)
        XCTAssertFalse(SteepleTab.allCases.map(\.rawValue).contains("game"))
        XCTAssertEqual(Set(SteepleTab.allCases.map(\.rawValue)), ["tower", "analytics", "settings"])
        XCTAssertEqual(AshlarWash.face, "SF Pro")
        XCTAssertEqual(AshlarWash.Hex.background, "#FAF4F6")
        XCTAssertEqual(AshlarWash.Hex.surface, "#FEFDFE")
        XCTAssertEqual(AshlarWash.Hex.ink, "#391821")
        XCTAssertEqual(AshlarWash.Hex.accent, "#C3224B")
        XCTAssertEqual(AshlarWash.Hex.muted, "#8D5E6A")
        XCTAssertEqual(AshlarFace.cardRadius, 22)
        XCTAssertEqual(AshlarFace.chipRadius, 14)
        XCTAssertEqual(AshlarFace.unit, 8)
        XCTAssertEqual(AshlarFace.tap, 44)
        XCTAssertEqual(AshlarPlate.splash, "asb_Splash")
        XCTAssertEqual(ReviewPane.today.tab, .tower)
        XCTAssertEqual(ReviewPane.log.tab, .analytics)
        XCTAssertEqual(ReviewPane.goals.tab, .settings)
    }
}
