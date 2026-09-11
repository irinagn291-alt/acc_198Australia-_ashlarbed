import SwiftUI

/// Role: Scaffold. The only custom-drawn surface: stacked ashlar courses. Every course is a Button.
struct ClimbableSteeple: View {
    var steeple: Steeple
    var today: SteepleDay
    var onPick: ((SteepleRise.Course) -> Void)?

    var body: some View {
        let rows = SteepleRise.courses(steeple: steeple, today: today)
        GeometryReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: AshlarFace.space(1)) {
                    Spacer(minLength: 0)
                    goalChip
                    ForEach(Array(rows.reversed().enumerated()), id: \.element.id) { index, course in
                        let width = SteepleRise.taper(
                            indexFromPeak: index,
                            count: rows.count,
                            base: min(proxy.size.width - AshlarFace.space(2), proxy.size.width * 0.92)
                        )
                        AshlarCourseButton(
                            course: course,
                            width: width,
                            height: SteepleRise.height(for: course)
                        ) {
                            AshlarKeyboard.dismiss()
                            onPick?(course)
                        }
                    }
                    plinth(width: min(proxy.size.width - AshlarFace.space(2), proxy.size.width * 0.96))
                }
                .frame(minHeight: proxy.size.height)
                .padding(.horizontal, AshlarFace.space(1))
            }
            .scrollDismissesKeyboard(.immediately)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
    }

    private var goalChip: some View {
        HStack {
            Spacer(minLength: 0)
            AshlarChip(title: "Goal \(AshlarFigure.count(steeple.dailyFloorGoal)) floors")
        }
        .frame(maxWidth: .infinity)
        .accessibilityLabel("Daily floor goal \(AshlarFigure.count(steeple.dailyFloorGoal))")
    }

    private func plinth(width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: AshlarFace.chipRadius, style: .continuous)
            .fill(AshlarSwatch.ink.opacity(0.12))
            .overlay {
                RoundedRectangle(cornerRadius: AshlarFace.chipRadius, style: .continuous)
                    .stroke(AshlarSwatch.ink.opacity(0.28), lineWidth: 1)
            }
            .frame(width: width, height: AshlarFace.space(2))
            .frame(maxWidth: .infinity)
            .accessibilityHidden(true)
    }
}

/// Role: Scaffold. Layout math for the climbable hero. Not a domain type. Not a second canvas.
enum SteepleRise {
    struct Course: Identifiable, Equatable, Sendable {
        var id: String
        var kind: Kind

        enum Kind: Equatable, Sendable {
            case storey(Storey)
            case rest(day: SteepleDay)
            case scaffold(tonnage: Double, day: SteepleDay)
        }
    }

    static func courses(steeple: Steeple, today: SteepleDay) -> [Course] {
        var rows: [Course] = []
        for scaffold in steeple.orderedScaffolds {
            switch scaffold {
            case .bedded(let band):
                for storey in band.storeys {
                    rows.append(Course(id: storey.id.uuidString, kind: .storey(storey)))
                }
            case .rest(let band):
                rows.append(Course(id: "rest-\(band.day.rawValue)", kind: .rest(day: band.day)))
            case .open:
                break
            }
        }
        if steeple.canWriteSet(on: today) {
            let tonnage = steeple.openScaffold(on: today)?.liveTonnage ?? steeple.remainderKilograms
            rows.append(
                Course(
                    id: "scaffold-\(today.rawValue)",
                    kind: .scaffold(tonnage: tonnage, day: today)
                )
            )
        }
        return rows
    }

    static func height(for course: Course) -> CGFloat {
        switch course.kind {
        case .storey, .rest:
            return AshlarFace.tap
        case .scaffold(let tonnage, _):
            let fraction = tonnage / StoreyFold.kilogramsPerStorey
            let steps = min(6, max(0, Int(fraction.rounded(.down))))
            return AshlarFace.tap + AshlarFace.space(steps)
        }
    }

    static func taper(indexFromPeak: Int, count: Int, base: CGFloat) -> CGFloat {
        let top = base * 0.62
        let last = max(count - 1, 1)
        let t = CGFloat(indexFromPeak) / CGFloat(last)
        return top + (base - top) * t
    }
}

