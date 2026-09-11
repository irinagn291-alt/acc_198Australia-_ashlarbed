import SwiftUI

/// Role: RestBand. Stock chip for a rest course. Rest is a real band, not a missing row. Not custom-drawn.
struct RestCourseChip: View {
    var day: SteepleDay
    var calendar: Calendar = .current

    var body: some View {
        HStack(spacing: AshlarFace.space(1)) {
            AshlarChip(title: "Rest band")
            Text(AshlarFigure.day(day, calendar: calendar))
                .font(AshlarFace.font(.callout))
                .foregroundStyle(AshlarSwatch.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: AshlarFace.tap, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Rest band, \(AshlarFigure.day(day, calendar: calendar))")
    }
}
