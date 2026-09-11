import SwiftUI

/// Role: Steeple. Settings. Lifts, experience, aim, Sources, contact, re-run onboarding, reset.
struct AshlarSettings: View {
    var watch: SteepleWatch
    @State private var confirmReset = false
    @State private var confirmDelete: MasonryLift?
    @State private var openLifts = true
    @State private var openAim = true
    @State private var openSources = true
    @State private var openHouse = true
    @State private var newLiftName = ""
    @State private var draftNames: [UUID: String] = [:]

    var body: some View {
        Group {
            if watch.isHauling {
                ProgressView()
                    .tint(AshlarSwatch.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if watch.loadFailed {
                AshlarVacancy(
                    image: AshlarPlate.emptyList,
                    headline: "Settings could not be read.",
                    line: watch.fault ?? "The steeple started empty.",
                    actionTitle: "Retry",
                    enabled: !watch.isCommitting
                ) {
                    Task { await watch.retry() }
                }
            } else if !watch.onboardingComplete {
                AshlarVacancy(
                    image: AshlarPlate.emptyList,
                    headline: "The tower is not open yet.",
                    line: "Finish the first pages to keep a steeple, then return here.",
                    actionTitle: "Open the pages"
                ) {
                    Task { await watch.reopenOnboarding() }
                }
            } else {
                populated
            }
        }
        .background(AshlarSwatch.background.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AshlarSwatch.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .confirmationDialog(
            "Erase every set, floor, and stamp?",
            isPresented: $confirmReset,
            titleVisibility: .visible
        ) {
            Button("Reset all data", role: .destructive) {
                Task { await watch.resetAll() }
            }
            Button("Keep my steeple", role: .cancel) {}
        }
        .confirmationDialog(
            "Remove this lift from the rack?",
            isPresented: Binding(
                get: { confirmDelete != nil },
                set: { if !$0 { confirmDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Remove lift", role: .destructive) {
                if let lift = confirmDelete {
                    Task { await removeLift(lift) }
                }
                confirmDelete = nil
            }
            Button("Keep it", role: .cancel) {
                confirmDelete = nil
            }
        }
        .onAppear {
            syncDrafts()
        }
        .onChange(of: watch.steeple.lifts) { _, _ in
            syncDrafts()
        }
    }

    private var populated: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AshlarFace.space(2)) {
                summary
                DisclosureGroup("Lifts", isExpanded: $openLifts) {
                    liftsBlock
                }
                .ashlarInk(.title)
                .padding(AshlarFace.space(2))
                .frame(maxWidth: .infinity, alignment: .leading)
                .ashlarCardFill()

                DisclosureGroup("Experience and aim", isExpanded: $openAim) {
                    aimBlock
                }
                .ashlarInk(.title)
                .padding(AshlarFace.space(2))
                .frame(maxWidth: .infinity, alignment: .leading)
                .ashlarCardFill()

                DisclosureGroup("Sources", isExpanded: $openSources) {
                    sourcesBlock
                }
                .ashlarInk(.title)
                .padding(AshlarFace.space(2))
                .frame(maxWidth: .infinity, alignment: .leading)
                .ashlarCardFill()

                DisclosureGroup("Housekeeping", isExpanded: $openHouse) {
                    houseBlock
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
        .scrollDismissesKeyboard(.interactively)
        .scrollContentBackground(.hidden)
        .contentMargins(.bottom, AshlarFace.space(3), for: .scrollContent)
    }

    private var summary: some View {
        Button {
            watch.tab = .analytics
        } label: {
            HStack(spacing: AshlarFace.space(2)) {
                Image(AshlarPlate.controlFace)
                    .resizable()
                    .scaledToFit()
                    .frame(width: AshlarFace.space(7), height: AshlarFace.space(7))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Local steeple")
                        .ashlarInk(.title)
                        .lineLimit(1)
                    Text("Goal \(AshlarFigure.count(watch.steeple.dailyFloorGoal)) floors · \(AshlarFigure.count(watch.steeple.beddedFloorCount)) laid")
                        .font(AshlarFace.font(.callout))
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
        .accessibilityLabel(
            "Analytics, local steeple, goal \(AshlarFigure.count(watch.steeple.dailyFloorGoal)) floors, \(AshlarFigure.count(watch.steeple.beddedFloorCount)) laid"
        )
    }

    private var liftsBlock: some View {
        VStack(alignment: .leading, spacing: AshlarFace.space(1)) {
            ForEach(watch.steeple.lifts) { lift in
                HStack(spacing: AshlarFace.space(1)) {
                    TextField("Lift name", text: draftBinding(lift.id))
                        .font(AshlarFace.font(.body))
                        .foregroundStyle(AshlarSwatch.ink)
                        .padding(.horizontal, AshlarFace.space(1))
                        .frame(maxWidth: .infinity, minHeight: AshlarFace.tap)
                        .background(AshlarSwatch.background)
                        .clipShape(AshlarFace.chipShape)
                        .onSubmit {
                            Task { await persistLifts() }
                        }
                    if watch.steeple.lifts.count > 1 {
                        Button {
                            confirmDelete = lift
                        } label: {
                            Image(systemName: "trash")
                                .font(AshlarFace.font(.body))
                                .foregroundStyle(AshlarSwatch.accent)
                                .frame(width: AshlarFace.tap, height: AshlarFace.tap)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(AshlarPressStyle(enabled: !watch.isCommitting))
                        .accessibilityLabel("Remove \(lift.name)")
                    }
                }
            }
            HStack(spacing: AshlarFace.space(1)) {
                TextField("New lift", text: $newLiftName)
                    .font(AshlarFace.font(.body))
                    .foregroundStyle(AshlarSwatch.ink)
                    .padding(.horizontal, AshlarFace.space(1))
                    .frame(maxWidth: .infinity, minHeight: AshlarFace.tap)
                    .background(AshlarSwatch.background)
                    .clipShape(AshlarFace.chipShape)
                Button {
                    Task { await addLift() }
                } label: {
                    Image(systemName: "plus")
                        .font(AshlarFace.font(.body).weight(.semibold))
                        .foregroundStyle(AshlarSwatch.ink)
                        .frame(width: AshlarFace.tap, height: AshlarFace.tap)
                        .background(AshlarSwatch.background)
                        .clipShape(AshlarFace.chipShape)
                        .contentShape(AshlarFace.chipShape)
                }
                .buttonStyle(AshlarPressStyle(enabled: !watch.isCommitting))
                .disabled(watch.isCommitting)
                .accessibilityLabel("Add lift")
            }
            AshlarChromeButton(
                title: "Save lifts",
                fills: true,
                enabled: !watch.isCommitting,
                busy: watch.isCommitting
            ) {
                Task { await persistLifts() }
            }
        }
        .padding(.top, AshlarFace.space(1))
    }

    private var aimBlock: some View {
        VStack(alignment: .leading, spacing: AshlarFace.space(1)) {
            Stepper(value: experienceBinding, in: StoreyFold.experienceSpan) {
                Text("Experience \(AshlarFigure.count(watch.steeple.experience))")
                    .ashlarInk(.body)
            }
            .frame(minHeight: AshlarFace.tap)
            Stepper(value: aimBinding, in: StoreyFold.aimSpan) {
                Text("Aim \(AshlarFigure.count(watch.steeple.aim))")
                    .ashlarInk(.body)
            }
            .frame(minHeight: AshlarFace.tap)
            Text("Daily floor goal \(AshlarFigure.count(watch.steeple.dailyFloorGoal))")
                .font(AshlarFace.font(.callout).monospacedDigit())
                .foregroundStyle(AshlarSwatch.ink)
        }
        .padding(.top, AshlarFace.space(1))
    }

    private var sourcesBlock: some View {
        VStack(alignment: .leading, spacing: AshlarFace.space(1)) {
            Text("Ashlarbed uses the Epley estimate for one-repetition maximum: weight × (1 + repetitions / 30). This is a personal training log, not medical advice.")
                .font(AshlarFace.font(.callout))
                .foregroundStyle(AshlarSwatch.ink)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(EpleyCite.marks) { mark in
                Link(destination: mark.url) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(mark.title)
                            .ashlarInk(.body)
                        Text(mark.url.absoluteString)
                            .font(AshlarFace.font(.caption))
                            .foregroundStyle(AshlarSwatch.ink)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, minHeight: AshlarFace.tap, alignment: .leading)
                    .contentShape(Rectangle())
                }
            }
        }
        .padding(.top, AshlarFace.space(1))
    }

    private var houseBlock: some View {
        VStack(alignment: .leading, spacing: AshlarFace.space(1)) {
            Link(destination: SteepleClient.contactURL) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Contact Ashlarbed")
                        .ashlarInk(.body)
                    Text(SteepleClient.contactURL.absoluteString)
                        .font(AshlarFace.font(.caption))
                        .foregroundStyle(AshlarSwatch.ink)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, minHeight: AshlarFace.tap, alignment: .leading)
                .contentShape(Rectangle())
            }
            AshlarChromeButton(
                title: "Re-run onboarding",
                fills: true,
                enabled: !watch.isCommitting
            ) {
                Task { await watch.reopenOnboarding() }
            }
            Button {
                confirmReset = true
            } label: {
                Text("Reset all data")
                    .font(AshlarFace.font(.body))
                    .foregroundStyle(AshlarSwatch.accent)
                    .frame(maxWidth: .infinity, minHeight: AshlarFace.tap)
                    .background(AshlarSwatch.background)
                    .clipShape(AshlarFace.cardShape)
                    .contentShape(AshlarFace.cardShape)
            }
            .buttonStyle(AshlarPressStyle(enabled: !watch.isCommitting))
            .disabled(watch.isCommitting)
            .accessibilityLabel("Reset all data")
        }
        .padding(.top, AshlarFace.space(1))
    }

    private var experienceBinding: Binding<Int> {
        Binding(
            get: { watch.steeple.experience },
            set: { value in
                Task { await watch.setExperience(value) }
            }
        )
    }

    private var aimBinding: Binding<Int> {
        Binding(
            get: { watch.steeple.aim },
            set: { value in
                Task { await watch.setAim(value) }
            }
        )
    }

    private func draftBinding(_ id: UUID) -> Binding<String> {
        Binding(
            get: { draftNames[id] ?? watch.liftName(id) },
            set: { draftNames[id] = $0 }
        )
    }

    private func syncDrafts() {
        var next: [UUID: String] = [:]
        for lift in watch.steeple.lifts {
            next[lift.id] = draftNames[lift.id] ?? lift.name
        }
        draftNames = next
    }

    private func persistLifts() async {
        let updated = watch.steeple.lifts.map { lift in
            MasonryLift(id: lift.id, name: (draftNames[lift.id] ?? lift.name))
        }
        await watch.setLifts(updated)
        syncDrafts()
    }

    private func addLift() async {
        let name = newLiftName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        var lifts = watch.steeple.lifts
        lifts.append(MasonryLift(id: UUID(), name: name))
        await watch.setLifts(lifts)
        newLiftName = ""
        syncDrafts()
    }

    private func removeLift(_ lift: MasonryLift) async {
        let remaining = watch.steeple.lifts.filter { $0.id != lift.id }
        await watch.setLifts(remaining)
        syncDrafts()
    }
}
