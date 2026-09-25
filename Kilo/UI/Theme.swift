import SwiftUI

struct KiloScreen: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background(Color.kiloGround)
    }
}

extension View {
    func kiloScreen() -> some View { modifier(KiloScreen()) }
}

struct SupplyIcon: View {
    let supply: SupplyInfo
    var size: CGFloat = 32

    var body: some View {
        Image(supply.assetName)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

struct RangeBar: View {
    let fraction: Double

    var body: some View {
        GeometryReader { geo in
            let x = geo.size.width * min(max(fraction, 0), 1)
            ZStack(alignment: .leading) {
                Capsule().fill(Color.kiloTrack)
                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: max(geo.size.width - x, 0))
                    .offset(x: x)
                Circle()
                    .fill(Color.primary)
                    .frame(width: 8, height: 8)
                    .offset(x: min(max(x - 4, 0), geo.size.width - 8))
            }
        }
        .frame(height: 6)
        .accessibilityHidden(true)
    }
}

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
