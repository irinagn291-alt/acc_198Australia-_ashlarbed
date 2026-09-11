import SwiftUI

/// Role: Scaffold. Tower home. Climbable steeple plus fused set log. Bed is a control, not a destination.
struct TowerPane: View {
    var watch: SteepleWatch
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var openScaffold = true
    @State private var openLog = true
    @State private var showTwist = false
    @State private var logging = false
    @State private var showSuccess = false
    @State private var pickedCourse: SteepleRise.Course?
    @State private var successTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { proxy in
            let wide = proxy.size.width >= 700
            Group {
                if watch.isHauling {
                    ProgressView()
                        .tint(AshlarSwatch.accent)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if watch.loadFailed {
                    AshlarVacancy(
                        image: AshlarPlate.emptyHome,
                        headline: "The tower could not be read.",
                        line: watch.fault ?? "The steeple started empty.",
                        actionTitle: "Retry",
                        enabled: !watch.isCommitting
                    ) {
                        Task { await watch.retry() }
                    }
                } else if watch.isFreshTower, !logging {
                    AshlarVacancy(
                        image: AshlarPlate.emptyHome,
                        headline: "The tower has no floors yet.",
                        line: "Log the first set.",
                        actionTitle: "Log the first set",
                        enabled: !watch.isCommitting
                    ) {
                        logging = true
                    }
                } else if wide {
                    HStack(alignment: .top, spacing: AshlarFace.space(2)) {
                        VStack(spacing: AshlarFace.space(1)) {
                            header
                            hero
                        }
                        ScrollView {
                            chrome
                        }
                        .scrollDismissesKeyboard(.immediately)
                        .frame(width: min(400, proxy.size.width * 0.42))
                    }
                    .padding(.horizontal, AshlarFace.space(2))
                    .padding(.bottom, AshlarFace.space(1))
                } else {
                    ScrollView {
                        VStack(spacing: AshlarFace.space(1)) {
                            header
                            hero
                                .frame(height: max(AshlarFace.space(30), proxy.size.height * 0.42))
                            chrome
                        }
                    }
                    .scrollDismissesKeyboard(.immediately)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .background(AshlarSwatch.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if showsBedDock {
                bedDock
            }
        }
        .navigationTitle("Tower")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AshlarSwatch.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $showTwist) {
            BedFoldView(watch: watch, onClose: { showTwist = false })
        }
        .sheet(item: $pickedCourse) { course in
            AshlarCourseFold(course: course, watch: watch) {
                pickedCourse = nil
            }
        }
        .sensoryFeedback(.success, trigger: watch.commitTick)
        .onChange(of: watch.bedTick) { _, _ in
            flashSuccess()
        }
        .onDisappear {
            successTask?.cancel()
        }
        .overlay {
            if showSuccess {
                Image(AshlarPlate.successMark)
                    .resizable()
                    .scaledToFit()
                    .frame(width: AshlarFace.space(10), height: AshlarFace.space(10))
                    .accessibilityHidden(true)
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
        .animation(reduceMotion ? AshlarFace.fade : AshlarFace.motion, value: showSuccess)
    }

    private var showsBedDock: Bool {
        !watch.isHauling && !watch.loadFailed && !(watch.isFreshTower && !logging)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AshlarFace.space(1)) {
            ZStack(alignment: .topTrailing) {
                Image(AshlarPlate.headerDecor)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: AshlarFace.space(8))
                    .accessibilityHidden(true)
                    .allowsHitTesting(false)
                AshlarGlyphButton(
                    systemName: "info.circle",
                    label: "How floors are written",
                    enabled: true
                ) {
                    showTwist = true
                }
            }
            Text(watch.jobTitle)
                .ashlarInk(.spire)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(watch.jobLine)
                .font(AshlarFace.font(.body))
                .foregroundStyle(AshlarSwatch.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
            Button {
                watch.tab = .analytics
            } label: {
                HStack(spacing: AshlarFace.space(2)) {
                    stripFigure(AshlarFigure.count(watch.steeple.beddedFloorCount), "Floors")
                    stripFigure(AshlarFigure.kilograms(watch.liveTonnage), "Scaffold kg")
                    stripFigure(AshlarFigure.count(watch.steeple.dailyFloorGoal), "Goal")
                }
                .padding(.horizontal, AshlarFace.space(2))
                .frame(maxWidth: .infinity, minHeight: AshlarFace.tap, alignment: .leading)
                .ashlarCardFill()
                .contentShape(AshlarFace.cardShape)
            }
            .buttonStyle(AshlarPressStyle(enabled: true))
            .accessibilityLabel(
                "Analytics, \(AshlarFigure.count(watch.steeple.beddedFloorCount)) floors, scaffold \(AshlarFigure.kilogramsWithUnit(watch.liveTonnage)), goal \(AshlarFigure.count(watch.steeple.dailyFloorGoal))"
            )
            if let fault = watch.fault, !watch.loadFailed {
                AshlarBanner(text: fault) {
                    Task { await watch.retry() }
                }
            }
        }
        .padding(.horizontal, AshlarFace.space(2))
        .padding(.bottom, AshlarFace.space(1))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func stripFigure(_ value: String, _ caption: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value)
                .ashlarInk(.figure)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .layoutPriority(1)
            Text(caption)
                .font(AshlarFace.font(.caption))
                .foregroundStyle(AshlarSwatch.ink)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var hero: some View {
        ClimbableSteeple(steeple: watch.steeple, today: watch.today) { course in
            pickedCourse = course
        }
        .padding(.horizontal, AshlarFace.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(reduceMotion ? AshlarFace.fade : AshlarFace.motion, value: watch.steeple.beddedFloorCount)
        .animation(reduceMotion ? AshlarFace.fade : AshlarFace.motion, value: watch.liveTonnage)
    }

    private var chrome: some View {
        VStack(alignment: .leading, spacing: AshlarFace.space(2)) {
            DisclosureGroup("Today’s scaffold", isExpanded: $openScaffold) {
                scaffoldSection
            }
            .ashlarInk(.title)
            .padding(AshlarFace.space(2))
            .frame(maxWidth: .infinity, alignment: .leading)
            .ashlarCardFill()

            DisclosureGroup("Write a set", isExpanded: $openLog) {
                SetLogFold(watch: watch)
                    .padding(.top, AshlarFace.space(1))
            }
            .ashlarInk(.title)
            .padding(AshlarFace.space(2))
            .frame(maxWidth: .infinity, alignment: .leading)
            .ashlarCardFill()
        }
        .padding(.horizontal, AshlarFace.space(2))
        .padding(.bottom, AshlarFace.space(2))
    }

    private var scaffoldSection: some View {
        VStack(alignment: .leading, spacing: AshlarFace.space(1)) {
            HStack(alignment: .firstTextBaseline, spacing: AshlarFace.space(2)) {
                figure(AshlarFigure.kilogramsWithUnit(watch.liveTonnage), "Live")
                figure(AshlarFigure.count(watch.waitingFold.floors), "Floors waiting")
                figure(AshlarFigure.kilogramsWithUnit(watch.waitingFold.remainder), "Carry")
            }
            if let open = watch.openToday {
                Text("Stub \(AshlarFigure.kilogramsWithUnit(open.stubKilograms))")
                    .font(AshlarFace.font(.caption).monospacedDigit())
                    .foregroundStyle(AshlarSwatch.ink)
                ForEach(open.sets) { logged in
                    HStack {
                        Text(watch.liftName(logged.liftID))
                            .font(AshlarFace.font(.callout))
                            .foregroundStyle(AshlarSwatch.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                        Spacer(minLength: AshlarFace.space(1))
                        Text("\(AshlarFigure.kilograms(logged.weightKilograms)) × \(AshlarFigure.count(logged.reps))")
                            .font(AshlarFace.font(.callout).monospacedDigit())
                            .foregroundStyle(AshlarSwatch.ink)
                            .lineLimit(1)
                            .layoutPriority(1)
                    }
                    .frame(maxWidth: .infinity, minHeight: AshlarFace.space(4), alignment: .leading)
                }
            } else if watch.steeple.remainderKilograms > 0 {
                Text("Remainder \(AshlarFigure.kilogramsWithUnit(watch.steeple.remainderKilograms)) waits for the first set.")
                    .font(AshlarFace.font(.callout))
                    .foregroundStyle(AshlarSwatch.ink)
            } else {
                Text("No sets on today’s scaffold yet.")
                    .font(AshlarFace.font(.callout))
                    .foregroundStyle(AshlarSwatch.ink)
            }
        }
        .padding(.top, AshlarFace.space(1))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func figure(_ value: String, _ caption: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value)
                .ashlarInk(.figure)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .layoutPriority(1)
            Text(caption)
                .font(AshlarFace.font(.caption))
                .foregroundStyle(AshlarSwatch.ink)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var bedDock: some View {
        VStack(spacing: AshlarFace.space(1)) {
            bedButton
        }
        .padding(.horizontal, AshlarFace.space(2))
        .padding(.top, AshlarFace.space(1))
        .padding(.bottom, AshlarFace.space(1))
        .frame(maxWidth: .infinity)
        .background(AshlarSwatch.surface)
        .ashlarRaised()
    }

    private var bedButton: some View {
        AshlarChromeButton(
            title: "Bed the session",
            detail: watch.bedDetail,
            artwork: AshlarPlate.controlFace,
            fills: true,
            emphasized: true,
            enabled: watch.canBedSession,
            busy: watch.isCommitting,
            hint: "Folds today’s scaffold into 500 kg floors."
        ) {
            AshlarKeyboard.dismiss()
            Task { await watch.bedSession() }
        }
    }

    private func flashSuccess() {
        successTask?.cancel()
        successTask = Task {
            showSuccess = true
            try? await Task.sleep(nanoseconds: 900_000_000)
            guard !Task.isCancelled else { return }
            showSuccess = false
        }
    }
}
