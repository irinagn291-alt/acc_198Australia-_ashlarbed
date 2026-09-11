import SwiftUI

/// Role: Steeple. Three-to-four pages. Skip still writes defaults. Re-runnable from Settings.
struct AshlarPassage: View {
    var watch: SteepleWatch
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0
    @State private var experience: Int
    @State private var aim: Int

    private let last = 3

    init(watch: SteepleWatch) {
        self.watch = watch
        _experience = State(initialValue: watch.steeple.experience)
        _aim = State(initialValue: watch.steeple.aim)
    }

    var body: some View {
        VStack(spacing: AshlarFace.space(2)) {
            Group {
                switch page {
                case 0:
                    pageView(
                        image: AshlarPlate.onboarding1,
                        title: "Log a set on the tower",
                        line: "Pick a lift, enter weight and reps. Each set raises today’s scaffold — never a climbable floor."
                    )
                case 1:
                    pageView(
                        image: AshlarPlate.onboarding2,
                        title: "Bed the session",
                        line: "Bed folds the scaffold into 500 kg floors and carries the remainder under 500 kg into tomorrow."
                    )
                case 2:
                    pageView(
                        image: AshlarPlate.onboarding3,
                        title: "Climb the week",
                        line: "Floors stay. A PR stamp appears only when you beat a weight or an Epley 1RM."
                    )
                default:
                    settingsPage
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(reduceMotion ? nil : AshlarFace.motion, value: page)
            AshlarChromeButton(
                title: page < last ? "Next" : "Open the tower",
                fills: true,
                emphasized: true,
                busy: watch.isCommitting
            ) {
                if page < last {
                    page += 1
                } else {
                    Task { await finish(skipped: false) }
                }
            }
            Button {
                Task { await finish(skipped: true) }
            } label: {
                Text("Skip")
                    .ashlarInk(.body)
                    .frame(maxWidth: .infinity, minHeight: AshlarFace.tap)
                    .contentShape(Rectangle())
            }
            .buttonStyle(AshlarPressStyle(enabled: !watch.isCommitting))
            .disabled(watch.isCommitting)
            .accessibilityLabel("Skip")
        }
        .padding(AshlarFace.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AshlarSwatch.background.ignoresSafeArea())
    }

    private var settingsPage: some View {
        VStack(spacing: AshlarFace.space(2)) {
            Image(AshlarPlate.twistHero)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityHidden(true)
            Text("Set the day’s aim")
                .ashlarInk(.spire)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            Text("Daily floor goal is experience times aim. Both stay on this device.")
                .font(AshlarFace.font(.body))
                .foregroundStyle(AshlarSwatch.ink)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            VStack(alignment: .leading, spacing: AshlarFace.space(1)) {
                Stepper(value: $experience, in: StoreyFold.experienceSpan) {
                    Text("Experience \(AshlarFigure.count(experience))")
                        .ashlarInk(.body)
                }
                .frame(minHeight: AshlarFace.tap)
                Stepper(value: $aim, in: StoreyFold.aimSpan) {
                    Text("Aim \(AshlarFigure.count(aim))")
                        .ashlarInk(.body)
                }
                .frame(minHeight: AshlarFace.tap)
                Text("Goal \(AshlarFigure.count(experience * aim)) floors")
                    .font(AshlarFace.font(.callout).monospacedDigit())
                    .foregroundStyle(AshlarSwatch.ink)
            }
            .padding(AshlarFace.space(2))
            .frame(maxWidth: .infinity, alignment: .leading)
            .ashlarCardFill()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func pageView(image: String, title: String, line: String) -> some View {
        VStack(spacing: AshlarFace.space(2)) {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityHidden(true)
            Text(title)
                .ashlarInk(.spire)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            Text(line)
                .font(AshlarFace.font(.body))
                .foregroundStyle(AshlarSwatch.ink)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func finish(skipped: Bool) async {
        if !skipped {
            await watch.setExperience(experience)
            await watch.setAim(aim)
        }
        await watch.finishOnboarding(skipped: skipped)
    }
}