/// Role: Scaffold. One tappable course. Radius and elevation come from AshlarFace only.
private struct AshlarCourseButton: View {
    var course: SteepleRise.Course
    var width: CGFloat
    var height: CGFloat
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AshlarFace.space(1)) {
                Text(title)
                    .font(AshlarFace.font(.callout).weight(.semibold))
                    .foregroundStyle(AshlarSwatch.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Spacer(minLength: AshlarFace.space(1))
                Text(figure)
                    .font(AshlarFace.font(.figure))
                    .foregroundStyle(AshlarSwatch.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .layoutPriority(1)
                if stamped {
                    AshlarChip(title: "PR")
                }
            }
            .padding(.horizontal, AshlarFace.space(2))
            .frame(width: width, height: height, alignment: .leading)
            .background {
                face
            }
            .clipShape(shape)
            .overlay {
                shape.stroke(stroke, style: strokeStyle)
            }
            .ashlarRaised()
            .contentShape(shape)
        }
        .buttonStyle(AshlarPressStyle(enabled: true))
        .frame(maxWidth: .infinity)
        .accessibilityLabel(accessibility)
        .accessibilityHint("Opens this course.")
    }

    private var shape: RoundedRectangle {
        switch course.kind {
        case .rest:
            AshlarFace.chipShape
        case .storey, .scaffold:
            AshlarFace.cardShape
        }
    }

    @ViewBuilder
    private var face: some View {
        switch course.kind {
        case .storey:
            AshlarSwatch.surface
                .overlay { AshlarHatch().stroke(AshlarSwatch.ink.opacity(0.08), lineWidth: 1) }
        case .rest:
            AshlarSwatch.muted.opacity(0.18)
        case .scaffold:
            AshlarSwatch.surface
                .overlay {
                    Image(AshlarPlate.controlFace)
                        .resizable()
                        .scaledToFit()
                        .frame(width: AshlarFace.space(4), height: AshlarFace.space(4))
                        .opacity(0.35)
                        .accessibilityHidden(true)
                }
        }
    }

    private var stroke: Color {
        switch course.kind {
        case .scaffold:
            AshlarSwatch.accent
        case .storey, .rest:
            AshlarSwatch.ink.opacity(0.28)
        }
    }

    private var strokeStyle: StrokeStyle {
        switch course.kind {
        case .scaffold:
            StrokeStyle(lineWidth: 2, dash: [AshlarFace.unit, AshlarFace.unit])
        case .storey, .rest:
            StrokeStyle(lineWidth: 1)
        }
    }

    private var stamped: Bool {
        if case .storey(let storey) = course.kind { return !storey.stamps.isEmpty }
        return false
    }

    private var title: String {
        switch course.kind {
        case .storey(let storey):
            "Storey \(AshlarFigure.count(storey.ordinal))"
        case .rest:
            "Rest band"
        case .scaffold:
            "Open scaffold"
        }
    }

    private var figure: String {
        switch course.kind {
        case .storey(let storey):
            AshlarFigure.kilogramsWithUnit(storey.kilograms)
        case .rest(let day):
            AshlarFigure.day(day, calendar: .current)
        case .scaffold(let tonnage, _):
            AshlarFigure.kilogramsWithUnit(tonnage)
        }
    }

    private var accessibility: String {
        switch course.kind {
        case .storey(let storey):
            let stamp = storey.stamps.isEmpty ? "" : ", earned stamp"
            return "Storey \(AshlarFigure.count(storey.ordinal)), \(AshlarFigure.kilogramsWithUnit(storey.kilograms))\(stamp)"
        case .rest(let day):
            return "Rest band, \(AshlarFigure.day(day, calendar: .current))"
        case .scaffold(let tonnage, _):
            return "Open scaffold, \(AshlarFigure.kilogramsWithUnit(tonnage))"
        }
    }
}

/// Role: Scaffold. Hatch for ashlar faces. Confined to the Tower hero.
private struct AshlarHatch: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        var x = rect.minX + AshlarFace.unit
        while x < rect.maxX - AshlarFace.unit {
            path.move(to: CGPoint(x: x, y: rect.minY + AshlarFace.unit))
            path.addLine(to: CGPoint(x: x, y: rect.maxY - AshlarFace.unit))
            x += AshlarFace.unit
        }
        return path
    }
}

