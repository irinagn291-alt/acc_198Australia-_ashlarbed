import SwiftUI

/// Role: Storey. Section 3.6 Analytics tab. Named for the live driver; body is the floor ledger.
struct AnalyticsPane: View {
    var watch: SteepleWatch

    var body: some View {
        FloorLedger(watch: watch)
    }
}

/// Role: Storey. Analytics of bedded floors, volume, and earned PR stamps. Not a workout table.
struct FloorLedger: View {
    var watch: SteepleWatch
    @State private var openFloors = true
    @State private var openVolume = true
    @State private var openStamps = true
    @State private var showTwist = false

    var body: some View {
        Group {
            if watch.isHauling {
                ProgressView()
                    .tint(AshlarSwatch.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if watch.loadFailed {
                AshlarVacancy(
                    image: AshlarPlate.emptyList,
                    headline: "Floors could not be read.",
                    line: watch.fault ?? "The steeple started empty.",
                    actionTitle: "Retry",
                    enabled: !watch.isCommitting
                ) {
                    Task { await watch.retry() }
                }
            } else if watch.steeple.beddedFloorCount == 0 {
                AshlarVacancy(
                    image: AshlarPlate.emptyList,
                    headline: "No floors bedded yet.",
                    line: "Bed a session on the Tower tab to write climbable storeys.",
                    actionTitle: "Open Tower"
                ) {
                    watch.tab = .tower
                }
            } else {
                populated
            }
        }
        .background(AshlarSwatch.background.ignoresSafeArea())
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AshlarSwatch.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $showTwist) {
            BedFoldView(watch: watch, onClose: { showTwist = false })
        }
    }

    private var populated: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AshlarFace.space(2)) {
                readout
                Button {
                    showTwist = true
                } label: {
                    HStack(spacing: AshlarFace.space(2)) {
                        Image(AshlarPlate.twistHero)
                            .resizable()
                            .scaledToFit()
                            .frame(width: AshlarFace.tap, height: AshlarFace.tap)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Scaffold, then bed")
                                .ashlarInk(.title)
                                .lineLimit(1)
                            Text("Floors count only after Bed. Sets never skip the scaffold.")
                                .font(AshlarFace.font(.caption))
                                .foregroundStyle(AshlarSwatch.ink)
                                .lineLimit(2)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .foregroundStyle(AshlarSwatch.ink)
                            .accessibilityHidden(true)
                    }
                    .padding(AshlarFace.space(2))
                    .frame(maxWidth: .infinity, minHeight: AshlarFace.tap, alignment: .leading)
                    .ashlarCardFill()
                    .contentShape(AshlarFace.cardShape)
                }
                .buttonStyle(AshlarPressStyle(enabled: true))
                .accessibilityLabel("Scaffold, then bed")

                DisclosureGroup("Bedded floors", isExpanded: $openFloors) {
                    floorsBlock
                }
                .ashlarInk(.title)
                .padding(AshlarFace.space(2))
                .frame(maxWidth: .infinity, alignment: .leading)
                .ashlarCardFill()

                DisclosureGroup("Volume", isExpanded: $openVolume) {
                    volumeBlock
                }
                .ashlarInk(.title)
                .padding(AshlarFace.space(2))
                .frame(maxWidth: .infinity, alignment: .leading)
                .ashlarCardFill()

                DisclosureGroup("Earned PR stamps", isExpanded: $openStamps) {
                    stampsBlock
                }
                .ashlarInk(.title)
                .padding(AshlarFace.space(2))
                .frame(maxWidth: .infinity, alignment: .leading)
                .ashlarCardFill()

                if let fault = watch.fault, !watch.loadFailed {
                    AshlarBanner(text: fault) {
                        Task { await watch.retry() }
                    }
                }
            }
            .padding(AshlarFace.space(2))
        }
        .scrollContentBackground(.hidden)
        .contentMargins(.bottom, AshlarFace.space(3), for: .scrollContent)
    }

    private var readout: some View {
        VStack(alignment: .leading, spacing: AshlarFace.space(1)) {
            Text(AshlarFigure.count(watch.steeple.beddedFloorCount))
                .ashlarInk(.spire)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .layoutPriority(1)
            Text("Bedded floors")
                .font(AshlarFace.font(.callout))
                .foregroundStyle(AshlarSwatch.ink)
            HStack(alignment: .firstTextBaseline, spacing: AshlarFace.space(3)) {
                figure(AshlarFigure.kilogramsWithUnit(watch.steeple.beddedVolume), "Volume")
                figure(AshlarFigure.count(watch.steeple.earnedStamps.count), "Stamps")
            }
        }
        .padding(AshlarFace.space(2))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            Image(AshlarPlate.cardBackdrop)
                .resizable()
                .scaledToFill()
                .opacity(0.22)
                .clipped()
                .accessibilityHidden(true)
        }
        .clipShape(AshlarFace.cardShape)
        .ashlarRaised()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(AshlarFigure.count(watch.steeple.beddedFloorCount)) bedded floors, volume \(AshlarFigure.kilogramsWithUnit(watch.steeple.beddedVolume)), \(AshlarFigure.count(watch.steeple.earnedStamps.count)) stamps"
        )
    }

    private var floorsBlock: some View {
        VStack(alignment: .leading, spacing: AshlarFace.space(1)) {
            ForEach(watch.steeple.beddedStoreys) { storey in
                HStack(alignment: .firstTextBaseline, spacing: AshlarFace.space(1)) {
                    Text("Storey \(AshlarFigure.count(storey.ordinal))")
                        .font(AshlarFace.font(.body))
                        .foregroundStyle(AshlarSwatch.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    Spacer(minLength: AshlarFace.space(1))
                    Text(AshlarFigure.day(storey.day, calendar: .current))
                        .font(AshlarFace.font(.caption))
                        .foregroundStyle(AshlarSwatch.ink)
                        .lineLimit(1)
                        .layoutPriority(1)
                }
                .frame(maxWidth: .infinity, minHeight: AshlarFace.space(5), alignment: .leading)
                if !storey.stamps.isEmpty {
                    HStack(spacing: AshlarFace.space(1)) {
                        ForEach(storey.stamps) { stamp in
                            AshlarChip(title: stamp.kind == .epley ? "Epley" : "Weight")
                        }
                    }
                }
            }
            restRows
        }
        .padding(.top, AshlarFace.space(1))
    }

    @ViewBuilder
    private var restRows: some View {
        let rests = watch.steeple.orderedScaffolds.compactMap { scaffold -> RestBand? in
            if case .rest(let band) = scaffold { return band }
            return nil
        }
        ForEach(rests, id: \.day.rawValue) { band in
            RestCourseChip(day: band.day)
        }
    }

    private var volumeBlock: some View {
        VStack(alignment: .leading, spacing: AshlarFace.space(1)) {
            Text(AshlarFigure.kilogramsWithUnit(watch.steeple.beddedVolume))
                .ashlarInk(.figure)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .layoutPriority(1)
            Text("Bedded tonnage")
                .font(AshlarFace.font(.caption))
                .foregroundStyle(AshlarSwatch.ink)
            ForEach(watch.steeple.lifts) { lift in
                let volume = watch.volume(liftID: lift.id)
                HStack {
                    Text(lift.name)
                        .font(AshlarFace.font(.callout))
                        .foregroundStyle(AshlarSwatch.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    Spacer(minLength: AshlarFace.space(1))
                    Text(volume > 0 ? AshlarFigure.kilogramsWithUnit(volume) : "—")
                        .font(AshlarFace.font(.callout).monospacedDigit())
                        .foregroundStyle(AshlarSwatch.ink)
                        .lineLimit(1)
                        .layoutPriority(1)
                }
                .frame(maxWidth: .infinity, minHeight: AshlarFace.space(5), alignment: .leading)
            }
        }
        .padding(.top, AshlarFace.space(1))
    }

    private var stampsBlock: some View {
        VStack(alignment: .leading, spacing: AshlarFace.space(1)) {
            ForEach(watch.steeple.lifts) { lift in
                let epley = watch.bestEpley(liftID: lift.id)
                let weight = watch.bestWeight(liftID: lift.id)
                VStack(alignment: .leading, spacing: 0) {
                    Text(lift.name)
                        .font(AshlarFace.font(.body))
                        .foregroundStyle(AshlarSwatch.ink)
                        .lineLimit(1)
                    HStack(spacing: AshlarFace.space(2)) {
                        Text("Epley \(epley.map(AshlarFigure.kilogramsWithUnit) ?? "—")")
                            .font(AshlarFace.font(.caption).monospacedDigit())
                            .foregroundStyle(AshlarSwatch.ink)
                        Text("Weight \(weight.map(AshlarFigure.kilogramsWithUnit) ?? "—")")
                            .font(AshlarFace.font(.caption).monospacedDigit())
                            .foregroundStyle(AshlarSwatch.ink)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: AshlarFace.tap, alignment: .leading)
            }
            ForEach(watch.steeple.earnedStamps) { stamp in
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
            if watch.steeple.earnedStamps.isEmpty {
                Text("No stamp is decorative. Equal numbers do not earn.")
                    .font(AshlarFace.font(.callout))
                    .foregroundStyle(AshlarSwatch.ink)
            }
            ForEach(EpleyCite.marks) { mark in
                Link(destination: mark.url) {
                    Text(mark.title)
                        .font(AshlarFace.font(.caption))
                        .foregroundStyle(AshlarSwatch.accent)
                        .frame(maxWidth: .infinity, minHeight: AshlarFace.tap, alignment: .leading)
                        .contentShape(Rectangle())
                }
            }
        }
        .padding(.top, AshlarFace.space(1))
    }

    private func figure(_ value: String, _ caption: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value)
                .ashlarInk(.figure)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(caption)
                .font(AshlarFace.font(.caption))
                .foregroundStyle(AshlarSwatch.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
