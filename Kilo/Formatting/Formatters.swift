import Foundation

func isCountUnit(_ unit: String) -> Bool { unit != "kg" && unit != "litros" }

func formatQuantity(_ value: Double) -> String {
    value.formatted(.number.precision(.fractionLength(0...1)).locale(Locale(identifier: "es_PE")))
}

func withUnit(_ value: Double, _ unit: String) -> String {
    let shown = isCountUnit(unit) ? value.rounded() : value
    let singular = shown == 1 && unit.hasSuffix("s") ? String(unit.dropLast()) : unit
    let label = singular == "unidade" ? "unidad" : singular
    return "\(formatQuantity(shown)) \(label)"
}

func soles(_ value: Double) -> String {
    "S/\(value.formatted(.number.precision(.fractionLength(0)).locale(Locale(identifier: "es_PE"))))"
}

func money(_ value: Double) -> String {
    "S/\(value.formatted(.number.precision(.fractionLength(2)).locale(Locale(identifier: "es_PE"))))"
}

func expiryText(_ days: Int) -> String {
    switch days {
    case ..<0: "venció"
    case 0: "vence hoy"
    case 1: "vence mañana"
    default: "vence en \(days) días"
    }
}

let weekdayShort = ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"]

let weekdayLong = ["lunes", "martes", "miércoles", "jueves", "viernes", "sábado", "domingo"]
