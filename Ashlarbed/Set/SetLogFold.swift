import SwiftUI

/// Role: Set. Fused set log on Tower. Pick a lift, enter weight and reps, write the set. Never inserts a Storey.
struct SetLogFold: View {
    var watch: SteepleWatch
    @State private var liftID: UUID?
    @State private var weightDraft = ""
    @State private var repsDraft = ""
    @FocusState private var focus: Field?

    private enum Field: Hashable {
        case weight
        case reps
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AshlarFace.space(1)) {
            if watch.steeple.lifts.isEmpty {
                Text("Add a lift in Settings before logging.")
                    .font(AshlarFace.font(.callout))
                    .foregroundStyle(AshlarSwatch.ink)
                    .frame(maxWidth: .infinity, minHeight: AshlarFace.tap, alignment: .leading)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AshlarFace.space(1)) {
                        ForEach(watch.steeple.lifts) { lift in
                            let selected = lift.id == (liftID ?? watch.steeple.lifts.first?.id)
                            Button {
                                liftID = lift.id
                            } label: {
                                HStack(spacing: AshlarFace.space(1)) {
                                    if selected {
                                        Image(systemName: "checkmark")
                                            .font(AshlarFace.font(.caption).weight(.semibold))
                                            .foregroundStyle(AshlarSwatch.ink)
                                            .accessibilityHidden(true)
                                    }
                                    Text(lift.name)
                                        .font(AshlarFace.font(.callout).weight(.semibold))
                                        .foregroundStyle(AshlarSwatch.ink)
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, AshlarFace.space(2))
                                .frame(minHeight: AshlarFace.tap)
                                .background(AshlarSwatch.surface)
                                .clipShape(AshlarFace.chipShape)
                                .overlay {
                                    AshlarFace.chipShape.stroke(
                                        selected ? AshlarSwatch.accent : AshlarSwatch.muted.opacity(0.35),
                                        lineWidth: selected ? 2 : 1
                                    )
                                }
                                .ashlarRaised()
                                .contentShape(AshlarFace.chipShape)
                            }
                            .buttonStyle(AshlarPressStyle(enabled: true))
                            .accessibilityLabel(lift.name)
                            .accessibilityValue(selected ? "Selected" : "Not selected")
                        }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: AshlarFace.tap, alignment: .leading)
                .accessibilityLabel("Lift")

                TextField("Weight", text: $weightDraft)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.plain)
                    .font(AshlarFace.font(.body).monospacedDigit())
                    .foregroundStyle(AshlarSwatch.ink)
                    .padding(.horizontal, AshlarFace.space(1))
                    .frame(maxWidth: .infinity, minHeight: AshlarFace.tap)
                    .background(AshlarSwatch.background)
                    .clipShape(AshlarFace.chipShape)
                    .focused($focus, equals: .weight)
                    .onChange(of: weightDraft) { _, next in
                        let cleaned = AshlarFigure.sanitizeDecimal(next)
                        if cleaned != next { weightDraft = cleaned }
                    }
                    .accessibilityLabel("Weight in kilograms")

                TextField("Reps", text: $repsDraft)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.plain)
                    .font(AshlarFace.font(.body).monospacedDigit())
                    .foregroundStyle(AshlarSwatch.ink)
                    .padding(.horizontal, AshlarFace.space(1))
                    .frame(maxWidth: .infinity, minHeight: AshlarFace.tap)
                    .background(AshlarSwatch.background)
                    .clipShape(AshlarFace.chipShape)
                    .focused($focus, equals: .reps)
                    .onChange(of: repsDraft) { _, next in
                        let cleaned = AshlarFigure.sanitizeCount(next)
                        if cleaned != next { repsDraft = cleaned }
                    }
                    .accessibilityLabel("Repetitions")

                if let preview = previewLine {
                    Text(preview)
                        .font(AshlarFace.font(.caption).monospacedDigit())
                        .foregroundStyle(AshlarSwatch.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                AshlarChromeButton(
                    title: "Write the set",
                    detail: watch.canWriteSet ? "Adds tonnage to today’s scaffold." : "Today is already bedded.",
                    fills: true,
                    emphasized: false,
                    enabled: canWrite,
                    busy: watch.isCommitting,
                    hint: "Logs weight times reps onto the open scaffold."
                ) {
                    focus = nil
                    guard let liftID, let weight = AshlarFigure.parseDecimal(weightDraft), let reps = AshlarFigure.parseCount(repsDraft) else {
                        return
                    }
                    Task {
                        await watch.writeSet(liftID: liftID, weight: weight, reps: reps)
                        if watch.fault == nil {
                            weightDraft = ""
                            repsDraft = ""
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            if liftID == nil {
                liftID = watch.steeple.lifts.first?.id
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focus = nil }
                    .accessibilityLabel("Done")
            }
        }
    }

    private var canWrite: Bool {
        watch.canWriteSet
            && liftID != nil
            && AshlarFigure.parseDecimal(weightDraft) != nil
            && AshlarFigure.parseCount(repsDraft) != nil
    }

    private var previewLine: String? {
        guard let weight = AshlarFigure.parseDecimal(weightDraft), let reps = AshlarFigure.parseCount(repsDraft) else {
            return nil
        }
        let tonnage = StoreyFold.tonnage(weight: weight, reps: reps)
        let epley = StoreyFold.epley1RM(weight: weight, reps: reps)
        return "Tonnage \(AshlarFigure.kilogramsWithUnit(tonnage)) · Epley \(AshlarFigure.kilogramsWithUnit(epley))"
    }
}
