import SwiftUI

/// Role: Scaffold. Scaffold-then-bed. Own screen plus the Bed surface on Tower.
struct BedFoldView: View {
    var watch: SteepleWatch
    var onClose: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AshlarFace.space(2)) {
                    Image(AshlarPlate.twistHero)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(height: AshlarFace.space(28))
                        .accessibilityHidden(true)
                    Text("Scaffold, then bed")
                        .ashlarInk(.spire)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    Text("A set always writes weight times reps onto today’s open scaffold. It never lays a climbable floor.")
                        .ashlarInk(.body)
                    Text("Bed the session divides that tonnage into 500 kg storeys, carries the remainder under 500 kg into tomorrow, and stamps an Epley or weight PR only when the number is beaten.")
                        .ashlarInk(.body)
                    Text("Bedding with no sets writes a rest band. Rest is a real course in the steeple, not a missing day.")
                        .ashlarInk(.body)
                    VStack(alignment: .leading, spacing: AshlarFace.space(1)) {
                        Text("Today")
                            .ashlarInk(.title)
                            .lineLimit(1)
                        HStack(spacing: AshlarFace.space(2)) {
                            figure(AshlarFigure.kilogramsWithUnit(watch.liveTonnage), "Scaffold")
                            figure(AshlarFigure.count(watch.waitingFold.floors), "Floors waiting")
                            figure(AshlarFigure.count(watch.steeple.dailyFloorGoal), "Goal")
                        }
                        Text(watch.canBedSession ? watch.bedDetail : "Today is already bedded.")
                            .font(AshlarFace.font(.callout))
                            .foregroundStyle(AshlarSwatch.ink)
                    }
                    .padding(AshlarFace.space(2))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .ashlarCardFill()
                    AshlarChromeButton(
                        title: "Back to the tower",
                        fills: true,
                        emphasized: true
                    ) {
                        watch.tab = .tower
                        close()
                    }
                }
                .padding(AshlarFace.space(2))
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollContentBackground(.hidden)
            .contentMargins(.bottom, AshlarFace.space(3), for: .scrollContent)
            .background(AshlarSwatch.background.ignoresSafeArea())
            .navigationTitle("Scaffold, then bed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        close()
                    } label: {
                        Image(systemName: "xmark")
                            .frame(width: AshlarFace.tap, height: AshlarFace.tap)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Close")
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(AshlarSwatch.background)
        .presentationCornerRadius(AshlarFace.cardRadius)
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

    private func close() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }
}
