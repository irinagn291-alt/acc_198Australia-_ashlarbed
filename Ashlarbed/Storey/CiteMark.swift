import Foundation

/// Role: Storey. Tappable Epley 1RM source. Same screen as the claim in Settings; never a dead label.
struct CiteMark: Equatable, Sendable, Identifiable {
    var id: String { url.absoluteString }
    var title: String
    var url: URL
}

/// Role: Storey. Offline citations for the Epley estimate. Network is not required to show these.
enum EpleyCite: Sendable {
    /// Programmer constants; URLs are fixed in SPEC.md / 1.4.1 sources.
    static let marks: [CiteMark] = [
        CiteMark(
            title: "Epley one-repetition maximum",
            url: URL(string: "https://en.wikipedia.org/wiki/One-repetition_maximum")!
        ),
        CiteMark(
            title: "NIH MedlinePlus — Exercise and Physical Fitness",
            url: URL(string: "https://medlineplus.gov/exerciseandphysicalfitness.html")!
        ),
    ]
}