/// Role: Scaffold. Stock sheet for a picked course. No custom drawing.
struct AshlarCourseFold: View {
    var course: SteepleRise.Course
    var watch: SteepleWatch
    var onClose: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AshlarFace.space(2)) {
                    Image(art)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(height: AshlarFace.space(16))
                        .accessibilityHidden(true)
                    Text(headline)
                        .ashlarInk(.spire)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    Text(line)
                        .ashlarInk(.body)
                    figures
                    AshlarChromeButton(
                        title: "Close",
                        fills: true,
                        emphasized: true,
                        action: onClose
                    )
                }
                .padding(AshlarFace.space(2))
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollContentBackground(.hidden)
            .background(AshlarSwatch.background.ignoresSafeArea())
            .navigationTitle(headline)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .frame(width: AshlarFace.tap, height: AshlarFace.tap)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Close")
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(AshlarSwatch.background)
        .presentationCornerRadius(AshlarFace.cardRadius)
    }

    private var art: String {
        switch course.kind {
        case .scaffold:
            AshlarPlate.controlFace
        case .rest:
            AshlarPlate.emptyList
        case .storey:
            AshlarPlate.successMark
        }
    }

    private var headline: String {
        switch course.kind {
        case .storey(let storey):
            "Storey \(AshlarFigure.count(storey.ordinal))"
        case .rest:
            "Rest band"
        case .scaffold:
            "Open scaffold"
        }
    }

    private var line: String {
        switch course.kind {
        case .storey:
            "This floor exists because a session was bedded. Sets never skip the scaffold."
        case .rest:
            "Bedding with no sets writes a rest band. Rest is a real course, not a missing day."
        case .scaffold:
            "Sets write weight times reps here. Bed the session is the only write that lays climbable floors."
        }
    }

    @ViewBuilder
    private var figures: some View {
        VStack(alignment: .leading, spacing: AshlarFace.space(1)) {
            switch course.kind {
            case .storey(let storey):
                row(AshlarFigure.kilogramsWithUnit(storey.kilograms), "Mass")
                row(AshlarFigure.day(storey.day, calendar: .current), "Laid")
                if storey.stamps.isEmpty {
                    Text("No stamp. Equal numbers do not earn.")
                        .font(AshlarFace.font(.callout))
                        .foregroundStyle(AshlarSwatch.ink)
                } else {
                    ForEach(storey.stamps) { stamp in
                        HStack {
                            Text(watch.liftName(stamp.liftID))
                                .font(AshlarFace.font(.callout))
                                .foregroundStyle(AshlarSwatch.ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                            AshlarChip(title: stamp.kind == .epley ? "Epley 1RM" : "Heavier set")
                            Spacer(minLength: AshlarFace.space(1))
                            Text(AshlarFigure.kilogramsWithUnit(stamp.value))
                                .font(AshlarFace.font(.callout).monospacedDigit())
                                .foregroundStyle(AshlarSwatch.ink)
                                .lineLimit(1)
                                .layoutPriority(1)
                        }
                        .frame(maxWidth: .infinity, minHeight: AshlarFace.tap, alignment: .leading)
                    }
                }
            case .rest(let day):
                row(AshlarFigure.day(day, calendar: .current), "Day")
            case .scaffold(let tonnage, _):
                let split = StoreyFold.floorsAndRemainder(tonnage: tonnage)
                row(AshlarFigure.kilogramsWithUnit(tonnage), "Live")
                row(AshlarFigure.count(split.floors), "Floors waiting")
                row(AshlarFigure.kilogramsWithUnit(split.remainder), "Carry")
            }
        }
        .padding(AshlarFace.space(2))
        .frame(maxWidth: .infinity, alignment: .leading)
        .ashlarCardFill()
    }

    private func row(_ value: String, _ caption: String) -> some View {
        HStack {
            Text(caption)
                .font(AshlarFace.font(.callout))
                .foregroundStyle(AshlarSwatch.ink)
                .lineLimit(1)
            Spacer(minLength: AshlarFace.space(1))
            Text(value)
                .font(AshlarFace.font(.figure))
                .foregroundStyle(AshlarSwatch.ink)
                .lineLimit(1)
                .layoutPriority(1)
        }
        .frame(maxWidth: .infinity, minHeight: AshlarFace.tap)
    }
}
