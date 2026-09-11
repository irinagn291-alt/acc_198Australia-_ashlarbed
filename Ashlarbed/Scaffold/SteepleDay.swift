import Foundation

/// Role: Scaffold. Day key as Int YYYYMMDD from Calendar.startOfDay. Never a Date dictionary key.
struct SteepleDay: RawRepresentable, Hashable, Sendable, Comparable {
    let rawValue: Int

    init(rawValue: Int) {
        self.rawValue = rawValue
    }

    static func from(_ date: Date, calendar: Calendar) -> SteepleDay {
        let start = calendar.startOfDay(for: date)
        let parts = calendar.dateComponents([.year, .month, .day], from: start)
        let year = parts.year ?? 1970
        let month = parts.month ?? 1
        let day = parts.day ?? 1
        return SteepleDay(rawValue: year * 10_000 + month * 100 + day)
    }

    static func < (lhs: SteepleDay, rhs: SteepleDay) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    func adding(days: Int, calendar: Calendar) -> SteepleDay {
        let parts = DateComponents(
            year: rawValue / 10_000,
            month: (rawValue / 100) % 100,
            day: rawValue % 100
        )
        let base = calendar.date(from: parts) ?? Date(timeIntervalSince1970: 0)
        let shifted = calendar.date(byAdding: .day, value: days, to: base) ?? base
        return SteepleDay.from(shifted, calendar: calendar)
    }
}
