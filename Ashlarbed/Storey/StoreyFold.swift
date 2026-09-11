import Foundation

/// Role: Storey. Family math: tonnage = weight × reps; Epley 1RM = w × (1 + reps / 30); 500 kg = 1 floor.
enum StoreyFold: Sendable {
    static let kilogramsPerStorey: Double = 500
    static let experienceSpan = 1 ... 99
    static let aimSpan = 1 ... 99

    static func tonnage(weight: Double, reps: Int) -> Double {
        weight * Double(reps)
    }

    static func epley1RM(weight: Double, reps: Int) -> Double {
        weight * (1 + Double(reps) / 30)
    }

    static func floorsAndRemainder(tonnage: Double) -> (floors: Int, remainder: Double) {
        guard tonnage.isFinite, tonnage > 0 else { return (0, 0) }
        let floors = Int(tonnage / kilogramsPerStorey)
        let remainder = tonnage - (Double(floors) * kilogramsPerStorey)
        return (floors, remainder)
    }

    static func dailyFloorGoal(experience: Int, aim: Int) -> Int {
        experience * aim
    }

    /// Stamps only when the session number strictly beats prior bedded work. Equal is not earned.
    static func earnedStamps(
        session: [LoggedSet],
        prior: [LoggedSet],
        ids: [UUID] = []
    ) -> [PRStamp] {
        var stamps: [PRStamp] = []
        var nextID = 0
        let liftIDs = Array(Set(session.map(\.liftID))).sorted { $0.uuidString < $1.uuidString }
        for liftID in liftIDs {
            let group = session.filter { $0.liftID == liftID }
            let priorGroup = prior.filter { $0.liftID == liftID }
            let priorWeight = priorGroup.map(\.weightKilograms).max() ?? 0
            let priorEpley = priorGroup.map(\.epley1RM).max() ?? 0
            if let best = group.max(by: { $0.weightKilograms < $1.weightKilograms }),
               best.weightKilograms > priorWeight {
                let id = ids.indices.contains(nextID) ? ids[nextID] : UUID()
                nextID += 1
                stamps.append(
                    PRStamp(
                        id: id,
                        liftID: liftID,
                        kind: .rawWeight,
                        value: best.weightKilograms,
                        setID: best.id
                    )
                )
            }
            if let best = group.max(by: { $0.epley1RM < $1.epley1RM }),
               best.epley1RM > priorEpley {
                let id = ids.indices.contains(nextID) ? ids[nextID] : UUID()
                nextID += 1
                stamps.append(
                    PRStamp(
                        id: id,
                        liftID: liftID,
                        kind: .epley,
                        value: best.epley1RM,
                        setID: best.id
                    )
                )
            }
        }
        return stamps
    }
}
