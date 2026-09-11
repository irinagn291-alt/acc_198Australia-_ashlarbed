import Foundation

/// Role: Steeple. Locale figures. Round only at display. Stored values keep full precision.
enum AshlarFigure {
    static func kilograms(_ value: Double) -> String {
        let formatted = massFormatter.string(from: NSNumber(value: value)) ?? "—"
        return formatted
    }

    static func kilogramsWithUnit(_ value: Double) -> String {
        let formatted = kilograms(value)
        if formatted == "—" { return formatted }
        return "\(formatted) kg"
    }

    static func count(_ value: Int) -> String {
        countFormatter.string(from: NSNumber(value: value)) ?? "—"
    }

    static func parseDecimal(_ raw: String) -> Double? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard let value = decimalFormatter.number(from: trimmed)?.doubleValue else { return nil }
        guard value.isFinite, value > 0 else { return nil }
        return value
    }

    static func parseCount(_ raw: String) -> Int? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard let number = countFormatter.number(from: trimmed) else { return nil }
        let value = number.intValue
        guard value > 0 else { return nil }
        return value
    }

    static func sanitizeDecimal(_ raw: String) -> String {
        let separator = Locale.current.decimalSeparator ?? "."
        var seenSeparator = false
        var out = ""
        for character in raw {
            if character.isNumber {
                out.append(character)
            } else if String(character) == separator || character == "." || character == "," {
                guard !seenSeparator else { continue }
                seenSeparator = true
                out.append(contentsOf: separator)
            }
        }
        return out
    }

    static func sanitizeCount(_ raw: String) -> String {
        raw.filter(\.isNumber)
    }

    static func day(_ stamp: SteepleDay, calendar: Calendar) -> String {
        let raw = stamp.rawValue
        var parts = DateComponents()
        parts.year = raw / 10_000
        parts.month = (raw / 100) % 100
        parts.day = raw % 100
        let date = calendar.date(from: parts) ?? Date()
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = calendar.locale ?? .current
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private static var massFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        formatter.usesGroupingSeparator = true
        return formatter
    }

    private static var countFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.usesGroupingSeparator = true
        return formatter
    }

    private static var decimalFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }
}
