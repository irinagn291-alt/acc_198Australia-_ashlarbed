import SwiftUI

/// Role: Steeple. Named colours from Assets. Hex lives in AshlarWash; views never write a raw hex.
enum AshlarSwatch {
    static var background: Color { Color("background") }
    static var surface: Color { Color("surface") }
    static var ink: Color { Color("ink") }
    static var accent: Color { Color("ashlarAccent") }
    static var muted: Color { Color("muted") }
}

/// Role: Steeple. Catalog names for section 13 cutouts. SF Symbols are never brand art.
enum AshlarPlate {
    static let splash = "asb_Splash"
    static let onboarding1 = "asb_Onboarding1"
    static let onboarding2 = "asb_Onboarding2"
    static let onboarding3 = "asb_Onboarding3"
    static let emptyHome = "asb_EmptyHome"
    static let emptyList = "asb_EmptyList"
    static let cardBackdrop = "asb_CardBackdrop"
    static let controlFace = "asb_ControlFace"
    static let twistHero = "asb_TwistHero"
    static let successMark = "asb_SuccessMark"
    static let headerDecor = "asb_HeaderDecor"
}
