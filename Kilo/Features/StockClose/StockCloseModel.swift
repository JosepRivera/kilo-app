import Foundation

private let spanishNumberWords: [Int: String] = [
    1: "uno", 2: "dos", 3: "tres", 4: "cuatro", 5: "cinco",
    6: "seis", 7: "siete", 8: "ocho", 9: "nueve", 10: "diez",
    11: "once", 12: "doce", 13: "trece", 14: "catorce", 15: "quince",
    16: "dieciséis", 17: "diecisiete", 18: "dieciocho", 19: "diecinueve",
]

private func spanishNumberWord(_ value: Int) -> String {
    spanishNumberWords[value] ?? "\(value)"
}

private func roundToUnitStep(_ value: Double, unit: String) -> Double {
    let step = isCountUnit(unit) ? 1.0 : 0.5
    return (value / step).rounded() * step
}

struct HeardScenario {
    struct Mistranscription {
        let supplyId: String
        let heardValue: Double
        let heardWord: String
        let suggestedValue: Double
        let suggestedWord: String
    }

    let heard: [String: Double]
    let anomalyId: String?
    let mistranscription: Mistranscription?

    static func build(engine: Engine, supplies: [SupplyInfo]) -> HeardScenario {
        var heard: [String: Double] = [:]
        for supply in supplies {
            heard[supply.id] = roundToUnitStep(engine.expectedRemainingTonight(supply.id), unit: supply.unit)
        }

        func anomalousRemaining(for supply: SupplyInfo) -> Double? {
            let step = isCountUnit(supply.unit) ? 1.0 : 0.5
            var remaining = roundToUnitStep(engine.currentStock(supply.id), unit: supply.unit)
            while remaining >= 0 {
                if engine.checkClose(supply.id, remaining: remaining) != nil {
                    return max(0, remaining - step)
                }
                remaining -= step
            }
            return nil
        }

        let preferred = ["beef", "potato"]
        let ordered = supplies.sorted {
            (preferred.firstIndex(of: $0.id) ?? preferred.count) < (preferred.firstIndex(of: $1.id) ?? preferred.count)
        }
        var anomalyId: String?
        for supply in ordered where !isCountUnit(supply.unit) {
            if let remaining = anomalousRemaining(for: supply) {
                heard[supply.id] = remaining
                anomalyId = supply.id
                break
            }
        }

        func digit(for supply: SupplyInfo) -> Int? {
            let value = min(9, max(1, Int(heard[supply.id] ?? 0)))
            return engine.currentStock(supply.id) >= Double(value) ? value : nil
        }

        let candidates = supplies.filter { $0.id != anomalyId && isCountUnit($0.unit) }
        let chosen = candidates.first { $0.id == "corn" && digit(for: $0) != nil }
            ?? candidates.first { $0.id == "egg" && digit(for: $0) != nil }
            ?? candidates.first { digit(for: $0) != nil }

        var mistranscription: Mistranscription?
        if let chosen, let digit = digit(for: chosen) {
            let heardValue = Double(digit + 10)
            heard[chosen.id] = heardValue
            mistranscription = Mistranscription(
                supplyId: chosen.id,
                heardValue: heardValue,
                heardWord: spanishNumberWord(digit + 10),
                suggestedValue: Double(digit),
                suggestedWord: spanishNumberWord(digit)
            )
        }

        return HeardScenario(heard: heard, anomalyId: anomalyId, mistranscription: mistranscription)
    }
}

struct StockCloseModel {
    struct Row: Identifiable {
        let supply: SupplyInfo
        let flag: AnomalyFlag?
        var id: String { supply.id }
    }

    let rows: [Row]
    let transcript: String

    init(engine: Engine, supplies: [SupplyInfo], scenario: HeardScenario, values: [String: Double]) {
        rows = supplies.map { supply in
            let value = values[supply.id] ?? scenario.heard[supply.id] ?? 0
            return Row(supply: supply, flag: engine.checkClose(supply.id, remaining: value))
        }
        transcript = StockCloseModel.buildTranscript(supplies: supplies, heard: scenario.heard)
    }

    private static func buildTranscript(supplies: [SupplyInfo], heard: [String: Double]) -> String {
        let parts = supplies.compactMap { supply -> String? in
            guard let value = heard[supply.id], value > 0 else { return nil }
            return "\(withUnit(value, supply.unit)) de \(supply.name.lowercased())"
        }
        let listed = parts.formatted(.list(type: .and).locale(Locale(identifier: "es_PE")))
        if parts.isEmpty { return "«No queda nada.»" }
        return parts.count < supplies.count ? "«Quedan \(listed). Lo demás se acabó.»" : "«Quedan \(listed).»"
    }
}
